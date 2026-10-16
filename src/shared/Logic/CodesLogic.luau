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
	if profile.codes[clean] then
		return false, "already_redeemed", nil
	end
	profile.codes[clean] = ctx.now
	local granted = Grants.apply(profile, def, ctx)
	return true, nil, granted
end

return CodesLogic
