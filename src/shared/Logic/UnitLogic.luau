--!strict
-- Collection rules: owning units, copies → stars, traits, loadouts, and the stats a placed
-- tower gets from (unit, level, stars, trait). Pure.

export type OwnedUnit = { copies: number, trait: string, at: number }

export type Stats = {
	damage: number,
	range: number,
	cooldown: number,
	splash: number?,
	slow: number?,
	slowFor: number?,
	stun: number?,
	buff: number?,
	income: number?,
	heal: number?,
	cash: number, -- kill reward multiplier
	hitsStealth: boolean,
	revealsStealth: boolean,
	ability: any?,
	maxLevel: number,
}

local UnitLogic = {}

-- Number of stars for a unit with `copies` extra copies (0 = only the first copy).
function UnitLogic.stars(copies: number, starCopies: { number }): number
	local stars = 0
	for i, needed in starCopies do
		if copies >= needed then
			stars = i
		end
	end
	return stars
end

function UnitLogic.stats(def: any, level: number, stars: number, trait: any?, starBonus: number): Stats
	local lv = def.levels[math.clamp(level, 1, #def.levels)]
	local dmgMul = (1 + starBonus * stars) * (if trait and trait.damage then trait.damage else 1)
	local rangeMul = if trait and trait.range then trait.range else 1
	local cdMul = if trait and trait.cooldown then trait.cooldown else 1
	return {
		damage = lv.damage * dmgMul,
		range = lv.range * rangeMul,
		cooldown = lv.cooldown * cdMul,
		splash = lv.splash,
		slow = lv.slow,
		slowFor = lv.slowFor,
		stun = lv.stun,
		buff = lv.buff,
		income = lv.income,
		heal = lv.heal,
		cash = if trait and trait.cash then trait.cash else 1,
		hitsStealth = def.hitsStealth == true,
		revealsStealth = def.revealsStealth == true,
		ability = def.ability,
		maxLevel = #def.levels,
	}
end

-- Rolls a trait id with the configured weights. rng() → [0, 1).
function UnitLogic.rollTrait(traits: { [string]: { weight: number } }, order: { string }, rng: () -> number): string
	local total = 0
	for _, id in order do
		total += traits[id].weight
	end
	local r = rng() * total
	for _, id in order do
		r -= traits[id].weight
		if r < 0 then
			return id
		end
	end
	return order[1]
end

-- Adds a copy of `unitId`. Returns "new" (first copy) or "copy".
function UnitLogic.obtain(profile: any, unitId: string, now: number, trait: string): string
	local owned = profile.units[unitId]
	if owned then
		owned.copies += 1
		return "copy"
	end
	profile.units[unitId] = { copies = 0, trait = trait, at = now }
	return "new"
end

-- Validates and sets the loadout: owned, unique, at most `slots` entries.
function UnitLogic.setLoadout(profile: any, list: any, slots: number, units: { [string]: any }): (boolean, string?)
	if type(list) ~= "table" or #list > slots then
		return false, "bad_loadout"
	end
	local seen = {}
	local clean = {}
	for i = 1, #list do
		local id = list[i]
		if type(id) ~= "string" or not units[id] or not profile.units[id] or seen[id] then
			return false, "bad_loadout"
		end
		seen[id] = true
		clean[i] = id
	end
	profile.loadout = clean
	return true, nil
end

function UnitLogic.rerollTrait(profile: any, unitId: string, cost: number, traits: any, order: { string }, rng: () -> number): (boolean, string?, string?)
	local owned = profile.units[unitId]
	if not owned then
		return false, "not_owned", nil
	end
	if profile.traitStones < cost then
		return false, "no_stones", nil
	end
	profile.traitStones -= cost
	local before = owned.trait
	local t = UnitLogic.rollTrait(traits, order, rng)
	-- Never waste a stone on the exact same roll: nudge once.
	if t == before then
		t = UnitLogic.rollTrait(traits, order, rng)
	end
	owned.trait = t
	return true, nil, t
end

-- Exact odds of one rerollTrait from `current` (paid random item: shown before the reroll), in
-- `order`, as percentages summing to 100. Same weights as the roll, and includes the nudge:
-- P(t) = p(t) · (1 + p(current)) for t ≠ current, P(current) = p(current)².
function UnitLogic.rerollOdds(traits: any, order: { string }, current: string?): { { trait: string, percent: number } }
	local total = 0
	for _, id in order do
		total += traits[id].weight
	end
	local pc = 0
	for _, id in order do
		if id == current then
			pc = traits[id].weight / total
		end
	end
	local out = {}
	for _, id in order do
		local p = traits[id].weight / total
		table.insert(out, { trait = id, percent = 100 * (if id == current then p * p else p * (1 + pc)) })
	end
	return out
end

return UnitLogic
