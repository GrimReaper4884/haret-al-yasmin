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
	matchCash: number?, -- wave cash in the current match; repeatable, only works during a match
	onlyUserIds: { number }?, -- if set, only these Roblox user ids can redeem; others get unknown_code
	expiresAt: number?,
}

local Codes: { [string]: CodeDef } = {
	-- Launch (expire 2026-12-31)
	YASMIN = { lira = 100, expiresAt = 1798675200 },
	HARA = { lira = 50, qirsh = 150, expiresAt = 1798675200 },
	SHABRIYEH = { lira = 150, expiresAt = 1798675200 },
	-- The Cat was retired for Al-Adashari (S1-S12b, 2026-10-18): the code expired at the deploy and its
	-- unit no longer exists (Grants skips it). Remove this line one release later (STORY_PLAN §7.7).
	QITT = { unit = "qitt", expiresAt = 1792281600 },
	-- Season 1 pass preview
	DIARY = { traitStones = 1, lira = 40, expiresAt = 1764460800 },
	-- Testers: every defender. Hand out privately, never post publicly (expires 2026-11-17).
	-- To lock it to named testers, add onlyUserIds = { 12345, ... }.
	HARATESTERWRCF5G = { allUnits = true, expiresAt = 1794873600 },
	-- Owner only: +50,000 wave cash in the current match, reusable every match. Anyone else gets unknown_code.
	MONEY50K = { matchCash = 50000, onlyUserIds = { 2465538767 } },
}

return Codes
