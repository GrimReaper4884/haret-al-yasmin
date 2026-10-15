--!strict
-- Unit traits: one per owned unit, rolled on obtain and rerollable with trait stones. Pure data.
-- Multipliers apply to every level of that unit. weight = relative roll chance.

export type TraitDef = {
	nameKey: string,
	weight: number,
	damage: number?, -- multiplier
	range: number?,
	cooldown: number?, -- multiplier (< 1 is faster)
	cash: number?, -- multiplier on kill rewards
	tier: number, -- 1 common … 4 best (for the UI colour)
}

local Traits: { [string]: TraitDef } = {
	steady = { nameKey = "trait.steady.name", weight = 30, damage = 1.05, tier = 1 },
	swift = { nameKey = "trait.swift.name", weight = 22, cooldown = 0.92, tier = 1 },
	keen = { nameKey = "trait.keen.name", weight = 18, range = 1.1, tier = 2 },
	sharp = { nameKey = "trait.sharp.name", weight = 14, damage = 1.15, tier = 2 },
	golden = { nameKey = "trait.golden.name", weight = 8, cash = 1.25, tier = 3 },
	hawk = { nameKey = "trait.hawk.name", weight = 5, range = 1.25, cooldown = 0.95, tier = 3 },
	zaim = { nameKey = "trait.zaim.name", weight = 2.5, damage = 1.3, range = 1.1, tier = 4 },
	legend = { nameKey = "trait.legend.name", weight = 0.5, damage = 1.5, range = 1.2, cooldown = 0.85, tier = 4 },
}

return { traits = Traits, order = { "steady", "swift", "keen", "sharp", "golden", "hawk", "zaim", "legend" } }
