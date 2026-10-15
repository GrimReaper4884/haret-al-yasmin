--!strict
-- Wave scripts per story episode, and the parameters of the endless mode. Pure data; Logic/WaveLogic
-- turns a script and a wave number into concrete spawn groups.
--
-- pool entries: `enemy` appears from wave `from` (to `to`), `base` of them on its first wave and
-- `perWave` more per later wave (rounded), one every `gap` seconds, starting `delay` seconds into
-- the wave. Boss waves add the boss after the regular groups.

export type PoolEntry = {
	enemy: string,
	from: number,
	to: number?,
	base: number,
	perWave: number,
	gap: number,
	delay: number?,
}

export type Episode = {
	waves: number,
	hpPerWave: number, -- enemy HP multiplier grows by this per wave after the first
	pool: { PoolEntry },
	bosses: { [number]: string },
}

local Waves = {
	ep1 = {
		waves = 20,
		hpPerWave = 0.07,
		pool = {
			{ enemy = "thief", from = 1, base = 4, perWave = 0.9, gap = 1.1 },
			{ enemy = "gendarme", from = 3, base = 3, perWave = 0.8, gap = 1.4, delay = 4 },
			{ enemy = "thug", from = 7, base = 2, perWave = 0.6, gap = 1.8, delay = 8 },
			{ enemy = "bandit", from = 12, base = 1, perWave = 0.5, gap = 3, delay = 10 },
		},
		bosses = { [10] = "sergeant", [20] = "chief_thief" },
	} :: Episode,
	ep2 = {
		waves = 30,
		hpPerWave = 0.08,
		pool = {
			{ enemy = "thug", from = 1, base = 5, perWave = 0.9, gap = 1.0 },
			{ enemy = "gendarme", from = 2, base = 3, perWave = 0.9, gap = 1.3, delay = 3 },
			{ enemy = "thief", from = 4, base = 3, perWave = 0.7, gap = 1.0, delay = 6 },
			{ enemy = "bandit", from = 8, base = 2, perWave = 0.6, gap = 2.5, delay = 8 },
			{ enemy = "spy", from = 13, base = 1, perWave = 0.5, gap = 3, delay = 12 },
			{ enemy = "rider", from = 17, base = 1, perWave = 0.5, gap = 4, delay = 14 },
		},
		bosses = { [10] = "sergeant", [20] = "chief_thief", [30] = "rival_zaim" },
	} :: Episode,
	ep3 = {
		waves = 40,
		hpPerWave = 0.09,
		pool = {
			{ enemy = "gendarme", from = 1, base = 6, perWave = 1.0, gap = 0.9 },
			{ enemy = "thug", from = 3, base = 4, perWave = 0.8, gap = 1.1, delay = 4 },
			{ enemy = "rider", from = 6, base = 1, perWave = 0.6, gap = 3, delay = 8 },
			{ enemy = "bandit", from = 9, base = 2, perWave = 0.7, gap = 2.2, delay = 10 },
			{ enemy = "spy", from = 12, base = 2, perWave = 0.5, gap = 2.5, delay = 12 },
			{ enemy = "sapper", from = 18, base = 1, perWave = 0.4, gap = 5, delay = 15 },
			{ enemy = "thief", from = 22, base = 4, perWave = 0.8, gap = 0.8, delay = 2 },
		},
		bosses = { [10] = "sergeant", [20] = "chief_thief", [30] = "rival_zaim", [40] = "colonel" },
	} :: Episode,
}

-- Endless: the same pool as ep3 but open-ended, with quadratic HP growth and a boss every 10 waves
-- cycling through the list.
local Infinite = {
	hpPerWave = 0.10,
	hpPerWaveSq = 0.004,
	speedPerWave = 0.004, -- enemies get 0.4% faster per wave (capped in WaveLogic)
	pool = {
		{ enemy = "thief", from = 1, base = 4, perWave = 0.8, gap = 1.0 },
		{ enemy = "gendarme", from = 2, base = 4, perWave = 0.9, gap = 1.1, delay = 3 },
		{ enemy = "thug", from = 5, base = 3, perWave = 0.7, gap = 1.3, delay = 6 },
		{ enemy = "bandit", from = 9, base = 2, perWave = 0.6, gap = 2.4, delay = 8 },
		{ enemy = "rider", from = 14, base = 1, perWave = 0.5, gap = 3, delay = 10 },
		{ enemy = "spy", from = 16, base = 2, perWave = 0.5, gap = 2.5, delay = 12 },
		{ enemy = "sapper", from = 22, base = 1, perWave = 0.4, gap = 5, delay = 15 },
	},
	bossCycle = { "sergeant", "chief_thief", "rival_zaim", "colonel" },
	bossEvery = 10,
}

return { episodes = Waves, infinite = Infinite }
