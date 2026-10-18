--!strict
-- Unit traits: rolled on obtain and rerollable with trait stones. Pure data. A unit has one trait,
-- and a second slot once it reaches TD.TRAIT2_STARS stars (traits v2, docs/STORY_PLAN.md §7.2).
-- Multipliers apply to every level of that unit. weight = relative roll chance (both slots roll
-- with the same weights; the Rates panel shows them from this table).
--
-- Two traits never stack the same stat: per stat the better one wins (UnitLogic.combineTraits),
-- and whatever the traits say, UnitLogic.stats clamps them to `caps` (DECISIONS D-041).

export type TraitDef = {
	nameKey: string,
	weight: number,
	damage: number?, -- multiplier
	range: number?,
	cooldown: number?, -- multiplier (< 1 is faster)
	cash: number?, -- multiplier on kill rewards
	hitsStealth: boolean?, -- the unit can target stealth enemies itself
	costMul: number?, -- multiplier on its placement and upgrade prices (< 1 is cheaper)
	maxPlaced: number?, -- extra copies of the unit a player may place
	douse: number?, -- burn stacks it takes off the gate per attack
	tier: number, -- 1 common … 4 best (for the UI colour)
}

export type Caps = { damage: number, range: number, cooldown: number }

local Traits: { [string]: TraitDef } = {
	steady = { nameKey = "trait.steady.name", weight = 30, damage = 1.05, tier = 1 },
	swift = { nameKey = "trait.swift.name", weight = 22, cooldown = 0.92, tier = 1 },
	keen = { nameKey = "trait.keen.name", weight = 18, range = 1.1, tier = 2 },
	sharp = { nameKey = "trait.sharp.name", weight = 14, damage = 1.15, tier = 2 },
	golden = { nameKey = "trait.golden.name", weight = 8, cash = 1.25, tier = 3 },
	hawk = { nameKey = "trait.hawk.name", weight = 5, range = 1.25, cooldown = 0.95, tier = 3 },
	zaim = { nameKey = "trait.zaim.name", weight = 2.5, damage = 1.3, range = 1.1, tier = 4 },
	legend = {
		nameKey = "trait.legend.name",
		weight = 0.5,
		damage = 1.5,
		range = 1.2,
		cooldown = 0.85,
		tier = 4,
	},
	-- Traits v2 (Season Story 1): 20 of the 120 weight, so the first eight keep their relative odds.
	lantern = { nameKey = "trait.lantern.name", weight = 6, hitsStealth = true, tier = 2 },
	fireproof = { nameKey = "trait.fireproof.name", weight = 6, douse = 1, tier = 2 },
	miser = { nameKey = "trait.miser.name", weight = 5, costMul = 0.9, tier = 3 },
	twin = { nameKey = "trait.twin.name", weight = 3, maxPlaced = 1, tier = 3 },
}

-- The most any combination of traits may give (STORY_PLAN §7.2, D-008 cap row D-041).
local CAPS: Caps = { damage = 1.5, range = 1.25, cooldown = 0.85 }

return {
	traits = Traits,
	order = {
		"steady",
		"swift",
		"keen",
		"sharp",
		"golden",
		"hawk",
		"zaim",
		"legend",
		"lantern",
		"fireproof",
		"miser",
		"twin",
	},
	caps = CAPS,
}
