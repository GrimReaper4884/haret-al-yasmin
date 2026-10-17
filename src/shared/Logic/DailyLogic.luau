--!strict
-- Daily login streak. Days are UTC calendar days (floor(now / 86400)). Pure.

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

local DailyLogic = {}

local DAY = 86400

function DailyLogic.day(now: number): number
	return math.floor(now / DAY)
end

-- The streak day (1..#rewards) the player would claim now, and whether they can.
function DailyLogic.status(profile: any, now: number, rewards: { any }): { canClaim: boolean, day: number, streak: number }
	local today = DailyLogic.day(now)
	local d = profile.daily
	local canClaim = d.lastDay ~= today
	local streak = if d.lastDay == today then d.streak elseif d.lastDay == today - 1 then d.streak + 1 else 1
	if streak < 1 then
		streak = 1
	end
	local day = ((streak - 1) % #rewards) + 1
	return { canClaim = canClaim, day = day, streak = streak }
end

function DailyLogic.claim(profile: any, now: number, rewards: { any }, ctx: any): (boolean, string?, any?, number?)
	local s = DailyLogic.status(profile, now, rewards)
	if not s.canClaim then
		return false, "already_claimed", nil, nil
	end
	profile.daily.lastDay = DailyLogic.day(now)
	profile.daily.streak = s.streak
	local granted = Grants.apply(profile, rewards[s.day], ctx)
	return true, nil, granted, s.day
end

return DailyLogic
