--!strict
-- The attackers of the lane. Pure data. hp at Normal difficulty, speed in studs/second,
-- reward = cash to the killing tower's owner, gateDamage = HP the gate loses if they reach it.
-- armor = fraction of damage ignored. stealth = only towers with hitsStealth can target them.
--
-- Original archetypes of 1930s troubles: gendarmes of the occupation, night thieves, bandits from
-- the orchards, thugs from the rival lane, and their officers as bosses.

export type EnemyDef = {
	nameKey: string,
	hp: number,
	speed: number,
	reward: number,
	gateDamage: number,
	armor: number?,
	stealth: boolean?,
	boss: boolean?,
	-- Story mechanics (docs/STORY_PLAN.md §10.1, TdSim / WaveLogic):
	swarm: boolean?, -- tiny and many: groups up to WaveLogic.SWARM_PER_GROUP, half weight in the wave cap
	aura: { speed: number, radius: number }?, -- other enemies within radius walk speed× faster (best one, capped)
	shield: { radius: number, reduce: number }?, -- enemies within radius (itself too) take (1 - reduce) damage; not stacking
	burn: number?, -- burn stacks laid on the gate when it reaches it (TD.BURN_*)
	disguised: boolean?, -- untargetable and splash-immune until a lantern lights it or a lit defender's single hit lands
	summon: { enemy: string, count: number, every: number }?, -- boss: calls `count` escorts every `every` s until it dies
	teleport: { atHp: number, fraction: number, telegraph: number }?, -- boss: once, at `atHp` of its HP, jumps `fraction` of the road after a `telegraph` s warning
	sabotage: { range: number, duration: number, cooldown: number }?, -- stops to shoot the nearest defender within range; it can't attack for `duration` s
	split: { enemy: string, count: number }?, -- releases `count` attackers where it dies
	enrage: { belowHp: number, speed: number }?, -- walks speed× faster below belowHp of its HP (capped like auras)
	healAura: { radius: number, pct: number }?, -- other enemies within radius regain pct of max HP per second (best one)
	small: boolean?, -- render only: half-height health bar (snakes)
	visual: {
		robe: string,
		accent: string,
		skin: string,
		hat: "tarboosh" | "cap" | "hatta" | "scarf" | "none" | "turban" | "kepi" | "helmet",
		hatColor: string,
		weapon: "stick" | "dagger" | "rifle" | "sack" | "none" | "sword",
		scale: number?,
	},
}

local Enemies: { [string]: EnemyDef } = {
	gendarme = {
		nameKey = "enemy.gendarme.name",
		hp = 40,
		speed = 5.5,
		reward = 14,
		gateDamage = 1,
		visual = { robe = "#2F3E6B", accent = "#1F1B18", skin = "#E0B894", hat = "kepi", hatColor = "#2F3E6B", weapon = "rifle" },
	},
	thief = {
		nameKey = "enemy.thief.name",
		hp = 28,
		speed = 8.5,
		reward = 12,
		gateDamage = 1,
		stealth = true,
		visual = { robe = "#2A211B", accent = "#2A211B", skin = "#B97F5A", hat = "scarf", hatColor = "#1F1B18", weapon = "sack", scale = 0.95 },
	},
	bandit = {
		nameKey = "enemy.bandit.name",
		hp = 160,
		speed = 4.0,
		reward = 30,
		gateDamage = 2,
		armor = 0.15,
		visual = { robe = "#6E5E50", accent = "#A4302A", skin = "#B97F5A", hat = "hatta", hatColor = "#8C8079", weapon = "sword", scale = 1.15 },
	},
	thug = {
		nameKey = "enemy.thug.name",
		hp = 90,
		speed = 5.6,
		reward = 22,
		gateDamage = 1,
		visual = { robe = "#3E5B3A", accent = "#1F1B18", skin = "#C68E64", hat = "tarboosh", hatColor = "#1F1B18", weapon = "stick", scale = 1.05 },
	},
	rider = {
		nameKey = "enemy.rider.name",
		hp = 180,
		speed = 6.8,
		reward = 40,
		gateDamage = 3,
		armor = 0.2,
		visual = { robe = "#2F3E6B", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#1F1B18", weapon = "sword", scale = 1.2 },
	},
	sapper = {
		nameKey = "enemy.sapper.name",
		hp = 320,
		speed = 3.2,
		reward = 55,
		gateDamage = 8,
		armor = 0.35,
		visual = { robe = "#3D3A38", accent = "#2F3E6B", skin = "#E0B894", hat = "helmet", hatColor = "#3D3A38", weapon = "sack", scale = 1.2 },
	},
	spy = {
		nameKey = "enemy.spy.name",
		hp = 140,
		speed = 7.0,
		reward = 35,
		gateDamage = 2,
		stealth = true,
		visual = { robe = "#EADFC8", accent = "#2A211B", skin = "#D2A07A", hat = "tarboosh", hatColor = "#A4302A", weapon = "dagger" },
	},

	-- Season Story 1, batch 1 (STORY_PLAN §6.1, S1-S03): Episodes 4–6. Primitive figures until their
	-- Meshy models land (S1-A02); numbers are the harness starting points.
	pickpocket = {
		nameKey = "enemy.pickpocket.name",
		hp = 16,
		speed = 9.5,
		reward = 6,
		gateDamage = 1,
		steal = 0.1, -- at the gate: a tenth of each merchant's next payout (LP-E01, TD.STEAL_CAP in all)
		swarm = true, -- groups of 12, half weight in the wave cap
		visual = { robe = "#6E6A64", accent = "#3E5B3A", skin = "#C68E64", hat = "cap", hatColor = "#3D3A38", weapon = "sack", scale = 0.8 },
	},
	drummer = {
		nameKey = "enemy.drummer.name",
		hp = 110,
		speed = 5.0,
		reward = 28,
		gateDamage = 1,
		aura = { speed = 1.25, radius = 7 }, -- the drum hurries everyone near him
		visual = { robe = "#3E5B3A", accent = "#A4302A", skin = "#C68E64", hat = "turban", hatColor = "#5E6B3A", weapon = "stick", scale = 1.05 },
	},
	torchbearer = {
		nameKey = "enemy.torchbearer.name",
		hp = 70,
		speed = 6.2,
		reward = 20,
		gateDamage = 1,
		burn = 1, -- sets the gate burning (TD.BURN_*)
		visual = { robe = "#2A211B", accent = "#A4302A", skin = "#B97F5A", hat = "scarf", hatColor = "#1F1B18", weapon = "stick" },
	},
	porter = {
		nameKey = "enemy.porter.name",
		hp = 260,
		speed = 3.6,
		reward = 45,
		gateDamage = 2,
		armor = 0.25,
		shield = { radius = 6, reduce = 0.3 }, -- the crate covers everyone close behind it
		visual = { robe = "#6E5E50", accent = "#3D3A38", skin = "#B97F5A", hat = "scarf", hatColor = "#8C8079", weapon = "sack", scale = 1.2 },
	},
	disguised = {
		nameKey = "enemy.disguised.name",
		hp = 120,
		speed = 5.4,
		reward = 32,
		gateDamage = 2,
		disguised = true, -- walks as a neighbour until a lantern or a lit hit unmasks him
		visual = { robe = "#D9C9A8", accent = "#8C8079", skin = "#D2A07A", hat = "tarboosh", hatColor = "#A4302A", weapon = "dagger" },
	},
	-- Abu Jawdan's escort (S1-S05): a gendarme in the corporal's colours, on the gendarme's mesh.
	corporal_minion = {
		nameKey = "enemy.corporal_minion.name",
		hp = 40,
		speed = 5.5,
		reward = 14,
		gateDamage = 1,
		visual = { robe = "#2F3E6B", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#2F3E6B", weapon = "rifle" },
	},
	beggar = {
		nameKey = "enemy.beggar.name",
		hp = 90,
		speed = 6.0,
		reward = 26,
		gateDamage = 1,
		disguised = true,
		stealth = true, -- once unmasked he still slips into the dark
		visual = { robe = "#6E6A64", accent = "#3D3A38", skin = "#B97F5A", hat = "scarf", hatColor = "#2A211B", weapon = "stick", scale = 0.95 },
	},

	-- Season Story 1, batch 2 (STORY_PLAN §6.1, S1-S08): Episodes 7–9. Primitive figures until S1-A04.
	rifleman = {
		nameKey = "enemy.rifleman.name",
		hp = 150,
		speed = 5.0,
		reward = 38,
		gateDamage = 2,
		armor = 0.2,
		sabotage = { range = 10, duration = 2.5, cooldown = 8 }, -- stops to pin down the nearest defender
		visual = { robe = "#8A7A52", accent = "#3D3A38", skin = "#B97F5A", hat = "tarboosh", hatColor = "#A4302A", weapon = "rifle" },
	},
	cart = {
		nameKey = "enemy.cart.name",
		hp = 420,
		speed = 3.4,
		reward = 60,
		gateDamage = 3,
		armor = 0.3,
		split = { enemy = "thug", count = 4 }, -- four thugs jump out of the sacks
		visual = { robe = "#6E5E50", accent = "#8C8079", skin = "#8C8079", hat = "none", hatColor = "#6E5E50", weapon = "sack", scale = 1.3 },
	},
	hakim_rival = {
		nameKey = "enemy.hakim_rival.name",
		hp = 200,
		speed = 4.6,
		reward = 50,
		gateDamage = 1,
		healAura = { radius = 8, pct = 0.02 }, -- mends the rival lane's men around him
		visual = { robe = "#2A211B", accent = "#3E5B3A", skin = "#D2A07A", hat = "turban", hatColor = "#3E5B3A", weapon = "sack" },
	},
	snake = {
		nameKey = "enemy.snake.name",
		hp = 20,
		speed = 12.0,
		reward = 4,
		gateDamage = 2,
		stealth = true,
		swarm = true,
		small = true, -- half-height health bar
		visual = { robe = "#B39B6A", accent = "#1F1B18", skin = "#B39B6A", hat = "none", hatColor = "#1F1B18", weapon = "none", scale = 0.5 },
	},
	brute = {
		nameKey = "enemy.brute.name",
		hp = 380,
		speed = 4.2,
		reward = 65,
		gateDamage = 3,
		armor = 0.2,
		enrage = { belowHp = 0.5, speed = 1.6 }, -- wounded, he charges
		visual = { robe = "#3D3A38", accent = "#A4302A", skin = "#B97F5A", hat = "none", hatColor = "#1F1B18", weapon = "none", scale = 1.25 },
	},

	-- Bosses
	sergeant = {
		nameKey = "enemy.sergeant.name",
		hp = 700,
		speed = 3.8,
		reward = 200,
		gateDamage = 40,
		armor = 0.2,
		boss = true,
		visual = { robe = "#2F3E6B", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#A4302A", weapon = "sword", scale = 1.45 },
	},
	chief_thief = {
		nameKey = "enemy.chief_thief.name",
		hp = 1200,
		speed = 4.6,
		reward = 320,
		gateDamage = 60,
		stealth = true,
		boss = true,
		visual = { robe = "#1F1B18", accent = "#A4302A", skin = "#B97F5A", hat = "scarf", hatColor = "#A4302A", weapon = "dagger", scale = 1.5 },
	},
	rival_zaim = {
		nameKey = "enemy.rival_zaim.name",
		hp = 2600,
		speed = 4.8,
		reward = 500,
		gateDamage = 80,
		armor = 0.25,
		boss = true,
		visual = { robe = "#3E5B3A", accent = "#C9A13B", skin = "#C68E64", hat = "tarboosh", hatColor = "#1F1B18", weapon = "dagger", scale = 1.6 },
	},
	colonel = {
		nameKey = "enemy.colonel.name",
		hp = 6000,
		speed = 3.6,
		reward = 1200,
		gateDamage = 100,
		armor = 0.4,
		boss = true,
		visual = { robe = "#1F1B18", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#1F1B18", weapon = "sword", scale = 1.8 },
	},

	-- Season Story 1 bosses, batch 1 (STORY_PLAN §6.2, S1-S03; summon and teleport S1-S05).
	corporal = {
		nameKey = "enemy.corporal.name",
		hp = 900,
		speed = 4.4,
		reward = 240,
		gateDamage = 40,
		armor = 0.2,
		boss = true,
		visual = { robe = "#2F3E6B", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#2F3E6B", weapon = "rifle", scale = 1.4 },
	},
	abu_jawdan = {
		nameKey = "enemy.abu_jawdan.name",
		hp = 4600,
		speed = 3.8,
		reward = 520,
		gateDamage = 80,
		armor = 0.3,
		boss = true,
		summon = { enemy = "corporal_minion", count = 2, every = 15 }, -- his corporals, two at a time
		visual = { robe = "#2F3E6B", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#A4302A", weapon = "stick", scale = 1.65 },
	},
	abu_shatour = {
		nameKey = "enemy.abu_shatour.name",
		hp = 5000,
		speed = 4.6,
		reward = 600,
		gateDamage = 80,
		armor = 0.2,
		boss = true,
		burn = 3, -- his torch: three burn stacks if he reaches the door
		visual = { robe = "#1F1B18", accent = "#A4302A", skin = "#B97F5A", hat = "hatta", hatColor = "#1F1B18", weapon = "sword", scale = 1.7 },
	},
	lateef = {
		nameKey = "enemy.lateef.name",
		hp = 4850,
		speed = 4.4,
		reward = 700,
		gateDamage = 90,
		boss = true,
		disguised = true, -- the "blind" beggar: only a lantern or a lit hit unmasks him
		teleport = { atHp = 0.5, fraction = 0.2, telegraph = 2 }, -- at half HP he jumps a fifth of the road
		visual = { robe = "#6E6A64", accent = "#2A211B", skin = "#B97F5A", hat = "scarf", hatColor = "#2A211B", weapon = "dagger", scale = 1.6 },
	},

	-- Season Story 1 bosses, batch 2 (STORY_PLAN §6.2, S1-S08).
	fakhr = {
		nameKey = "enemy.fakhr.name",
		hp = 4200,
		speed = 4.8,
		reward = 800,
		gateDamage = 90,
		armor = 0.25,
		boss = true,
		enrage = { belowHp = 0.5, speed = 1.5 }, -- the plan gives no numbers: a brute's rage, a little slower (D-046)
		visual = { robe = "#1F1B18", accent = "#A4302A", skin = "#B97F5A", hat = "hatta", hatColor = "#1F1B18", weapon = "stick", scale = 1.75 },
	},
	abu_zira = {
		nameKey = "enemy.abu_zira.name",
		hp = 5000,
		speed = 5.2,
		reward = 950,
		gateDamage = 100,
		armor = 0.2,
		boss = true,
		enrage = { belowHp = 0.6, speed = 1.6 }, -- plan 1.7, held at the 1.6 speed cap (D-046)
		visual = { robe = "#6E6A64", accent = "#A4302A", skin = "#C68E64", hat = "tarboosh", hatColor = "#A4302A", weapon = "sword", scale = 1.7 },
	},
	rival_zaim_enraged = {
		nameKey = "enemy.rival_zaim_enraged.name",
		hp = 9000,
		speed = 5.0,
		reward = 1600,
		gateDamage = 120,
		armor = 0.3,
		boss = true,
		shield = { radius = 8, reduce = 0.3 }, -- his men close ranks around him
		enrage = { belowHp = 0.5, speed = 1.3 },
		visual = { robe = "#3E5B3A", accent = "#A4302A", skin = "#C68E64", hat = "tarboosh", hatColor = "#1F1B18", weapon = "dagger", scale = 1.75 },
	},
}

return Enemies
