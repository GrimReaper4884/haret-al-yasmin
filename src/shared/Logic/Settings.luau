--!strict
-- Player preferences stored in profile.settings (besides `language`, which predates this module).
-- Each setting is an enum (a list of allowed string values) or a boolean, with a default. The
-- server accepts a change only through Settings.accept; sanitize drops anything unknown. Pure.

export type Def = { kind: "enum", values: { string }, default: string } | { kind: "bool", default: boolean }

local Settings = {}

Settings.defs = {
	-- How much visual effect a client draws: full, reduced (no particles / camera moves / shine),
	-- or off (plain beams only). Client-side only; never changes the simulation.
	effects = { kind = "enum", values = { "full", "reduced", "off" }, default = "full" },
	-- Show summon results straight away (no lantern build-up).
	skipSummon = { kind = "bool", default = false },
	-- Defenders fire their ultimate as soon as it is ready (otherwise the player taps it).
	autoUlt = { kind = "bool", default = true },
	-- The camera a match opens in: on foot behind the character, or the watchtower overview.
	camera = { kind = "enum", values = { "walk", "overhead" }, default = "walk" },
	-- Walk a lobby player who has been idle a while up to the Hakawati's room (Config/Afk).
	autoAfk = { kind = "bool", default = true },
	-- Vote to skip the countdown between waves automatically (never the setup before wave 1).
	autoSkip = { kind = "bool", default = false },
	-- Play the lobby / match / boss music loops. Client-side only (AudioController).
	music = { kind = "bool", default = true },
	-- Play one-shot stings (gate, waves, summons, clicks). Client-side only (AudioController).
	sfx = { kind = "bool", default = true },
	-- Short camera moves for story moments (the boss intro push). Client-side only.
	cutscenes = { kind = "bool", default = true },
} :: { [string]: Def }

local function valid(def: Def, value: any): boolean
	if def.kind == "bool" then
		return type(value) == "boolean"
	end
	if type(value) ~= "string" then
		return false
	end
	for _, v in (def :: any).values do
		if v == value then
			return true
		end
	end
	return false
end

-- Is `value` an allowed value for setting `key`? Returns ok.
function Settings.accept(key: any, value: any): boolean
	if type(key) ~= "string" then
		return false
	end
	local def = Settings.defs[key]
	return def ~= nil and valid(def, value)
end

-- The effective value (stored or default).
function Settings.get(settings: { [string]: any }?, key: string): any
	local def = Settings.defs[key]
	assert(def, "unknown setting " .. key)
	local v = if settings then settings[key] else nil
	if v ~= nil and valid(def, v) then
		return v
	end
	return def.default
end

-- Drops invalid values of known settings in place (unknown keys such as `language` are left to
-- their own sanitisers). Returns the table.
function Settings.sanitize(settings: { [string]: any }): { [string]: any }
	for key, def in Settings.defs do
		local v = settings[key]
		if v ~= nil and not valid(def, v) then
			settings[key] = nil
		end
	end
	return settings
end

-- Effective values of every setting (for the client snapshot).
function Settings.resolve(settings: { [string]: any }?): { [string]: any }
	local out = {}
	for key in Settings.defs do
		out[key] = Settings.get(settings, key)
	end
	return out
end

return Settings
