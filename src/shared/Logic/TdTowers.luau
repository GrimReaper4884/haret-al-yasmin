--!strict
-- Placing, upgrading, selling and retargeting towers inside a TdSim state. Pure. The server
-- validates the player's loadout/ownership before calling these; they validate everything
-- about the match itself (cash, caps, spacing, path clearance, bounds).

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Path = sibling("Path")
local UnitLogic = sibling("UnitLogic")

export type Rules = {
	bounds: { number }, -- x0, z0, x1, z1
	pathHalfWidth: number,
	spacing: number,
	towerCap: number,
	sellRefund: number,
	starBonus: number,
	traitCaps: any?, -- Config/Traits.caps: UnitLogic.stats clamps trait multipliers to these
}

local TdTowers = {}

local function isFinite(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function TdTowers.countOwned(state: any, owner: string, unitId: string?): number
	local n = 0
	for _, t in state.towers do
		if t.owner == owner and (unitId == nil or t.unitId == unitId) then
			n += 1
		end
	end
	return n
end

-- trait: the owner's (merged) trait for this unit: twin raises the unit cap, miser lowers the price.
function TdTowers.canPlace(state: any, owner: string, unitId: string, def: any, x: any, z: any, rules: Rules, trait: any?): (boolean, string?)
	local p = state.players[owner]
	if not p then
		return false, "not_in_match"
	end
	if state.phase == "won" or state.phase == "lost" then
		return false, "match_over"
	end
	if not isFinite(x) or not isFinite(z) then
		return false, "bad_position"
	end
	local b = rules.bounds
	if x < b[1] or x > b[3] or z < b[2] or z > b[4] then
		return false, "out_of_bounds"
	end
	if Path.distanceToAll(state.paths or { state.path }, x, z) < rules.pathHalfWidth then
		return false, "on_path"
	end
	for _, t in state.towers do
		if (t.x - x) ^ 2 + (t.z - z) ^ 2 < rules.spacing * rules.spacing then
			return false, "too_close"
		end
	end
	if TdTowers.countOwned(state, owner) >= rules.towerCap then
		return false, "tower_cap"
	end
	if TdTowers.countOwned(state, owner, unitId) >= def.maxPlaced + (if trait and trait.maxPlaced then trait.maxPlaced else 0) then
		return false, "unit_cap"
	end
	-- A party-wide cap (the genre's farm-link limit, LP-E01): this many in the whole match, whoever owns them
	local partyCap = def.maxPerParty
	if partyCap then
		local n = 0
		for _, t in state.towers do
			if t.unitId == unitId and not t.ally then
				n += 1
			end
		end
		if n >= partyCap then
			return false, "party_cap"
		end
	end
	local cost = UnitLogic.costFor(def.levels[1].cost, trait)
	if p.cash < cost then
		return false, "cannot_afford"
	end
	return true, nil
end

-- Places a tower. stars/trait/bead come from the owner's collection (validated by the caller).
function TdTowers.place(state: any, owner: string, unitId: string, def: any, x: number, z: number, stars: number, trait: any?, rules: Rules, bead: any?): (boolean, string?, any?)
	local ok, err = TdTowers.canPlace(state, owner, unitId, def, x, z, rules, trait)
	if not ok then
		return false, err, nil
	end
	local cost = UnitLogic.costFor(def.levels[1].cost, trait)
	local p = state.players[owner]
	p.cash -= cost
	p.spent += cost
	local tower = {
		id = state.nextId,
		owner = owner,
		unitId = unitId,
		level = 1,
		x = x,
		z = z,
		stats = UnitLogic.stats(def, 1, stars, trait, rules.starBonus, rules.traitCaps, nil, bead),
		nextAt = 0,
		abilityAt = 0,
		targeting = "first",
		invested = cost,
		kills = 0,
		stars = stars,
		trait = trait,
		bead = bead,
	}
	state.nextId += 1
	table.insert(state.towers, tower)
	state.buffsDirty = true -- supports around it change (TdSim buff cache, LP-A02)
	return true, nil, tower
end

local function find(state: any, towerId: any): (any?, number)
	if type(towerId) ~= "number" then
		return nil, 0
	end
	for i, t in state.towers do
		if t.id == towerId then
			return t, i
		end
	end
	return nil, 0
end

-- The owner taps a defender's ultimate. It fires on that defender's next attack (it still needs a
-- target). Returns ok, err ("not_yours" | "no_ability" | "not_ready" | "match_over").
function TdTowers.useAbility(state: any, owner: string, towerId: any): (boolean, string?)
	local t = find(state, towerId)
	if not t or t.ally or t.owner ~= owner then
		return false, "not_yours"
	end
	if state.phase == "won" or state.phase == "lost" then
		return false, "match_over"
	end
	if not t.stats.ability then
		return false, "no_ability"
	end
	if state.time < t.abilityAt then
		return false, "not_ready"
	end
	t.abilityQueued = true
	return true, nil
end

-- path: only for the level-7 signature (the last level → 7): "a" or "b", required there and
-- refused anywhere else ("bad_path"). A signature is bought once ("max_level" after).
function TdTowers.upgrade(state: any, owner: string, towerId: any, def: any, rules: Rules, path: any?): (boolean, string?, any?)
	local t = find(state, towerId)
	if not t or t.ally or t.owner ~= owner then
		return false, "not_yours", nil
	end
	if state.phase == "won" or state.phase == "lost" then
		return false, "match_over", nil
	end
	local nextLevel = t.level + 1
	local lv = def.levels[nextLevel]
	local p = state.players[owner]
	if not lv then
		local sig = def.signature
		if not sig or t.level ~= #def.levels then
			return false, "max_level", nil
		end
		if path ~= "a" and path ~= "b" then
			return false, "bad_path", nil
		end
		local cost = UnitLogic.costFor(sig[path].cost, t.trait)
		if p.cash < cost then
			return false, "cannot_afford", nil
		end
		p.cash -= cost
		p.spent += cost
		t.invested += cost
		t.level = nextLevel
		t.path = path
		t.stats = UnitLogic.stats(def, nextLevel, t.stars, t.trait, rules.starBonus, rules.traitCaps, path, t.bead)
		state.buffsDirty = true
		return true, nil, t
	end
	if path ~= nil then
		return false, "bad_path", nil
	end
	local cost = UnitLogic.costFor(lv.cost, t.trait)
	if p.cash < cost then
		return false, "cannot_afford", nil
	end
	p.cash -= cost
	p.spent += cost
	t.invested += cost
	t.level = nextLevel
	t.stats = UnitLogic.stats(def, nextLevel, t.stars, t.trait, rules.starBonus, rules.traitCaps, nil, t.bead)
	state.buffsDirty = true
	return true, nil, t
end

function TdTowers.sell(state: any, owner: string, towerId: any, rules: Rules): (boolean, string?, number?)
	local t, i = find(state, towerId)
	if not t or t.ally or t.owner ~= owner then
		return false, "not_yours", nil
	end
	local refund = math.floor(t.invested * rules.sellRefund)
	state.players[owner].cash += refund
	table.remove(state.towers, i)
	state.buffsDirty = true
	return true, nil, refund
end

-- A story ally (STORY_PLAN §5.2: Al-Adashari turns in Episode 8 and guards Episode 9): a defender
-- that belongs to no player (owner ALLY_OWNER, which is never a player key), pays nobody, and is
-- refused by every remote (sell, upgrade, targeting, ability: "not_yours"). `shield` is gate
-- damage it absorbs before the gate takes any (added to state.allyShield). No placement rules:
-- the script puts it where the arena says.
TdTowers.ALLY_OWNER = "@ally"

function TdTowers.addAlly(state: any, unitId: string, def: any, level: number, x: number, z: number, rules: Rules, shield: number?, path: string?): any
	local lv = math.clamp(level, 1, #def.levels)
	local tower = {
		id = state.nextId,
		owner = TdTowers.ALLY_OWNER,
		unitId = unitId,
		level = lv,
		x = x,
		z = z,
		stats = UnitLogic.stats(def, lv, 0, nil, rules.starBonus, rules.traitCaps, path),
		nextAt = 0,
		abilityAt = 0,
		targeting = "first",
		invested = 0,
		kills = 0,
		stars = 0,
		ally = true,
	}
	state.nextId += 1
	table.insert(state.towers, tower)
	state.buffsDirty = true -- supports around it change (TdSim buff cache, LP-A02)
	state.allyShield = (state.allyShield or 0) + (shield or 0)
	return tower
end

-- Runs an episode's scripted beat for `wave`, if any (Config/Waves episodes[id].script, pure data):
-- { kind = "ally", unit, level, shield?, path? } puts the ally at `spot` ({x, z}, the arena's
-- allySpot). Returns the new ally tower or nil. Called by MatchService and the auto-battler when
-- a wave starts.
function TdTowers.runScript(state: any, script: any?, wave: number, units: { [string]: any }, rules: Rules, spot: { number }?): any?
	local entry = script and script[wave]
	if not entry or entry.kind ~= "ally" or not spot then
		return nil
	end
	local def = units[entry.unit]
	if not def then
		return nil
	end
	return TdTowers.addAlly(state, entry.unit, def, entry.level or 1, spot[1], spot[2], rules, entry.shield, entry.path)
end

local TARGETING = { first = true, last = true, strong = true, close = true }

-- The owner switches one defender's auto ultimate on or off (LP-B01); it overrides the owner's
-- setting for that defender. Returns ok, err ("not_yours" | "bad_request" | "no_ability" | "match_over").
function TdTowers.setAutoAbility(state: any, owner: string, towerId: any, on: any): (boolean, string?)
	local t = find(state, towerId)
	if not t or t.ally or t.owner ~= owner then
		return false, "not_yours"
	end
	if type(on) ~= "boolean" then
		return false, "bad_request"
	end
	if state.phase == "won" or state.phase == "lost" then
		return false, "match_over"
	end
	if not t.stats.ability then
		return false, "no_ability"
	end
	t.autoAbility = on
	return true, nil
end

function TdTowers.setTargeting(state: any, owner: string, towerId: any, mode: any): (boolean, string?)
	local t = find(state, towerId)
	if not t or t.ally or t.owner ~= owner then
		return false, "not_yours"
	end
	if type(mode) ~= "string" or not TARGETING[mode] then
		return false, "bad_request"
	end
	t.targeting = mode
	return true, nil
end

return TdTowers
