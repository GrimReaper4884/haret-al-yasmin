--!strict
-- Season pass: level from XP, claiming tiers on the free and premium tracks. Pure.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Grants = sibling("Grants")

local PassLogic = {}

-- Makes sure the profile's pass record is for the current season (a new season resets it).
function PassLogic.ensureSeason(profile: any, season: string)
	if profile.pass.season ~= season then
		profile.pass = { season = season, xp = 0, premium = false, claimedFree = {}, claimedPremium = {} }
	end
end

-- Returns level (0..levels) and xp progress into the next level, and that level's requirement.
function PassLogic.level(xp: number, tiers: { any }): (number, number, number)
	local level = 0
	local remaining = xp
	for i, tier in tiers do
		if remaining >= tier.xp then
			remaining -= tier.xp
			level = i
		else
			return level, remaining, tier.xp
		end
	end
	return level, 0, 0
end

function PassLogic.addLevels(profile: any, n: number, tiers: { any })
	local level = PassLogic.level(profile.pass.xp, tiers)
	local target = math.min(level + n, #tiers)
	local xp = 0
	for i = 1, target do
		xp += tiers[i].xp
	end
	profile.pass.xp = math.max(profile.pass.xp, xp)
end

function PassLogic.canClaim(profile: any, tier: any, track: any, tiers: { any }): (boolean, string?)
	if type(tier) ~= "number" or tier < 1 or tier > #tiers or math.floor(tier) ~= tier then
		return false, "bad_request"
	end
	if track ~= "free" and track ~= "premium" then
		return false, "bad_request"
	end
	local level = PassLogic.level(profile.pass.xp, tiers)
	if tier > level then
		return false, "locked"
	end
	if track == "premium" and not profile.pass.premium then
		return false, "premium_required"
	end
	local claimed = if track == "free" then profile.pass.claimedFree else profile.pass.claimedPremium
	if claimed[tostring(tier)] then
		return false, "already_claimed"
	end
	return true, nil
end

-- The lowest tier with a reward the player can claim now on either track (nil when none); the
-- Lane Diary opens its strip there (MH-20). Takes anything with a `pass` field (profile or snapshot).
function PassLogic.firstClaimable(profile: any, tiers: { any }): number?
	local level = PassLogic.level(profile.pass.xp, tiers)
	for tier = 1, level do
		if PassLogic.canClaim(profile, tier, "free", tiers) or PassLogic.canClaim(profile, tier, "premium", tiers) then
			return tier
		end
	end
	return nil
end

function PassLogic.claim(profile: any, tier: any, track: any, tiers: { any }, ctx: any): (boolean, string?, any?)
	local ok, err = PassLogic.canClaim(profile, tier, track, tiers)
	if not ok then
		return false, err, nil
	end
	local reward = if track == "free" then tiers[tier].free else tiers[tier].premium
	local claimed = if track == "free" then profile.pass.claimedFree else profile.pass.claimedPremium
	claimed[tostring(tier)] = true
	local granted = Grants.apply(profile, reward, ctx)
	return true, nil, granted
end

return PassLogic
