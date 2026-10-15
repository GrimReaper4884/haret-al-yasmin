--!strict
-- Summons: banner rotation, odds, pity and the lira cost. Pure; rng() → [0, 1) is injected.
-- Odds shown to players (SummonLogic.displayOdds) come from the same tables as the rolls.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local UnitLogic = sibling("UnitLogic")

export type Context = {
	units: { [string]: any },
	banners: { any },
	odds: { [string]: number },
	rarityOrder: { string },
	pityLegendary: number,
	pityMythic: number,
	featuredShare: number,
	rotation: number,
	traits: any,
	rng: () -> number,
	now: number,
}

export type Result = { unitId: string, rarity: string, result: string, featured: boolean, pity: boolean }

local SummonLogic = {}

function SummonLogic.activeBannerIndex(now: number, count: number, rotation: number): number
	if count == 0 then
		return 0
	end
	return (math.floor(now / rotation) % count) + 1
end

function SummonLogic.activeBanner(ctx: Context): any
	return ctx.banners[SummonLogic.activeBannerIndex(ctx.now, #ctx.banners, ctx.rotation)]
end

-- Units of a rarity that can come from a banner.
function SummonLogic.poolFor(units: { [string]: any }, rarity: string): { string }
	local list = {}
	for id, def in units do
		if def.rarity == rarity and not def.noBanner then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return list
end

-- Rarity roll with pity. Returns rarity, pityTriggered.
function SummonLogic.rollRarity(summons: any, ctx: Context): (string, boolean)
	if summons.sinceMythic + 1 >= ctx.pityMythic then
		return "mythic", true
	end
	if summons.sinceLegendary + 1 >= ctx.pityLegendary then
		return "legendary", true
	end
	local r = ctx.rng()
	local acc = 0
	for _, rarity in ctx.rarityOrder do
		local p = ctx.odds[rarity]
		if p then
			acc += p
			if r < acc then
				return rarity, false
			end
		end
	end
	return ctx.rarityOrder[1], false
end

-- Picks the unit within a rarity: featured unit gets featuredShare, the rest is split evenly.
function SummonLogic.rollUnit(rarity: string, banner: any, ctx: Context): (string, boolean)
	local pool = SummonLogic.poolFor(ctx.units, rarity)
	local featured = if rarity == "legendary" then banner.featuredLegendary elseif rarity == "mythic" then banner.featuredMythic else nil
	if featured and ctx.units[featured] and #pool > 1 and ctx.rng() < ctx.featuredShare then
		return featured, true
	end
	if #pool == 0 then
		error("empty summon pool for " .. rarity)
	end
	local idx = math.floor(ctx.rng() * #pool) + 1
	local id = pool[math.clamp(idx, 1, #pool)]
	return id, id == featured
end

-- Per-rarity odds as shown in the UI (the effective odds this very pull, pity included).
function SummonLogic.displayOdds(summons: any, ctx: Context): { { rarity: string, percent: number } }
	local out = {}
	if summons.sinceMythic + 1 >= ctx.pityMythic then
		return { { rarity = "mythic", percent = 100 } }
	end
	if summons.sinceLegendary + 1 >= ctx.pityLegendary then
		return { { rarity = "legendary", percent = 100 } }
	end
	for _, rarity in ctx.rarityOrder do
		local p = ctx.odds[rarity]
		if p then
			table.insert(out, { rarity = rarity, percent = p * 100 })
		end
	end
	return out
end

function SummonLogic.cost(n: number, single: number, ten: number, vipDiscount: number, vip: boolean): number
	local base = if n == 10 then ten else single * n
	if vip then
		base = math.floor(base * (1 - vipDiscount) + 0.5)
	end
	return base
end

-- Performs n summons. Validates lira first; writes only on success.
function SummonLogic.summon(profile: any, n: number, cost: number, ctx: Context): (boolean, string?, { Result }?)
	if n ~= 1 and n ~= 10 then
		return false, "bad_request", nil
	end
	if #ctx.banners == 0 then
		return false, "no_banner", nil
	end
	if profile.lira < cost then
		return false, "no_lira", nil
	end
	profile.lira -= cost
	local banner = SummonLogic.activeBanner(ctx)
	local results: { Result } = {}
	local s = profile.summons
	for _ = 1, n do
		local rarity, pity = SummonLogic.rollRarity(s, ctx)
		local unitId, featured = SummonLogic.rollUnit(rarity, banner, ctx)
		s.total += 1
		if rarity == "mythic" then
			s.sinceMythic = 0
			s.sinceLegendary = 0
		elseif rarity == "legendary" then
			s.sinceLegendary = 0
			s.sinceMythic += 1
		else
			s.sinceLegendary += 1
			s.sinceMythic += 1
		end
		local trait = UnitLogic.rollTrait(ctx.traits.traits, ctx.traits.order, ctx.rng)
		local result = UnitLogic.obtain(profile, unitId, ctx.now, trait)
		table.insert(results, { unitId = unitId, rarity = rarity, result = result, featured = featured, pity = pity })
	end
	return true, nil, results
end

return SummonLogic
