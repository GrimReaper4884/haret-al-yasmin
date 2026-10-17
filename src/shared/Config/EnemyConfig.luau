--!strict
--[[
	EnemyConfig: enemy archetypes, bosses, difficulty and the wave HP formula.

	Enemies are plain server data (no Humanoids). HP for one enemy:
	  hp = BaseHp x hpMult x waveFactor(w) x Difficulty.hpMult x WorldHpMult[world] [x finaleHpScale]
	  waveFactor(w) = 1 + 0.12w + 0.004w^2   (2.6x at w10, 5.0x at w20, 8.2x at w30, 14.5x at w45)
	Infinite mode: past the last authored wave L, waveFactor is frozen at L and HP is multiplied by
	InfiniteGrowth^(w - L). Shield pools = hp x shieldMult x Difficulty.shieldMult (Fortified).
	Speed = BaseSpeed x speedMult (studs/s). GDD: docs/GAME_DESIGN.md sections 12-14.

	Attribute rules (EnemySim / Targeting implement them):
	  veiled    - untargetable unless inside a detection aura (Lantern); splash/zone damage still hits.
	  flying    - see UnitConfig flyer rules (Marksman Full, others Half or None).
	  armorPlates (Ironbound) - immune to non-Breaker damage AND stun-immune until all plates are
	              stripped by Breaker hits; then takes normal damage and can be stunned.
	  stunImmune / bosses - incoming stuns become a BossStunToSlowPct slow for the stun's duration.
]]

local Types = require(script.Parent.Types)

export type Tier = "Normal" | "MiniBoss" | "Boss"

export type SummonEntry = { enemy: string, count: number }

export type Pulse = {
	radius: number, -- studs around the boss
	stun: number, -- seconds; stuns player units in radius
	every: number, -- seconds between pulses
	windup: number, -- seconds of visible telegraph ring before the stun lands
}

export type BossPhase = {
	atHpPct: number, -- phase starts when hp / maxHp <= atHpPct (first phase uses 1.0)
	rootFor: number?, -- seconds the boss stops moving on phase entry
	summon: { SummonEntry }?, -- spawned at the boss's path position, HP for the current wave
	shieldPctOfMax: number?, -- grants a shield pool = maxHp x this
	speedMult: number?, -- multiplies the boss's base speed from this phase on
	pulse: Pulse?,
}

export type EnemyDef = {
	id: string,
	displayName: string,
	model: string, -- asset name in ReplicatedStorage.Assets.Enemies
	tier: Tier,
	hpMult: number,
	speedMult: number,
	shieldMult: number?,
	bounty: number, -- Cash on death, split evenly across the party
	leakDamage: number, -- Gate HP lost if it reaches the end of the path
	veiled: boolean?,
	flying: boolean?,
	stunImmune: boolean?,
	armorPlates: number?,
	regen: { delay: number, pctPerSec: number, healRadius: number, healPctPerSec: number }?,
	split: SummonEntry?, -- spawned on death at the death position
	hex: { radius: number, stun: number, every: number }?, -- stuns the nearest player unit
	snuff: { radius: number, every: number, disableFor: number }?, -- disables nearest Lantern aura
	phases: { BossPhase }?,
}

export type DifficultyDef = { hpMult: number, shieldMult: number, fortified: boolean }

local EnemyConfig = {}

EnemyConfig.BaseHp = 100 -- TUNE
EnemyConfig.BaseSpeed = 6 -- studs/s at speedMult 1.0. TUNE
EnemyConfig.GateHp = 100 -- match is lost at 0. TUNE
EnemyConfig.InfiniteGrowth = 1.06
EnemyConfig.BossStunToSlowPct = 0.20

local difficulty: { [string]: DifficultyDef } = {
	Normal = { hpMult = 1.0, shieldMult = 1.0, fortified = false },
	Nightmare = { hpMult = 2.0, shieldMult = 2.0, fortified = true }, -- Fortified doubles shield pools
	Legend = { hpMult = 3.0, shieldMult = 2.0, fortified = true },
	EventHard = { hpMult = 10.0, shieldMult = 2.0, fortified = true },
}
EnemyConfig.Difficulty = difficulty

-- World HP multipliers. TUNE (W5 ships in Update 1)
local worldHpMult: { [number]: number } = { [1] = 1.0, [2] = 1.6, [3] = 2.5, [4] = 4.0, [5] = 6.0 }
EnemyConfig.WorldHpMult = worldHpMult

local enemies: { [string]: EnemyDef } = {
	Wisp = {
		id = "Wisp",
		displayName = "Wisp",
		model = "HY_Enemy_Wisp",
		tier = "Normal",
		hpMult = 1.0,
		speedMult = 1.0,
		bounty = 6,
		leakDamage = 3,
	},
	Courier = {
		id = "Courier",
		displayName = "Courier",
		model = "HY_Enemy_Courier",
		tier = "Normal",
		hpMult = 0.5,
		speedMult = 1.8,
		bounty = 4,
		leakDamage = 2,
	},
	Brute = {
		id = "Brute",
		displayName = "Brute",
		model = "HY_Enemy_Brute",
		tier = "Normal",
		hpMult = 4.0,
		speedMult = 0.6,
		bounty = 20,
		leakDamage = 10,
	},
	Veiled = {
		id = "Veiled",
		displayName = "Veiled",
		model = "HY_Enemy_Veiled",
		tier = "Normal",
		hpMult = 1.2,
		speedMult = 1.1,
		bounty = 8,
		leakDamage = 4,
		veiled = true,
	},
	Ironbound = {
		id = "Ironbound",
		displayName = "Ironbound",
		model = "HY_Enemy_Ironbound",
		tier = "Normal",
		hpMult = 2.5,
		speedMult = 0.8,
		bounty = 18,
		leakDamage = 8,
		armorPlates = 3, -- 1 plate per Breaker hit (some Breaker upgrades strip 2)
	},
	Warded = {
		id = "Warded",
		displayName = "Warded",
		model = "HY_Enemy_Warded",
		tier = "Normal",
		hpMult = 1.5,
		speedMult = 1.0,
		shieldMult = 1.0, -- shield pool absorbs damage first; Breakers deal 3x to it
		bounty = 14,
		leakDamage = 6,
	},
	Moth = {
		id = "Moth",
		displayName = "Moth",
		model = "HY_Enemy_Moth",
		tier = "Normal",
		hpMult = 0.8,
		speedMult = 1.3,
		bounty = 8,
		leakDamage = 3,
		flying = true,
	},
	Hive = {
		id = "Hive",
		displayName = "Hive",
		model = "HY_Enemy_Hive",
		tier = "Normal",
		hpMult = 3.0,
		speedMult = 0.7,
		bounty = 24,
		leakDamage = 10,
		split = { enemy = "Courier", count = 4 },
	},
	Mender = {
		id = "Mender",
		displayName = "Mender",
		model = "HY_Enemy_Mender",
		tier = "Normal",
		hpMult = 1.5,
		speedMult = 0.9,
		bounty = 14,
		leakDamage = 5,
		-- After 3 s without taking damage: regenerates 5% max HP/s and heals other enemies within
		-- 6 studs for 2% of THEIR max HP/s (also heals bosses). TUNE
		regen = { delay = 3, pctPerSec = 0.05, healRadius = 6, healPctPerSec = 0.02 },
	},
	Hexer = {
		id = "Hexer",
		displayName = "Hexer",
		model = "HY_Enemy_Hexer",
		tier = "Normal",
		hpMult = 2.0,
		speedMult = 0.9,
		bounty = 18,
		leakDamage = 6,
		hex = { radius = 15, stun = 3, every = 10 },
	},

	-- Mini-boss (World 1 waves 10 and 25).
	Thornback = {
		id = "Thornback",
		displayName = "Thornback",
		model = "HY_Boss_Thornback",
		tier = "MiniBoss",
		hpMult = 20,
		speedMult = 0.6,
		bounty = 300,
		leakDamage = 40,
		stunImmune = true,
		phases = {
			{ atHpPct = 1.0 },
			{ atHpPct = 0.5, summon = { { enemy = "Courier", count = 4 } } }, -- "Thorn Shed"
		},
	},
	-- Flying mid-boss (World 1 wave 15): tests Marksmen and punishes a single Lantern.
	LanternEater = {
		id = "LanternEater",
		displayName = "Lantern-Eater",
		model = "HY_Boss_LanternEater",
		tier = "MiniBoss",
		hpMult = 30,
		speedMult = 0.9,
		bounty = 400,
		leakDamage = 50,
		flying = true,
		stunImmune = true,
		snuff = { radius = 30, every = 12, disableFor = 4 },
	},
	-- World 1 final boss. Untimed, unskippable final wave of every World 1 act.
	WiltMatron = {
		id = "WiltMatron",
		displayName = "The Wilt Matron",
		model = "HY_Boss_WiltMatron",
		tier = "Boss",
		hpMult = 150, -- TUNE: 123,000 HP at W1 wave 30 Normal before finaleHpScale
		speedMult = 0.5,
		bounty = 0,
		leakDamage = 100, -- a leaked final boss ends the match
		stunImmune = true,
		phases = {
			{ atHpPct = 1.0, pulse = { radius = 18, stun = 3, every = 15, windup = 2 } },
			{
				atHpPct = 0.66,
				rootFor = 3,
				summon = { { enemy = "Wisp", count = 6 }, { enemy = "Brute", count = 2 } },
				shieldPctOfMax = 0.15,
				pulse = { radius = 18, stun = 3, every = 12, windup = 2 },
			},
			{
				atHpPct = 0.33,
				speedMult = 1.3,
				summon = { { enemy = "Veiled", count = 4 }, { enemy = "Mender", count = 2 } },
				pulse = { radius = 20, stun = 3, every = 10, windup = 1.5 },
			},
		},
	},
}
EnemyConfig.Enemies = enemies

function EnemyConfig.waveFactor(wave: number): number
	return 1 + 0.12 * wave + 0.004 * wave * wave
end

-- Max HP for one enemy. `lastAuthoredWave` is only passed by Infinite mode.
function EnemyConfig.computeHp(
	enemyId: string,
	wave: number,
	difficultyId: Types.Difficulty,
	world: number,
	lastAuthoredWave: number?
): number
	local def = enemies[enemyId]
	assert(def, `unknown enemy {enemyId}`)
	local diff = difficulty[difficultyId]
	assert(diff, `unknown difficulty {difficultyId}`)
	local w = wave
	local infinite = 1
	if lastAuthoredWave ~= nil and wave > lastAuthoredWave then
		w = lastAuthoredWave
		infinite = EnemyConfig.InfiniteGrowth ^ (wave - lastAuthoredWave)
	end
	local worldMult = worldHpMult[world] or 1
	return EnemyConfig.BaseHp * def.hpMult * EnemyConfig.waveFactor(w) * diff.hpMult * worldMult * infinite
end

return EnemyConfig
