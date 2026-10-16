--!strict
-- Profile defaults, migration and sanitisation (docs/DATA_SCHEMA.md). Pure.

type ItemDef = { kind: string, stackMax: number, slot: string? }
export type Context = {
	schemaVersion: number,
	maxQirsh: number,
	maxLira: number,
	maxStones: number,
	receiptHistory: number,
	items: { [string]: ItemDef },
	units: { [string]: any },
	traits: { [string]: any },
	starterUnit: string,
	starterLira: number?,
	season: string,
}

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Settings = sibling("Settings")
local EventLogic = sibling("EventLogic")
local AfkLogic = sibling("AfkLogic")

local ProfileSchema = {}

-- Migration steps: MIGRATIONS[n] upgrades a version-n profile to version n + 1.
local MIGRATIONS: { [number]: (any) -> any } = {
	-- v1 → v2: tower-defense fields. All of them have defaults filled in by sanitize.
	[1] = function(p: any): any
		return p
	end,
}

local function isFinite(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function isPosInt(v: any): boolean
	return isFinite(v) and v > 0 and math.floor(v) == v
end

-- ctx (optional) fills the starter unit, loadout and current season so a fresh default is
-- already a fixed point of sanitize.
function ProfileSchema.default(now: number, schemaVersion: number, ctx: Context?): any
	local units: { [string]: any } = {}
	local loadout: { string } = {}
	if ctx and ctx.units[ctx.starterUnit] then
		units[ctx.starterUnit] = { copies = 0, trait = "steady", at = now }
		loadout = { ctx.starterUnit }
	end
	return {
		schemaVersion = schemaVersion,
		qirsh = 0,
		inventory = {},
		equipped = {},
		quests = {},
		settings = {},
		stats = { firstJoin = now, lastJoin = now, sessions = 0 },
		receipts = {},
		-- Tower defense (schema v2)
		lira = if ctx then ctx.starterLira or 0 else 0,
		welcomeLira = if ctx then true else nil, -- the starter lira gift has been paid
		traitStones = 0,
		units = units,
		loadout = loadout,
		summons = { total = 0, sinceLegendary = 0, sinceMythic = 0 },
		pass = { season = if ctx then ctx.season else "", xp = 0, premium = false, claimedFree = {}, claimedPremium = {} },
		codes = {},
		bundles = {},
		events = {}, -- Logic/EventLogic: { [eventId] = { currency, bought } }
		daily = { streak = 0, lastDay = 0 },
		afk = { day = 0, lira = 0, carry = 0, cups = 0, tales = 0, seconds = 0 }, -- Logic/AfkLogic
		td = { matches = 0, wins = 0, kills = 0, cleared = {}, bestInfinite = 0 },
	}
end

local function nonNegInt(v: any, default: number): number
	return if isFinite(v) and v >= 0 then math.floor(v) else default
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
			-- Objective progress (investigations): { [objectiveId]: true }
			if rec.progress ~= nil then
				if type(rec.progress) ~= "table" then
					rec.progress = nil
				else
					for k, v in pairs(rec.progress) do
						if type(k) ~= "string" or v ~= true then
							rec.progress[k] = nil
						end
					end
				end
			end
		end
	end
	p.quests = quests

	-- Settings
	local settings = tableOr(p.settings)
	if settings.language ~= "en" and settings.language ~= "ar" then
		settings.language = nil
	end
	p.settings = Settings.sanitize(settings)

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

	-- Tower defense -------------------------------------------------------------------------
	p.lira = math.clamp(nonNegInt(p.lira, 0), 0, ctx.maxLira)
	-- One-time welcome lira so a new player can summon at once (players saved before the gift get it too)
	if p.welcomeLira ~= true then
		p.lira = math.clamp(p.lira + (ctx.starterLira or 0), 0, ctx.maxLira)
		p.welcomeLira = true
	end
	p.traitStones = math.clamp(nonNegInt(p.traitStones, 0), 0, ctx.maxStones)

	local units = tableOr(p.units)
	for id, rec in pairs(units) do
		if type(id) ~= "string" or ctx.units[id] == nil or type(rec) ~= "table" then
			units[id] = nil
		else
			rec.copies = nonNegInt(rec.copies, 0)
			if type(rec.trait) ~= "string" or ctx.traits[rec.trait] == nil then
				rec.trait = "steady"
			end
			rec.at = if isFinite(rec.at) then rec.at else now
		end
	end
	if ctx.units[ctx.starterUnit] and units[ctx.starterUnit] == nil then
		units[ctx.starterUnit] = { copies = 0, trait = "steady", at = now }
	end
	p.units = units

	local loadout = {}
	local seen = {}
	for _, id in ipairs(tableOr(p.loadout)) do
		if type(id) == "string" and units[id] and not seen[id] then
			seen[id] = true
			table.insert(loadout, id)
		end
	end
	if #loadout == 0 and units[ctx.starterUnit] then
		loadout = { ctx.starterUnit }
	end
	p.loadout = loadout

	local summons = tableOr(p.summons)
	summons.total = nonNegInt(summons.total, 0)
	summons.sinceLegendary = nonNegInt(summons.sinceLegendary, 0)
	summons.sinceMythic = nonNegInt(summons.sinceMythic, 0)
	p.summons = summons

	local pass = tableOr(p.pass)
	if pass.season ~= ctx.season then
		pass = { season = ctx.season, xp = 0, premium = false, claimedFree = {}, claimedPremium = {} }
	end
	pass.xp = nonNegInt(pass.xp, 0)
	pass.premium = pass.premium == true
	pass.claimedFree = tableOr(pass.claimedFree)
	pass.claimedPremium = tableOr(pass.claimedPremium)
	p.pass = pass

	local codes = tableOr(p.codes)
	for code, at in pairs(codes) do
		if type(code) ~= "string" or not isFinite(at) then
			codes[code] = nil
		end
	end
	p.codes = codes

	local bundles = tableOr(p.bundles)
	for key, at in pairs(bundles) do
		if type(key) ~= "string" or not isFinite(at) then
			bundles[key] = nil
		end
	end
	p.bundles = bundles
	p.events = EventLogic.sanitize(p.events)

	local daily = tableOr(p.daily)
	daily.streak = nonNegInt(daily.streak, 0)
	daily.lastDay = nonNegInt(daily.lastDay, 0)
	p.daily = daily
	p.afk = AfkLogic.sanitize(p.afk)

	local td = tableOr(p.td)
	td.matches = nonNegInt(td.matches, 0)
	td.wins = nonNegInt(td.wins, 0)
	td.kills = nonNegInt(td.kills, 0)
	td.bestInfinite = nonNegInt(td.bestInfinite, 0)
	local cleared = tableOr(td.cleared)
	for mode, diff in pairs(cleared) do
		if type(mode) ~= "string" or (diff ~= "normal" and diff ~= "hard" and diff ~= "nightmare") then
			cleared[mode] = nil
		end
	end
	td.cleared = cleared
	p.td = td

	p.schemaVersion = ctx.schemaVersion
	return p
end

-- Turns whatever is stored into a valid current-version profile.
-- Errors: "corrupt" (not a table), "newer_schema" (written by a newer server).
function ProfileSchema.load(raw: any, ctx: Context, now: number): (any?, string?)
	if raw == nil then
		return ProfileSchema.default(now, ctx.schemaVersion, ctx), nil
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
