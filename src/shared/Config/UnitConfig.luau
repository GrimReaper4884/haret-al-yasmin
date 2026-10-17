--!strict
--[[
	UnitConfig: the starter roster (12 original units) and global unit rules.
	GDD: docs/GAME_DESIGN.md sections 7-8. All characters are original to Haret Al Yasmin.

	Level data rules:
	  * `levels` are cumulative states: levels[1] = Lv0 (placement), levels[2..4] = U1..U3.
	    `cost` is the Cash paid to reach that level. Omitted fields inherit from the previous level.
	  * `branches` (non-Merchant units): exactly two (A and B), each with two levels = U4 and U5.
	    The player picks the branch when buying U4; U4 inherits from U3. Merchants do not fork.
	  * `attack`, `aura` and `effects` REPLACE the previous value when present (they do not merge).
	  * Attack patterns:
	      Single - hits up to maxTargets (default 1) distinct targets
	      Circle - splash of `radius` around the primary target, up to maxTargets
	      Cone   - `angle` degrees from the unit, length = range, up to maxTargets
	      Line   - `width` x `length` (default range) from the unit toward the target, up to maxTargets
	      Nova   - circle of `radius` centred on the unit
	      Zone   - persistent circle of `radius` on the best path point in range; ticks every SPA
	      None   - does not attack (Merchants)
	  * Flyers: Full = 100% vs Flying, Half = 50%, None = cannot target Flying.
	  * Ground units must be placed on surfaces tagged "Ground", Hill units on "Hill".
]]

local Types = require(script.Parent.Types)

export type AttackPattern = "None" | "Single" | "Circle" | "Cone" | "Line" | "Nova" | "Zone"

export type Attack = {
	pattern: AttackPattern,
	radius: number?,
	angle: number?,
	width: number?,
	length: number?,
	maxTargets: number?,
}

export type Aura = {
	radius: number,
	detection: boolean?, -- reveals Veiled enemies inside the aura to every player's units
	revealedDamageTakenPct: number?, -- Veiled/revealed enemies inside take +x% damage
	damagePct: number?,
	rangePct: number?,
	spaPct: number?,
	upgradeCostPct: number?,
}

export type Level = {
	cost: number,
	damage: number?,
	spa: number?,
	range: number?,
	income: number?, -- Merchants: Cash per wave end, paid to the owner only
	attack: Attack?,
	aura: Aura?,
	effects: { [string]: number }?,
}

export type Branch = { id: string, name: string, levels: { Level } }

export type Passive = { id: string, name: string, description: string, params: { [string]: number }? }

export type Ability = {
	id: string,
	name: string,
	cooldown: number, -- seconds, server-enforced
	description: string,
	params: { [string]: number },
}

export type Evolution = {
	evolvedName: string,
	evolvedModel: string,
	relic: string,
	gold: number,
	essence: number,
	takedowns: number, -- quest: takedowns with this unit
	addsPassive: Passive,
	ultimateUpgrade: string,
}

export type UnitDef = {
	id: string,
	name: string,
	title: string,
	rarity: Types.Rarity,
	role: Types.Role,
	placement: Types.Placement,
	placementCap: number,
	flyers: Types.FlyerRule,
	defaultTargeting: Types.Targeting,
	summonPool: string, -- "Standard" | "Limited" | "None"
	model: string,
	attack: Attack,
	passives: { Passive },
	active: Ability?,
	ultimate: Ability?, -- cooldown unused; charges via UnitConfig.Ultimate
	evolution: Evolution?,
	levels: { Level },
	branches: { Branch }?,
}

local UnitConfig = {}

UnitConfig.TeamSlots = 6
UnitConfig.PresetSlotsBase = 2 -- +3 with the Extra Team Preset Slots pass
UnitConfig.SellRefund = 0.60 -- of total Cash spent on the unit. TUNE
UnitConfig.PlayerPlacementCap = { 40, 30, 25, 20 } -- total placements per player by party size 1..4
UnitConfig.Footprint = 1.5 -- unit radius in studs for spacing checks. TUNE
UnitConfig.PathClearance = 1.0 -- extra studs beyond the path half-width. TUNE
UnitConfig.BaseCritMultiplier = 1.5
UnitConfig.MaxCritChance = 0.75
UnitConfig.MaxDamageTakenPct = 0.40 -- cap on stacked "enemy takes +x% damage" debuffs (Bind, Storm Mark, Beacon)
UnitConfig.MaxUpgradeDiscount = 0.25 -- cap on all upgrade-cost reductions combined
UnitConfig.MinSpa = 0.2 -- SPA floor after all modifiers
UnitConfig.HeraldAurasStack = false -- only the strongest Herald aura applies per stat
UnitConfig.UnitLevel = { cap = 50, damagePctPerLevel = 0.005 } -- +24.5% at Lv50
UnitConfig.Bloom = { maxLevel = 5, damagePctPerLevel = 0.02, dupesPerLevel = 1, goldPerLevel = 1_000 }
UnitConfig.Ultimate = {
	max = 100,
	perHit = 1.5, -- charge per damaging hit
	perSecondInHeraldAura = 1.0, -- support uptime also charges
	flourishSeconds = 1.5, -- camera flourish; skippable after the player's first viewing
}
-- Auto Play places and upgrades units but NEVER fires actives or ultimates.

local units: { [string]: UnitDef } = {
	-- RARE ------------------------------------------------------------------------------------
	spice_caravan = {
		id = "spice_caravan",
		name = "Spice Caravan",
		title = "Mule-Cart Traders",
		rarity = "Rare",
		role = "Merchant",
		placement = "Ground",
		placementCap = 3,
		flyers = "None",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_SpiceCaravan",
		attack = { pattern = "None" },
		passives = {},
		levels = { -- total 9,200
			{ cost = 500, income = 150 },
			{ cost = 900, income = 350 },
			{ cost = 1_600, income = 700 },
			{ cost = 2_600, income = 1_200 },
			{ cost = 3_600, income = 1_900 },
		},
	},
	tarek = {
		id = "tarek",
		name = "Tarek",
		title = "Alley Duelist",
		rarity = "Rare",
		role = "Striker",
		placement = "Ground",
		placementCap = 6,
		flyers = "None",
		defaultTargeting = "Strongest",
		summonPool = "Standard",
		model = "HY_Unit_Tarek",
		attack = { pattern = "Single" },
		passives = {
			{
				id = "DuelistsFocus",
				name = "Duelist's Focus",
				description = "+15% damage to mini-bosses and bosses.",
				params = { bossDamagePct = 0.15 },
			},
		},
		levels = { -- total 7,750
			{ cost = 250, damage = 40, spa = 1.0, range = 14 },
			{ cost = 300, damage = 60 },
			{ cost = 600, damage = 95, spa = 0.9 },
			{ cost = 1_100, damage = 160, spa = 0.85, range = 15 },
		},
		branches = {
			{
				id = "A",
				name = "Lone Blade",
				levels = {
					{ cost = 2_000, damage = 300, spa = 0.8 },
					{ cost = 3_500, damage = 520, spa = 0.75, range = 16 },
				},
			},
			{
				id = "B",
				name = "Crescent Sweep",
				levels = {
					{
						cost = 2_000,
						damage = 180,
						spa = 0.8,
						attack = { pattern = "Cone", angle = 70, maxTargets = 4 },
					},
					{ cost = 3_500, damage = 300, spa = 0.75, range = 16 },
				},
			},
		},
	},
	rima = {
		id = "rima",
		name = "Rima",
		title = "Rooftop Slinger",
		rarity = "Rare",
		role = "Marksman",
		placement = "Hill",
		placementCap = 5,
		flyers = "Full",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Rima",
		attack = { pattern = "Single" },
		passives = {
			{
				id = "Spotter",
				name = "Spotter",
				description = "+20% damage to Flying enemies.",
				params = { flyingDamagePct = 0.20 },
			},
		},
		levels = { -- total 8,200
			{ cost = 300, damage = 30, spa = 1.4, range = 24 },
			{ cost = 350, damage = 45 },
			{ cost = 650, damage = 70, spa = 1.3, range = 26 },
			{ cost = 1_200, damage = 120, spa = 1.2, range = 28 },
		},
		branches = {
			{
				id = "A",
				name = "Hawk's Eye",
				levels = {
					{ cost = 2_100, damage = 230, spa = 1.1, range = 32 },
					{ cost = 3_600, damage = 400, spa = 1.0, range = 34 },
				},
			},
			{
				id = "B",
				name = "Scatter Shot",
				levels = {
					{
						cost = 2_100,
						damage = 120,
						spa = 1.1,
						attack = { pattern = "Circle", radius = 4, maxTargets = 5 },
					},
					{
						cost = 3_600,
						damage = 210,
						spa = 1.0,
						attack = { pattern = "Circle", radius = 5, maxTargets = 5 },
					},
				},
			},
		},
	},

	-- EPIC ------------------------------------------------------------------------------------
	hadi = {
		id = "hadi",
		name = "Old Hadi",
		title = "the Lamplighter",
		rarity = "Epic",
		role = "Lantern",
		placement = "Hill",
		placementCap = 4,
		flyers = "Half",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Hadi",
		attack = { pattern = "Single" },
		passives = {
			{
				id = "Lamplight",
				name = "Lamplight",
				description = "From U2, Veiled enemies inside his aura are revealed to every player's units.",
			},
		},
		levels = { -- total 7,150
			{ cost = 400, damage = 20, spa = 1.5, range = 16 },
			{ cost = 350, damage = 30 },
			{ cost = 600, damage = 45, aura = { radius = 16, detection = true } },
			{ cost = 1_000, damage = 70, aura = { radius = 18, detection = true } },
		},
		branches = {
			{
				id = "A",
				name = "Beacon",
				levels = {
					{ cost = 1_800, aura = { radius = 22, detection = true, revealedDamageTakenPct = 0.10 } },
					{ cost = 3_000, aura = { radius = 26, detection = true, revealedDamageTakenPct = 0.15 } },
				},
			},
			{
				id = "B",
				name = "Flare",
				levels = {
					{ cost = 1_800, damage = 90, attack = { pattern = "Circle", radius = 5, maxTargets = 6 } },
					{ cost = 3_000, damage = 150, attack = { pattern = "Circle", radius = 6, maxTargets = 6 } },
				},
			},
		},
	},
	nadia = {
		id = "nadia",
		name = "Nadia",
		title = "Ember Fan Dancer",
		rarity = "Epic",
		role = "Sweeper",
		placement = "Ground",
		placementCap = 5,
		flyers = "Half",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Nadia",
		attack = { pattern = "Cone", angle = 90, maxTargets = 6 },
		passives = {
			{
				id = "Cinders",
				name = "Cinders",
				description = "Hit enemies burn for 10% of the hit's damage per second for 3 s (refreshes, does not stack).",
				params = { burnPctPerSec = 0.10, burnDuration = 3 },
			},
		},
		levels = { -- total 8,900
			{ cost = 450, damage = 18, spa = 1.3, range = 11 },
			{ cost = 400, damage = 28 },
			{ cost = 750, damage = 42, spa = 1.2 },
			{ cost = 1_300, damage = 70, range = 12 },
		},
		branches = {
			{
				id = "A",
				name = "Whirl",
				levels = {
					{ cost = 2_200, damage = 110, attack = { pattern = "Nova", radius = 12, maxTargets = 8 } },
					{ cost = 3_800, damage = 180, attack = { pattern = "Nova", radius = 12, maxTargets = 10 } },
				},
			},
			{
				id = "B",
				name = "Flame Ribbon",
				levels = {
					{
						cost = 2_200,
						damage = 130,
						attack = { pattern = "Line", width = 4, length = 18, maxTargets = 6 },
					},
					{
						cost = 3_800,
						damage = 220,
						attack = { pattern = "Line", width = 4, length = 20, maxTargets = 6 },
					},
				},
			},
		},
	},
	bassam = {
		id = "bassam",
		name = "Bassam",
		title = "the Anvil",
		rarity = "Epic",
		role = "Breaker",
		placement = "Ground",
		placementCap = 4,
		flyers = "None",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Bassam",
		attack = { pattern = "Single" },
		passives = {
			{
				id = "Shatter",
				name = "Shatter",
				description = "Deals 3x damage to shield pools; each hit strips 1 Ironbound armor plate.",
				params = { shieldDamageMult = 3, armorPlatesPerHit = 1 },
			},
		},
		levels = { -- total 9,550
			{ cost = 500, damage = 35, spa = 1.6, range = 9 },
			{ cost = 450, damage = 55 },
			{ cost = 800, damage = 85, spa = 1.5 },
			{ cost = 1_400, damage = 140, range = 10 },
		},
		branches = {
			{
				id = "A",
				name = "Splitting Maul",
				levels = {
					{ cost = 2_400, damage = 220, attack = { pattern = "Circle", radius = 3, maxTargets = 3 } },
					{ cost = 4_000, damage = 360 },
				},
			},
			{
				id = "B",
				name = "Rivet Driver",
				levels = {
					{ cost = 2_400, damage = 240, spa = 1.1, effects = { armorPlatesPerHit = 2 } },
					{ cost = 4_000, damage = 400, spa = 1.0 },
				},
			},
		},
	},

	-- LEGENDARY -------------------------------------------------------------------------------
	silk_bazaar = {
		id = "silk_bazaar",
		name = "Silk Bazaar",
		title = "Night-Market Pavilion",
		rarity = "Legendary",
		role = "Merchant",
		placement = "Ground",
		placementCap = 1,
		flyers = "None",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_SilkBazaar",
		attack = { pattern = "None" },
		passives = {
			{
				id = "Caravanserai",
				name = "Caravanserai",
				description = "Your Spice Caravans earn +10% income while this Bazaar stands.",
				params = { caravanIncomePct = 0.10 },
			},
			{
				id = "Haggler",
				name = "Haggler",
				description = "Your other units' upgrades cost 5% less (all discounts capped at 25%).",
				params = { upgradeCostPct = -0.05 },
			},
		},
		active = {
			id = "MarketDay",
			name = "Market Day",
			cooldown = 90,
			description = "Instantly pays 50% of this Bazaar's current per-wave income.",
			params = { payoutPct = 0.5 },
		},
		levels = { -- total 32,800; only wins in modes longer than ~25 waves
			{ cost = 800, income = 200 },
			{ cost = 1_500, income = 500 },
			{ cost = 3_000, income = 1_100 },
			{ cost = 5_500, income = 2_200 },
			{ cost = 9_000, income = 3_800 },
			{ cost = 13_000, income = 6_000 },
		},
	},
	layla = {
		id = "layla",
		name = "Layla",
		title = "Nightwind Warden",
		rarity = "Legendary",
		role = "Warden",
		placement = "Ground",
		placementCap = 3,
		flyers = "Half",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Layla",
		attack = { pattern = "Circle", radius = 5, maxTargets = 5 },
		passives = {
			{
				id = "Bind",
				name = "Bind",
				description = "Stunned or rooted enemies take +10% damage from all sources.",
				params = { stunnedDamageTakenPct = 0.10 },
			},
			{ id = "CalmAir", name = "Calm Air", description = "Immune to Hexer stuns." },
		},
		active = {
			id = "NightwindSnare",
			name = "Nightwind Snare",
			cooldown = 60,
			description = "Stuns all non-boss enemies in range for 3 s; bosses and mini-bosses are slowed 20% for 5 s.",
			params = { stun = 3, bossSlowPct = 0.20, bossSlowDuration = 5 },
		},
		levels = { -- total 11,250
			{ cost = 700, damage = 25, spa = 1.4, range = 12, effects = { slowPct = 0.30, slowDuration = 2 } },
			{ cost = 550, damage = 38 },
			{ cost = 1_000, damage = 55, effects = { slowPct = 0.35, slowDuration = 2 } },
			{
				cost = 1_700,
				damage = 85,
				range = 13,
				effects = { slowPct = 0.35, slowDuration = 2, stunEvery = 3, stunDuration = 1.5 },
			},
		},
		branches = {
			{
				id = "A",
				name = "Gale Prison",
				levels = {
					{
						cost = 2_800,
						damage = 110,
						attack = { pattern = "Circle", radius = 6, maxTargets = 5 },
						effects = { slowPct = 0.35, slowDuration = 2, stunEvery = 3, stunDuration = 2.5 },
					},
					{
						cost = 4_500,
						damage = 160,
						effects = { slowPct = 0.35, slowDuration = 2, stunEvery = 2, stunDuration = 2.5 },
					},
				},
			},
			{
				id = "B",
				name = "Ebb Tide",
				levels = {
					{ cost = 2_800, damage = 120, effects = { slowPct = 0.35, slowDuration = 2, auraSlowPct = 0.25 } },
					{ cost = 4_500, damage = 180, effects = { slowPct = 0.35, slowDuration = 2, auraSlowPct = 0.35 } },
				},
			},
		},
	},
	qamar = {
		id = "qamar",
		name = "Qamar",
		title = "Moon Herald",
		rarity = "Legendary",
		role = "Herald",
		placement = "Hill",
		placementCap = 3,
		flyers = "Half",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Qamar",
		attack = { pattern = "Single" },
		passives = {
			{
				id = "GuidingLight",
				name = "Guiding Light",
				description = "Her aura buffs every player's units, not just her owner's.",
			},
			{
				id = "SteadyHands",
				name = "Steady Hands",
				description = "Units in her aura recover from stuns 30% faster.",
				params = { stunDurationPct = -0.30 },
			},
		},
		active = {
			id = "Rally",
			name = "Rally",
			cooldown = 45,
			description = "Units in her aura attack 15% faster (SPA x0.85) for 10 s.",
			params = { spaMult = 0.85, duration = 10 },
		},
		levels = { -- total 11,950
			{ cost = 650, damage = 15, spa = 2.0, range = 16, aura = { radius = 14, damagePct = 0.08 } },
			{ cost = 600, aura = { radius = 14, damagePct = 0.10 } },
			{ cost = 1_100, aura = { radius = 16, damagePct = 0.10, rangePct = 0.05 } },
			{ cost = 1_800, aura = { radius = 16, damagePct = 0.12, rangePct = 0.08 } },
		},
		branches = {
			{
				id = "A",
				name = "Full Moon",
				levels = {
					{ cost = 3_000, aura = { radius = 18, damagePct = 0.20, rangePct = 0.10 } },
					{ cost = 4_800, aura = { radius = 18, damagePct = 0.25, rangePct = 0.12, spaPct = -0.05 } },
				},
			},
			{
				id = "B",
				name = "New Moon",
				levels = {
					{ cost = 3_000, aura = { radius = 16, damagePct = 0.12, rangePct = 0.08, upgradeCostPct = -0.10 } },
					{ cost = 4_800, aura = { radius = 18, damagePct = 0.15, rangePct = 0.08, upgradeCostPct = -0.15 } },
				},
			},
		},
	},

	-- MYTHIC ----------------------------------------------------------------------------------
	saif = {
		id = "saif",
		name = "Saif al-Layl",
		title = "the Night Blade",
		rarity = "Mythic",
		role = "Striker",
		placement = "Ground",
		placementCap = 3,
		flyers = "None",
		defaultTargeting = "Strongest",
		summonPool = "Standard",
		model = "HY_Unit_Saif",
		attack = { pattern = "Single" },
		passives = {
			{
				id = "MoonlitEdge",
				name = "Moonlit Edge",
				description = "+20% damage to mini-bosses and bosses.",
				params = { bossDamagePct = 0.20 },
			},
			{
				id = "Momentum",
				name = "Momentum",
				description = "Each consecutive hit on the same target adds +4% damage, up to +20%.",
				params = { perHitPct = 0.04, maxPct = 0.20 },
			},
			{
				id = "NightsPatience",
				name = "Night's Patience",
				description = "10% critical hit chance.",
				params = { critChance = 0.10 },
			},
		},
		active = {
			id = "CrescentDraw",
			name = "Crescent Draw",
			cooldown = 40,
			description = "Dash-slash in a 4 x 24 stud line toward the target, dealing 6x damage to every enemy hit.",
			params = { damageMult = 6, width = 4, length = 24 },
		},
		ultimate = {
			id = "ThousandPetalCut",
			name = "Thousand-Petal Cut",
			cooldown = 0,
			description = "12 strikes over 2 s on the strongest enemy in range, each dealing 3x damage.",
			params = { strikes = 12, damageMult = 3, duration = 2 },
		},
		evolution = {
			evolvedName = "Saif, Dawnbreaker",
			evolvedModel = "HY_Unit_Saif_Evo",
			relic = "DawnsteelHilt",
			gold = 15_000,
			essence = 20,
			takedowns = 1_000,
			addsPassive = {
				id = "Dawn",
				name = "Dawn",
				description = "The first hit on each enemy deals +50% damage.",
				params = { firstHitPct = 0.50 },
			},
			ultimateUpgrade = "Thousand-Petal Cut becomes 16 strikes at 3.5x damage.",
		},
		levels = { -- total 16,000
			{ cost = 900, damage = 120, spa = 1.1, range = 16 },
			{ cost = 800, damage = 190 },
			{ cost = 1_400, damage = 320, spa = 1.0 },
			{ cost = 2_400, damage = 560, spa = 0.95, range = 17 },
		},
		branches = {
			{
				id = "A",
				name = "Edge of Night",
				levels = {
					{ cost = 4_000, damage = 1_000, spa = 0.9 },
					{ cost = 6_500, damage = 1_700, spa = 0.85, range = 18 },
				},
			},
			{
				id = "B",
				name = "Petal Storm",
				levels = {
					{
						cost = 4_000,
						damage = 520,
						spa = 0.9,
						attack = { pattern = "Cone", angle = 90, maxTargets = 5 },
					},
					{ cost = 6_500, damage = 900, spa = 0.85, range = 18 },
				},
			},
		},
	},
	dalia = {
		id = "dalia",
		name = "Dalia",
		title = "Monsoon Archer",
		rarity = "Mythic",
		role = "Marksman",
		placement = "Hill",
		placementCap = 3,
		flyers = "Full",
		defaultTargeting = "First",
		summonPool = "Standard",
		model = "HY_Unit_Dalia",
		attack = { pattern = "Line", width = 3, maxTargets = 4 },
		passives = {
			{
				id = "Skybreaker",
				name = "Skybreaker",
				description = "+30% damage to Flying enemies.",
				params = { flyingDamagePct = 0.30 },
			},
			{
				id = "RainSoaked",
				name = "Rain-Soaked",
				description = "Hits slow enemies by 10% for 1 s.",
				params = { slowPct = 0.10, slowDuration = 1 },
			},
			{
				id = "StormMark",
				name = "Storm Mark",
				description = "Every 5th arrow marks its target: +15% damage taken from all sources for 4 s.",
				params = { every = 5, damageTakenPct = 0.15, duration = 4 },
			},
		},
		active = {
			id = "Cloudburst",
			name = "Cloudburst",
			cooldown = 50,
			description = "Radius-10 storm at a chosen point in range: 8x damage over 2 s; hits Flying and Veiled.",
			params = { radius = 10, damageMult = 8, duration = 2 },
		},
		ultimate = {
			id = "MonsoonBloom",
			name = "Monsoon Bloom",
			cooldown = 0,
			description = "For 4 s, every 0.2 s deals 2x damage to all enemies in range (max 12 per tick).",
			params = { duration = 4, tick = 0.2, damageMult = 2, maxTargets = 12 },
		},
		evolution = {
			evolvedName = "Dalia, Eye of the Monsoon",
			evolvedModel = "HY_Unit_Dalia_Evo",
			relic = "StormglassQuiver",
			gold = 15_000,
			essence = 20,
			takedowns = 1_000,
			addsPassive = {
				id = "EyeOfTheStorm",
				name = "Eye of the Storm",
				description = "Detects Veiled enemies within her own range.",
			},
			ultimateUpgrade = "Monsoon Bloom lasts 6 s.",
		},
		levels = { -- total 16,950
			{ cost = 1_000, damage = 90, spa = 1.5, range = 28 },
			{ cost = 850, damage = 140 },
			{ cost = 1_500, damage = 230, spa = 1.4 },
			{ cost = 2_600, damage = 400, spa = 1.3, range = 30 },
		},
		branches = {
			{
				id = "A",
				name = "Heavenpiercer",
				levels = {
					{
						cost = 4_200,
						damage = 700,
						attack = { pattern = "Line", width = 3, length = 40, maxTargets = 6 },
					},
					{ cost = 6_800, damage = 1_150, spa = 1.2 },
				},
			},
			{
				id = "B",
				name = "Tempest Volley",
				levels = {
					{ cost = 4_200, damage = 300, attack = { pattern = "Single", maxTargets = 3 } },
					{ cost = 6_800, damage = 500, spa = 1.2 },
				},
			},
		},
	},

	-- SECRET (limited banner Limited_S1) ------------------------------------------------------
	yasmin = {
		id = "yasmin",
		name = "Yasmin",
		title = "the Night-Blooming",
		rarity = "Secret",
		role = "Sweeper",
		placement = "Hill",
		placementCap = 2,
		flyers = "Half",
		defaultTargeting = "First",
		summonPool = "Limited",
		model = "HY_Unit_Yasmin",
		attack = { pattern = "Circle", radius = 7, maxTargets = 8 },
		passives = {
			{
				id = "ThornedGarden",
				name = "Thorned Garden",
				description = "Hits root non-boss enemies for 0.5 s (bosses: 20% slow instead).",
				params = { root = 0.5 },
			},
			{
				id = "Fragrance",
				name = "Fragrance",
				description = "Your units within 12 studs deal +8% damage (stacks with Herald auras).",
				params = { radius = 12, damagePct = 0.08 },
			},
			{
				id = "Uproot",
				name = "Uproot",
				description = "Deals 2x damage to Menders and Hives.",
				params = { damageMult = 2 },
			},
		},
		active = {
			id = "JasmineGale",
			name = "Jasmine Gale",
			cooldown = 60,
			description = "6 x 40 stud gust: 10x damage and pushes non-boss enemies 6 studs back along the path.",
			params = { width = 6, length = 40, damageMult = 10, pushback = 6 },
		},
		ultimate = {
			id = "NightOfAThousandBlossoms",
			name = "Night of a Thousand Blossoms",
			cooldown = 0,
			description = "5 s field (radius 16) in range: 1.5x damage every 0.25 s to all enemies inside (max 16 per tick); reveals Veiled inside.",
			params = { duration = 5, radius = 16, tick = 0.25, damageMult = 1.5, maxTargets = 16 },
		},
		evolution = {
			evolvedName = "Yasmin, Eternal Bloom",
			evolvedModel = "HY_Unit_Yasmin_Evo",
			relic = "SeedOfTheFirstGarden",
			gold = 30_000,
			essence = 20,
			takedowns = 1_000,
			addsPassive = {
				id = "Perennial",
				name = "Perennial",
				description = "Ultimate charges 25% faster.",
				params = { ultimateChargePct = 0.25 },
			},
			ultimateUpgrade = "Night of a Thousand Blossoms lasts 7 s and its radius becomes 20.",
		},
		levels = { -- total 20,000
			{ cost = 1_200, damage = 80, spa = 1.4, range = 22 },
			{ cost = 1_000, damage = 125 },
			{ cost = 1_800, damage = 200, spa = 1.3 },
			{ cost = 3_000, damage = 340, spa = 1.25, range = 24 },
		},
		branches = {
			{
				id = "A",
				name = "Moonflower",
				levels = {
					{ cost = 5_000, damage = 600, attack = { pattern = "Circle", radius = 8, maxTargets = 10 } },
					{ cost = 8_000, damage = 1_000 },
				},
			},
			{
				id = "B",
				name = "Thorn Lattice",
				levels = {
					{
						cost = 5_000,
						damage = 150,
						spa = 0.5,
						attack = { pattern = "Zone", radius = 6, maxTargets = 12 },
					},
					{ cost = 8_000, damage = 260 },
				},
			},
		},
	},
}
UnitConfig.Units = units

-- Units every new account owns after the tutorial (plus the free Tutorial summon).
UnitConfig.StarterUnits = { "tarek", "rima", "hadi", "spice_caravan" }

return UnitConfig
