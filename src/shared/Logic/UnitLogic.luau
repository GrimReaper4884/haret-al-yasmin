--!strict
-- Collection rules: owning units, copies → stars, traits, loadouts, and the stats a placed
-- tower gets from (unit, level, stars, trait). Pure.

-- trait2: the second trait slot (traits v2), rolled once the unit has `TD.TRAIT2_STARS` stars.
export type OwnedUnit = { copies: number, trait: string, trait2: string?, at: number }

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
	douse: number?, -- burn stacks taken off the gate per attack
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

-- Two traits never stack the same stat: per stat the better one wins. Returns the merged trait
-- (nil when both are nil). Flags or together; tier is the higher one.
function UnitLogic.combineTraits(a: any?, b: any?): any?
	if not a or not b then
		return a or b
	end
	local function pick(key: string, better: (number, number) -> number): number?
		local x, y = a[key], b[key]
		if x == nil or y == nil then
			return x or y
		end
		return better(x, y)
	end
	return {
		nameKey = a.nameKey,
		weight = a.weight,
		damage = pick("damage", math.max),
		range = pick("range", math.max),
		cooldown = pick("cooldown", math.min),
		cash = pick("cash", math.max),
		costMul = pick("costMul", math.min),
		maxPlaced = pick("maxPlaced", math.max),
		douse = pick("douse", math.max),
		hitsStealth = if a.hitsStealth or b.hitsStealth then true else nil,
		tier = math.max(a.tier or 1, b.tier or 1),
	}
end

-- The trait a placed copy of an owned unit gets: its first trait, merged with the second one
-- once the unit has `slot2Stars` stars (a trait2 rolled earlier but below the threshold is ignored).
function UnitLogic.ownedTrait(owned: any?, traits: { [string]: any }, starCopies: { number }, slot2Stars: number): any?
	if not owned then
		return nil
	end
	local first = traits[owned.trait]
	if owned.trait2 and UnitLogic.stars(owned.copies, starCopies) >= slot2Stars then
		return UnitLogic.combineTraits(first, traits[owned.trait2])
	end
	return first
end

-- A price after the trait's cost multiplier (miser), rounded to whole cash.
function UnitLogic.costFor(cost: number, trait: any?): number
	if trait and trait.costMul then
		return math.floor(cost * trait.costMul + 0.5)
	end
	return cost
end

-- caps (Config/Traits.caps): clamps the trait multipliers (damage ≤, range ≤, cooldown ≥); nil = no clamp.
function UnitLogic.stats(def: any, level: number, stars: number, trait: any?, starBonus: number, caps: any?): Stats
	local lv = def.levels[math.clamp(level, 1, #def.levels)]
	local tDmg = if trait and trait.damage then trait.damage else 1
	local rangeMul = if trait and trait.range then trait.range else 1
	local cdMul = if trait and trait.cooldown then trait.cooldown else 1
	if caps then
		tDmg = math.min(tDmg, caps.damage)
		rangeMul = math.min(rangeMul, caps.range)
		cdMul = math.max(cdMul, caps.cooldown)
	end
	local dmgMul = (1 + starBonus * stars) * tDmg
	local douse = def.douse
	if trait and trait.douse and (douse == nil or trait.douse > douse) then
		douse = trait.douse
	end
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
		hitsStealth = def.hitsStealth == true or (trait ~= nil and trait.hitsStealth == true),
		revealsStealth = def.revealsStealth == true,
		douse = douse,
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

-- Second-slot rules for rerollTrait: the slot opens at `stars` stars (TD.TRAIT2_STARS).
export type Slot2Rule = { starCopies: { number }, stars: number }

-- slot: 1 (default) or 2. Slot 2 needs `slot2` (the unlock rule) and enough stars: "slot_locked".
function UnitLogic.rerollTrait(profile: any, unitId: string, cost: number, traits: any, order: { string }, rng: () -> number, slot: number?, slot2: Slot2Rule?): (boolean, string?, string?)
	local owned = profile.units[unitId]
	if not owned then
		return false, "not_owned", nil
	end
	local which = slot or 1
	if which ~= 1 and which ~= 2 then
		return false, "bad_request", nil
	end
	if which == 2 and (not slot2 or UnitLogic.stars(owned.copies, slot2.starCopies) < slot2.stars) then
		return false, "slot_locked", nil
	end
	if profile.traitStones < cost then
		return false, "no_stones", nil
	end
	profile.traitStones -= cost
	local before = if which == 2 then owned.trait2 else owned.trait
	local t = UnitLogic.rollTrait(traits, order, rng)
	-- Never waste a stone on the exact same roll: nudge once.
	if t == before then
		t = UnitLogic.rollTrait(traits, order, rng)
	end
	if which == 2 then
		owned.trait2 = t
	else
		owned.trait = t
	end
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
