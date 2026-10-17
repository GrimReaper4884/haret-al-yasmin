--!strict
--[[
	StatGradeConfig: per-unit stat grades for Damage, SPA and Range, plus the potential meter.

	Each unit rolls a grade independently for each of the three stats. Within a grade the bonus is
	uniform between min and max (fractions: 0.11 = +11%). For SPA the bonus REDUCES seconds per
	attack (SPA x (1 - bonus)); for Damage and Range it adds.

	Odds depend on the unit's potential p in [0, 1]:
	  p = min(1, takedownsSinceLastRoll / Potential.takedownsForFull)
	  odds(grade) = basePpm x (1 - p) + fullPotentialPpm x p
	The odds UI shows the interpolated table for the selected unit, rounded to 1 ppm with
	largest-remainder so it still sums to exactly 1_000_000. Potential resets to 0 after any roll.
	Stat Cores reroll all three stats; Focus Cores reroll one chosen stat. New units roll at p = 0.
	Disabled in the Fair-Play Arena. GDD: docs/GAME_DESIGN.md section 11.
]]

local Types = require(script.Parent.Types)

export type Range = { min: number, max: number }

export type GradeDef = {
	id: string,
	displayName: string,
	damage: Range,
	spaRange: Range, -- applies to both SPA and Range rolls
	basePpm: number,
	fullPotentialPpm: number,
}

local StatGradeConfig = {}

local grades: { GradeDef } = {
	{
		id = "D",
		displayName = "D",
		damage = { min = 0.00, max = 0.0499 },
		spaRange = { min = 0.00, max = 0.0249 },
		basePpm = 350_000,
		fullPotentialPpm = 0,
	},
	{
		id = "C",
		displayName = "C",
		damage = { min = 0.05, max = 0.0799 },
		spaRange = { min = 0.025, max = 0.0399 },
		basePpm = 300_000,
		fullPotentialPpm = 0,
	},
	{
		id = "B",
		displayName = "B",
		damage = { min = 0.08, max = 0.1099 },
		spaRange = { min = 0.04, max = 0.0549 },
		basePpm = 220_000,
		fullPotentialPpm = 0,
	},
	{
		id = "A",
		displayName = "A",
		damage = { min = 0.11, max = 0.1399 },
		spaRange = { min = 0.055, max = 0.0699 },
		basePpm = 100_000,
		fullPotentialPpm = 700_000,
	},
	{
		id = "S",
		displayName = "S",
		damage = { min = 0.14, max = 0.1699 },
		spaRange = { min = 0.07, max = 0.0849 },
		basePpm = 25_000,
		fullPotentialPpm = 220_000,
	},
	{
		id = "SS",
		displayName = "SS",
		damage = { min = 0.17, max = 0.1999 },
		spaRange = { min = 0.085, max = 0.0999 },
		basePpm = 4_500,
		fullPotentialPpm = 70_000,
	},
	{
		id = "Jasmine",
		displayName = "Jasmine",
		damage = { min = 0.20, max = 0.22 },
		spaRange = { min = 0.10, max = 0.11 },
		basePpm = 500,
		fullPotentialPpm = 10_000,
	},
}
StatGradeConfig.Grades = grades

StatGradeConfig.Stats = { "Damage", "SPA", "Range" }

StatGradeConfig.Potential = {
	takedownsForFull = 3_000, -- takedowns by THIS unit since its last stat roll
	resetsOnRoll = true,
}

StatGradeConfig.Reroll = {
	all = { item = "StatCores", cost = 1 }, -- rerolls Damage, SPA and Range
	one = { item = "FocusCores", cost = 1 }, -- rerolls one chosen stat
}

StatGradeConfig.DisabledInModes = { "FairPlayArena" }

StatGradeConfig.PPM_TOTAL = Types.PPM_TOTAL

return StatGradeConfig
