--!strict
-- Analytics event shapes (BUILD_PLAN P3-07). Pure. Roblox caps how many distinct custom event *names* an
-- experience may log, far below the cap on custom-field values, and recommends one name with the varying
-- part in a field ("PlantSeed" with "Cabbage", not "PlantCabbage"). So every custom event here has a name from
-- the closed list NAMES and puts ids (unit, mode, code, clue…) in up to three fields; AnalyticsService maps
-- fields 1..3 to Enum.AnalyticsCustomFieldKeys.CustomField01..03. Matches are progression events instead
-- (start / complete / fail on a path per mode kind).

local AnalyticsEvents = {}

export type Custom = { name: string, value: number, fields: { string } }
export type Progression = { status: "Start" | "Complete" | "Fail", path: string, level: number, levelName: string, fields: { string } }

-- Every custom event name the game logs (specs keep it closed).
AnalyticsEvents.NAMES = {
	"SummonPull", -- value = pulls; field 1 = "x1" | "x10"
	"SummonResult", -- field 1 = rarity, field 2 = unit id
	"TraitReroll",
	"CodeRedeem", -- field 1 = code
	"ClueFound", -- field 1 = clue id
	"PassClaim", -- value = tier; field 1 = "free" | "premium"
	"EventBuy", -- field 1 = event id, field 2 = shop key
	"DailyClaim", -- value = streak day
	"ShopOpened",
	"LanguageSet", -- field 1 = language
	"AfkEnter", -- field 1 = reason
	"AfkHop",
	"AfkMinutes", -- value = minutes
	"MatchEnd", -- value = waves cleared; field 1 = mode, field 2 = difficulty, field 3 = "won" | "lost"
	"ui_device", -- value = HUD profile index; field 1 = profile (MH-17)
	"place_outcome_placed", -- MH-17 placement telemetry (DeviceTelemetry.events)
	"place_outcome_invalid",
	"place_outcome_cancelled",
}

local MAX_FIELD = 50

local function field(v: any): string
	return string.sub(tostring(v), 1, MAX_FIELD)
end

local function custom(name: string, value: number?, ...: any): Custom
	local fields = {}
	for i = 1, math.min(select("#", ...), 3) do
		table.insert(fields, field((select(i, ...))))
	end
	return { name = name, value = value or 1, fields = fields }
end

function AnalyticsEvents.summonPull(n: number): Custom
	return custom("SummonPull", n, "x" .. n)
end

function AnalyticsEvents.summonResult(rarity: string, unitId: string): Custom
	return custom("SummonResult", 1, rarity, unitId)
end

function AnalyticsEvents.traitReroll(): Custom
	return custom("TraitReroll")
end

function AnalyticsEvents.codeRedeem(code: string): Custom
	return custom("CodeRedeem", 1, code)
end

function AnalyticsEvents.clueFound(clueId: string): Custom
	return custom("ClueFound", 1, clueId)
end

function AnalyticsEvents.passClaim(track: string, tier: number): Custom
	return custom("PassClaim", tier, track)
end

function AnalyticsEvents.eventBuy(eventId: string, key: string): Custom
	return custom("EventBuy", 1, eventId, key)
end

function AnalyticsEvents.dailyClaim(day: number): Custom
	return custom("DailyClaim", day)
end

function AnalyticsEvents.shopOpened(): Custom
	return custom("ShopOpened")
end

function AnalyticsEvents.languageSet(lang: string): Custom
	return custom("LanguageSet", 1, lang)
end

function AnalyticsEvents.afkEnter(reason: string): Custom
	return custom("AfkEnter", 1, reason)
end

function AnalyticsEvents.afkHop(): Custom
	return custom("AfkHop")
end

function AnalyticsEvents.afkMinutes(minutes: number): Custom
	return custom("AfkMinutes", minutes)
end

function AnalyticsEvents.matchEnd(modeId: string, difficulty: string, won: boolean, waves: number): Custom
	return custom("MatchEnd", waves, modeId, difficulty, if won then "won" else "lost")
end

-- A match as a progression attempt. path: the mode's kind ("Story", "Event", "Infinite"); level: the
-- episode number for story modes, else 1; levelName: the mode id; field 1: difficulty.
-- mode: a Config/Modes entry.
function AnalyticsEvents.progression(status: "Start" | "Complete" | "Fail", mode: any, modeId: string, difficulty: string): Progression
	local kind = if type(mode) == "table" and type(mode.kind) == "string" then mode.kind else "other"
	local path = string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2)
	local level = if kind == "story" then tonumber(string.match(modeId, "(%d+)$")) or 1 else 1
	return { status = status, path = path, level = level, levelName = field(modeId), fields = { field(difficulty) } }
end

return AnalyticsEvents
