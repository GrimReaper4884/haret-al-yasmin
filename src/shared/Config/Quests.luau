--!strict
-- Quest definitions. Pure data.

export type QuestDef = {
	titleKey: string,
	objectiveKeys: { active: string, completed: string },
	giver: string, -- npc id that hands out the errand
	target: string, -- npc id that receives it
	item: string, -- quest item granted on accept, taken on delivery
	reward: { qirsh: number },
	repeatable: boolean,
}

local Quests: { [string]: QuestDef } = {
	delivery_kaak = {
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
}

return Quests
