--!nocheck
-- Auto-battler: plays a whole tower-defense match headlessly with a scripted player, on the real
-- config and the real simulation (TdSim/TdTowers/WaveLogic at TD.TICK). Used by the balance report
-- (tests/balance.luau) and by the balance assertions in tests/td.spec.luau.
--
-- The bot is a plausible, not optimal, player: the planner is Logic/AutoPlay (P3-06), the same one a
-- player's Auto Play uses; see it for the rules. Here the bot also skips every countdown (no skip bonus:
-- the sim has none) and places with its policy's stars, traits and beads.
-- Parties (opts.party = N) are N such bots in one match, each with its own cash and plan, scaled
-- exactly as MatchService.create scales a real party (TD.PARTY_HP / PARTY_BOSS_HP / PARTY_CASH).
--
-- Requires _G.LogicRequire to be installed (tests/run.luau and tests/balance.luau do this).

local L = _G.LogicRequire
local TdSim = L("TdSim")
local TdTowers = L("TdTowers")
local Traits = require("../src/shared/Config/Traits")
local Beads = require("../src/shared/Config/Beads")
local UnitLogic = L("UnitLogic")
local WaveLogic = L("WaveLogic")
local AutoPlay = L("AutoPlay")

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
	-- LP-E01 (LOOK_AND_PLAY_PLAN §7.3): re10up with two merchants and two coffee-house keepers first.
	-- The farms must not lift a Rare/Epic loadout into cells above its tier.
	["re10up+farm"] = {
		label = "10 Rare/Epic + 2 merchants + 2 coffee keepers + upgrades (6 unit types)",
		plan = { "tajir", "qahwaji", "hallaq", "natour", "qabaday", "tajir", "qahwaji", "hallaq", "haddad", "qabaday", "hallaq", "natour", "haddad", "qabaday" },
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
	-- Season Story 1 power steps (STORY_PLAN §5.3); AutoBattle.adapt brings lanterns or water when an
	-- episode asks for them.
	["leg10up+sig"] = {
		label = "10 with Legendaries + upgrades + level-7 signatures (path a)",
		plan = { "walad", "hallaq", "hallaq", "zaim", "qabaday", "pahlawan", "mukhtar", "zaim", "pahlawan", "mukhtar" },
		upgrades = true,
		signature = "a",
	},
	myth12up = {
		label = "12 Mythic/Legendary + upgrades",
		plan = { "hallaq", "hallaq", "hallaq", "zaim", "zaim_akbar", "arada", "mukhtar", "pahlawan", "zaim", "pahlawan", "mukhtar", "hallaq" },
		upgrades = true,
	},
	["myth12up+beads"] = {
		label = "12 Mythic/Legendary + upgrades + beads in 2 of 3 slots (cooldown, range)",
		plan = { "hallaq", "hallaq", "hallaq", "zaim", "zaim_akbar", "arada", "mukhtar", "pahlawan", "zaim", "pahlawan", "mukhtar", "hallaq" },
		upgrades = true,
		beads = { "cooldown", "range" },
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
-- whale2: the whale with traits v2 (za'im's blood + hawk), beads and signatures.
AutoBattle.POLICIES.whale2 = {
	label = "16 Mythic/Legendary, 5 stars, two traits, beads, signatures + upgrades (7 slots)",
	plan = {
		"hallaq", "hallaq", "hallaq", "zaim", "zaim_akbar", "arada", "mukhtar", "pahlawan", "zaim", "pahlawan",
		"mukhtar", "qabaday", "qabaday", "qabaday", "qabaday", "hallaq",
	},
	upgrades = true,
	stars = 5,
	trait = "zaim",
	trait2 = "hawk",
	beads = { "cooldown", "range" },
	signature = "a",
	slots = 7,
}
AutoBattle.POLICY_ORDER = { "re6", "re4up", "re6up", "re10up", "re10up+farm", "leg6", "leg10up", "leg10up+sig", "myth12up", "myth12up+beads", "whale", "whale2" }

local THINK_EVERY = 0.5 -- seconds of game time between bot decisions

local spotCache = {}

local function spotsFor(arenaId: string, rules)
	if not spotCache[arenaId] then
		spotCache[arenaId] = AutoPlay.spots(Arenas[arenaId], rules.pathHalfWidth)
	end
	return spotCache[arenaId]
end

local function rulesFor(arenaId: string)
	return {
		bounds = Arenas[arenaId].bounds,
		pathHalfWidth = TD.PATH_HALF_WIDTH,
		spacing = TD.TOWER_SPACING,
		towerCap = TD.TOWER_CAP,
		sellRefund = TD.SELL_REFUND,
		starBonus = TD.STAR_BONUS,
		traitCaps = Traits.caps,
	}
end

-- One decision round: AutoPlay decides, the bot applies it straight into the sim with its policy's
-- stars, trait(s) and beads.
local function think(bot, state, spots, rules)
	local policy = bot.policy
	AutoPlay.think(bot, state, spots, Units, rules.spacing, {
		place = function(unitId, x, z)
			local def = Units[unitId]
			-- Beads: the policy's kinds where this unit takes them, else its first allowed kind.
			local bead = nil
			if policy.beads then
				local allowed = UnitLogic.beadKinds(def, Beads)
				local slots = {}
				for _, k in policy.beads do
					table.insert(slots, if table.find(allowed, k) then k else allowed[1])
				end
				bead = UnitLogic.beadBonus(slots, Beads)
			end
			local trait = policy.trait and Traits.traits[policy.trait]
			if policy.trait2 then
				trait = UnitLogic.combineTraits(trait, Traits.traits[policy.trait2])
			end
			local ok, err = TdTowers.place(state, bot.key, unitId, def, x, z, policy.stars or 0, trait, rules, bead)
			return ok, err
		end,
		upgrade = function(tower, path)
			return (TdTowers.upgrade(state, bot.key, tower.id, Units[tower.unitId], rules, path))
		end,
	})
end

-- { hp, boss, cash } scaling for a party of `party` players (as MatchService.create applies it).
function AutoBattle.partyScale(party: number)
	return WaveLogic.partyScale(TD, party)
end

-- A sensible player brings what an episode asks for (STORY_PLAN §5.3: "needs 2 revealers", "needs a
-- douser") and pays for it with a loadout slot: the unit type the plan uses least (after the opener;
-- ties go to the later one) gives its towers to the newcomer, whose first `copies` go down right after
-- the opener. Disguised attackers bring two watchmen, burning ones Fawza. Stock episodes 1–3 are
-- never touched.
local function swapIn(plan, unitId: string, copies: number)
	local count = {}
	for i, id in plan do
		if i > 1 then
			count[id] = (count[id] or 0) + 1
		end
	end
	local drop, least = nil, math.huge
	for i, id in plan do
		if i > 1 and id ~= unitId and count[id] <= least then
			drop, least = id, count[id]
		end
	end
	local out = {}
	for _, id in plan do
		if id ~= drop then
			table.insert(out, id)
		end
	end
	for c = 1, math.max(copies, least) do
		table.insert(out, if c <= copies then 1 + c else #out + 1, unitId)
	end
	return out
end

function AutoBattle.adapt(policy, episode)
	if not episode then
		return policy
	end
	local disguised, burning = false, false
	for _, entry in episode.pool do
		local def = Enemies[entry.enemy]
		disguised = disguised or (def and def.disguised == true)
		burning = burning or (def and def.burn ~= nil)
	end
	for _, boss in episode.bosses do
		local def = Enemies[boss]
		disguised = disguised or (def and def.disguised == true)
		burning = burning or (def and def.burn ~= nil)
	end
	local lit, wet = false, false
	for _, id in policy.plan do
		lit = lit or Units[id].revealsStealth == true
		wet = wet or Units[id].douse ~= nil
	end
	if (not disguised or lit) and (not burning or wet) then
		return policy
	end
	local plan = policy.plan
	if disguised and not lit then
		plan = swapIn(plan, "natour", 2)
	end
	if burning and not wet then
		plan = swapIn(plan, "saqqa", 1)
	end
	local adapted = table.clone(policy)
	adapted.plan = plan
	return adapted
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
-- opts.anchor / opts.anchorRadius: every bot builds only near that point, as a player's Auto Play does;
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
		table.insert(bots, { key = key, policy = resolvePolicy(list[i] or list[1]), planIndex = 1, anchor = opts.anchor, anchorRadius = opts.anchorRadius })
	end
	local scale = WaveLogic.partyScale(TD, party)
	-- Story episodes and events play their wave script (as MatchService does); opts.arena tries the
	-- mode on another map (e.g. an event on its new arena before the switch).
	local episode = if mode.kind == "story" then Waves.episodes[mode.episode] elseif mode.kind == "event" then Waves.events[mode.event] else nil
	if not opts.raw then -- opts.raw: the loadout exactly as written (to show what the episode asks for)
		for _, bot in bots do
			bot.policy = AutoBattle.adapt(bot.policy, episode)
		end
	end
	local total = if episode then episode.waves else nil
	local arenaId = opts.arena or mode.arena
	local arena = Arenas[arenaId]
	local rules = rulesFor(arenaId)
	local spots = spotsFor(arenaId, rules)
	-- Twin roads only where the mode walks them (Modes.twinRoads, as MatchService does).
	local roads = if mode.twinRoads and arena.paths then arena.paths else arena.path
	local state = TdSim.new(roads, keys, math.floor(TD.START_CASH * scale.cash + 0.5), opts.gate or diff.gate, total, TD.PREP_SECONDS, {
		between = TD.BETWEEN_WAVES,
		waveBonusBase = TD.WAVE_BONUS_BASE * scale.cash,
		waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE * scale.cash,
		rewardMul = diff.reward,
		enemies = Enemies,
		stunChainMax = TD.STUN_CHAIN_MAX,
		buffCap = TD.BUFF_CAP,
		stealCap = TD.STEAL_CAP,
		farmMul = scale.farm,
		hasteFloor = TD.HASTE_FLOOR,
		stunImmunity = TD.STUN_IMMUNITY,
		maxSpeedMul = WaveLogic.MAX_SPEED_MUL,
		burnMax = TD.BURN_MAX_STACKS,
		burnTick = TD.BURN_TICK,
		burnDamage = TD.BURN_DAMAGE,
		burnFor = TD.BURN_SECONDS,
	}, function(wave)
		if episode then
			return WaveLogic.story(episode, wave, diff, scale, Enemies)
		end
		return WaveLogic.infinite(Waves.infinite, wave, diff, scale, Enemies)
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
				-- Scripted beats (the ally of Episodes 8 and 9), as MatchService runs them.
				if episode and episode.script then
					TdTowers.runScript(state, episode.script, e.wave, Units, rules, arena.allySpot)
				end
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
		signatures = (function()
			local n = 0
			for _, t in state.towers do
				if t.path then
					n += 1
				end
			end
			return n
		end)(),
		waves = rows,
		totalWaves = total,
		party = party,
		scale = scale,
	}
end

return AutoBattle
