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

function TdTowers.canPlace(state: any, owner: string, unitId: string, def: any, x: any, z: any, rules: Rules): (boolean, string?)
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
	if Path.distanceTo(state.path, x, z) < rules.pathHalfWidth then
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
	if TdTowers.countOwned(state, owner, unitId) >= def.maxPlaced then
		return false, "unit_cap"
	end
	local cost = def.levels[1].cost
	if p.cash < cost then
		return false, "cannot_afford"
	end
	return true, nil
end

-- Places a tower. stars/trait come from the owner's collection (validated by the caller).
function TdTowers.place(state: any, owner: string, unitId: string, def: any, x: number, z: number, stars: number, trait: any?, rules: Rules): (boolean, string?, any?)
	local ok, err = TdTowers.canPlace(state, owner, unitId, def, x, z, rules)
	if not ok then
		return false, err, nil
	end
	local cost = def.levels[1].cost
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
		stats = UnitLogic.stats(def, 1, stars, trait, rules.starBonus),
		nextAt = 0,
		abilityAt = 0,
		targeting = "first",
		invested = cost,
		kills = 0,
		stars = stars,
		trait = trait,
	}
	state.nextId += 1
	table.insert(state.towers, tower)
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
	if not t or t.owner ~= owner then
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

function TdTowers.upgrade(state: any, owner: string, towerId: any, def: any, rules: Rules): (boolean, string?, any?)
	local t = find(state, towerId)
	if not t or t.owner ~= owner then
		return false, "not_yours", nil
	end
	if state.phase == "won" or state.phase == "lost" then
		return false, "match_over", nil
	end
	local nextLevel = t.level + 1
	local lv = def.levels[nextLevel]
	if not lv then
		return false, "max_level", nil
	end
	local p = state.players[owner]
	if p.cash < lv.cost then
		return false, "cannot_afford", nil
	end
	p.cash -= lv.cost
	p.spent += lv.cost
	t.invested += lv.cost
	t.level = nextLevel
	t.stats = UnitLogic.stats(def, nextLevel, t.stars, t.trait, rules.starBonus)
	return true, nil, t
end

function TdTowers.sell(state: any, owner: string, towerId: any, rules: Rules): (boolean, string?, number?)
	local t, i = find(state, towerId)
	if not t or t.owner ~= owner then
		return false, "not_yours", nil
	end
	local refund = math.floor(t.invested * rules.sellRefund)
	state.players[owner].cash += refund
	table.remove(state.towers, i)
	return true, nil, refund
end

local TARGETING = { first = true, last = true, strong = true, close = true }

function TdTowers.setTargeting(state: any, owner: string, towerId: any, mode: any): (boolean, string?)
	local t = find(state, towerId)
	if not t or t.owner ~= owner then
		return false, "not_yours"
	end
	if type(mode) ~= "string" or not TARGETING[mode] then
		return false, "bad_request"
	end
	t.targeting = mode
	return true, nil
end

return TdTowers
