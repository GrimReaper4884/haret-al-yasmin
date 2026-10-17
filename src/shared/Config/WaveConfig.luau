--!strict
--[[
	WaveConfig: authored waves. GDD: docs/GAME_DESIGN.md section 13.

	World 1 ("Lantern Market") uses ONE 30-wave master template:
	  * Act 6 plays all 30 waves (wave 30 is the finale).
	  * Acts 1-5 play the first `waveCount` waves, and their LAST wave is replaced by `finale`
	    (untimed, unskippable, final boss HP x finaleHpScale).
	Pacing: a new attribute every 5-8 waves (Veiled 5, Moth 11, Warded 13, Ironbound 17), spikes at
	8 and 20 (2x the previous wave's count), mini-bosses at 10 and 25, flying mid-boss at 15,
	exam wave 27, breathers 9/16/23/28, final boss 30.

	Spawn groups start at `delay` seconds after the wave starts (default 0) and spawn `count`
	enemies `interval` seconds apart. `addFlags` adds attribute flags to that group only.
	HP for each enemy comes from EnemyConfig.computeHp(enemy, waveNumber, difficulty, world).
]]

export type WaveTag =
	"Basics"
	| "NewAttribute"
	| "Spike"
	| "Breather"
	| "MiniBoss"
	| "MidBoss"
	| "Exam"
	| "Rush"
	| "FinalBoss"

export type SpawnGroup = {
	enemy: string,
	count: number,
	interval: number,
	delay: number?,
	addFlags: { string }?, -- e.g. { "veiled" }
}

export type WaveDef = {
	tag: WaveTag,
	note: string?,
	timed: boolean?, -- default true; boss finales are false
	skippable: boolean?, -- default true; boss finales are false
	groups: { SpawnGroup },
}

export type ActDef = {
	act: number,
	waveCount: number,
	finaleHpScale: number, -- multiplies the final boss HP in this act. TUNE
}

export type WorldDef = {
	id: string,
	index: number,
	name: string,
	startingCash: number,
	template: { WaveDef },
	finale: WaveDef,
	acts: { ActDef },
	musicBands: { { from: number, to: number, track: string } },
}

local WaveConfig = {}

WaveConfig.Timer = {
	-- Wave time limit = min(maxSeconds, baseSeconds + perEnemySeconds x enemies in the wave).
	-- When it expires the next wave starts even if enemies remain. TUNE
	baseSeconds = 30,
	perEnemySeconds = 1,
	maxSeconds = 75,
	skipVoteOpensAfter = 10, -- seconds into a wave; vote passes with all-but-one yes (AFK = abstain)
	firstWaveCountdown = 10,
}

-- Wave-end bonus = (BonusBase + BonusPerWave x waveNumber) / partySize, paid to every player.
WaveConfig.Bonus = { base = 250, perWave = 40 }

local finale: WaveDef = {
	tag = "FinalBoss",
	note = "The Wilt Matron (3 phases at 66% / 33%) with escorts. Untimed and unskippable.",
	timed = false,
	skippable = false,
	groups = {
		{ enemy = "WiltMatron", count = 1, interval = 0 },
		{ enemy = "Wisp", count = 8, interval = 0.8, delay = 4 },
	},
}

local w1Template: { WaveDef } = {
	-- 1-4 basics
	{ tag = "Basics", groups = { { enemy = "Wisp", count = 8, interval = 1.2 } } },
	{ tag = "Basics", groups = { { enemy = "Wisp", count = 12, interval = 1.0 } } },
	{
		tag = "Basics",
		groups = {
			{ enemy = "Wisp", count = 10, interval = 1.0 },
			{ enemy = "Courier", count = 4, interval = 0.6, delay = 6 },
		},
	},
	{
		tag = "Basics",
		groups = {
			{ enemy = "Wisp", count = 14, interval = 0.8 },
			{ enemy = "Courier", count = 6, interval = 0.5, delay = 8 },
		},
	},
	-- 5 first attribute: Veiled (needs a Lantern at U2, or splash)
	{
		tag = "NewAttribute",
		note = "Veiled introduced",
		groups = {
			{ enemy = "Wisp", count = 10, interval = 1.0 },
			{ enemy = "Veiled", count = 6, interval = 1.2, delay = 5 },
		},
	},
	{
		tag = "Basics",
		note = "first Brutes",
		groups = {
			{ enemy = "Wisp", count = 12, interval = 0.8 },
			{ enemy = "Brute", count = 2, interval = 3.0, delay = 6 },
		},
	},
	{
		tag = "Basics",
		groups = {
			{ enemy = "Courier", count = 8, interval = 0.6 },
			{ enemy = "Veiled", count = 8, interval = 1.0, delay = 4 },
		},
	},
	-- 8 spike: 32 enemies (2x wave 7)
	{
		tag = "Spike",
		groups = {
			{ enemy = "Wisp", count = 14, interval = 0.6 },
			{ enemy = "Courier", count = 8, interval = 0.5, delay = 4 },
			{ enemy = "Veiled", count = 8, interval = 0.8, delay = 6 },
			{ enemy = "Brute", count = 2, interval = 3.0, delay = 10 },
		},
	},
	{ tag = "Breather", groups = { { enemy = "Wisp", count = 12, interval = 1.0 } } },
	-- 10 mini-boss
	{
		tag = "MiniBoss",
		note = "Thornback: sheds 4 Couriers at 50% HP",
		groups = {
			{ enemy = "Wisp", count = 10, interval = 0.8 },
			{ enemy = "Thornback", count = 1, interval = 0, delay = 6 },
		},
	},
	-- 11 second attribute: Moth (flying; Marksman check)
	{
		tag = "NewAttribute",
		note = "Moths introduced",
		groups = {
			{ enemy = "Wisp", count = 12, interval = 0.8 },
			{ enemy = "Moth", count = 6, interval = 1.2, delay = 5 },
		},
	},
	{
		tag = "Basics",
		groups = {
			{ enemy = "Courier", count = 10, interval = 0.5 },
			{ enemy = "Moth", count = 8, interval = 1.0, delay = 3 },
			{ enemy = "Veiled", count = 4, interval = 1.2, delay = 8 },
		},
	},
	-- 13 third attribute: Warded (shield pools; Breaker check)
	{
		tag = "NewAttribute",
		note = "Warded introduced",
		groups = {
			{ enemy = "Wisp", count = 10, interval = 0.8 },
			{ enemy = "Warded", count = 6, interval = 1.5, delay = 4 },
		},
	},
	{
		tag = "Basics",
		note = "first Menders",
		groups = {
			{ enemy = "Wisp", count = 10, interval = 0.8 },
			{ enemy = "Brute", count = 4, interval = 2.5, delay = 4 },
			{ enemy = "Mender", count = 4, interval = 1.5, delay = 6 },
		},
	},
	-- 15 flying mid-boss (Act 1 replaces this wave with the finale)
	{
		tag = "MidBoss",
		note = "Lantern-Eater snuffs the nearest Lantern aura every 12 s",
		groups = {
			{ enemy = "Moth", count = 6, interval = 1.0 },
			{ enemy = "LanternEater", count = 1, interval = 0, delay = 5 },
		},
	},
	{
		tag = "Breather",
		groups = {
			{ enemy = "Wisp", count = 14, interval = 0.8 },
			{ enemy = "Courier", count = 6, interval = 0.5, delay = 6 },
		},
	},
	-- 17 fourth attribute: Ironbound (immune to non-Breaker damage until 3 plates are stripped)
	{
		tag = "NewAttribute",
		note = "Ironbound introduced",
		groups = {
			{ enemy = "Wisp", count = 14, interval = 0.8 },
			{ enemy = "Ironbound", count = 4, interval = 2.0, delay = 5 },
		},
	},
	{
		tag = "Basics",
		note = "Hives split into 4 Couriers each",
		groups = {
			{ enemy = "Courier", count = 10, interval = 0.5 },
			{ enemy = "Hive", count = 3, interval = 3.0, delay = 4 },
		},
	},
	{
		tag = "Basics",
		note = "first Hexers",
		groups = {
			{ enemy = "Wisp", count = 12, interval = 0.8 },
			{ enemy = "Brute", count = 4, interval = 2.5, delay = 4 },
			{ enemy = "Hexer", count = 2, interval = 4.0, delay = 8 },
		},
	},
	-- 20 spike: 36 enemies (2x wave 19)
	{
		tag = "Spike",
		groups = {
			{ enemy = "Wisp", count = 16, interval = 0.5 },
			{ enemy = "Brute", count = 6, interval = 2.0, delay = 3 },
			{ enemy = "Veiled", count = 6, interval = 0.8, delay = 6 },
			{ enemy = "Moth", count = 6, interval = 0.8, delay = 8 },
			{ enemy = "Hexer", count = 2, interval = 4.0, delay = 10 },
		},
	},
	{
		tag = "Basics",
		groups = {
			{ enemy = "Moth", count = 12, interval = 0.8 },
			{ enemy = "Veiled", count = 10, interval = 0.8, delay = 4 },
		},
	},
	{
		tag = "Basics",
		groups = {
			{ enemy = "Ironbound", count = 6, interval = 2.0 },
			{ enemy = "Warded", count = 6, interval = 1.5, delay = 3 },
			{ enemy = "Mender", count = 4, interval = 1.5, delay = 6 },
		},
	},
	{
		tag = "Breather",
		groups = {
			{ enemy = "Wisp", count = 16, interval = 0.6 },
			{ enemy = "Courier", count = 8, interval = 0.5, delay = 5 },
		},
	},
	{
		tag = "Basics",
		groups = {
			{ enemy = "Brute", count = 6, interval = 2.0 },
			{ enemy = "Hive", count = 6, interval = 2.5, delay = 3 },
			{ enemy = "Hexer", count = 3, interval = 4.0, delay = 6 },
		},
	},
	-- 25 mini-boss pair
	{
		tag = "MiniBoss",
		groups = {
			{ enemy = "Thornback", count = 2, interval = 6.0 },
			{ enemy = "Mender", count = 4, interval = 1.5, delay = 2 },
			{ enemy = "Warded", count = 4, interval = 1.5, delay = 6 },
		},
	},
	{
		tag = "Basics",
		note = "Veiled Moths: needs detection AND anti-air in the same lane",
		groups = {
			{ enemy = "Courier", count = 10, interval = 0.5 },
			{ enemy = "Veiled", count = 10, interval = 0.8, delay = 3 },
			{ enemy = "Moth", count = 6, interval = 1.0, delay = 6, addFlags = { "veiled" } },
		},
	},
	-- 27 exam: every attribute at once
	{
		tag = "Exam",
		groups = {
			{ enemy = "Wisp", count = 10, interval = 0.5 },
			{ enemy = "Veiled", count = 6, interval = 0.8, delay = 2 },
			{ enemy = "Moth", count = 6, interval = 0.8, delay = 4 },
			{ enemy = "Ironbound", count = 4, interval = 2.0, delay = 5 },
			{ enemy = "Warded", count = 4, interval = 1.5, delay = 6 },
			{ enemy = "Brute", count = 4, interval = 2.0, delay = 7 },
			{ enemy = "Mender", count = 3, interval = 1.5, delay = 8 },
			{ enemy = "Hive", count = 2, interval = 3.0, delay = 9 },
			{ enemy = "Hexer", count = 2, interval = 4.0, delay = 10 },
		},
	},
	{ tag = "Breather", groups = { { enemy = "Wisp", count = 16, interval = 0.6 } } },
	{
		tag = "Rush",
		groups = {
			{ enemy = "Courier", count = 20, interval = 0.4 },
			{ enemy = "Brute", count = 8, interval = 1.5, delay = 4 },
			{ enemy = "Warded", count = 4, interval = 1.5, delay = 8 },
		},
	},
	-- 30 final boss
	finale,
}

local world1: WorldDef = {
	id = "W1",
	index = 1,
	name = "Lantern Market",
	startingCash = 600,
	template = w1Template,
	finale = finale,
	acts = {
		{ act = 1, waveCount = 15, finaleHpScale = 0.50 },
		{ act = 2, waveCount = 18, finaleHpScale = 0.65 },
		{ act = 3, waveCount = 20, finaleHpScale = 0.80 },
		{ act = 4, waveCount = 22, finaleHpScale = 0.90 },
		{ act = 5, waveCount = 25, finaleHpScale = 0.95 },
		{ act = 6, waveCount = 30, finaleHpScale = 1.00 },
	},
	-- Music changes telegraph the bands (TDS pattern). Track names map to SoundService assets.
	musicBands = {
		{ from = 1, to = 9, track = "Dusk" },
		{ from = 10, to = 19, track = "Lanterns" },
		{ from = 20, to = 26, track = "Wilt" },
		{ from = 27, to = 30, track = "LastBloom" },
	},
}

local worlds: { [string]: WorldDef } = { W1 = world1 }
WaveConfig.Worlds = worlds

return WaveConfig
