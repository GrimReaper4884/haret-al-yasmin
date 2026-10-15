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

local Quests: { [string]: QuestDef } = {
	delivery_kaak = {
		kind = "delivery",
		titleKey = "quest.delivery_kaak.title",
		objectiveKeys = {
			active = "quest.delivery_kaak.obj_active",
			completed = "quest.delivery_kaak.obj_completed",
		},
		giver = "abu_nadim",
		target = "sitt_wardeh",
		item = "basket_kaak",
		reward = { qirsh = 50 },
		repeatable = false,
	},

	-- Season 1 · Episode 1 — "Wedding Eve" (docs/SEASON_1.md)
	s1e1_wedding_eve = {
		kind = "investigate",
		episode = 1,
		titleKey = "quest.s1e1.title",
		objectiveKeys = {
			active = "quest.s1e1.obj_active",
			ready = "quest.s1e1.obj_ready",
			completed = "quest.s1e1.obj_completed",
		},
		giver = "hajj_rashid",
		target = "hajj_rashid",
		clues = { "clue_slipper", "clue_thread", "clue_token" },
		requires = { "delivery_kaak" },
		reward = { qirsh = 60 },
		repeatable = false,
	},
}

return Quests
