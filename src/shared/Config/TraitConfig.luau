--!strict
--[[
	TraitConfig: trait reroll table (17 entries, sums to exactly 1_000_000 ppm = 100%).

	Read by the server reroll RNG AND the odds UI (same rule as SummonConfig: the displayed table is
	generated from this module). GDD: docs/GAME_DESIGN.md section 10.

	Rules (implemented by RerollService):
	  * 1 Trait Seed per reroll. A reroll always replaces the current trait (use the
	    "stop at or above" auto-reroll setting to avoid overwriting a good roll).
	  * Pity is tracked PER UNIT (GUID record) and per pity trait: a counter of rerolls since that
	    unit last obtained that trait. When a reroll would be number `pity`, it yields that trait.
	    If several pity counters trigger on the same reroll, the rarest trait wins and the others
	    keep counting. Pity counters survive evolution; they reset on trade (Update 5).
	  * pity = round(PITY_MULTIPLIER x expected rerolls) where expected = 1_000_000 / ppm.
	  * placementLimit overrides the unit's placement cap for that player in a match.
	  * Units are summoned with no trait. TUNE
	  * Traits are disabled in the Fair-Play Arena.
]]

local Types = require(script.Parent.Types)

export type TraitDef = {
	id: string,
	displayName: string,
	ppm: number,
	rank: number, -- 1 (common) .. 7 (Crown); used by "stop at or above" auto-reroll
	mods: Types.StatMods,
	pity: number?,
	placementLimit: number?,
}

local TraitConfig = {}

TraitConfig.PITY_MULTIPLIER = 1.2

TraitConfig.Reroll = {
	currency = "TraitSeeds", -- paid and earned balances tracked separately (PolicyService)
	cost = 1,
	autoRerollStopAtOrAbove = true,
}

-- Second trait slot ("Divine" layer) ships in Update 2, bought with Divine Seeds from the Raid shop.
TraitConfig.SecondSlot = {
	enabled = false,
	currency = "DivineSeeds",
	unlocksIn = "Update2",
}

local traits: { TraitDef } = {
	{ id = "Might1", displayName = "Might I", ppm = 165_000, rank = 1, mods = { damagePct = 0.05 } },
	{ id = "Haste1", displayName = "Haste I", ppm = 165_000, rank = 1, mods = { spaPct = -0.04 } },
	{ id = "Reach1", displayName = "Reach I", ppm = 165_000, rank = 1, mods = { rangePct = 0.05 } },
	{ id = "Might2", displayName = "Might II", ppm = 80_000, rank = 2, mods = { damagePct = 0.10 } },
	{ id = "Haste2", displayName = "Haste II", ppm = 80_000, rank = 2, mods = { spaPct = -0.08 } },
	{ id = "Reach2", displayName = "Reach II", ppm = 80_000, rank = 2, mods = { rangePct = 0.10 } },
	{ id = "Scholar", displayName = "Scholar", ppm = 70_000, rank = 2, mods = { unitXpPct = 0.50 } },
	{ id = "Might3", displayName = "Might III", ppm = 25_000, rank = 3, mods = { damagePct = 0.15 } },
	{ id = "Haste3", displayName = "Haste III", ppm = 25_000, rank = 3, mods = { spaPct = -0.125 } },
	{ id = "Reach3", displayName = "Reach III", ppm = 25_000, rank = 3, mods = { rangePct = 0.15 } },
	{
		-- Economy trait (not the Merchant role): farm income on Merchant units, discount on all others.
		id = "Merchant",
		displayName = "Merchant",
		ppm = 40_000,
		rank = 3,
		mods = { farmIncomePct = 0.20, upgradeCostPct = -0.10 },
	},
	{
		id = "Steadfast",
		displayName = "Steadfast",
		ppm = 30_000,
		rank = 3,
		mods = { bossStunImmune = true, bossDamagePct = 0.10 },
	},
	{
		id = "KeenEye",
		displayName = "Keen Eye",
		ppm = 26_000,
		rank = 3,
		mods = { critChance = 0.35, critDamagePct = 0.50 },
	},
	{ id = "Tempest", displayName = "Tempest", ppm = 14_700, rank = 4, mods = { spaPct = -0.20 } },
	{
		id = "Radiant",
		displayName = "Radiant",
		ppm = 6_000,
		rank = 5,
		mods = { damagePct = 0.10, spaPct = -0.05, rangePct = 0.25 },
		pity = 200,
	},
	{
		id = "Eclipse",
		displayName = "Eclipse",
		ppm = 2_500,
		rank = 6,
		mods = { damagePct = 0.25, spaPct = -0.15, rangePct = 0.10, shieldIgnorePct = 0.25 },
		pity = 480,
	},
	{
		id = "Crown",
		displayName = "Crown of Jasmine",
		ppm = 800,
		rank = 7,
		mods = { damagePct = 2.00, spaPct = -0.10, rangePct = 0.10 },
		pity = 1_500,
		placementLimit = 1,
	},
}
TraitConfig.Traits = traits

TraitConfig.PPM_TOTAL = Types.PPM_TOTAL

return TraitConfig
