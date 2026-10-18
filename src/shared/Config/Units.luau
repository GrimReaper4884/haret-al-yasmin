--!strict
-- The defenders of the lane ("towers"). Pure data. Names and flavour live in Strings
-- (unit.<id>.name / .desc); visuals describe a primitive rig (Util/RigBuilder).
--
-- Since 2026-10-16 (owner's decision, docs/COPYRIGHT_REGISTER.md C-201) most defenders carry the
-- roles of the lane's main characters in the classic Damascus-lane drama; since 2026-10-18 their
-- names are one letter off (STORY_PLAN §3, C-241: Abu Hissam the barber-hakim, Abu Shehan,
-- Mo'ez…). Ids and balance were kept, only identities moved: e.g. the
-- legendary healer slot `umm_hara` is Abu Hissam. Faces are stylized cartoons, never actor
-- likenesses. Display names are plain strings and can be changed in Strings without touching
-- balance.
--
-- levels[1] is the stats when placed (placeCost); levels[i>=2].cost is the upgrade price to reach i.
-- damage per hit, range in studs, cooldown in seconds. splash = radius; slow = speed multiplier
-- applied for slowFor seconds; buff = damage multiplier granted to towers in range (support);
-- income = cash per cleared wave (farm); heal = gate HP per cleared wave (healer).
-- revealsStealth = the unit's light lets every other defender inside its range target stealth
-- enemies too (Natour's lantern; TdSim.revealerFor), and unmasks disguised enemies inside it.
-- douse = burn stacks the unit takes off the gate with every attack (water on the flames).

export type Rarity = "rare" | "epic" | "legendary" | "mythic" | "secret"
export type Role = "melee" | "ranged" | "splash" | "support" | "farm" | "healer"

export type Level = {
	cost: number,
	damage: number,
	range: number,
	cooldown: number,
	splash: number?,
	slow: number?,
	slowFor: number?,
	stun: number?,
	buff: number?,
	income: number?,
	bounty: number?, -- farm: cash for every enemy that dies inside its range, whoever lands the blow
	heal: number?,
}

export type Ability = {
	kind: "shabriyeh" | "sweep" | "mark",
	stun: number?, -- sweep: also stuns everything it hits (signature)
	slow: number?, -- shabriyeh: also slows the target to this speed multiplier … (signature)
	slowFor: number?, -- … for this many seconds
	cooldown: number, -- seconds
	multiplier: number, -- damage multiplier on the target (shabriyeh), on everything in radius (sweep), or that the marked enemy takes from every defender (mark; cap 1.4, D-045)
	radius: number?,
	duration: number?, -- mark: seconds the mark lasts
	count: number?, -- mark: how many enemies one Oath marks (default 1; signature Repentance 2)
}

export type Visual = {
	robe: string, -- hex
	accent: string, -- hex (sash / waistcoat)
	skin: string,
	hat: "tarboosh" | "cap" | "hatta" | "scarf" | "none" | "turban" | "kepi" | "helmet",
	hatColor: string,
	weapon: "stick" | "dagger" | "razor" | "sling" | "jug" | "lantern" | "needle" | "hammer" | "tray" | "none" | "sword" | "bread" | "cat" | "rifle" | "sack",
	scale: number?,
}

-- Level 7 "signature" (STORY_PLAN §7.1): bought once at the last level, for `cost`, choosing path a or b.
-- It starts from the last level and changes it: `set` overrides Level fields, `cooldownMul` scales
-- the attack cooldown, `ability` overrides ability fields, `revealsStealth` lights a lantern,
-- `haste` speeds up other defenders in a radius (cooldown × mul). Cap (D-047): a path adds at most
-- +35 % damage per second or exactly one effect, never both (tests/td.spec "Signatures").
export type Signature = {
	key: string, -- name: unit.<id>.sig.<key>.name / .desc
	cost: number,
	set: { [string]: number }?,
	cooldownMul: number?,
	ability: { [string]: number }?,
	revealsStealth: boolean?,
	haste: { radius: number, mul: number }?,
}

export type UnitDef = {
	nameKey: string,
	descKey: string,
	rarity: Rarity,
	role: Role,
	maxPlaced: number,
	hitsStealth: boolean?,
	revealsStealth: boolean?,
	douse: number?,
	levels: { Level },
	ability: Ability?,
	visual: Visual,
	noBanner: boolean?, -- secret / event units never come from a banner
	signature: { a: Signature, b: Signature }?, -- level 7 (Epic and above): one of two paths, bought once at max level
	beads: { string }?, -- the three bead kinds its slots take (default Config/Beads.byRole[role])
}

local function L(cost: number, damage: number, range: number, cooldown: number, extra: { [string]: any }?): Level
	local l: any = { cost = cost, damage = damage, range = range, cooldown = cooldown }
	if extra then
		for k, v in extra do
			l[k] = v
		end
	end
	return l
end

local Units: { [string]: UnitDef } = {
	---------------------------------------------------------------- Rare (starters)
	walad = {
		nameKey = "unit.walad.name",
		descKey = "unit.walad.desc",
		rarity = "rare",
		role = "ranged",
		maxPlaced = 8,
		hitsStealth = true, -- the starter must be able to stop Episode 1's night thieves
		levels = {
			L(120, 4, 14, 1.0),
			L(90, 6, 15, 0.95),
			L(160, 9, 16, 0.9),
			L(260, 14, 17, 0.85),
			L(420, 22, 18, 0.8),
		},
		visual = { robe = "#EADFC8", accent = "#2F3E6B", skin = "#C68E64", hat = "cap", hatColor = "#FBF8F1", weapon = "sling", scale = 0.85 },
	},
	natour = {
		nameKey = "unit.natour.name",
		descKey = "unit.natour.desc",
		rarity = "rare",
		role = "ranged",
		maxPlaced = 4,
		hitsStealth = true,
		revealsStealth = true, -- the lantern: defenders inside his range see hidden thieves too
		levels = {
			L(180, 4, 12, 1.15, { slow = 0.75, slowFor = 1.5 }),
			L(120, 6, 13, 1.1, { slow = 0.7, slowFor = 1.8 }),
			L(220, 8, 14, 1.1, { slow = 0.65, slowFor = 2.0 }),
			L(360, 12, 15, 1.0, { slow = 0.6, slowFor = 2.4 }),
			L(560, 18, 16, 0.95, { slow = 0.5, slowFor = 2.8 }),
		},
		visual = { robe = "#4A2E18", accent = "#B87333", skin = "#B97F5A", hat = "hatta", hatColor = "#EFE6D2", weapon = "lantern" },
	},
	-- Umm Baki the midwife (STORY_PLAN §7.5, S1-A03): the second lamp after Abu Hares. Her lamp lights
	-- stealth and disguised attackers for every defender in range; she hits lightly and never slows.
	-- The first Normal clear of Episode 6 gives her (TD.STORY_FIRST_CLEAR).
	qabilah = {
		nameKey = "unit.qabilah.name",
		descKey = "unit.qabilah.desc",
		rarity = "rare",
		role = "ranged",
		maxPlaced = 4,
		hitsStealth = true,
		revealsStealth = true,
		levels = {
			L(160, 3, 11, 1.2),
			L(110, 5, 12, 1.15),
			L(190, 8, 13, 1.1),
			L(300, 11, 14, 1.05),
			L(460, 15, 15, 1.0),
		},
		visual = { robe = "#2B3550", accent = "#B5532C", skin = "#C68E64", hat = "scarf", hatColor = "#F4F1EA", weapon = "lantern" },
	},
	-- Season Story 1 defenders (STORY_PLAN §7.5, S1-A07).
	-- Abu Samih the hummus seller: a farm that pays for every attacker that falls in his range.
	hummus = {
		nameKey = "unit.hummus.name",
		descKey = "unit.hummus.desc",
		rarity = "rare",
		role = "farm",
		maxPlaced = 3,
		levels = {
			L(320, 4, 9, 1.2, { bounty = 6 }),
			L(220, 6, 9.5, 1.15, { bounty = 9 }),
			L(360, 8, 10, 1.1, { bounty = 13 }),
			L(560, 11, 10.5, 1.05, { bounty = 18 }),
			L(800, 14, 11, 1.0, { bounty = 24 }),
		},
		visual = { robe = "#8A8A84", accent = "#D9C9A8", skin = "#C68E64", hat = "cap", hatColor = "#F4F1EA", weapon = "tray" },
	},
	-- Abu Hamoud the cobbler: nails on the road; whoever steps in them slows.
	iskafi = {
		nameKey = "unit.iskafi.name",
		descKey = "unit.iskafi.desc",
		rarity = "rare",
		role = "splash",
		maxPlaced = 5,
		levels = {
			L(240, 4, 10, 1.6, { splash = 3, slow = 0.6, slowFor = 2 }),
			L(160, 7, 10.5, 1.55, { splash = 3.3, slow = 0.6, slowFor = 2 }),
			L(280, 10, 11, 1.5, { splash = 3.7, slow = 0.6, slowFor = 2 }),
			L(440, 14, 11.5, 1.45, { splash = 4.1, slow = 0.6, slowFor = 2 }),
			L(680, 20, 12, 1.4, { splash = 4.5, slow = 0.6, slowFor = 2 }),
		},
		visual = { robe = "#5A4632", accent = "#3B2A20", skin = "#C68E64", hat = "cap", hatColor = "#1F1B18", weapon = "hammer" },
	},
	-- Abu Basim of the hammam: a cloud of steam every 3 s over his whole range that slows the crowd
	-- and takes a burn stack off the gate (the plan's "aura", built from splash + slow + douse).
	hammam = {
		nameKey = "unit.hammam.name",
		descKey = "unit.hammam.desc",
		rarity = "epic",
		role = "splash",
		maxPlaced = 2,
		douse = 1,
		levels = {
			L(480, 2, 11, 3.0, { splash = 11, slow = 0.8, slowFor = 3 }),
			L(320, 3, 12, 3.0, { splash = 12, slow = 0.77, slowFor = 3 }),
			L(480, 4, 13, 3.0, { splash = 13, slow = 0.74, slowFor = 3 }),
			L(720, 6, 14, 3.0, { splash = 14, slow = 0.71, slowFor = 3 }),
			L(1000, 8, 15, 3.0, { splash = 15, slow = 0.68, slowFor = 3 }),
			L(1400, 10, 16, 3.0, { splash = 16, slow = 0.65, slowFor = 3 }),
		},
		signature = {
			a = { key = "scald", cost = 2100, set = { douse = 2 } },
			b = { key = "fog", cost = 2100, set = { slow = 0.55 } },
		},
		visual = { robe = "#F4F1EA", accent = "#A4302A", skin = "#C68E64", hat = "none", hatColor = "#F4F1EA", weapon = "jug" },
	},
	-- Su'da Khanum: The Cry silences the road around her (ability sweep with a stun).
	matriarch = {
		nameKey = "unit.matriarch.name",
		descKey = "unit.matriarch.desc",
		rarity = "mythic",
		role = "splash",
		maxPlaced = 1,
		hitsStealth = true,
		levels = {
			L(1300, 60, 11, 1.1, { splash = 6 }),
			L(850, 90, 11.5, 1.05, { splash = 6.5 }),
			L(1300, 135, 12, 1.0, { splash = 7 }),
			L(1950, 200, 12.5, 0.95, { splash = 7.5 }),
			L(2900, 310, 13, 0.88, { splash = 8.2 }),
			L(4300, 480, 13.5, 0.8, { splash = 9 }),
		},
		ability = { kind = "sweep", cooldown = 11, multiplier = 4, radius = 11, stun = 1.2 },
		signature = {
			a = { key = "wail", cost = 6450, ability = { radius = 13 } },
			b = { key = "silence", cost = 6450, ability = { stun = 1.8 } },
		},
		visual = { robe = "#5A2340", accent = "#C9A13B", skin = "#C68E64", hat = "scarf", hatColor = "#1F1B18", weapon = "none" },
	},
	farran = {
		nameKey = "unit.farran.name",
		descKey = "unit.farran.desc",
		rarity = "rare",
		role = "splash",
		maxPlaced = 6,
		levels = {
			L(220, 5, 11, 1.6, { splash = 3 }),
			L(150, 8, 12, 1.55, { splash = 3.2 }),
			L(260, 12, 12, 1.5, { splash = 3.5 }),
			L(420, 19, 13, 1.4, { splash = 3.8 }),
			L(650, 30, 14, 1.3, { splash = 4.2 }),
		},
		visual = { robe = "#F1E9DA", accent = "#6B4423", skin = "#C68E64", hat = "cap", hatColor = "#EFE6D2", weapon = "bread" },
	},

	---------------------------------------------------------------- Rare
	saqqa = {
		nameKey = "unit.saqqa.name",
		descKey = "unit.saqqa.desc",
		rarity = "rare",
		role = "splash",
		maxPlaced = 5,
		douse = 1, -- her water puts out the torchbearers' fire on the gate
		levels = {
			L(300, 6, 12, 1.5, { splash = 4, slow = 0.7, slowFor = 1.5 }),
			L(200, 9, 13, 1.45, { splash = 4.2, slow = 0.65, slowFor = 1.8 }),
			L(340, 14, 14, 1.4, { splash = 4.5, slow = 0.6, slowFor = 2 }),
			L(520, 22, 15, 1.3, { splash = 5, slow = 0.55, slowFor = 2.4 }),
			L(800, 34, 16, 1.2, { splash = 5.5, slow = 0.5, slowFor = 2.8 }),
		},
		visual = { robe = "#7A3B5C", accent = "#E8B23A", skin = "#C68E64", hat = "scarf", hatColor = "#F1E9DA", weapon = "stick" },
	},
	hallaq = {
		nameKey = "unit.hallaq.name",
		descKey = "unit.hallaq.desc",
		rarity = "rare",
		role = "melee",
		maxPlaced = 5,
		hitsStealth = true,
		levels = {
			L(280, 9, 7, 0.5),
			L(190, 13, 7.5, 0.48),
			L(320, 19, 8, 0.45),
			L(500, 29, 8.5, 0.42),
			L(780, 44, 9, 0.38),
		},
		visual = { robe = "#FBF8F1", accent = "#2F3E6B", skin = "#D2A07A", hat = "tarboosh", hatColor = "#A4302A", weapon = "razor" },
	},
	khayyat = {
		nameKey = "unit.khayyat.name",
		descKey = "unit.khayyat.desc",
		rarity = "rare",
		role = "ranged",
		maxPlaced = 5,
		levels = {
			L(260, 7, 18, 1.1),
			L(180, 11, 19, 1.05),
			L(300, 16, 20, 1.0),
			L(480, 25, 21, 0.95),
			L(740, 38, 22, 0.9),
		},
		visual = { robe = "#6E5E50", accent = "#A4302A", skin = "#C08A62", hat = "cap", hatColor = "#FBF8F1", weapon = "jug" },
	},
	qahwaji = {
		nameKey = "unit.qahwaji.name",
		descKey = "unit.qahwaji.desc",
		rarity = "rare",
		role = "farm",
		maxPlaced = 4,
		-- Income is the job; the small damage is his tea-glass throw at anyone who comes near the
		-- coffee house (a chip, not a damage dealer: re-run tests/balance before raising it).
		levels = {
			L(350, 4, 9, 1.6, { income = 90 }),
			L(300, 6, 9.5, 1.6, { income = 160 }),
			L(500, 9, 10, 1.55, { income = 260 }),
			L(800, 13, 10.5, 1.5, { income = 400 }),
			L(1300, 18, 11, 1.45, { income = 620 }),
		},
		visual = { robe = "#5E7D3A", accent = "#C9A13B", skin = "#C08A62", hat = "tarboosh", hatColor = "#A4302A", weapon = "tray" },
	},

	---------------------------------------------------------------- Epic
	qabaday = {
		nameKey = "unit.qabaday.name",
		descKey = "unit.qabaday.desc",
		rarity = "epic",
		role = "melee",
		maxPlaced = 4,
		hitsStealth = true,
		levels = {
			L(450, 22, 8, 0.7),
			L(300, 32, 8.5, 0.68),
			L(500, 48, 9, 0.65),
			L(800, 72, 9.5, 0.6),
			L(1200, 108, 10, 0.55),
			L(1800, 160, 10.5, 0.5),
		},
		ability = { kind = "shabriyeh", cooldown = 12, multiplier = 6 },
		signature = {
			a = { key = "rage", cost = 2700, ability = { cooldown = 8 } },
			b = { key = "guard", cost = 2700, set = { stun = 0.3 } },
		},
		visual = { robe = "#1F1B18", accent = "#A4302A", skin = "#C68E64", hat = "tarboosh", hatColor = "#A4302A", weapon = "dagger", scale = 1.08 },
	},
	haddad = {
		nameKey = "unit.haddad.name",
		descKey = "unit.haddad.desc",
		rarity = "epic",
		role = "splash",
		maxPlaced = 4,
		levels = {
			L(520, 20, 10, 2.0, { splash = 5, stun = 0.4 }),
			L(350, 30, 10.5, 1.95, { splash = 5.3, stun = 0.5 }),
			L(560, 46, 11, 1.9, { splash = 5.6, stun = 0.6 }),
			L(880, 70, 11.5, 1.8, { splash = 6, stun = 0.7 }),
			L(1350, 105, 12, 1.7, { splash = 6.5, stun = 0.8 }),
			L(2000, 155, 12.5, 1.6, { splash = 7, stun = 1.0 }),
		},
		signature = {
			a = { key = "anvil", cost = 3000, set = { stun = 1.4 } },
			b = { key = "forge", cost = 3000, set = { splash = 9 } },
		},
		visual = { robe = "#6E5E50", accent = "#3D3A38", skin = "#B97F5A", hat = "none", hatColor = "#000000", weapon = "hammer", scale = 1.12 },
	},
	mukhtar = {
		nameKey = "unit.mukhtar.name",
		descKey = "unit.mukhtar.desc",
		rarity = "epic",
		role = "support",
		maxPlaced = 2,
		levels = {
			L(500, 0, 12, 1, { buff = 1.15 }),
			L(350, 0, 13, 1, { buff = 1.22 }),
			L(600, 0, 14, 1, { buff = 1.3 }),
			L(950, 0, 15, 1, { buff = 1.4 }),
			L(1500, 0, 16, 1, { buff = 1.52 }),
			L(2200, 0, 17, 1, { buff = 1.65 }),
		},
		signature = {
			a = { key = "loud", cost = 3300, set = { buff = 1.8 } },
			b = { key = "brave", cost = 3300, set = { damage = 6, cooldown = 1.2 } },
		},
		visual = { robe = "#EADFC8", accent = "#C9A13B", skin = "#C08A62", hat = "tarboosh", hatColor = "#A4302A", weapon = "none" },
	},

	---------------------------------------------------------------- Legendary
	zaim = {
		nameKey = "unit.zaim.name",
		descKey = "unit.zaim.desc",
		rarity = "legendary",
		role = "melee",
		maxPlaced = 2,
		hitsStealth = true,
		levels = {
			L(800, 45, 9, 0.65),
			L(500, 65, 9.5, 0.62),
			L(800, 95, 10, 0.6),
			L(1250, 140, 10.5, 0.55),
			L(1900, 205, 11, 0.5),
			L(2800, 300, 12, 0.45),
		},
		ability = { kind = "shabriyeh", cooldown = 9, multiplier = 10 },
		signature = {
			a = { key = "judgment", cost = 4200, ability = { multiplier = 14 } },
			b = { key = "mercy", cost = 4200, ability = { slow = 0.5, slowFor = 3 } },
		},
		visual = { robe = "#1F1B18", accent = "#C9A13B", skin = "#C68E64", hat = "tarboosh", hatColor = "#A4302A", weapon = "dagger", scale = 1.12 },
	},
	pahlawan = {
		nameKey = "unit.pahlawan.name",
		descKey = "unit.pahlawan.desc",
		rarity = "legendary",
		role = "splash",
		maxPlaced = 2,
		levels = {
			L(850, 40, 9, 1.4, { splash = 6, stun = 0.6 }),
			L(550, 60, 9.5, 1.35, { splash = 6.3, stun = 0.7 }),
			L(850, 90, 10, 1.3, { splash = 6.6, stun = 0.8 }),
			L(1300, 135, 10.5, 1.2, { splash = 7, stun = 0.9 }),
			L(2000, 200, 11, 1.1, { splash = 7.5, stun = 1.0 }),
			L(2900, 290, 12, 1.0, { splash = 8, stun = 1.2 }),
		},
		ability = { kind = "sweep", cooldown = 14, multiplier = 4, radius = 9 },
		signature = {
			a = { key = "iron", cost = 4350, ability = { radius = 12 } },
			b = { key = "pin", cost = 4350, ability = { stun = 1.5 } },
		},
		visual = { robe = "#A4302A", accent = "#1F1B18", skin = "#B97F5A", hat = "none", hatColor = "#000000", weapon = "none", scale = 1.25 },
	},
	umm_hara = {
		nameKey = "unit.umm_hara.name",
		descKey = "unit.umm_hara.desc",
		rarity = "legendary",
		role = "healer",
		maxPlaced = 1,
		levels = {
			L(700, 0, 14, 1, { heal = 6, buff = 1.1 }),
			L(500, 0, 15, 1, { heal = 9, buff = 1.15 }),
			L(800, 0, 16, 1, { heal = 13, buff = 1.2 }),
			L(1200, 0, 17, 1, { heal = 18, buff = 1.28 }),
			L(1800, 0, 18, 1, { heal = 24, buff = 1.36 }),
			L(2600, 0, 19, 1, { heal = 32, buff = 1.45 }),
		},
		signature = {
			a = { key = "hakim", cost = 3900, set = { heal = 44 } },
			b = { key = "elder", cost = 3900, set = { buff = 1.6 } },
		},
		visual = { robe = "#EADFC8", accent = "#1F1B18", skin = "#D2A07A", hat = "tarboosh", hatColor = "#A4302A", weapon = "razor" },
	},

	---------------------------------------------------------------- Mythic
	arada = {
		nameKey = "unit.arada.name",
		descKey = "unit.arada.desc",
		rarity = "mythic",
		role = "splash",
		maxPlaced = 1,
		hitsStealth = true,
		levels = {
			L(1200, 70, 11, 1.0, { splash = 7 }),
			L(800, 105, 11.5, 0.95, { splash = 7.5 }),
			L(1200, 160, 12, 0.9, { splash = 8 }),
			L(1800, 240, 12.5, 0.85, { splash = 8.5 }),
			L(2700, 360, 13, 0.8, { splash = 9 }),
			L(4000, 540, 14, 0.7, { splash = 10 }),
		},
		ability = { kind = "sweep", cooldown = 10, multiplier = 5, radius = 12 },
		signature = {
			a = { key = "drums", cost = 6000, cooldownMul = 0.8 },
			b = { key = "swords", cost = 6000, revealsStealth = true },
		},
		visual = { robe = "#FBF8F1", accent = "#A4302A", skin = "#C68E64", hat = "tarboosh", hatColor = "#A4302A", weapon = "sword", scale = 1.1 },
	},
	zaim_akbar = {
		nameKey = "unit.zaim_akbar.name",
		descKey = "unit.zaim_akbar.desc",
		rarity = "mythic",
		role = "melee",
		maxPlaced = 1,
		hitsStealth = true,
		levels = {
			L(1500, 110, 10, 0.55),
			L(900, 160, 10.5, 0.52),
			L(1400, 240, 11, 0.5),
			L(2100, 360, 11.5, 0.46),
			L(3000, 540, 12, 0.42),
			L(4500, 800, 13, 0.38),
		},
		ability = { kind = "shabriyeh", cooldown = 7, multiplier = 15 },
		signature = {
			a = { key = "akeed", cost = 6750, ability = { multiplier = 20 } },
			b = { key = "rally", cost = 6750, haste = { radius = 10, mul = 0.9 } },
		},
		visual = { robe = "#1F1B18", accent = "#C9A13B", skin = "#C68E64", hat = "tarboosh", hatColor = "#A4302A", weapon = "dagger", scale = 1.18 },
	},

	---------------------------------------------------------------- Secret (story drops only)

	-- The secret unit of Season Story 1 (STORY_PLAN §7.6, S1-S12): the thief of Episodes 1–3, the
	-- one-armed night guard after his confession. Only from Episode 9 wins (TD.SECRET_DROP).
	adashari = {
		nameKey = "unit.adashari.name",
		descKey = "unit.adashari.desc",
		rarity = "secret",
		role = "melee",
		maxPlaced = 1,
		hitsStealth = true,
		revealsStealth = true, -- his lantern (D-051: lights his attack range for now)
		noBanner = true,
		levels = {
			L(900, 60, 8, 0.6),
			L(600, 90, 8.5, 0.58),
			L(1000, 135, 9, 0.55),
			L(1600, 200, 9.5, 0.5),
			L(2400, 300, 10, 0.46),
			L(3600, 450, 11, 0.42),
		},
		-- The Oath: marks the strongest enemy in range; every defender hits it ×1.4 for 4 s.
		ability = { kind = "mark", cooldown = 10, multiplier = 1.4, duration = 4 },
		signature = {
			a = { key = "repentance", cost = 5400, ability = { count = 2 } },
			b = { key = "warehouse", cost = 5400, set = { douse = 2 } },
		},
		visual = { robe = "#7A6A55", accent = "#1F1B18", skin = "#B97F5A", hat = "hatta", hatColor = "#2A211B", weapon = "lantern", scale = 0.95 },
	},
}

return Units
