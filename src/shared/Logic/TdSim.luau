--!strict
-- The match simulation: enemies walking a path, towers shooting, the gate taking hits, waves and
-- phases. Pure and deterministic (no RNG, no Roblox globals): the server steps it on Heartbeat,
-- Lune tests step it directly. Tower placement/upgrades live in TdTowers.

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

export type Enemy = {
	id: number,
	enemyId: string,
	hp: number,
	maxHp: number,
	dist: number,
	speed: number,
	slowMul: number,
	slowUntil: number,
	stunUntil: number,
	stunSince: number, -- start of the current unbroken chain of stuns
	stunImmuneUntil: number,
	armor: number,
	stealth: boolean,
	disguised: boolean, -- not yet revealed (Enemies[id].disguised); stays false once revealed
	baseSpeed: number, -- the def's speed before difficulty, for the aura speed cap
	aura: { speed: number, radius: number }?, -- speeds up other enemies nearby (drummer)
	shield: { radius: number, reduce: number }?, -- enemies nearby (itself too) take less damage (porter)
	burn: number?, -- burn stacks it lays on the gate when it reaches it (torchbearer)
	hpMul: number, -- the wave's HP multiplier it spawned with (summons inherit it)
	pathIndex: number, -- which road it walks (state.paths); escorts and passengers keep their parent's
	summon: { enemy: string, count: number, every: number }?, -- calls escorts on a timer (Abu Jawdan)
	summonAt: number, -- time of the next summon
	teleport: { atHp: number, fraction: number, telegraph: number }?, -- one jump forward (Lateef)
	teleportAt: number?, -- set when the jump is telegraphed; it lands at this time …
	teleportTo: number?, -- … at this path distance
	sabotage: { range: number, duration: number, cooldown: number }?, -- disables the nearest defender (rifleman)
	sabotageAt: number, -- earliest time of its next shot
	holdUntil: number, -- it stands still (aiming) until then
	split: { enemy: string, count: number }?, -- releases attackers when it dies (cart)
	enrage: { belowHp: number, speed: number }?, -- walks faster once wounded (brute)
	healAura: { radius: number, pct: number }?, -- mends others nearby, pct of their max HP per second (rival hakim)
	markedUntil: number, -- marked by a defender's ability until then …
	markMul: number, -- … and takes this much more damage from every defender
	reward: number,
	gateDamage: number,
	boss: boolean,
	alive: boolean,
}

export type Tower = {
	id: number,
	owner: string,
	unitId: string,
	level: number,
	x: number,
	z: number,
	stats: any, -- UnitLogic.Stats
	nextAt: number,
	abilityAt: number,
	abilityQueued: boolean?, -- the owner tapped the ultimate; fires on the next attack once ready
	targeting: string, -- "first" | "last" | "strong" | "close"
	invested: number,
	kills: number,
	disabledUntil: number?, -- a saboteur's shot: no attacks until then
	ally: boolean?, -- a story ally (TdTowers.addAlly): no owner, cannot be sold, upgraded or retargeted
	path: string?, -- "a" | "b": its level-7 signature
}

-- autoAbility: ultimates fire as soon as they are ready (nil counts as on).
export type PlayerState = { cash: number, kills: number, spent: number, autoAbility: boolean? }

export type Event = { type: string, [string]: any }

export type PathData = { pts: { { number } }, cum: { number }, length: number }

-- Burn stacks on the gate: each stack costs cfg.burnDamage gate HP every cfg.burnTick seconds
-- until `untilT` (refreshed by every new stack); defenders with `douse` remove stacks as they attack.
export type GateBurn = { stacks: number, untilT: number, nextTick: number }

export type Shield = { x: number, z: number, r2: number, reduce: number }

export type State = {
	path: PathData, -- the first road (back-compat); every road is in `paths`
	paths: { PathData }, -- one road, or several that merge before the gate (twin gates)
	spawnCount: number, -- wave spawns so far: they alternate between the roads
	allyShield: number, -- gate damage an ally still absorbs before the gate takes any
	time: number,
	phase: string, -- "prep" | "wave" | "won" | "lost"
	wave: number, -- the wave being fought or prepared (1-based)
	totalWaves: number?, -- nil = endless
	wavesCleared: number,
	nextWaveAt: number,
	waveStartedAt: number,
	gateHp: number,
	gateMax: number,
	gateBurn: GateBurn,
	shields: { Shield }?, -- this step's shield bearers (nil = none alive)
	pendingSplits: { { enemy: string, count: number, dist: number, hpMul: number, speedMul: number, by: number, pathIndex: number } }, -- deaths that release attackers, spawned after the towers act
	enemies: { Enemy },
	towers: { Tower },
	players: { [string]: PlayerState },
	queue: { any }, -- pending spawns of the current wave, sorted by `at`
	queueIndex: number,
	nextId: number,
	cfg: {
		between: number,
		waveBonusBase: number,
		waveBonusPerWave: number,
		rewardMul: number,
		enemies: { [string]: any },
		stunChainMax: number?, -- longest unbroken chain of stuns an enemy can be held in (nil = no cap) …
		stunImmunity: number?, -- … after which it ignores stuns for this long
		maxSpeedMul: number?, -- an aura never pushes an enemy past baseSpeed × this (nil = no cap)
		burnMax: number?, -- most burn stacks on the gate (nil = burning is off)
		burnTick: number?, -- seconds between burn damage ticks
		burnDamage: number?, -- gate HP per stack per tick
		burnFor: number?, -- seconds the stacks last after the newest one
	},
	buildWave: (number) -> any, -- wave number → WaveLogic.Wave
}

local TdSim = {}

-- pathPoints: one road ({ {x, z}, … }) or several ({ road, road }, twin gates).
function TdSim.new(pathPoints: { any }, players: { string }, startCash: number, gateHp: number, totalWaves: number?, prep: number, cfg: any, buildWave: (number) -> any): State
	local ps = {}
	for _, key in players do
		ps[key] = { cash = startCash, kills = 0, spent = 0 }
	end
	local roads: { any } = if type(pathPoints[1][1]) == "table" then pathPoints else { pathPoints }
	local paths = {}
	for _, pts in roads do
		table.insert(paths, Path.build(pts))
	end
	return {
		path = paths[1],
		paths = paths,
		spawnCount = 0,
		allyShield = 0,
		time = 0,
		phase = "prep",
		wave = 1,
		totalWaves = totalWaves,
		wavesCleared = 0,
		nextWaveAt = prep,
		waveStartedAt = 0,
		gateHp = gateHp,
		gateMax = gateHp,
		gateBurn = { stacks = 0, untilT = 0, nextTick = 0 },
		pendingSplits = {},
		enemies = {},
		towers = {},
		players = ps,
		queue = {},
		queueIndex = 1,
		nextId = 1,
		cfg = cfg,
		buildWave = buildWave,
	}
end

function TdSim.enemyPosition(state: State, e: Enemy): (number, number, number, number)
	return Path.position(state.paths[e.pathIndex], e.dist)
end

-- Every defender of a match must keep clear of every road.
function TdSim.distanceToRoads(state: State, x: number, z: number): number
	return Path.distanceToAll(state.paths, x, z)
end

local function startWave(state: State, events: { Event })
	local wave = state.buildWave(state.wave)
	state.queue = wave.spawns
	state.queueIndex = 1
	state.phase = "wave"
	state.waveStartedAt = state.time
	table.insert(events, { type = "waveStart", wave = state.wave, count = wave.count, boss = wave.boss })
end

-- Lets the service start the next wave early (skip vote).
function TdSim.skipCountdown(state: State)
	if state.phase == "prep" then
		state.nextWaveAt = state.time
	end
end

-- Adds one live enemy at path distance `dist` (0 = the spawn) and emits its spawn event.
-- `by`: the summoner's id for escorts (the client places them at the summoner).
local function addEnemy(state: State, enemyId: string, hpMul: number, speedMul: number, dist: number, events: { Event }, by: number?, pathIndex: number?): Enemy?
	local def = state.cfg.enemies[enemyId]
	if not def then
		return nil
	end
	local id = state.nextId
	state.nextId += 1
	local hp = def.hp * hpMul
	local e: Enemy = {
		id = id,
		enemyId = enemyId,
		hp = hp,
		maxHp = hp,
		dist = dist,
		speed = def.speed * speedMul,
		slowMul = 1,
		slowUntil = 0,
		stunUntil = 0,
		stunSince = 0,
		stunImmuneUntil = 0,
		armor = def.armor or 0,
		stealth = def.stealth == true,
		disguised = def.disguised == true,
		baseSpeed = def.speed,
		aura = def.aura,
		shield = def.shield,
		burn = def.burn,
		hpMul = hpMul,
		pathIndex = pathIndex or 1,
		summon = def.summon,
		summonAt = if def.summon then state.time + def.summon.every else 0,
		teleport = def.teleport,
		sabotage = def.sabotage,
		sabotageAt = 0,
		holdUntil = 0,
		split = def.split,
		enrage = def.enrage,
		healAura = def.healAura,
		markedUntil = 0,
		markMul = 1,
		reward = def.reward,
		gateDamage = def.gateDamage,
		boss = def.boss == true,
		alive = true,
	}
	table.insert(state.enemies, e)
	table.insert(events, { type = "spawn", id = id, enemyId = enemyId, boss = def.boss == true, hp = hp, dist = if dist > 0 then dist else nil, by = by, path = if (pathIndex or 1) > 1 then pathIndex else nil })
	return e
end

local function spawnDue(state: State, events: { Event })
	local q = state.queue
	local offset = state.waveStartedAt
	while state.queueIndex <= #q and q[state.queueIndex].at + offset <= state.time do
		local s = q[state.queueIndex]
		state.queueIndex += 1
		-- Twin gates: spawns alternate between the roads (a script may pin one with `path`).
		state.spawnCount += 1
		local road = s.path or ((state.spawnCount - 1) % #state.paths + 1)
		addEnemy(state, s.enemy, s.hpMul, s.speedMul, 0, events, nil, road)
	end
end

-- Boss behaviours (STORY_PLAN §10.1, S1-S05). Summoners call `count` escorts every `every` seconds
-- at their own spot on the road (same wave HP and speed), until they die; the escorts belong to
-- the wave, so it only ends once they are dealt with too. A teleporter, the first time its HP drops
-- to `atHp`, telegraphs a jump of `fraction` of the road (event `telegraph`) and lands `telegraph`
-- seconds later (event `teleport`), never past the last stud before the gate. Once per enemy.
local function bossActs(state: State, events: { Event })
	for i = 1, #state.enemies do
		local e = state.enemies[i]
		local length = state.paths[e.pathIndex].length
		if e.alive then
			local sm = e.summon
			if sm and state.time >= e.summonAt then
				e.summonAt += sm.every
				local speedMul = e.speed / e.baseSpeed
				for k = 1, sm.count do
					-- Escorts step out just behind him, spread a little so they don't stack.
					addEnemy(state, sm.enemy, e.hpMul, speedMul, math.max(0, e.dist - k * 0.8), events, e.id, e.pathIndex)
				end
				table.insert(events, { type = "summon", id = e.id, enemy = sm.enemy, count = sm.count })
			end
			local tp = e.teleport
			if tp then
				if e.teleportAt == nil and e.hp <= tp.atHp * e.maxHp then
					e.teleportAt = state.time + tp.telegraph
					e.teleportTo = math.min(e.dist + tp.fraction * length, length - 1)
					table.insert(events, { type = "telegraph", id = e.id, from = e.dist, to = e.teleportTo, at = e.teleportAt })
				elseif e.teleportAt and e.teleportTo and state.time >= e.teleportAt then
					-- He kept walking during the telegraph: never jump backwards.
					e.dist = math.max(e.dist, e.teleportTo)
					e.teleportTo = nil
					table.insert(events, { type = "teleport", id = e.id, dist = e.dist })
				end
			end
		end
	end
end

local function dist2(ax: number, az: number, bx: number, bz: number): number
	local dx, dz = ax - bx, az - bz
	return dx * dx + dz * dz
end

type Bearer = { e: Enemy, x: number, z: number, r2: number, mul: number }

-- Speed auras (drummers): the best aura covering each other enemy, never stacking, capped so no
-- enemy walks faster than baseSpeed × cfg.maxSpeedMul. nil when no aura bearer is alive (the usual
-- case costs one pass). O(n · k), k = live aura bearers.
local function auraMuls(state: State): { [Enemy]: number }?
	local bearers: { Bearer } = {}
	for _, e in state.enemies do
		local a = e.aura
		if e.alive and a then
			local x, z = Path.position(state.paths[e.pathIndex], e.dist)
			table.insert(bearers, { e = e, x = x, z = z, r2 = a.radius * a.radius, mul = a.speed })
		end
	end
	if #bearers == 0 then
		return nil
	end
	local cap = state.cfg.maxSpeedMul
	local out: { [Enemy]: number } = {}
	for _, e in state.enemies do
		if e.alive then
			local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
			local best = 1
			for _, b in bearers do
				if b.e ~= e and b.mul > best and dist2(ex, ez, b.x, b.z) <= b.r2 then
					best = b.mul
				end
			end
			if best > 1 then
				if cap then
					best = math.max(1, math.min(best, cap * e.baseSpeed / e.speed))
				end
				out[e] = best
			end
		end
	end
	return out
end
TdSim.auraMuls = auraMuls

local function addBurn(state: State, stacks: number, events: { Event })
	local max = state.cfg.burnMax
	if not max or stacks <= 0 then
		return
	end
	local b = state.gateBurn
	if b.stacks == 0 then
		b.nextTick = state.time + (state.cfg.burnTick or 0)
	end
	b.stacks = math.min(max, b.stacks + stacks)
	b.untilT = state.time + (state.cfg.burnFor or 0)
	table.insert(events, { type = "gateBurn", stacks = b.stacks, gateHp = state.gateHp })
end

local function clearBurn(state: State, events: { Event })
	if state.gateBurn.stacks > 0 then
		state.gateBurn.stacks = 0
		table.insert(events, { type = "gateBurn", stacks = 0, gateHp = state.gateHp })
	end
end

-- The burning gate loses stacks × burnDamage every burnTick until the stacks run out.
local function burnGate(state: State, events: { Event })
	local b = state.gateBurn
	if b.stacks == 0 then
		return
	end
	local tick = state.cfg.burnTick or 0
	while tick > 0 and state.time >= b.nextTick and b.nextTick <= b.untilT do
		local dmg = b.stacks * (state.cfg.burnDamage or 0)
		state.gateHp = math.max(0, state.gateHp - dmg)
		b.nextTick += tick
		table.insert(events, { type = "gateBurn", stacks = b.stacks, damage = dmg, gateHp = state.gateHp })
	end
	if state.time >= b.untilT then
		clearBurn(state, events)
	end
end

local function moveEnemies(state: State, dt: number, events: { Event })
	local auras = auraMuls(state)
	local cap = state.cfg.maxSpeedMul
	for _, e in state.enemies do
		if e.alive and state.time >= e.stunUntil and state.time >= e.holdUntil then
			local mul = if state.time < e.slowUntil then e.slowMul else 1
			-- Speed-ups (an aura, an enraged brute) multiply but share one cap: never past base × maxSpeedMul.
			local boost = if auras and auras[e] then auras[e] else 1
			local en = e.enrage
			if en and e.hp <= en.belowHp * e.maxHp then
				boost *= en.speed
			end
			if boost > 1 and cap then
				boost = math.max(1, math.min(boost, cap * e.baseSpeed / e.speed))
			end
			mul *= boost
			e.dist += e.speed * mul * dt
			if e.dist >= state.paths[e.pathIndex].length then
				e.alive = false
				-- A story ally standing at the gate takes the first blows (allyShield, TdTowers.addAlly).
				local absorbed = math.min(state.allyShield, e.gateDamage)
				state.allyShield -= absorbed
				local damage = e.gateDamage - absorbed
				state.gateHp = math.max(0, state.gateHp - damage)
				table.insert(events, { type = "reached", id = e.id, damage = damage, absorbed = if absorbed > 0 then absorbed else nil, gateHp = state.gateHp })
				if e.burn then
					addBurn(state, e.burn, events)
				end
			end
		end
	end
end

-- This step's shield bearers (porters) for hit(); nil when none is alive.
local function gatherShields(state: State)
	local list: { Shield }? = nil
	for _, e in state.enemies do
		local s = e.shield
		if e.alive and s then
			local x, z = Path.position(state.paths[e.pathIndex], e.dist)
			local l = list or {}
			table.insert(l, { x = x, z = z, r2 = s.radius * s.radius, reduce = s.reduce })
			list = l
		end
	end
	state.shields = list
end

-- The best shield reduction covering an enemy (shields never stack; a bearer covers itself): 0 if none.
local function shieldFor(state: State, e: Enemy): number
	local list = state.shields
	if not list then
		return 0
	end
	local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
	local best = 0
	for _, s in list do
		if s.reduce > best and dist2(ex, ez, s.x, s.z) <= s.r2 then
			best = s.reduce
		end
	end
	return best
end
TdSim.shieldFor = shieldFor

-- Heal auras (rival hakim): every other enemy within the radius regains pct of its max HP per
-- second from the best aura covering it (not stacking), never past its max. nil-cost when none live.
local function healAuras(state: State, dt: number)
	local bearers: { { e: Enemy, x: number, z: number, r2: number, pct: number } } = {}
	for _, e in state.enemies do
		local h = e.healAura
		if e.alive and h then
			local x, z = Path.position(state.paths[e.pathIndex], e.dist)
			table.insert(bearers, { e = e, x = x, z = z, r2 = h.radius * h.radius, pct = h.pct })
		end
	end
	if #bearers == 0 then
		return
	end
	for _, e in state.enemies do
		if e.alive and e.hp < e.maxHp then
			local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
			local best = 0
			for _, b in bearers do
				if b.e ~= e and b.pct > best and dist2(ex, ez, b.x, b.z) <= b.r2 then
					best = b.pct
				end
			end
			if best > 0 then
				e.hp = math.min(e.maxHp, e.hp + best * e.maxHp * dt)
			end
		end
	end
end

-- Saboteurs (riflemen): when a defender is within `range`, stop for `duration` s to shoot the nearest
-- one, which then cannot attack for `duration` s; again after `cooldown`. One defender per shot.
local function saboteursAct(state: State, events: { Event })
	for _, e in state.enemies do
		local sb = e.sabotage
		if e.alive and sb and state.time >= e.sabotageAt and state.time >= e.stunUntil then
			local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
			local best: Tower? = nil
			local bestD2 = sb.range * sb.range
			for _, t in state.towers do
				if not (t.disabledUntil and state.time < t.disabledUntil) then
					local d2 = dist2(ex, ez, t.x, t.z)
					if d2 <= bestD2 then
						best, bestD2 = t, d2
					end
				end
			end
			if best then
				best.disabledUntil = state.time + sb.duration
				e.holdUntil = state.time + sb.duration
				e.sabotageAt = state.time + sb.cooldown
				table.insert(events, { type = "towerDisabled", tower = best.id, by = e.id, untilT = best.disabledUntil })
			end
		end
	end
end

-- Attackers that split on death (carts) release their passengers at the same spot, with the wave's
-- HP and speed, after the towers have acted (so one splash never hits the cart and its passengers).
local function releaseSplits(state: State, events: { Event })
	if #state.pendingSplits == 0 then
		return
	end
	for _, sp in state.pendingSplits do
		for k = 1, sp.count do
			addEnemy(state, sp.enemy, sp.hpMul, sp.speedMul, math.max(0, sp.dist - (k - 1) * 0.6), events, sp.by, sp.pathIndex)
		end
		table.insert(events, { type = "split", id = sp.by, enemy = sp.enemy, count = sp.count })
	end
	state.pendingSplits = {}
end

-- Best haste (signature "Rally") from another defender whose haste radius covers the tower: its
-- attack cooldown is multiplied by this (1 = none). Not stacking.
local function hasteFor(state: State, t: Tower): number
	local best = 1
	for _, s in state.towers do
		local h = s.stats.haste
		if h and s ~= t and h.mul < best and dist2(s.x, s.z, t.x, t.z) <= h.radius * h.radius then
			best = h.mul
		end
	end
	return best
end
TdSim.hasteFor = hasteFor

-- Best buff multiplier from support/healer towers whose range covers the tower.
local function buffFor(state: State, t: Tower): number
	local best = 1
	for _, s in state.towers do
		local b = s.stats.buff
		if b and s ~= t and dist2(s.x, s.z, t.x, t.z) <= s.stats.range * s.stats.range and b > best then
			best = b
		end
	end
	return best
end
-- Exposed so the server can show each defender's live buff (players couldn't tell buffs applied).
TdSim.buffFor = buffFor

-- The nearest other revealer (Natour's lantern, `revealsStealth`) whose range covers the tower, or
-- nil. A covered defender can target stealth enemies even without hitsStealth of its own.
local function revealerFor(state: State, t: Tower): Tower?
	local best: Tower? = nil
	local bestD2 = math.huge
	for _, s in state.towers do
		if s.stats.revealsStealth and s ~= t then
			local d2 = dist2(s.x, s.z, t.x, t.z)
			if d2 <= s.stats.range * s.stats.range and d2 < bestD2 then
				best, bestD2 = s, d2
			end
		end
	end
	return best
end
-- Exposed so the server can tell each defender's panel who lets it see hidden thieves.
TdSim.revealerFor = revealerFor

local function seesStealth(state: State, t: Tower): boolean
	return t.stats.hitsStealth or revealerFor(state, t) ~= nil
end
TdSim.seesStealth = seesStealth

-- Can this defender land a single-target hit on a disguised enemy that is not revealed yet? Only a
-- lantern bearer or a defender its lantern lights (the hit then reveals it); splash never can.
local function seesDisguised(state: State, t: Tower): boolean
	return not t.stats.splash and (t.stats.revealsStealth or revealerFor(state, t) ~= nil)
end
TdSim.seesDisguised = seesDisguised

local function reveal(e: Enemy, by: number, events: { Event })
	e.disguised = false
	table.insert(events, { type = "revealed", id = e.id, by = by })
end

-- Lanterns (revealsStealth) unmask every disguised enemy inside their range; they stay revealed.
local function revealInLight(state: State, events: { Event })
	local hidden = false
	for _, e in state.enemies do
		if e.alive and e.disguised then
			hidden = true
			break
		end
	end
	if not hidden then
		return
	end
	for _, s in state.towers do
		if s.stats.revealsStealth then
			local r2 = s.stats.range * s.stats.range
			for _, e in state.enemies do
				if e.alive and e.disguised then
					local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
					if dist2(ex, ez, s.x, s.z) <= r2 then
						reveal(e, s.id, events)
					end
				end
			end
		end
	end
end

local function pickTarget(state: State, t: Tower, sees: boolean): (Enemy?, number, number)
	local r2 = t.stats.range * t.stats.range
	local best: Enemy? = nil
	local bestScore = -math.huge
	local bx, bz = 0, 0
	local lit: boolean? = nil -- seesDisguised, worked out only once a disguised enemy shows up
	for _, e in state.enemies do
		local ok = e.alive and (sees or not e.stealth)
		if ok and e.disguised then
			if lit == nil then
				lit = seesDisguised(state, t)
			end
			ok = lit == true
		end
		if ok then
			local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
			local d2 = dist2(ex, ez, t.x, t.z)
			if d2 <= r2 then
				local score
				if t.targeting == "last" then
					score = -e.dist
				elseif t.targeting == "strong" then
					score = e.hp
				elseif t.targeting == "close" then
					score = -d2
				else
					score = e.dist
				end
				if score > bestScore then
					best, bestScore, bx, bz = e, score, ex, ez
				end
			end
		end
	end
	return best, bx, bz
end

-- single: a single-target hit (not splash). Only those reveal a disguised enemy; splash skips it.
-- extra: an ability's own stun / slow on top of the tower's (signatures).
local function hit(state: State, t: Tower, e: Enemy, damage: number, events: { Event }, single: boolean?, extra: any?)
	if not e.alive then
		return
	end
	if e.disguised then
		if not single then
			return
		end
		reveal(e, t.id, events)
	end
	local marked = if state.time < e.markedUntil then e.markMul else 1
	e.hp -= damage * marked * (1 - e.armor) * (1 - shieldFor(state, e))
	if t.stats.slow and t.stats.slowFor then
		e.slowMul = math.min(e.slowMul, t.stats.slow)
		e.slowUntil = math.max(e.slowUntil, state.time + t.stats.slowFor)
	end
	if extra and extra.slow and extra.slowFor then
		e.slowMul = math.min(e.slowMul, extra.slow)
		e.slowUntil = math.max(e.slowUntil, state.time + extra.slowFor)
	end
	local stun = t.stats.stun
	if extra and extra.stun then
		stun = math.max(stun or 0, extra.stun)
	end
	-- Stuns chain, but a chain is capped (then the enemy shrugs stuns off for a moment), so a stack
	-- of stunners (a party of Blacksmiths and Strongmen) cannot pin a wave at the spawn forever. A
	-- chain only resets once the enemy has been free for the immunity time (re-stuns landing on the
	-- tick a stun ends would otherwise start a fresh chain every time).
	if stun and state.time >= e.stunImmuneUntil then
		if state.time >= e.stunUntil + (state.cfg.stunImmunity or 0) then
			e.stunSince = state.time
		end
		e.stunUntil = math.max(e.stunUntil, state.time + stun)
		local cap = state.cfg.stunChainMax
		if cap and e.stunUntil - e.stunSince >= cap then
			e.stunUntil = e.stunSince + cap
			e.stunImmuneUntil = e.stunUntil + (state.cfg.stunImmunity or 0)
		end
	end
	if e.hp <= 0 then
		e.alive = false
		t.kills += 1
		local p = state.players[t.owner]
		local cash = math.floor(e.reward * state.cfg.rewardMul * t.stats.cash + 0.5)
		if p then
			p.cash += cash
			p.kills += 1
		end
		table.insert(events, { type = "death", id = e.id, tower = t.id, owner = t.owner, cash = cash, boss = e.boss })
		local sp = e.split
		if sp then
			table.insert(state.pendingSplits, { enemy = sp.enemy, count = sp.count, dist = e.dist, hpMul = e.hpMul, speedMul = e.speed / e.baseSpeed, by = e.id, pathIndex = e.pathIndex })
		end
	end
end

local function splashHits(state: State, t: Tower, cx: number, cz: number, radius: number, damage: number, sees: boolean, events: { Event }, extra: any?)
	local r2 = radius * radius
	for _, e in state.enemies do
		if e.alive and not e.disguised and (sees or not e.stealth) then
			local ex, ez = Path.position(state.paths[e.pathIndex], e.dist)
			if dist2(ex, ez, cx, cz) <= r2 then
				hit(state, t, e, damage, events, nil, extra)
			end
		end
	end
end

local function towersAct(state: State, events: { Event })
	for _, t in state.towers do
		local st = t.stats
		local disabled = t.disabledUntil ~= nil and state.time < t.disabledUntil
		if st.damage > 0 and not disabled and state.time >= t.nextAt then
			local sees = seesStealth(state, t)
			local target, tx, tz = pickTarget(state, t, sees)
			if target then
				t.nextAt = state.time + st.cooldown * hasteFor(state, t)
				local damage = st.damage * buffFor(state, t)
				local ability = false
				local ab = st.ability
				local owner = state.players[t.owner]
				local wants = t.abilityQueued == true or owner == nil or owner.autoAbility ~= false
				if ab and wants and state.time >= t.abilityAt then
					t.abilityQueued = false
					if ab.kind == "shabriyeh" then
						damage *= ab.multiplier
						ability = true
						t.abilityAt = state.time + ab.cooldown
					elseif ab.kind == "sweep" then
						ability = true
						t.abilityAt = state.time + ab.cooldown
						splashHits(state, t, t.x, t.z, ab.radius or st.range, damage * ab.multiplier, sees, events, ab)
					elseif ab.kind == "mark" then
						-- The Oath: the strongest enemy it can see in range takes ×multiplier from every
						-- defender for `duration` s. Marks never stack: the stronger one holds.
						local keep = t.targeting
						t.targeting = "strong"
						local m = pickTarget(state, t, sees)
						t.targeting = keep
						if m then
							ability = true
							t.abilityAt = state.time + ab.cooldown
							m.markMul = if state.time < m.markedUntil then math.max(m.markMul, ab.multiplier) else ab.multiplier
							m.markedUntil = math.max(m.markedUntil, state.time + (ab.duration or 0))
							table.insert(events, { type = "mark", tower = t.id, target = m.id, untilT = m.markedUntil })
						end
					end
				end
				local perHit = damage
				if ability and ab and ab.kind == "sweep" then
					perHit = damage * ab.multiplier
				else
					if st.splash then
						splashHits(state, t, tx, tz, st.splash, damage, sees, events)
					else
						hit(state, t, target, damage, events, true, if ability and ab and ab.kind == "shabriyeh" then ab else nil)
					end
				end
				local shownMark = if state.time < target.markedUntil then target.markMul else 1
				-- Water on the flames: every attack of a dousing defender takes stacks off the gate.
				local douse = st.douse
				if douse and state.gateBurn.stacks > 0 then
					state.gateBurn.stacks = math.max(0, state.gateBurn.stacks - douse)
					table.insert(events, { type = "gateBurn", stacks = state.gateBurn.stacks, doused = t.id, gateHp = state.gateHp })
				end
				-- `damage`: what the primary target lost (after armour), for the client's damage numbers.
				local shown = math.floor(perHit * shownMark * (1 - target.armor) * (1 - shieldFor(state, target)) + 0.5)
				table.insert(events, { type = "attack", tower = t.id, target = target.id, ability = ability, x = tx, z = tz, damage = shown })
			end
		end
	end
end

local function compact(state: State)
	local live = {}
	for _, e in state.enemies do
		if e.alive then
			table.insert(live, e)
		end
	end
	state.enemies = live
end

local function endWave(state: State, events: { Event })
	state.wavesCleared = state.wave
	clearBurn(state, events) -- no burning between waves
	for _, t in state.towers do
		t.disabledUntil = nil -- a sabotaged defender is back for the next wave
	end
	local bonus = math.floor(state.cfg.waveBonusBase + state.cfg.waveBonusPerWave * state.wave + 0.5)
	for _, p in state.players do
		p.cash += bonus
	end
	-- Farms pay their owner, healers mend the gate
	local healed = 0
	for _, t in state.towers do
		if t.stats.income then
			local p = state.players[t.owner]
			if p then
				p.cash += t.stats.income
			end
		end
		if t.stats.heal then
			healed += t.stats.heal
		end
	end
	if healed > 0 then
		state.gateHp = math.min(state.gateMax, state.gateHp + healed)
	end
	table.insert(events, { type = "waveEnd", wave = state.wave, bonus = bonus, healed = healed, gateHp = state.gateHp })
	if state.totalWaves and state.wave >= state.totalWaves then
		state.phase = "won"
		table.insert(events, { type = "won", waves = state.wavesCleared })
		return
	end
	state.wave += 1
	state.phase = "prep"
	state.nextWaveAt = state.time + state.cfg.between
end

-- Advances the simulation by dt seconds of game time. Returns the events of this step.
function TdSim.step(state: State, dt: number): { Event }
	local events: { Event } = {}
	if state.phase == "won" or state.phase == "lost" then
		return events
	end
	state.time += dt
	if state.phase == "prep" then
		if state.time >= state.nextWaveAt then
			startWave(state, events)
		else
			return events
		end
	end
	spawnDue(state, events)
	moveEnemies(state, dt, events)
	healAuras(state, dt)
	burnGate(state, events)
	revealInLight(state, events)
	saboteursAct(state, events)
	gatherShields(state)
	towersAct(state, events)
	bossActs(state, events)
	releaseSplits(state, events)
	compact(state)
	if state.gateHp <= 0 then
		state.phase = "lost"
		table.insert(events, { type = "lost", waves = state.wavesCleared })
		return events
	end
	if state.queueIndex > #state.queue and #state.enemies == 0 then
		endWave(state, events)
	end
	return events
end

-- Seconds until the next wave starts (0 while fighting).
function TdSim.countdown(state: State): number
	if state.phase ~= "prep" then
		return 0
	end
	return math.max(0, state.nextWaveAt - state.time)
end

return TdSim
