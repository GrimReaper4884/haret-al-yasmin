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
		speed = 6.0,
		reward = 22,
		gateDamage = 1,
		visual = { robe = "#3E5B3A", accent = "#1F1B18", skin = "#C68E64", hat = "tarboosh", hatColor = "#1F1B18", weapon = "stick", scale = 1.05 },
	},
	rider = {
		nameKey = "enemy.rider.name",
		hp = 220,
		speed = 7.5,
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

	-- Bosses
	sergeant = {
		nameKey = "enemy.sergeant.name",
		hp = 900,
		speed = 4.2,
		reward = 200,
		gateDamage = 10,
		armor = 0.2,
		boss = true,
		visual = { robe = "#2F3E6B", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#A4302A", weapon = "sword", scale = 1.45 },
	},
	chief_thief = {
		nameKey = "enemy.chief_thief.name",
		hp = 1400,
		speed = 5.5,
		reward = 320,
		gateDamage = 15,
		stealth = true,
		boss = true,
		visual = { robe = "#1F1B18", accent = "#A4302A", skin = "#B97F5A", hat = "scarf", hatColor = "#A4302A", weapon = "dagger", scale = 1.5 },
	},
	rival_zaim = {
		nameKey = "enemy.rival_zaim.name",
		hp = 2600,
		speed = 4.8,
		reward = 500,
		gateDamage = 25,
		armor = 0.25,
		boss = true,
		visual = { robe = "#3E5B3A", accent = "#C9A13B", skin = "#C68E64", hat = "tarboosh", hatColor = "#1F1B18", weapon = "dagger", scale = 1.6 },
	},
	colonel = {
		nameKey = "enemy.colonel.name",
		hp = 6000,
		speed = 3.6,
		reward = 1200,
		gateDamage = 40,
		armor = 0.4,
		boss = true,
		visual = { robe = "#1F1B18", accent = "#C9A13B", skin = "#E0B894", hat = "kepi", hatColor = "#1F1B18", weapon = "sword", scale = 1.8 },
	},
}

return Enemies
