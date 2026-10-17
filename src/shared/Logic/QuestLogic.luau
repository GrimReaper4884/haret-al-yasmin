--!strict
-- Quest state machine. Pure. Each transition validates everything first and only then writes, so
-- a failed call leaves the profile untouched and a repeated call cannot pay twice.
--
-- Kinds:
--   "delivery"     accept → quest item granted; turn in at `target` → item taken, reward paid.
--   "investigate"  accept → progress = {}; find every clue in `clues`; turn in at `target` → reward.
-- States: "none" → "active" → ("ready" when objectives are met) → "completed".

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require -- name is dynamic; resolved at runtime
	return dynamicRequire((script :: any).Parent[name])
end

local Wallet = sibling("Wallet")
local Inventory = sibling("Inventory")

export type State = "none" | "active" | "ready" | "completed"

type QuestRecord = {
	state: string,
	startedAt: number,
	completedAt: number?,
	completions: number,
	progress: { [string]: boolean }?,
}
type QuestProfile = {
	qirsh: number,
	inventory: { [string]: number },
	quests: { [string]: QuestRecord },
}
type QuestDef = {
	kind: string?,
	item: string?,
	clues: { string }?,
	requires: { string }?,
	reward: { qirsh: number },
	repeatable: boolean,
	giver: string,
	target: string,
}
type Quests = { [string]: QuestDef }

local QuestLogic = {}

local function kindOf(def: QuestDef): string
	return def.kind or "delivery"
end

-- Raw stored state: "none" | "active" | "completed".
local function stored(profile: QuestProfile, questId: string): string
	local rec = profile.quests[questId]
	if rec == nil then
		return "none"
	end
	return if rec.state == "completed" then "completed" else "active"
end

-- True when an active quest's objectives are all met (it can be turned in).
function QuestLogic.objectivesMet(profile: QuestProfile, questId: string, quests: Quests): boolean
	local def = quests[questId]
	if not def or stored(profile, questId) ~= "active" then
		return false
	end
	if kindOf(def) == "investigate" then
		local progress = profile.quests[questId].progress or {}
		local clues: { string } = def.clues or {}
		for _, clueId in clues do
			if not progress[clueId] then
				return false
			end
		end
		return true
	end
	return def.item ~= nil and Inventory.has(profile, def.item, 1)
end

-- Display/dialogue state. Without `quests` it cannot tell "ready", so it reports "active".
function QuestLogic.state(profile: QuestProfile, questId: string, quests: Quests?): State
	local s = stored(profile, questId)
	if s == "active" and quests and QuestLogic.objectivesMet(profile, questId, quests) then
		return "ready"
	end
	return s :: State
end

function QuestLogic.cluesFound(profile: QuestProfile, questId: string): number
	local rec = profile.quests[questId]
	local n = 0
	if rec and rec.progress then
		for _, found in rec.progress do
			if found then
				n += 1
			end
		end
	end
	return n
end

function QuestLogic.canAccept(profile: QuestProfile, questId: string, quests: Quests, items: { [string]: any }): (boolean, string?)
	local def = quests[questId]
	if not def then
		return false, "unknown_quest"
	end
	local requires: { string } = def.requires or {}
	for _, req in requires do
		if stored(profile, req) ~= "completed" then
			return false, "locked"
		end
	end
	local st = stored(profile, questId)
	if st == "active" then
		return false, "already_active"
	end
	if st == "completed" and not def.repeatable then
		return false, "already_completed"
	end
	if kindOf(def) == "delivery" then
		if not def.item then
			return false, "bad_quest"
		end
		return Inventory.canAdd(profile, def.item, 1, items)
	end
	return true, nil
end

function QuestLogic.accept(
	profile: QuestProfile,
	questId: string,
	quests: Quests,
	items: { [string]: any },
	now: number
): (boolean, string?)
	local ok, err = QuestLogic.canAccept(profile, questId, quests, items)
	if not ok then
		return false, err
	end
	local def = quests[questId]
	local prev = profile.quests[questId]
	if kindOf(def) == "delivery" then
		Inventory.add(profile, def.item :: string, 1, items)
	end
	profile.quests[questId] = {
		state = "active",
		startedAt = now,
		completedAt = nil,
		completions = if prev then prev.completions else 0,
		progress = if kindOf(def) == "investigate" then {} else nil,
	}
	return true, nil
end

-- Marks a clue found. Returns ok, err, cluesFoundNow.
function QuestLogic.collectClue(profile: QuestProfile, questId: string, clueId: string, quests: Quests): (boolean, string?, number?)
	local def = quests[questId]
	if not def or kindOf(def) ~= "investigate" then
		return false, "unknown_quest", nil
	end
	if stored(profile, questId) ~= "active" then
		return false, "not_active", nil
	end
	if not table.find(def.clues or {}, clueId) then
		return false, "unknown_clue", nil
	end
	local rec = profile.quests[questId]
	local progress = rec.progress or {}
	if progress[clueId] then
		return false, "already_found", nil
	end
	progress[clueId] = true
	rec.progress = progress
	return true, nil, QuestLogic.cluesFound(profile, questId)
end

function QuestLogic.canDeliver(profile: QuestProfile, questId: string, quests: Quests): (boolean, string?)
	local def = quests[questId]
	if not def then
		return false, "unknown_quest"
	end
	if stored(profile, questId) ~= "active" then
		return false, "not_active"
	end
	if not QuestLogic.objectivesMet(profile, questId, quests) then
		return false, if kindOf(def) == "delivery" then "missing_item" else "missing_clues"
	end
	return true, nil
end

-- Turns the quest in. Returns ok, err, qirshPaid.
function QuestLogic.deliver(
	profile: QuestProfile,
	questId: string,
	quests: Quests,
	maxQirsh: number,
	now: number
): (boolean, string?, number?)
	local ok, err = QuestLogic.canDeliver(profile, questId, quests)
	if not ok then
		return false, err, nil
	end
	local def = quests[questId]
	if kindOf(def) == "delivery" then
		Inventory.remove(profile, def.item :: string, 1)
	end
	local _, _, paid = Wallet.add(profile, def.reward.qirsh, maxQirsh)
	local rec = profile.quests[questId]
	rec.state = "completed"
	rec.completedAt = now
	rec.completions += 1
	return true, nil, paid
end

return QuestLogic
