--!nocheck
-- Auto-battler: plays a whole tower-defense match headlessly with a scripted player, on the real
-- config and the real simulation (TdSim/TdTowers/WaveLogic at TD.TICK). Used by the balance report
-- (tests/balance.luau) and by the balance assertions in tests/td.spec.luau.
--
-- The bot is a plausible, not optimal, player: it places its `plan` in order (saving for the next
-- defender), each tower at the free spot that covers the most road for its range (supports go where
-- they buff the most defenders), then — if the policy allows upgrades — keeps buying the upgrade with
-- the most damage per cash
-- (after a wave that leaked it settles for the best upgrade it can afford instead of saving).
-- It never sells, never retargets and skips every countdown (no skip bonus: the sim has none).
-- Parties (opts.party = N) are N such bots in one match, each with its own cash and plan, scaled
-- exactly as MatchService.create scales a real party (TD.PARTY_HP / PARTY_BOSS_HP / PARTY_CASH).
--
-- Requires _G.LogicRequire to be installed (tests/run.luau and tests/balance.luau do this).

local L = _G.LogicRequire
local TdSim = L("TdSim")
local TdTowers = L("TdTowers")
local Traits = require("../src/shared/Config/Traits")
local WaveLogic = L("WaveLogic")
local Path = L("Path")

local TD = require("../src/shared/Config/TD")
local Units = require("../src/shared/Config/Units")
local Enemies = require("../src/shared/Config/Enemies")
local Waves = require("../src/shared/Config/Waves")
local Arenas = require("../src/shared/Config/Arenas")
local Modes = require("../src/shared/Config/Modes")

local AutoBattle = {}

-- Loadouts. `plan` = towers in placement order (unit ids may repeat up to maxPlaced).
AutoBattle.POLICIES = {
	starter = {
		label = "New player: starter unit only + upgrades",
		plan = { "walad", "walad", "walad", "walad", "walad", "walad", "walad", "walad" },
		upgrades = true,
	},
	re6 = {
		label = "6 Rare/Epic, no upgrades",
		plan = { "walad", "hallaq", "natour", "qabaday", "haddad", "mukhtar" },
		upgrades = false,
	},
	re4up = {
		label = "4 Rare/Epic + upgrades",
		plan = { "walad", "hallaq", "natour", "qabaday" },
		upgrades = true,
	},
	re6up = {
		label = "6 Rare/Epic + upgrades",
		plan = { "walad", "hallaq", "natour", "qabaday", "haddad", "mukhtar" },
		upgrades = true,
	},
	re10up = {
		label = "10 Rare/Epic + upgrades",
		plan = { "walad", "hallaq", "natour", "qabaday", "hallaq", "haddad", "mukhtar", "qabaday", "hallaq", "natour" },
		upgrades = true,
	},
	leg6 = {
		label = "6 with a Legendary, no upgrades",
		plan = { "walad", "hallaq", "natour", "zaim", "qabaday", "mukhtar" },
		upgrades = false,
	},
	leg10up = {
		label = "10 with Legendaries + upgrades",
		plan = { "walad", "hallaq", "hallaq", "zaim", "qabaday", "pahlawan", "mukhtar", "zaim", "pahlawan", "mukhtar" },
		upgrades = true,
	},
	myth12up = {
		label = "12 Mythic/Legendary + upgrades",
		plan = { "hallaq", "hallaq", "hallaq", "zaim", "zaim_akbar", "arada", "mukhtar", "pahlawan", "zaim", "pahlawan", "mukhtar", "hallaq" },
		upgrades = true,
	},
	whale = {
		label = "16 Mythic/Legendary, 5 stars, za'im's-blood traits + upgrades (7 slots)",
		plan = {
			"hallaq", "hallaq", "hallaq", "zaim", "zaim_akbar", "arada", "mukhtar", "pahlawan", "zaim", "pahlawan",
			"mukhtar", "qabaday", "qabaday", "qabaday", "qabaday", "hallaq",
		},
		upgrades = true,
		stars = 5,
		trait = "zaim",
		slots = 7, -- Extra Slot pass
	},
}
AutoBattle.POLICY_ORDER = { "re6", "re4up", "re6up", "re10up", "leg6", "leg10up", "myth12up", "whale" }

local SAMPLE_STEP = 1 -- studs between road samples for coverage
local MAX_SPOT_DIST = 9 -- spots farther than this from the road are never considered
local THINK_EVERY = 0.5 -- seconds of game time between bot decisions

local spotCache = {}
local levelValue

local function spotsFor(arenaId: string, rules)
	if spotCache[arenaId] then
		return spotCache[arenaId]
	end
	local arena = Arenas[arenaId]
	local path = Path.build(arena.path)
	local samples = {}
	local d = 0
	while d <= path.length do
		local x, z = Path.position(path, d)
		table.insert(samples, { x, z })
		d += SAMPLE_STEP
	end
	local cands = {}
	local b = arena.bounds
	for x = b[1], b[3] do
		for z = b[2], b[4] do
			local dp = Path.distanceTo(path, x, z)
			if dp >= rules.pathHalfWidth + 0.2 and dp <= MAX_SPOT_DIST then
				table.insert(cands, { x = x, z = z, dp = dp, cov = {} })
			end
		end
	end
	local res = { samples = samples, cands = cands }
	spotCache[arenaId] = res
	return res
end

local function coverage(spots, c, range: number): number
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

local function spacingOk(state, x: number, z: number, spacing: number): boolean
	for _, t in state.towers do
		if (t.x - x) ^ 2 + (t.z - z) ^ 2 < spacing * spacing then
			return false
		end
	end
	return true
end

-- Best free spot for a unit: most road in range; supports/healers: most damage towers in range.
local function bestSpot(state, spots, def, rules)
	local lv = def.levels[1]
	local support = lv.buff ~= nil
	local best, bestScore = nil, -math.huge
	for _, c in spots.cands do
		if spacingOk(state, c.x, c.z, rules.spacing) then
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
				score = -c.dp -- farms: anywhere off the road
			end
			if score > bestScore then
				best, bestScore = c, score
			end
		end
	end
	return best
end

local function rulesFor(arenaId: string)
	return {
		bounds = Arenas[arenaId].bounds,
		pathHalfWidth = TD.PATH_HALF_WIDTH,
		spacing = TD.TOWER_SPACING,
		towerCap = TD.TOWER_CAP,
		sellRefund = TD.SELL_REFUND,
		starBonus = TD.STAR_BONUS,
	}
end

-- Rough damage per second a tower adds at `level` (what a player reads off the upgrade card):
-- splash counts double, shabriyeh/sweep add their average, supports are worth their buff on the
-- damage towers they cover.
local function dps(def, level: number): number
	local lv = def.levels[level]
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

levelValue = function(state, t, def, level: number): number
	local lv = def.levels[level]
	if lv.buff then
		local covered = 0
		for _, o in state.towers do
			if o ~= t and (o.x - t.x) ^ 2 + (o.z - t.z) ^ 2 <= lv.range * lv.range then
				covered += dps(Units[o.unitId], o.level)
			end
		end
		return (lv.buff - 1) * covered
	end
	return dps(def, level)
end

local function think(bot, state, spots, rules)
	local p = state.players[bot.key]
	local policy = bot.policy
	-- 1) Place the plan in order, waiting for cash.
	while bot.planIndex <= #policy.plan do
		local unitId = policy.plan[bot.planIndex]
		local def = Units[unitId]
		if p.cash < def.levels[1].cost then
			return
		end
		local spot = bestSpot(state, spots, def, rules)
		if spot then
			local ok, err = TdTowers.place(state, bot.key, unitId, def, spot.x, spot.z, policy.stars or 0, policy.trait and Traits.traits[policy.trait], rules)
			if not ok and err == "cannot_afford" then
				return
			end
		end
		bot.planIndex += 1
	end
	if not policy.upgrades then
		return
	end
	-- 2) The upgrade with the most damage per cash: saves for it while the gate holds, settles for
	-- the best affordable one after a wave that leaked.
	while true do
		local best, bestValue = nil, -1
		local afford, affordValue = nil, -1
		for _, t in state.towers do
			if t.owner == bot.key then
				local def = Units[t.unitId]
				local nextLv = def.levels[t.level + 1]
				if nextLv and (policy.maxLevel == nil or t.level < policy.maxLevel) then
					local value = (levelValue(state, t, def, t.level + 1) - levelValue(state, t, def, t.level)) / nextLv.cost
					if value > bestValue then
						best, bestValue = t, value
					end
					if nextLv.cost <= p.cash and value > affordValue then
						afford, affordValue = t, value
					end
				end
			end
		end
		local pick = if best and Units[best.unitId].levels[best.level + 1].cost <= p.cash then best elseif bot.leaking then afford else nil
		if not pick then
			return
		end
		TdTowers.upgrade(state, bot.key, pick.id, Units[pick.unitId], rules)
	end
end

-- { hp, boss, cash } scaling for a party of `party` players (as MatchService.create applies it).
function AutoBattle.partyScale(party: number)
	return WaveLogic.partyScale(TD, party)
end

local function resolvePolicy(policyId)
	local policy = if type(policyId) == "table" then policyId else AutoBattle.POLICIES[policyId]
	assert(policy, "bad policy " .. tostring(policyId))
	local kinds = {}
	for _, id in policy.plan do
		assert(Units[id], "unknown unit " .. id)
		kinds[id] = true
	end
	local nKinds = 0
	for _ in kinds do
		nKinds += 1
	end
	assert(nKinds <= (policy.slots or TD.LOADOUT_SLOTS), "plan uses more unit types than the loadout has slots")
	return policy
end

-- Plays one match. modeId: "ep1" | "ep2" | "ep3" | "infinite". Returns { won, wavesCleared, waves = { per-wave rows } }.
-- policyId: a POLICIES key or a policy table, or a list of them (one per player).
-- opts.maxWaves caps endless runs (default 150); opts.gate overrides the gate HP (debug);
-- opts.party = number of players (default: the length of a policy list, else 1); every player
-- without its own entry plays the first policy. Rows sum cash / spent over the party.
function AutoBattle.play(modeId: string, difficulty: string, policyId: any, opts: any?)
	opts = opts or {}
	local mode = Modes[modeId]
	local diff = TD.DIFFICULTIES[difficulty]
	assert(mode and diff, "bad mode/difficulty")
	local list = if type(policyId) == "table" and policyId.plan == nil then policyId else { policyId }
	local party = opts.party or #list
	assert(party >= 1 and party <= TD.MAX_PLAYERS, "party must be 1.." .. TD.MAX_PLAYERS)
	local bots = {}
	local keys = {}
	for i = 1, party do
		local key = if party == 1 then "bot" else "bot" .. i
		table.insert(keys, key)
		table.insert(bots, { key = key, policy = resolvePolicy(list[i] or list[1]), planIndex = 1 })
	end
	local scale = WaveLogic.partyScale(TD, party)
	local episode = if mode.kind == "story" then Waves.episodes[mode.episode] else nil
	local total = if episode then episode.waves else nil
	local arena = Arenas[mode.arena]
	local rules = rulesFor(mode.arena)
	local spots = spotsFor(mode.arena, rules)
	local state = TdSim.new(arena.path, keys, math.floor(TD.START_CASH * scale.cash + 0.5), opts.gate or diff.gate, total, TD.PREP_SECONDS, {
		between = TD.BETWEEN_WAVES,
		waveBonusBase = TD.WAVE_BONUS_BASE * scale.cash,
		waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE * scale.cash,
		rewardMul = diff.reward,
		enemies = Enemies,
		stunChainMax = TD.STUN_CHAIN_MAX,
		stunImmunity = TD.STUN_IMMUNITY,
	}, function(wave)
		if episode then
			return WaveLogic.story(episode, wave, diff, scale)
		end
		return WaveLogic.infinite(Waves.infinite, wave, diff, scale)
	end)
	local turn = 0
	local maxWaves = opts.maxWaves or 150
	local rows = {}
	local cur = nil
	local bosses = {}
	local kinds = {}
	local nextThink = 0
	local dt = TD.TICK
	-- Hard stop so a stalled match cannot hang the report (≈ 10 min of game time per wave).
	local guard = 0
	while state.phase ~= "won" and state.phase ~= "lost" do
		if state.time >= nextThink then
			-- Rotate who decides first so no bot always gets the best spots.
			turn += 1
			for i = 0, party - 1 do
				think(bots[(turn + i) % party + 1], state, spots, rules)
			end
			nextThink = state.time + THINK_EVERY
		end
		if state.phase == "prep" then
			TdSim.skipCountdown(state)
		end
		for _, e in TdSim.step(state, dt) do
			if e.type == "waveStart" then
				cur = { wave = e.wave, count = e.count, boss = e.boss, leaked = 0, gateLost = 0, bossLeaked = false, leakedBy = {} }
				guard = 0
			elseif e.type == "spawn" then
				kinds[e.id] = e.enemyId
			end
			if e.type == "spawn" and e.boss then
				for _, en in state.enemies do
					if en.id == e.id then
						bosses[e.id] = en
					end
				end
			elseif e.type == "reached" and cur then
				cur.leaked += 1
				cur.gateLost += e.damage
				local kind = kinds[e.id] or "?"
				cur.leakedBy[kind] = (cur.leakedBy[kind] or 0) + 1
				local boss = bosses[e.id]
				if boss then
					cur.bossLeaked = true
					cur.bossHpLeft = boss.hp / boss.maxHp
				end
			elseif e.type == "waveEnd" or e.type == "lost" then
				if cur then
					cur.gateHp = state.gateHp
					cur.cash, cur.spent = 0, 0
					for _, bot in bots do
						bot.leaking = cur.leaked > 0
						local p = state.players[bot.key]
						cur.cash += p.cash
						cur.spent += p.spent
					end
					cur.towers = #state.towers
					local lv = 0
					for _, t in state.towers do
						lv += t.level
					end
					cur.levels = lv
					cur.result = if e.type == "lost" then "LOST" else "ok"
					table.insert(rows, cur)
					cur = nil
				end
			end
		end
		guard += 1
		if guard > 12000 then
			error(string.format("%s/%s/%s stalled on wave %d", modeId, difficulty, tostring(policyId), state.wave))
		end
		if not total and state.wavesCleared >= maxWaves then
			break
		end
	end
	return {
		won = state.phase == "won",
		lost = state.phase == "lost",
		wavesCleared = state.wavesCleared,
		gateHp = state.gateHp,
		gateMax = state.gateMax,
		waves = rows,
		totalWaves = total,
		party = party,
		scale = scale,
	}
end

return AutoBattle
