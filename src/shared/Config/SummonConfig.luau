--!strict
--[[
	SummonConfig: the ONLY source of summon odds, costs, pity, spark and shiny values.

	The server RNG (SummonService) and the "View Odds" UI must both read this module. Never copy a
	rate into UI text, a test literal, or another module: the odds table shown to players is
	GENERATED from these tables (per-unit split with largest-remainder rounding at 1 ppm), so the
	disclosure and the RNG can never drift apart. GDD: docs/GAME_DESIGN.md section 9.

	Rarity rates are ppm (1_000_000 = 100%). Every table must sum to exactly 1_000_000; Validate.luau
	asserts this at server start and in tests.

	Pity rules (implemented by SummonService, documented here so the numbers have one home):
	  * Counters count consecutive pulls WITHOUT a result at or above that rarity.
	  * When a pull would be pull number `Pity.legendary` without Legendary-or-better, it is a
	    guaranteed Legendary; same for `Pity.mythic` and Mythic. If both trigger, Mythic wins.
	  * Any result resets every counter at or below its rarity (a Mythic resets both counters;
	    a Secret resets both counters).
	  * Banners with the same `pityGroup` share counters (Standard + Featured share "Main").
	  * Pity counters are shown live next to the odds table.
]]

local Types = require(script.Parent.Types)

export type RarityTable = {
	Rare: number,
	Epic: number,
	Legendary: number,
	Mythic: number,
	Secret: number,
}

export type BannerKind = "Standard" | "Featured" | "Limited" | "Tutorial"

export type BannerDef = {
	id: string,
	kind: BannerKind,
	displayName: string,
	rarityTable: string, -- key into SummonConfig.RarityPpm (pulls 1-9 of a 10x and every single pull)
	slot10Table: string?, -- key into SummonConfig.RarityPpm used for the 10th pull of a 10x
	pityGroup: string?, -- nil = no pity (Tutorial)
	minAccountLevel: number,
	-- Featured: nil = chosen at runtime by the rotation (Featured.mythicsPerRotation units from the
	-- Mythic pool, seeded by the rotation window index so every server shows the same pair).
	featuredMythics: { string }?,
	featuredSecret: string?, -- Limited only: the Secret unit; 100% of Secret results
	sparkEnabled: boolean, -- awards Spark.currency per pull
	free: boolean?, -- no currency cost (still disclosed with odds)
	fixedPoolPpm: { [string]: number }?, -- unit id -> ppm; overrides rarity tables entirely
}

local SummonConfig = {}

SummonConfig.Cost = {
	currency = "Gems",
	singleCost = 50,
	multiCost = 500,
	multiCount = 10,
	-- Gem spending order for non-restricted players: earned Gems first, then paid Gems. A unit pulled
	-- with any paid Gems is flagged paidOrigin = true. Restricted players (PolicyService
	-- ArePaidRandomItemsRestricted) can spend ONLY earned Gems on summons.
	spendEarnedFirst = true,
}

local rarityPpm: { [string]: RarityTable } = {
	-- Standard and Featured banners. Secret's 0.05% from the Limited table is folded into Rare.
	Standard = { Rare = 720_500, Epic = 225_000, Legendary = 47_500, Mythic = 7_000, Secret = 0 },
	-- 10th pull of a 10x: Rare's weight moves to Epic, so it is always Epic or better while
	-- Legendary/Mythic keep their base odds (no hidden boost).
	StandardSlot10 = { Rare = 0, Epic = 945_500, Legendary = 47_500, Mythic = 7_000, Secret = 0 },
	-- Limited banners (one per update, account level 10+).
	Limited = { Rare = 720_000, Epic = 225_000, Legendary = 47_500, Mythic = 7_000, Secret = 500 },
	LimitedSlot10 = { Rare = 0, Epic = 945_000, Legendary = 47_500, Mythic = 7_000, Secret = 500 },
}
SummonConfig.RarityPpm = rarityPpm

SummonConfig.Pity = {
	legendary = 40, -- guaranteed Legendary on the 40th pull without Legendary+
	mythic = 300, -- guaranteed Mythic on the 300th pull without Mythic+ (~2.1x the 1/0.7% expectation)
}

SummonConfig.Featured = {
	rotationHours = 4,
	mythicsPerRotation = 2,
	-- Share of Mythic results that are one of the featured Mythics (split evenly between them).
	featuredShareOfMythicPpm = 500_000,
	-- Losing the 50/50 makes the next Mythic on a featured or limited banner a featured unit.
	guaranteeAfterLoss = true,
}

SummonConfig.Spark = {
	currency = "MoonSigils",
	perPull = 1, -- every pull on a sparkEnabled banner
	costForFeaturedSecret = 1_200, -- buys the banner's featuredSecret outright
	-- At banner end leftover Sigils convert instead of vanishing. TUNE
	leftoverConvertsTo = "ExchangeTokens",
	leftoverRate = 1,
}

SummonConfig.Shiny = {
	-- Independent roll after the unit is chosen. Cosmetic only (model/VFX variant).
	basePpm = 10_000, -- 1%
	shinyCharmPpm = 20_000, -- 2% with the Shiny Charm game pass (odds UI must update live)
	minAccountLevel = 10, -- below this the shiny chance is 0% and the odds UI says so
}

local banners: { [string]: BannerDef } = {
	Standard = {
		id = "Standard",
		kind = "Standard",
		displayName = "Courtyard Summon",
		rarityTable = "Standard",
		slot10Table = "StandardSlot10",
		pityGroup = "Main",
		minAccountLevel = 1,
		sparkEnabled = false,
	},
	Featured = {
		id = "Featured",
		kind = "Featured",
		displayName = "Lantern Rotation",
		rarityTable = "Standard",
		slot10Table = "StandardSlot10",
		pityGroup = "Main",
		minAccountLevel = 1,
		featuredMythics = nil, -- rotation-driven
		sparkEnabled = false,
	},
	-- Season 1 limited banner (runs for the launch update's lifetime). Own pity group. TUNE
	Limited_S1 = {
		id = "Limited_S1",
		kind = "Limited",
		displayName = "Night of First Bloom",
		rarityTable = "Limited",
		slot10Table = "LimitedSlot10",
		pityGroup = "Limited_S1",
		minAccountLevel = 10,
		featuredMythics = { "saif" },
		featuredSecret = "yasmin",
		sparkEnabled = true,
	},
	-- First-session free summon: guaranteed Epic, equal odds. Free, but odds are still shown.
	Tutorial = {
		id = "Tutorial",
		kind = "Tutorial",
		displayName = "First Light",
		rarityTable = "Standard",
		pityGroup = nil,
		minAccountLevel = 1,
		sparkEnabled = false,
		free = true,
		fixedPoolPpm = { nadia = 500_000, bassam = 500_000 },
	},
}
SummonConfig.Banners = banners

-- Pools: a unit is in the Standard pool when UnitConfig.Units[id].summonPool == "Standard".
-- A Limited banner's pool = Standard pool + its featuredSecret. Featured Mythics come from the pool.
SummonConfig.PPM_TOTAL = Types.PPM_TOTAL

return SummonConfig
