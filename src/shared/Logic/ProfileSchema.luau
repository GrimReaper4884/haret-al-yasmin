--!strict
-- Profile defaults, migration and sanitisation (docs/DATA_SCHEMA.md). Pure.

type ItemDef = { kind: string, stackMax: number, slot: string? }
export type Context = {
	schemaVersion: number,
	maxQirsh: number,
	receiptHistory: number,
	items: { [string]: ItemDef },
}

local ProfileSchema = {}

-- Migration steps: MIGRATIONS[n] upgrades a version-n profile to version n + 1.
local MIGRATIONS: { [number]: (any) -> any } = {}

local function isFinite(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function isPosInt(v: any): boolean
	return isFinite(v) and v > 0 and math.floor(v) == v
end

function ProfileSchema.default(now: number, schemaVersion: number): any
	return {
		schemaVersion = schemaVersion,
		qirsh = 0,
		inventory = {},
		equipped = {},
		quests = {},
		settings = {},
		stats = { firstJoin = now, lastJoin = now, sessions = 0 },
		receipts = {},
	}
end

local function tableOr(v: any): { [any]: any }
	return if type(v) == "table" then v else {}
end

-- Repairs a profile in place so it satisfies every invariant. Never deletes unknown items or quests.
function ProfileSchema.sanitize(p: any, ctx: Context, now: number): any
	-- Currency
	local q = if isFinite(p.qirsh) then math.floor(p.qirsh) else 0
	p.qirsh = math.clamp(q, 0, ctx.maxQirsh)

	-- Inventory
	local inv = tableOr(p.inventory)
	for id, n in pairs(inv) do
		if type(id) ~= "string" or not isPosInt(n) then
			inv[id] = nil
		else
			local def = ctx.items[id]
			if def and n > def.stackMax then
				inv[id] = def.stackMax
			end
		end
	end
	p.inventory = inv

	-- Equipped: must be an owned cosmetic in its own slot
	local eq = tableOr(p.equipped)
	for slot, id in pairs(eq) do
		local def = if type(id) == "string" then ctx.items[id] else nil
		if not def or def.kind ~= "cosmetic" or def.slot ~= slot or not inv[id] then
			eq[slot] = nil
		end
	end
	p.equipped = eq

	-- Quests
	local quests = tableOr(p.quests)
	for id, rec in pairs(quests) do
		if type(id) ~= "string" or type(rec) ~= "table" or (rec.state ~= "active" and rec.state ~= "completed") then
			quests[id] = nil
		else
			rec.startedAt = if isFinite(rec.startedAt) then rec.startedAt else now
			rec.completions = if isFinite(rec.completions) and rec.completions >= 0
				then math.floor(rec.completions)
				else (if rec.state == "completed" then 1 else 0)
			if rec.completedAt ~= nil and not isFinite(rec.completedAt) then
				rec.completedAt = nil
			end
		end
	end
	p.quests = quests

	-- Settings
	local settings = tableOr(p.settings)
	if settings.language ~= "en" and settings.language ~= "ar" then
		settings.language = nil
	end
	p.settings = settings

	-- Stats
	local stats = tableOr(p.stats)
	stats.firstJoin = if isFinite(stats.firstJoin) then stats.firstJoin else now
	stats.lastJoin = if isFinite(stats.lastJoin) then stats.lastJoin else now
	stats.sessions = if isFinite(stats.sessions) and stats.sessions >= 0 then math.floor(stats.sessions) else 0
	p.stats = stats

	-- Receipts: keep only the newest N
	local receipts = tableOr(p.receipts)
	local list = {}
	for id, at in pairs(receipts) do
		if type(id) == "string" and isFinite(at) then
			table.insert(list, { id = id, at = at })
		end
	end
	table.sort(list, function(a, b)
		return a.at > b.at
	end)
	local kept = {}
	for i = 1, math.min(#list, ctx.receiptHistory) do
		kept[list[i].id] = list[i].at
	end
	p.receipts = kept

	p.schemaVersion = ctx.schemaVersion
	return p
end

-- Turns whatever is stored into a valid current-version profile.
-- Errors: "corrupt" (not a table), "newer_schema" (written by a newer server).
function ProfileSchema.load(raw: any, ctx: Context, now: number): (any?, string?)
	if raw == nil then
		return ProfileSchema.default(now, ctx.schemaVersion), nil
	end
	if type(raw) ~= "table" then
		return nil, "corrupt"
	end
	local version = if isFinite(raw.schemaVersion) then raw.schemaVersion else 1
	if version > ctx.schemaVersion then
		return nil, "newer_schema"
	end
	local data = raw
	while version < ctx.schemaVersion do
		local step = MIGRATIONS[version]
		if not step then
			return nil, "corrupt"
		end
		data = step(data)
		version += 1
	end
	return ProfileSchema.sanitize(data, ctx, now), nil
end

function ProfileSchema.beginSession(p: any, now: number)
	p.stats.sessions += 1
	p.stats.lastJoin = now
end

-- Deep copy for snapshots / saving (profiles are plain trees of primitives).
function ProfileSchema.clone(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in pairs(v) do
		out[k] = ProfileSchema.clone(x)
	end
	return out
end

return ProfileSchema
