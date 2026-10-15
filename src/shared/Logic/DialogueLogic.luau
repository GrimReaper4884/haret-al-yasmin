--!strict
-- Resolves which dialogue node an NPC opens with, and validates choices. Pure.
-- Conditions test a quest's state: "none" | "active" | "ready" | "completed". "ready" (objectives
-- met, not yet turned in) needs the quests config; without it a ready quest counts as "active".

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require -- name is dynamic; resolved at runtime
	return dynamicRequire((script :: any).Parent[name])
end

local QuestLogic = sibling("QuestLogic")

type Condition = { quest: string, state: string }
type Choice = { textKey: string, action: { type: string, quest: string?, shop: string? }?, next: string? }
type Node = { textKey: string, choices: { Choice } }
type NpcDialogue = { entries: { { condition: Condition?, node: string } }, nodes: { [string]: Node } }

local DialogueLogic = {}

function DialogueLogic.matches(profile: any, condition: Condition?, quests: any?): boolean
	if condition == nil then
		return true
	end
	local state = QuestLogic.state(profile, condition.quest, quests)
	if condition.state == "active" and state == "ready" then
		-- An "active" entry should still match when no "ready" entry precedes it.
		return true
	end
	return state == condition.state
end

function DialogueLogic.entryNode(dialogue: NpcDialogue, profile: any, quests: any?): string?
	for _, entry in dialogue.entries do
		if DialogueLogic.matches(profile, entry.condition, quests) then
			return entry.node
		end
	end
	return nil
end

-- Returns the choice for a 1-based index if it exists in the given node.
function DialogueLogic.choice(dialogue: NpcDialogue, nodeId: string, index: any): Choice?
	local node = dialogue.nodes[nodeId]
	if node == nil or type(index) ~= "number" or index ~= index or math.floor(index) ~= index then
		return nil
	end
	return node.choices[index]
end

return DialogueLogic
