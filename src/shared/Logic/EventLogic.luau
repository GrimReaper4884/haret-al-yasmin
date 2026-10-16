--!strict
-- Limited-time events (Config/Events): which are running, the event currency a match earns, and
-- buying from an event shop. All state lives in profile.events[eventId] = { currency, bought }.
-- Pure; the server calls these inside DataService.mutate.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Grants = sibling("Grants")

local EventLogic = {}

function EventLogic.isActive(def: any, now: number): boolean
	return def ~= nil and now >= def.startsAt and now < def.endsAt
end

-- Ids of running events, sorted.
function EventLogic.active(events: { [string]: any }, now: number): { string }
	local out = {}
	for id, def in events do
		if EventLogic.isActive(def, now) then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

-- The running event whose mode is `modeId`, or nil.
function EventLogic.forMode(events: { [string]: any }, modeId: string, now: number): string?
	for id, def in events do
		if def.modeId == modeId and EventLogic.isActive(def, now) then
			return id
		end
	end
	return nil
end

local function record(profile: any, eventId: string): any
	local rec = profile.events[eventId]
	if type(rec) ~= "table" then
		rec = { currency = 0, bought = {} }
		profile.events[eventId] = rec
	end
	return rec
end

-- Currency a finished event match pays: perWave per wave held, plus winBonus for a win.
function EventLogic.matchCurrency(def: any, won: boolean, wavesCleared: number): number
	local n = def.perWave * math.max(0, math.floor(wavesCleared))
	if won then
		n += def.winBonus
	end
	return n
end

-- Adds currency (capped). Returns the amount actually added.
function EventLogic.addCurrency(profile: any, eventId: string, def: any, amount: number): number
	if type(amount) ~= "number" or amount <= 0 or amount ~= amount then
		return 0
	end
	local rec = record(profile, eventId)
	local before = rec.currency
	rec.currency = math.min(before + math.floor(amount), def.maxCurrency)
	return rec.currency - before
end

-- Buys one `key` from the event shop. Returns ok, err, granted.
-- err: "unknown_event" | "event_over" | "unknown_item" | "sold_out" | "not_enough"
function EventLogic.buy(profile: any, events: { [string]: any }, eventId: any, key: any, now: number, grantCtx: any): (boolean, string?, any?)
	local def = if type(eventId) == "string" then events[eventId] else nil
	if not def then
		return false, "unknown_event", nil
	end
	if not EventLogic.isActive(def, now) then
		return false, "event_over", nil
	end
	local entry = nil
	for _, e in def.shop do
		if e.key == key then
			entry = e
			break
		end
	end
	if not entry then
		return false, "unknown_item", nil
	end
	local rec = record(profile, eventId)
	local bought = rec.bought[entry.key] or 0
	if bought >= entry.stock then
		return false, "sold_out", nil
	end
	if rec.currency < entry.cost then
		return false, "not_enough", nil
	end
	rec.currency -= entry.cost
	rec.bought[entry.key] = bought + 1
	local granted = Grants.apply(profile, entry.reward, grantCtx)
	return true, nil, granted
end

-- Sanitises profile.events in place (stored data is untrusted too).
function EventLogic.sanitize(events: any): { [string]: any }
	local out = {}
	if type(events) ~= "table" then
		return out
	end
	for id, rec in events do
		if type(id) == "string" and #id <= 40 and type(rec) == "table" then
			local c = rec.currency
			local clean = { currency = if type(c) == "number" and c == c and c >= 0 and c < 1e9 then math.floor(c) else 0, bought = {} }
			if type(rec.bought) == "table" then
				for k, v in rec.bought do
					if type(k) == "string" and #k <= 40 and type(v) == "number" and v == v and v >= 0 and v < 1e6 then
						clean.bought[k] = math.floor(v)
					end
				end
			end
			out[id] = clean
		end
	end
	return out
end

return EventLogic
