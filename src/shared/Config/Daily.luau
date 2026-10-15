--!strict
-- Daily login rewards: a 7-day streak that loops. Missing a day resets the streak to day 1.
-- Days are UTC calendar days. Pure data.

export type DailyReward = { lira: number?, qirsh: number?, traitStones: number?, xp: number? }

local Daily: { DailyReward } = {
	{ lira = 20, xp = 40 },
	{ lira = 30, xp = 40 },
	{ qirsh = 120, xp = 40 },
	{ lira = 45, xp = 50 },
	{ lira = 60, xp = 50 },
	{ traitStones = 1, xp = 60 },
	{ lira = 120, qirsh = 200, xp = 80 },
}

return Daily
