--!strict
-- Redeemable codes (marketing: update day, like milestones, Discord, TikTok). Pure data.
-- Codes are upper-case, redeemed once per player, and stop working after `expiresAt` (UTC epoch).
-- Add a code here and deploy; remove it or set an expiry to retire it.

export type CodeDef = {
	lira: number?,
	qirsh: number?,
	traitStones: number?,
	unit: string?, -- grants one copy
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
}

return Codes
