--!strict
-- Auto Play (BUILD_PLAN P3-06): the planner that plays a match for a player. Pure. It was the balance
-- report's auto-battler (tests/autobattle.luau), which now plays through this module too, so the bot the
-- balance numbers come from and the one players switch on are the same.
--
-- It places its `plan` in order (saving for the next defender), each tower at the free spot that covers the
-- most road for its range (supports go where they buff the most defenders; farms anywhere off the road),
-- then, if the policy allows upgrades, keeps buying the upgrade with the most damage per cash (after a wave
-- that leaked it settles for the best upgrade it can afford instead of saving). It never sells, never
-- retargets and never fires an ability. A player's Auto Play adds an anchor: only spots within
-- `anchorRadius` of it are used. A layout (Logic/LayoutCode) fixes the spots instead of searching.
--
-- The caller applies every decision through `act` (the server through its validated place/upgrade paths,
-- the balance bot straight into TdTowers), so this module never touches the sim itself.

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

local AutoPlay = {}

AutoPlay.SAMPLE_STEP = 1 -- studs between road samples for coverage
AutoPlay.MAX_SPOT_DIST = 9 -- spots farther than this from the road are never considered

export type Spot = { x: number, z: number, dp: number, cov: { [number]: number } }
export type Spots = { samples: { { number } }, cands: { Spot } }
export type Policy = {
	plan: { string },
	upgrades: boolean?,
	maxLevel: number?,
	signature: string?, -- "a" | "b": also buys the level-7 signature on that path
	layout: { { x: number, z: number } }?, -- fixed spots, one per plan entry (LayoutCode)
}
export type Bot = {
	key: string,
	policy: Policy,
	planIndex: number,
	leaking: boolean?,
	anchor: { x: number, z: number }?,
	anchorRadius: number?,
}
-- place(unitId, x, z) -> (ok, err); upgrade(tower, path) -> ok
export type Act = {
	place: (unitId: string, x: number, z: number) -> (boolean, string?),
	upgrade: (tower: any, path: string?) -> boolean,
}

-- Every grid point of the arena close enough to a road to defend it and clear of it, plus road samples to
-- score coverage against. Twin-gate arenas: every road is sampled (a shared stretch counts twice).
-- arena: a Config/Arenas entry; pathHalfWidth: TD.PATH_HALF_WIDTH.
function AutoPlay.spots(arena: any, pathHalfWidth: number): Spots
	local roads = Path.buildAll(arena)
	local samples = {}
	for _, road in roads do
		local d = 0
		while d <= road.length do
			local x, z = Path.position(road, d)
			table.insert(samples, { x, z })
			d += AutoPlay.SAMPLE_STEP
		end
	end
	local cands: { Spot } = {}
	local b = arena.bounds
	for x = b[1], b[3] do
		for z = b[2], b[4] do
			local dp = Path.distanceToAll(roads, x, z)
			if dp >= pathHalfWidth + 0.2 and dp <= AutoPlay.MAX_SPOT_DIST then
				table.insert(cands, { x = x, z = z, dp = dp, cov = {} })
			end
		end
	end
	return { samples = samples, cands = cands }
end

local function coverage(spots: Spots, c: Spot, range: number): number
	local key = math.floor(range * 10 + 0.5)
	local v = c.cov[key]
	if v then
		return v
	end
	local r2 = range * range
	local n = 0
	for _, s in spots.samples do
		local dx, dz = s[1] - c.x, s[2] - c.z
		if dx * dx + dz * dz <= r2 then
			n += 1
		end
	end
	c.cov[key] = n
	return n
end

local function spacingOk(state: any, x: number, z: number, spacing: number): boolean
	for _, t in state.towers do
		if (t.x - x) ^ 2 + (t.z - z) ^ 2 < spacing * spacing then
			return false
		end
	end
	return true
end

-- Best free spot for a unit: most road in range; supports/healers: most damage towers in range; farms:
-- anywhere off the road. With an anchor, only spots within its radius.
function AutoPlay.bestSpot(state: any, spots: Spots, def: any, spacing: number, anchor: { x: number, z: number }?, radius: number?): Spot?
	local lv = def.levels[1]
	local support = lv.buff ~= nil
	local r2 = if anchor and radius then radius * radius else math.huge
	local best, bestScore = nil, -math.huge
	for _, c in spots.cands do
		local near = anchor == nil or (c.x - anchor.x) ^ 2 + (c.z - anchor.z) ^ 2 <= r2
		if near and spacingOk(state, c.x, c.z, spacing) then
			local score
			if support then
				local n = 0
				for _, t in state.towers do
					if t.stats.damage > 0 and (t.x - c.x) ^ 2 + (t.z - c.z) ^ 2 <= lv.range * lv.range then
						n += 1
					end
				end
				score = n * 1000 + coverage(spots, c, lv.range)
			elseif lv.range > 0 then
				score = coverage(spots, c, lv.range) - c.dp * 0.01
			else
				score = -c.dp
			end
			if score > bestScore then
				best, bestScore = c, score
			end
		end
	end
	return best
end

-- Rough damage per second a tower adds at `level` (what a player reads off the upgrade card): splash counts
-- double, shabriyeh/sweep add their average.
function AutoPlay.dps(def: any, level: number): number
	local lv = def.levels[math.min(level, #def.levels)] -- a level-7 signature counts as its last level here
	if lv.damage <= 0 then
		return 0
	end
	local v = lv.damage / lv.cooldown
	if lv.splash then
		v *= 2
	end
	local ab = def.ability
	if ab then
		v += lv.damage * (ab.multiplier - 1) / ab.cooldown * (if ab.kind == "sweep" then 2 else 1)
	end
	return v
end

-- What a tower is worth at `level`: its dps, or for a support its buff on the damage it covers.
local function levelValue(state: any, units: any, t: any, def: any, level: number): number
	local lv = def.levels[math.min(level, #def.levels)]
	if lv.buff then
		local covered = 0
		for _, o in state.towers do
			if o ~= t and (o.x - t.x) ^ 2 + (o.z - t.z) ^ 2 <= lv.range * lv.range then
				covered += AutoPlay.dps(units[o.unitId], o.level)
			end
		end
		return (lv.buff - 1) * covered
	end
	return AutoPlay.dps(def, level)
end

-- One decision round for `bot` (call it every half second or so of game time): places what the plan and
-- the cash allow, then upgrades. units: Config/Units; spacing: TD.TOWER_SPACING.
function AutoPlay.think(bot: Bot, state: any, spots: Spots, units: any, spacing: number, act: Act)
	local p = state.players[bot.key]
	if not p then
		return
	end
	local policy = bot.policy
	-- 1) Place the plan in order, waiting for cash.
	while bot.planIndex <= #policy.plan do
		local unitId = policy.plan[bot.planIndex]
		local def = units[unitId]
		if not def then
			bot.planIndex += 1
			continue
		end
		if p.cash < def.levels[1].cost then
			return
		end
		local fixed = policy.layout and policy.layout[bot.planIndex]
		local spot: { x: number, z: number }? = if fixed then fixed else AutoPlay.bestSpot(state, spots, def, spacing, bot.anchor, bot.anchorRadius)
		if spot then
			local ok, err = act.place(unitId, spot.x, spot.z)
			if not ok and err == "cannot_afford" then
				return
			end
		end
		bot.planIndex += 1
	end
	if not policy.upgrades then
		return
	end
	-- 2) The upgrade with the most damage per cash: saves for it while the gate holds, settles for the best
	-- affordable one after a wave that leaked. A level-7 signature (policy.signature = its path) is one more
	-- candidate, valued as a 15 % gain on the last level (its paths add up to +35 % damage or one effect, D-047).
	local function nextStep(t: any, def: any): (number?, number, string?)
		local nextLv = def.levels[t.level + 1]
		if nextLv and (policy.maxLevel == nil or t.level < policy.maxLevel) then
			return nextLv.cost, (levelValue(state, units, t, def, t.level + 1) - levelValue(state, units, t, def, t.level)) / nextLv.cost, nil
		end
		local sig = policy.signature and def.signature
		if sig and t.level == #def.levels then
			local cost = sig[policy.signature].cost
			return cost, 0.15 * levelValue(state, units, t, def, t.level) / cost, policy.signature
		end
		return nil, 0, nil
	end
	while true do
		local best, bestValue, bestCost, bestPath = nil, -1, 0, nil
		local afford, affordValue, affordPath = nil, -1, nil
		for _, t in state.towers do
			if t.owner == bot.key then
				local def = units[t.unitId]
				local cost, value, path = nextStep(t, def)
				if cost then
					if value > bestValue then
						best, bestValue, bestCost, bestPath = t, value, cost, path
					end
					if cost <= p.cash and value > affordValue then
						afford, affordValue, affordPath = t, value, path
					end
				end
			end
		end
		local pick, path = nil, nil
		if best and bestCost <= p.cash then
			pick, path = best, bestPath
		elseif bot.leaking then
			pick, path = afford, affordPath
		end
		if not pick or not act.upgrade(pick, path) then
			return
		end
	end
end

-- A player's plan from their loadout: one of each unit, cheapest to place first (ties in slot order) so it starts
-- building at once, then more copies round-robin in that order up to each unit's maxPlaced, never more than
-- `towerCap` towers in all.
function AutoPlay.planFor(loadout: { string }, units: any, towerCap: number): { string }
	local order = {}
	for i, id in loadout do
		if units[id] then
			table.insert(order, { id = id, slot = i, cost = units[id].levels[1].cost })
		end
	end
	table.sort(order, function(a, b)
		if a.cost ~= b.cost then
			return a.cost < b.cost
		end
		return a.slot < b.slot
	end)
	local plan = {}
	local placed: { [string]: number } = {}
	local added = true
	while added and #plan < towerCap do
		added = false
		for _, o in order do
			local id = o.id
			local def = units[id]
			local cap = if def then def.maxPlaced or towerCap else 0
			if #plan < towerCap and (placed[id] or 0) < cap then
				table.insert(plan, id)
				placed[id] = (placed[id] or 0) + 1
				added = true
			end
		end
	end
	return plan
end

-- What is left of a plan once the towers `key` already has are counted: one plan entry per tower of that unit,
-- earliest first. Switching Auto Play on again, or after placing by hand, continues instead of starting over.
function AutoPlay.remaining(plan: { string }, towers: { any }, key: string): { string }
	local have: { [string]: number } = {}
	for _, t in towers do
		if t.owner == key then
			have[t.unitId] = (have[t.unitId] or 0) + 1
		end
	end
	local out = {}
	for _, id in plan do
		if (have[id] or 0) > 0 then
			have[id] -= 1
		else
			table.insert(out, id)
		end
	end
	return out
end

return AutoPlay
