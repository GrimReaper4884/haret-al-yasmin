--!strict
-- Redeemable codes (marketing: update day, like milestones, Discord, TikTok). Pure data.
-- Codes are upper-case, redeemed once per player, and stop working after `expiresAt` (UTC epoch).
-- Add a code here and deploy; remove it or set an expiry to retire it.

export type CodeDef = {
	lira: number?,
	qirsh: number?,
	traitStones: number?,
	unit: string?, -- grants one copy
	allUnits: boolean?, -- grants every defender in Config/Units the player doesn't own yet
	onlyUserIds: { number }?, -- if set, only these Roblox user ids can redeem; others get unknown_code
	expiresAt: number?,
}

local Codes: { [string]: CodeDef } = {
	-- Launch (expire 2026-12-31)
	YASMIN = { lira = 100, expiresAt = 1798675200 },
	HARA = { lira = 50, qirsh = 150, expiresAt = 1798675200 },
	SHABRIYEH = { lira = 150, expiresAt = 1798675200 },
	-- Secret unit, announced on the community channels
	QITT = { unit = "qitt", expiresAt = 1798675200 },
	-- Season 1 pass preview
	DIARY = { traitStones = 1, lira = 40, expiresAt = 1764460800 },
	-- Testers: every defender. Hand out privately, never post publicly (expires 2026-11-17).
	-- To lock it to named testers, add onlyUserIds = { 12345, ... }.
	HARATESTERWRCF5G = { allUnits = true, expiresAt = 1794873600 },
	-- Owner only: 50,000 lira and qirsh to try every summon and shop item. Anyone else gets unknown_code.
	MONEY50K = { lira = 50000, qirsh = 50000, onlyUserIds = { 2465538767 } },
}

return Codes
