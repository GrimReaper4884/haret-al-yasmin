--!strict
-- Code redemption: once per player, case-insensitive, expiring. Pure.

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

local CodesLogic = {}

function CodesLogic.normalize(code: any): string?
	if type(code) ~= "string" then
		return nil
	end
	local clean = string.upper((string.gsub(code, "%s", "")))
	if #clean == 0 or #clean > 32 or not string.match(clean, "^[%w_]+$") then
		return nil
	end
	return clean
end

function CodesLogic.redeem(profile: any, code: any, codes: { [string]: any }, ctx: any): (boolean, string?, any?)
	local clean = CodesLogic.normalize(code)
	if not clean then
		return false, "bad_code", nil
	end
	local def = codes[clean]
	if not def then
		return false, "unknown_code", nil
	end
	if def.onlyUserIds and not table.find(def.onlyUserIds, ctx.userId) then
		-- Same answer as a typo, so a leaked code doesn't reveal that it exists.
		return false, "unknown_code", nil
	end
	if def.expiresAt and ctx.now > def.expiresAt then
		return false, "expired", nil
	end
	if def.matchCash then
		-- Match-cash codes never touch the profile; see redeemMatchCash.
		return false, "match_only", nil
	end
	if profile.codes[clean] then
		return false, "already_redeemed", nil
	end
	profile.codes[clean] = ctx.now
	local granted = Grants.apply(profile, def, ctx)
	return true, nil, granted
end

function CodesLogic.isMatchCash(code: any, codes: { [string]: any }): boolean
	local clean = CodesLogic.normalize(code)
	local def = clean and codes[clean]
	return def ~= nil and def.matchCash ~= nil
end

-- Wave cash for the redeemer's current match. Repeatable (nothing is recorded on the profile) and
-- only while a match is on (ctx.inMatch). Returns ok, err, amount.
function CodesLogic.redeemMatchCash(code: any, codes: { [string]: any }, ctx: any): (boolean, string?, number?)
	local clean = CodesLogic.normalize(code)
	if not clean then
		return false, "bad_code", nil
	end
	local def = codes[clean]
	if not def or not def.matchCash then
		return false, "unknown_code", nil
	end
	if def.onlyUserIds and not table.find(def.onlyUserIds, ctx.userId) then
		return false, "unknown_code", nil
	end
	if def.expiresAt and ctx.now > def.expiresAt then
		return false, "expired", nil
	end
	if not ctx.inMatch then
		return false, "match_only", nil
	end
	return true, nil, def.matchCash
end

return CodesLogic
