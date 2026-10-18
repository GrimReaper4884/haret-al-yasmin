--!strict
-- Applies a reward bundle ({ lira, qirsh, traitStones, item, unit, allUnits, xp }) to a profile. Shared by
-- codes, daily rewards, the season pass and match rewards. Pure. Returns what was granted.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Wallet = sibling("Wallet")
local Inventory = sibling("Inventory")
local UnitLogic = sibling("UnitLogic")

export type Context = {
	maxQirsh: number,
	maxLira: number,
	maxStones: number,
	items: { [string]: any },
	units: { [string]: any },
	traits: any, -- { traits, order }
	rng: () -> number,
	now: number,
	maxBeads: number?, -- shabriyeh beads cap (Config/Beads.maxBeads); nil = beads are not granted
}

local Grants = {}

local function isPosInt(v: any): boolean
	return type(v) == "number" and v == v and v > 0 and v ~= math.huge and math.floor(v) == v
end

function Grants.apply(profile: any, reward: any, ctx: Context): { [string]: any }
	local granted: { [string]: any } = {}
	if isPosInt(reward.lira) then
		local before = profile.lira
		profile.lira = math.min(before + reward.lira, ctx.maxLira)
		granted.lira = profile.lira - before
	end
	if isPosInt(reward.qirsh) then
		local _, _, added = Wallet.add(profile, reward.qirsh, ctx.maxQirsh)
		granted.qirsh = added
	end
	if isPosInt(reward.traitStones) then
		local before = profile.traitStones
		profile.traitStones = math.min(before + reward.traitStones, ctx.maxStones)
		granted.traitStones = profile.traitStones - before
	end
	if type(reward.item) == "string" and ctx.items[reward.item] then
		if not Inventory.has(profile, reward.item, 1) then
			if Inventory.add(profile, reward.item, 1, ctx.items) then
				granted.item = reward.item
			end
		else
			-- Already owned: a small qirsh consolation so the reward is never nothing.
			Wallet.add(profile, 100, ctx.maxQirsh)
			granted.qirsh = (granted.qirsh or 0) + 100
		end
	end
	if type(reward.unit) == "string" and ctx.units[reward.unit] then
		local trait = UnitLogic.rollTrait(ctx.traits.traits, ctx.traits.order, ctx.rng)
		granted.unit = reward.unit
		granted.unitResult = UnitLogic.obtain(profile, reward.unit, ctx.now, trait)
	end
	if reward.allUnits == true then
		-- Only the missing defenders, in a stable order, so a second source never adds copies.
		local ids = {}
		for id in ctx.units do
			if not profile.units[id] then
				table.insert(ids, id)
			end
		end
		table.sort(ids)
		for _, id in ids do
			local trait = UnitLogic.rollTrait(ctx.traits.traits, ctx.traits.order, ctx.rng)
			UnitLogic.obtain(profile, id, ctx.now, trait)
		end
		granted.units = ids
	end
	if isPosInt(reward.xp) then
		granted.xp = reward.xp
		profile.pass.xp += reward.xp
	end
	if isPosInt(reward.beads) and ctx.maxBeads then
		local before = profile.beads or 0
		profile.beads = math.min(before + reward.beads, ctx.maxBeads)
		granted.beads = profile.beads - before
	end
	return granted
end

return Grants
