--!strict
-- Wraps a DataStore behind a tiny interface so DataService can run against the real
-- DataStoreService or an in-memory mock (unpublished Studio places, or API access disabled).
-- The mock supports failure injection for testing retry and data-loss handling.

local DataStoreService = game:GetService("DataStoreService")

export type Transform = (current: any) -> (any, { number }?)

export type Store = {
	isMock: boolean,
	-- Runs an UpdateAsync. Raises on failure (callers retry). The transform may run more than once.
	update: (self: Store, key: string, transform: Transform) -> (),
	-- Mock only: make the next n calls raise.
	failNext: (self: Store, n: number) -> (),
	-- Mock only: read raw stored value (tests).
	peek: (self: Store, key: string) -> any,
}

local DataStoreAdapter = {}

local function deepCopy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in pairs(v) do
		out[k] = deepCopy(x)
	end
	return out
end

function DataStoreAdapter.mock(): Store
	local data: { [string]: any } = {}
	local failures = 0
	local store = { isMock = true } :: any

	function store.update(_, key: string, transform: Transform)
		if failures > 0 then
			failures -= 1
			error("MockDataStore: injected failure")
		end
		local nextValue = transform(deepCopy(data[key]))
		if nextValue ~= nil then
			data[key] = deepCopy(nextValue)
		end
	end

	function store.failNext(_, n: number)
		failures = n
	end

	function store.peek(_, key: string): any
		return deepCopy(data[key])
	end

	return store :: Store
end

local function real(ds: DataStore): Store
	local store = { isMock = false } :: any

	function store.update(_, key: string, transform: Transform)
		ds:UpdateAsync(key, function(current: any, _keyInfo: DataStoreKeyInfo?)
			local value, userIds = transform(current)
			if value == nil then
				return nil
			end
			return value, userIds
		end)
	end

	function store.failNext(_, _n: number)
		warn("[DataStoreAdapter] failNext is only available on the mock store")
	end

	function store.peek(_, _key: string): any
		return nil
	end

	return store :: Store
end

-- Picks the real store when the place can use DataStores, otherwise the mock.
function DataStoreAdapter.create(name: string): Store
	if game.PlaceId == 0 then
		warn("[DataService] PERSISTENCE DISABLED (mock store): place is not published")
		return DataStoreAdapter.mock()
	end
	local okStore, ds = pcall(function()
		return DataStoreService:GetDataStore(name)
	end)
	if not okStore then
		warn("[DataService] PERSISTENCE DISABLED (mock store): " .. tostring(ds))
		return DataStoreAdapter.mock()
	end
	-- Probe with a no-op write: Studio without "Enable Studio Access to API Services" raises
	-- ("403: Cannot write to DataStore from studio if API access is not enabled" or
	-- "StudioAccessToApisNotAllowed"); reads can succeed even then, so a read is not enough.
	local okProbe, probeErr = pcall(function()
		(ds :: DataStore):UpdateAsync("__probe", function()
			return nil
		end)
	end)
	if not okProbe then
		local msg = tostring(probeErr)
		if string.find(msg, "StudioAccessToApisNotAllowed", 1, true) or string.find(msg, "API access", 1, true) or string.find(msg, "403", 1, true) then
			warn("[DataService] PERSISTENCE DISABLED (mock store): Studio API access is off")
			return DataStoreAdapter.mock()
		end
		warn("[DataService] DataStore probe failed (using real store, calls will retry): " .. msg)
	end
	return real(ds :: DataStore)
end

return DataStoreAdapter
