--!strict
--[[
	Shared config types and constants. Pure data; no game logic.

	Conventions used by every Config module:
	  * Probabilities are integer ppm (parts per million): 1_000_000 ppm = 100%, 1 ppm = 0.0001%.
	    The Roblox odds disclosure must show 4 decimal places, so ppm is exactly the disclosure
	    resolution and every sum can be checked with integer equality (see Validate.luau).
	  * Stat modifiers are fractions: +0.05 = +5%. SPA is seconds per attack, so a negative SPA
	    modifier means faster attacks (-0.04 = 4% less time between attacks).
	  * Distances are studs; times are seconds; cash is in-match Cash.
	  * Values tagged TUNE in comments are starting points chosen to be tuned with telemetry.
]]

export type Rarity = "Rare" | "Epic" | "Legendary" | "Mythic" | "Secret"
export type Role = "Striker" | "Sweeper" | "Marksman" | "Lantern" | "Breaker" | "Warden" | "Herald" | "Merchant"
export type Placement = "Ground" | "Hill"
-- Damage vs Flying enemies: Full = 100%, Half = 50%, None = cannot target them.
export type FlyerRule = "Full" | "Half" | "None"
export type Targeting = "First" | "Last" | "Strongest" | "Closest"
export type Difficulty = "Normal" | "Nightmare" | "Legend" | "EventHard"

-- Additive permanent modifiers (traits, stat grades). See GDD section 7.3 for the damage formula.
export type StatMods = {
	damagePct: number?,
	spaPct: number?,
	rangePct: number?,
	unitXpPct: number?,
	farmIncomePct: number?, -- Merchant-role units only
	upgradeCostPct: number?, -- non-Merchant units only; total discounts capped by UnitConfig.MaxUpgradeDiscount
	bossDamagePct: number?,
	critChance: number?,
	critDamagePct: number?, -- added to UnitConfig.BaseCritMultiplier
	shieldIgnorePct: number?, -- fraction of incoming damage that bypasses shield pools
	bossStunImmune: boolean?,
}

local Types = {}

Types.PPM_TOTAL = 1_000_000

local rarityOrder: { Rarity } = { "Rare", "Epic", "Legendary", "Mythic", "Secret" }
Types.RarityOrder = rarityOrder

local roles: { Role } = { "Striker", "Sweeper", "Marksman", "Lantern", "Breaker", "Warden", "Herald", "Merchant" }
Types.Roles = roles

return Types
