--!strict
-- Clue spots in the world for investigation quests. Pure data (positions as { x, y, z }).
-- `look` names a primitive builder in server/Services/ClueService.

export type ClueDef = {
	quest: string,
	nameKey: string,
	textKey: string,
	position: { number }, -- where the prompt sits
	look: "slipper" | "thread" | "token",
	order: number, -- display order in the HUD journal
}

local Clues: { [string]: ClueDef } = {
	clue_slipper = {
		quest = "s1e1_wedding_eve",
		nameKey = "clue.slipper.name",
		textKey = "clue.slipper.text",
		position = { -21.5, 0.1, 8 },
		look = "slipper",
		order = 1,
	},
	clue_thread = {
		quest = "s1e1_wedding_eve",
		nameKey = "clue.thread.name",
		textKey = "clue.thread.text",
		position = { -5.1, 5, 89 },
		look = "thread",
		order = 2,
	},
	clue_token = {
		quest = "s1e1_wedding_eve",
		nameKey = "clue.token.name",
		textKey = "clue.token.text",
		position = { 12, 0.1, -9 },
		look = "token",
		order = 3,
	},
}

return Clues
