--!strict
-- Quest definitions. Pure data. See Logic/QuestLogic for the kinds and their state machines.

export type QuestDef = {
	kind: ("delivery" | "investigate")?, -- default "delivery"
	titleKey: string,
	objectiveKeys: { active: string, ready: string?, completed: string },
	giver: string, -- npc id that hands it out
	target: string, -- npc id that receives the turn-in
	item: string?, -- delivery: quest item granted on accept, taken on turn-in
	clues: { string }?, -- investigate: clue ids (Config/Clues) to find
	requires: { string }?, -- quests that must be completed first
	reward: { qirsh: number },
	repeatable: boolean,
	episode: number?, -- Season 1 episode number, for UI
}

-- The lane's errands (Abu Nadim's ka'ak delivery and Hajj Rashid's "Wedding Eve" clue hunt) were
-- removed on the owner's request (2026-10-19, DECISIONS D-132). The engine (Logic/QuestLogic,
-- QuestService, ClueService) stays and is covered by fixture specs; add a quest here to bring one back.
local Quests: { [string]: QuestDef } = {}

return Quests
