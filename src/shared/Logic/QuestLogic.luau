--!strict
-- Quest state machine: none → active (item granted) → completed (item taken, reward paid).
-- Pure. Each transition validates everything first and only then writes, so a failed call
-- leaves the profile untouched and a repeated call cannot pay twice.

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

export type State = "none" | "active" | "completed"

type QuestRecord = { state: string, startedAt: number, completedAt: number?, completions: number }
type QuestProfile = {
	qirsh: number,
	inventory: { [string]: number },
	quests: { [string]: QuestRecord },
}
type QuestDef = { item: string, reward: { qirsh: number }, repeatable: boolean, giver: string, target: string }

local QuestLogic = {}

function QuestLogic.state(profile: QuestProfile, questId: string): State
	local rec = profile.quests[questId]
	if rec == nil then
		return "none"
	end
	return if rec.state == "completed" then "completed" else "active"
end

function QuestLogic.canAccept(
	profile: QuestProfile,
	questId: string,
	quests: { [string]: QuestDef },
	items: { [string]: any }
): (boolean, string?)
	local def = quests[questId]
	if not def then
		return false, "unknown_quest"
	end
	local st = QuestLogic.state(profile, questId)
	if st == "active" then
		return false, "already_active"
	end
	if st == "completed" and not def.repeatable then
		return false, "already_completed"
	end
	return Inventory.canAdd(profile, def.item, 1, items)
end

function QuestLogic.accept(
	profile: QuestProfile,
	questId: string,
	quests: { [string]: QuestDef },
	items: { [string]: any },
	now: number
): (boolean, string?)
	local ok, err = QuestLogic.canAccept(profile, questId, quests, items)
	if not ok then
		return false, err
	end
	local def = quests[questId]
	local prev = profile.quests[questId]
	Inventory.add(profile, def.item, 1, items)
	profile.quests[questId] = {
		state = "active",
		startedAt = now,
		completedAt = nil,
		completions = if prev then prev.completions else 0,
	}
	return true, nil
end

function QuestLogic.canDeliver(profile: QuestProfile, questId: string, quests: { [string]: QuestDef }): (boolean, string?)
	local def = quests[questId]
	if not def then
		return false, "unknown_quest"
	end
	if QuestLogic.state(profile, questId) ~= "active" then
		return false, "not_active"
	end
	if not Inventory.has(profile, def.item, 1) then
		return false, "missing_item"
	end
	return true, nil
end

-- Returns ok, err, qirshPaid.
function QuestLogic.deliver(
	profile: QuestProfile,
	questId: string,
	quests: { [string]: QuestDef },
	maxQirsh: number,
	now: number
): (boolean, string?, number?)
	local ok, err = QuestLogic.canDeliver(profile, questId, quests)
	if not ok then
		return false, err, nil
	end
	local def = quests[questId]
	Inventory.remove(profile, def.item, 1)
	local _, _, paid = Wallet.add(profile, def.reward.qirsh, maxQirsh)
	local rec = profile.quests[questId]
	rec.state = "completed"
	rec.completedAt = now
	rec.completions += 1
	return true, nil, paid
end

return QuestLogic
