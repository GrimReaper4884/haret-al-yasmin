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

-- No clue spots: the Episode 1 errand was removed with the rest of the lane's errands (Config/Quests).
local Clues: { [string]: ClueDef } = {}

return Clues
