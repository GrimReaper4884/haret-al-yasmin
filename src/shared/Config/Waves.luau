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
	path: number?, -- twin-road arenas: pin this entry to one road (default: the alternation)
	hp: number?, -- HP factor for this entry (default 1): a second boss walking in with the first
}

export type Episode = {
	waves: number,
	hpPerWave: number, -- enemy HP multiplier grows by this per wave after the first
	pool: { PoolEntry },
	bosses: { [number]: string },
	bossHp: { [number]: number | { number } }?, -- per boss wave: an HP factor on top of the difficulty's, or one per difficulty (TD order)
	bossRoad: number?, -- twin-road arenas: the road every boss walks (default: the spawns' alternation)
	script: { [number]: any }?, -- scripted beats (TdTowers.runScript): the ally's turn (S1-S07)
}

local Waves = {
	ep1 = {
		waves = 20,
		hpPerWave = 0.07,
		pool = {
			{ enemy = "gendarme", from = 1, base = 3, perWave = 0.8, gap = 1.4 },
			{ enemy = "thief", from = 5, base = 3, perWave = 0.9, gap = 1.1, delay = 4 },
			{ enemy = "thug", from = 7, base = 2, perWave = 0.6, gap = 1.8, delay = 8 },
			{ enemy = "bandit", from = 12, base = 1, perWave = 0.5, gap = 3, delay = 10 },
		},
		bosses = { [10] = "sergeant", [20] = "chief_thief" },
	} :: Episode,
	ep2 = {
		waves = 30,
		hpPerWave = 0.075,
		pool = {
			{ enemy = "gendarme", from = 1, base = 4, perWave = 0.8, gap = 1.3 },
			{ enemy = "thug", from = 3, base = 2, perWave = 0.7, gap = 1.1, delay = 3 },
			{ enemy = "thief", from = 5, base = 3, perWave = 0.6, gap = 1.0, delay = 6 },
			{ enemy = "bandit", from = 9, base = 1, perWave = 0.5, gap = 2.5, delay = 8 },
			{ enemy = "spy", from = 14, base = 1, perWave = 0.4, gap = 3, delay = 12 },
			{ enemy = "rider", from = 18, base = 1, perWave = 0.4, gap = 4, delay = 14 },
		},
		bosses = { [10] = "sergeant", [20] = "chief_thief", [30] = "rival_zaim" },
	} :: Episode,
	ep3 = {
		waves = 40,
		hpPerWave = 0.075,
		pool = {
			{ enemy = "gendarme", from = 1, base = 4, perWave = 0.9, gap = 1.0 },
			{ enemy = "thug", from = 4, base = 2, perWave = 0.7, gap = 1.1, delay = 4 },
			{ enemy = "rider", from = 8, base = 1, perWave = 0.4, gap = 3, delay = 8 },
			{ enemy = "bandit", from = 11, base = 1, perWave = 0.5, gap = 2.2, delay = 10 },
			{ enemy = "spy", from = 13, base = 2, perWave = 0.4, gap = 2.5, delay = 12 },
			{ enemy = "sapper", from = 18, base = 1, perWave = 0.35, gap = 5, delay = 15 },
			{ enemy = "thief", from = 22, base = 4, perWave = 0.8, gap = 0.8, delay = 2 },
		},
		bosses = { [10] = "sergeant", [20] = "chief_thief", [30] = "rival_zaim", [40] = "colonel" },
	} :: Episode,
	-- Season Story 1 (STORY_PLAN §5, S1-S04). Each episode adds its mechanic through its attackers.
	-- Episode 4 "The Lost Shoe" (saha, two roads): pickpocket swarms with a drummer every few waves,
	-- the gendarmes searching houses.
	ep4 = {
		waves = 40,
		hpPerWave = 0.085,
		pool = {
			{ enemy = "gendarme", from = 1, base = 4, perWave = 0.9, gap = 1.0 },
			{ enemy = "pickpocket", from = 3, base = 6, perWave = 0.5, gap = 0.35, delay = 4 },
			{ enemy = "thug", from = 5, base = 2, perWave = 0.7, gap = 1.1, delay = 5 },
			{ enemy = "drummer", from = 6, base = 1, perWave = 0.08, gap = 4, delay = 4 },
			{ enemy = "rider", from = 8, base = 1, perWave = 0.4, gap = 3, delay = 8 },
			{ enemy = "bandit", from = 11, base = 1, perWave = 0.5, gap = 2.2, delay = 10 },
			{ enemy = "corporal_minion", from = 12, base = 2, perWave = 0.4, gap = 1.4, delay = 10 },
			{ enemy = "thief", from = 18, base = 4, perWave = 0.8, gap = 0.8, delay = 2 },
		},
		bosses = { [10] = "sergeant", [20] = "abu_jawdan", [30] = "corporal", [40] = "abu_jawdan" },
	} :: Episode,
	-- Episode 5 "Fire at the Warehouse" (warehouse yard): torchbearers set the door burning, porters
	-- shield the crowd behind them.
	ep5 = {
		waves = 45,
		hpPerWave = 0.085,
		pool = {
			{ enemy = "gendarme", from = 1, base = 3, perWave = 0.8, gap = 1.2 },
			{ enemy = "torchbearer", from = 4, base = 1, perWave = 0.4, gap = 1.6, delay = 3 },
			{ enemy = "thug", from = 6, base = 2, perWave = 0.6, gap = 1.1, delay = 5 },
			{ enemy = "porter", from = 8, base = 1, perWave = 0.18, gap = 4, delay = 6 },
			{ enemy = "bandit", from = 11, base = 1, perWave = 0.45, gap = 2.4, delay = 9 },
			{ enemy = "thief", from = 14, base = 3, perWave = 0.6, gap = 0.9, delay = 2 },
			{ enemy = "rider", from = 20, base = 1, perWave = 0.4, gap = 3, delay = 13 },
			{ enemy = "abu_shatour", from = 45, base = 1, perWave = 0, gap = 1, delay = 20 },
		},
		bosses = { [15] = "sergeant", [30] = "abu_shatour", [45] = "rival_zaim" },
	} :: Episode,
	-- Episode 6 "The Blind Beggar" (saha at night): disguised neighbours and false beggars walk among
	-- the crowd; only lanterns, or defenders in their light, unmask them.
	ep6 = {
		waves = 50,
		hpPerWave = 0.09,
		pool = {
			{ enemy = "gendarme", from = 1, base = 3, perWave = 0.8, gap = 1.2 },
			{ enemy = "disguised", from = 3, base = 1, perWave = 0.3, gap = 2.2, delay = 3 },
			{ enemy = "thief", from = 5, base = 2, perWave = 0.6, gap = 1.0, delay = 5 },
			{ enemy = "beggar", from = 7, base = 1, perWave = 0.25, gap = 2.6, delay = 7 },
			{ enemy = "thug", from = 9, base = 2, perWave = 0.6, gap = 1.2, delay = 9 },
			{ enemy = "spy", from = 12, base = 1, perWave = 0.35, gap = 2.6, delay = 11 },
			{ enemy = "porter", from = 18, base = 1, perWave = 0.15, gap = 4, delay = 13 },
			{ enemy = "drummer", from = 24, base = 1, perWave = 0.08, gap = 4, delay = 15 },
		},
		bosses = { [10] = "corporal", [25] = "abu_jawdan", [40] = "sergeant", [50] = "lateef" },
	} :: Episode,
	-- Episode 7 "The Police Post" (post road): riflemen pin defenders down (sabotage), sappers and
	-- porters bring armour; the commandant closes it with his corporals.
	ep7 = {
		waves = 50,
		hpPerWave = 0.095,
		pool = {
			{ enemy = "gendarme", from = 1, base = 4, perWave = 0.9, gap = 1.0 },
			{ enemy = "rifleman", from = 3, base = 1, perWave = 0.3, gap = 2.4, delay = 3 },
			{ enemy = "thug", from = 5, base = 2, perWave = 0.6, gap = 1.1, delay = 5 },
			{ enemy = "sapper", from = 8, base = 1, perWave = 0.25, gap = 5, delay = 8 },
			{ enemy = "corporal_minion", from = 10, base = 2, perWave = 0.4, gap = 1.4, delay = 9 },
			{ enemy = "bandit", from = 12, base = 1, perWave = 0.45, gap = 2.2, delay = 10 },
			{ enemy = "rider", from = 16, base = 1, perWave = 0.4, gap = 3, delay = 12 },
			{ enemy = "porter", from = 22, base = 1, perWave = 0.15, gap = 4, delay = 14 },
			{ enemy = "thief", from = 26, base = 3, perWave = 0.6, gap = 0.9, delay = 2 },
			{ enemy = "corporal_minion", from = 50, base = 6, perWave = 0, gap = 0.8, delay = 18 }, -- the commandant's escort
		},
		bosses = { [10] = "corporal", [20] = "sergeant", [35] = "abu_jawdan", [50] = "colonel" },
		bossHp = { [50] = { 2.5, 1.8, 1.6 } }, -- the commandant is the finale's damage check (Normal, Hard, Nightmare)
	} :: Episode,
	-- Episode 8 "The Two Lanes" (twin gates, both roads): the whole rival lane, carts that spill
	-- thugs, their hakim healing the crowd. The thief comes at wave 40, reaches the gate and turns:
	-- from wave 41 he guards it as an ally (STORY_PLAN §5.2).
	ep8 = {
		waves = 55,
		hpPerWave = 0.1,
		pool = {
			{ enemy = "thug", from = 1, base = 4, perWave = 0.8, gap = 1.0 },
			{ enemy = "gendarme", from = 2, base = 3, perWave = 0.6, gap = 1.2, delay = 3 },
			{ enemy = "hakim_rival", from = 5, base = 1, perWave = 0.2, gap = 3, delay = 6 },
			{ enemy = "brute", from = 8, base = 1, perWave = 0.25, gap = 3, delay = 7 },
			{ enemy = "cart", from = 10, base = 1, perWave = 0.15, gap = 5, delay = 9 },
			{ enemy = "bandit", from = 12, base = 1, perWave = 0.45, gap = 2.2, delay = 10 },
			{ enemy = "rifleman", from = 16, base = 1, perWave = 0.3, gap = 2.4, delay = 11 },
			{ enemy = "rider", from = 20, base = 1, perWave = 0.4, gap = 3, delay = 12 },
			{ enemy = "spy", from = 24, base = 1, perWave = 0.35, gap = 2.6, delay = 13 },
		},
		bosses = { [15] = "fakhr", [30] = "abu_zira", [40] = "chief_thief", [45] = "rival_zaim", [55] = "rival_zaim_enraged" },
		bossHp = { [15] = { 0.5, 0.5, 0.5 }, [55] = { 1.25, 1.3, 0.44 } },
		script = { [41] = { kind = "ally", unit = "adashari", level = 3 } },
	} :: Episode,
	-- Episode 9 "The Confession" (twin gates at dusk, both roads): the one-armed guard stands at the
	-- gate from wave 1 and takes the first 20 gate damage; snakes from the grave from wave 20; the
	-- 'akeed and the commandant walk in together at the end.
	ep9 = {
		waves = 60,
		hpPerWave = 0.1,
		pool = {
			{ enemy = "gendarme", from = 1, base = 4, perWave = 0.9, gap = 1.0 },
			{ enemy = "thug", from = 3, base = 2, perWave = 0.6, gap = 1.1, delay = 3 },
			{ enemy = "rifleman", from = 6, base = 1, perWave = 0.3, gap = 2.4, delay = 5 },
			{ enemy = "hakim_rival", from = 8, base = 1, perWave = 0.2, gap = 3, delay = 6 },
			{ enemy = "brute", from = 10, base = 1, perWave = 0.25, gap = 3, delay = 7 },
			{ enemy = "cart", from = 12, base = 1, perWave = 0.15, gap = 5, delay = 9 },
			{ enemy = "bandit", from = 14, base = 1, perWave = 0.45, gap = 2.2, delay = 10 },
			{ enemy = "snake", from = 20, base = 8, perWave = 0.4, gap = 0.3, delay = 4 },
			{ enemy = "spy", from = 22, base = 1, perWave = 0.35, gap = 2.6, delay = 12 },
			{ enemy = "rider", from = 26, base = 1, perWave = 0.4, gap = 3, delay = 13 },
			{ enemy = "porter", from = 30, base = 1, perWave = 0.15, gap = 4, delay = 14 },
			{ enemy = "fakhr", from = 45, to = 45, base = 1, perWave = 0, gap = 1, delay = 20, path = 1, hp = 0.3 }, -- with Abu Zira', by the other road
			{ enemy = "colonel", from = 60, base = 1, perWave = 0, gap = 1, delay = 20, path = 1, hp = 0.3 }, -- with the 'akeed, by the other road
		},
		bosses = { [15] = "abu_shatour", [30] = "lateef", [45] = "abu_zira", [60] = "rival_zaim" },
		bossHp = { [15] = { 0.5, 0.5, 0.3 }, [30] = { 1, 0.6, 0.4 }, [45] = { 1, 1, 0.3 } }, bossRoad = 2,
		script = { [1] = { kind = "ally", unit = "adashari", level = 3, shield = 20 } },
	} :: Episode,
}

-- Endless: the same pool as ep3 but open-ended, with quadratic HP growth (compounding after wave
-- 50) and a boss every 10 waves cycling through the list.
local Infinite = {
	hpPerWave = 0.05,
	hpPerWaveSq = 0.006,
	lateFrom = 50, -- after this wave HP also compounds by lateGrowth per wave
	lateGrowth = 0.035,
	speedPerWave = 0.004, -- enemies get 0.4% faster per wave (capped in WaveLogic)
	pool = {
		{ enemy = "gendarme", from = 1, base = 4, perWave = 0.9, gap = 1.1 },
		{ enemy = "thief", from = 5, base = 3, perWave = 0.8, gap = 1.0, delay = 3 },
		{ enemy = "thug", from = 7, base = 3, perWave = 0.7, gap = 1.3, delay = 6 },
		{ enemy = "bandit", from = 11, base = 2, perWave = 0.6, gap = 2.4, delay = 8 },
		{ enemy = "rider", from = 14, base = 1, perWave = 0.5, gap = 3, delay = 10 },
		{ enemy = "spy", from = 16, base = 2, perWave = 0.5, gap = 2.5, delay = 12 },
		{ enemy = "sapper", from = 22, base = 1, perWave = 0.4, gap = 5, delay = 15 },
	},
	bossCycle = { "sergeant", "chief_thief", "rival_zaim", "colonel" },
	bossEvery = 10,
}

-- Event wave scripts (same shape as episodes), keyed by Config/Events id.
local Events = {
	-- Bandits and thieves raid the olive harvest in the orchards; riders come to carry it off.
	olive_harvest = {
		waves = 15,
		hpPerWave = 0.07,
		pool = {
			{ enemy = "thief", from = 1, base = 4, perWave = 0.8, gap = 1.1 },
			{ enemy = "gendarme", from = 3, base = 2, perWave = 0.6, gap = 1.4, delay = 3 },
			{ enemy = "bandit", from = 5, base = 1, perWave = 0.5, gap = 2.6, delay = 6 },
			{ enemy = "rider", from = 9, base = 1, perWave = 0.4, gap = 3.5, delay = 9 },
		},
		bosses = { [8] = "sergeant", [15] = "chief_thief" },
	} :: Episode,
	-- Lantern Nights (LP-D12): the thieves think the lane sleeps between the musaharati's rounds. Abu
	-- al-Nahr's men come at wave 8 behind him; Abu Shatour and his torch end the month at wave 15.
	-- TUNE (D-122): both carry 80 gate damage, so they walk in at a small share of their story HP
	-- (0.12 and 0.15: about the Sergeant's and the Chief's HP in the Olive Harvest); tests/balance
	-- then matches Olive Harvest Nights loadout for loadout on Normal and Hard.
	ramadan = {
		waves = 15,
		hpPerWave = 0.07,
		pool = {
			{ enemy = "thief", from = 1, base = 4, perWave = 0.8, gap = 1.1 },
			{ enemy = "pickpocket", from = 2, base = 2, perWave = 0.5, gap = 1.2, delay = 2 },
			{ enemy = "thug", from = 4, base = 1, perWave = 0.5, gap = 1.8, delay = 5 },
			{ enemy = "disguised", from = 6, base = 1, perWave = 0.4, gap = 2.4, delay = 7 },
			{ enemy = "torchbearer", from = 10, base = 1, perWave = 0.4, gap = 2.6, delay = 9 },
		},
		bosses = { [8] = "rival_zaim", [15] = "abu_shatour" },
		bossHp = { [8] = { 0.12, 0.12, 0.12 }, [15] = { 0.15, 0.15, 0.15 } },
	} :: Episode,
}

return { episodes = Waves, infinite = Infinite, events = Events }
