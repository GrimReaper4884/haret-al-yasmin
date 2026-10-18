--!strict
-- Shabriyeh beads (خرزات الشبرية, STORY_PLAN §7.4, S1-S11): a non-random progression item. A
-- player earns beads (first clears of Episodes 5 and 7 on Hard, and wins of Episodes 7–9 on Hard
-- or Nightmare, at most `perDay` a day) and threads them onto a unit's three slots, each slot
-- taking one of the three kinds that unit allows (`Units[id].beads`, else `byRole`). Setting a
-- slot spends `setCost` beads. Pure data.
--
-- Cap (D-050, the D-008 row for this axis): whatever the three slots hold, beads never add more
-- than `cap` (+12 %) to any one stat; UnitLogic.stats clamps.

export type Kind = {
	nameKey: string,
	range: number?, -- studs added
	cooldown: number?, -- attack cooldown multiplier per bead (< 1 is faster)
	cash: number?, -- kill reward multiplier added
	heal: number?, -- gate HP per wave added (healers)
	buff: number?, -- damage buff added (supports)
}

local kinds: { [string]: Kind } = {
	range = { nameKey = "bead.range.name", range = 1 },
	cooldown = { nameKey = "bead.cooldown.name", cooldown = 0.96 },
	cash = { nameKey = "bead.cash.name", cash = 0.08 },
	heal = { nameKey = "bead.heal.name", heal = 2 },
	buff = { nameKey = "bead.buff.name", buff = 0.03 },
}

return {
	kinds = kinds,
	order = { "range", "cooldown", "cash", "heal", "buff" },
	-- The three kinds a unit's slots take, by role (a unit may list its own as Units[id].beads).
	byRole = {
		melee = { "range", "cooldown", "cash" },
		ranged = { "range", "cooldown", "cash" },
		splash = { "range", "cooldown", "cash" },
		farm = { "range", "cooldown", "cash" },
		support = { "buff", "range", "cooldown" },
		healer = { "heal", "buff", "range" },
	},
	slots = 3,
	cap = 0.12,
	setCost = 1,
	maxBeads = 999,
	perDay = 3,
	-- Episodes whose Hard and Nightmare wins drop one bead (within perDay).
	winDrops = { ep7 = true, ep8 = true, ep9 = true },
	-- First clears that gift beads: episode → { [difficulty] = beads } for the first clear at or above it.
	firstClear = { ep5 = { hard = 1 }, ep7 = { hard = 2 } },
}
