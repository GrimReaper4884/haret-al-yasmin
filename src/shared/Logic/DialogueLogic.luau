--!strict
-- Resolves which dialogue node an NPC opens with, and validates choices. Pure.

type Condition = { quest: string, state: string }
type Choice = { textKey: string, action: { type: string, quest: string?, shop: string? }?, next: string? }
type Node = { textKey: string, choices: { Choice } }
type NpcDialogue = { entries: { { condition: Condition?, node: string } }, nodes: { [string]: Node } }
type QuestProfile = { quests: { [string]: { state: string } } }

local DialogueLogic = {}

local function questState(profile: QuestProfile, questId: string): string
	local rec = profile.quests[questId]
	if rec == nil then
		return "none"
	end
	return if rec.state == "completed" then "completed" else "active"
end

function DialogueLogic.matches(profile: QuestProfile, condition: Condition?): boolean
	if condition == nil then
		return true
	end
	return questState(profile, condition.quest) == condition.state
end

function DialogueLogic.entryNode(dialogue: NpcDialogue, profile: QuestProfile): string?
	for _, entry in dialogue.entries do
		if DialogueLogic.matches(profile, entry.condition) then
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
