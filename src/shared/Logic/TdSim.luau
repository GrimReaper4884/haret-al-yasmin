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
}

-- autoAbility: ultimates fire as soon as they are ready (nil counts as on).
export type PlayerState = { cash: number, kills: number, spent: number, autoAbility: boolean? }

export type Event = { type: string, [string]: any }

export type PathData = { pts: { { number } }, cum: { number }, length: number }

export type State = {
	path: PathData,
	time: number,
	phase: string, -- "prep" | "wave" | "won" | "lost"
	wave: number, -- the wave being fought or prepared (1-based)
	totalWaves: number?, -- nil = endless
	wavesCleared: number,
	nextWaveAt: number,
	waveStartedAt: number,
	gateHp: number,
	gateMax: number,
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
	},
	buildWave: (number) -> any, -- wave number → WaveLogic.Wave
}

local TdSim = {}

function TdSim.new(pathPoints: { { number } }, players: { string }, startCash: number, gateHp: number, totalWaves: number?, prep: number, cfg: any, buildWave: (number) -> any): State
	local ps = {}
	for _, key in players do
		ps[key] = { cash = startCash, kills = 0, spent = 0 }
	end
	return {
		path = Path.build(pathPoints),
		time = 0,
		phase = "prep",
		wave = 1,
		totalWaves = totalWaves,
		wavesCleared = 0,
		nextWaveAt = prep,
		waveStartedAt = 0,
		gateHp = gateHp,
		gateMax = gateHp,
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
	return Path.position(state.path, e.dist)
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

local function spawnDue(state: State, events: { Event })
	local q = state.queue
	local offset = state.waveStartedAt
	while state.queueIndex <= #q and q[state.queueIndex].at + offset <= state.time do
		local s = q[state.queueIndex]
		state.queueIndex += 1
		local def = state.cfg.enemies[s.enemy]
		if def then
			local id = state.nextId
			state.nextId += 1
			local hp = def.hp * s.hpMul
			table.insert(state.enemies, {
				id = id,
				enemyId = s.enemy,
				hp = hp,
				maxHp = hp,
				dist = 0,
				speed = def.speed * s.speedMul,
				slowMul = 1,
				slowUntil = 0,
				stunUntil = 0,
				stunSince = 0,
				stunImmuneUntil = 0,
				armor = def.armor or 0,
				stealth = def.stealth == true,
				reward = def.reward,
				gateDamage = def.gateDamage,
				boss = def.boss == true,
				alive = true,
			})
			table.insert(events, { type = "spawn", id = id, enemyId = s.enemy, boss = def.boss == true, hp = hp })
		end
	end
end

local function moveEnemies(state: State, dt: number, events: { Event })
	for _, e in state.enemies do
		if e.alive and state.time >= e.stunUntil then
			local mul = if state.time < e.slowUntil then e.slowMul else 1
			e.dist += e.speed * mul * dt
			if e.dist >= state.path.length then
				e.alive = false
				state.gateHp = math.max(0, state.gateHp - e.gateDamage)
				table.insert(events, { type = "reached", id = e.id, damage = e.gateDamage, gateHp = state.gateHp })
			end
		end
	end
end

local function dist2(ax: number, az: number, bx: number, bz: number): number
	local dx, dz = ax - bx, az - bz
	return dx * dx + dz * dz
end

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

local function pickTarget(state: State, t: Tower): (Enemy?, number, number)
	local r2 = t.stats.range * t.stats.range
	local best: Enemy? = nil
	local bestScore = -math.huge
	local bx, bz = 0, 0
	for _, e in state.enemies do
		if e.alive and (t.stats.hitsStealth or not e.stealth) then
			local ex, ez = Path.position(state.path, e.dist)
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

local function hit(state: State, t: Tower, e: Enemy, damage: number, events: { Event })
	if not e.alive then
		return
	end
	e.hp -= damage * (1 - e.armor)
	if t.stats.slow and t.stats.slowFor then
		e.slowMul = math.min(e.slowMul, t.stats.slow)
		e.slowUntil = math.max(e.slowUntil, state.time + t.stats.slowFor)
	end
	-- Stuns chain, but a chain is capped (then the enemy shrugs stuns off for a moment), so a stack
	-- of stunners (a party of Blacksmiths and Strongmen) cannot pin a wave at the spawn forever. A
	-- chain only resets once the enemy has been free for the immunity time (re-stuns landing on the
	-- tick a stun ends would otherwise start a fresh chain every time).
	if t.stats.stun and state.time >= e.stunImmuneUntil then
		if state.time >= e.stunUntil + (state.cfg.stunImmunity or 0) then
			e.stunSince = state.time
		end
		e.stunUntil = math.max(e.stunUntil, state.time + t.stats.stun)
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
	end
end

local function splashHits(state: State, t: Tower, cx: number, cz: number, radius: number, damage: number, events: { Event })
	local r2 = radius * radius
	for _, e in state.enemies do
		if e.alive and (t.stats.hitsStealth or not e.stealth) then
			local ex, ez = Path.position(state.path, e.dist)
			if dist2(ex, ez, cx, cz) <= r2 then
				hit(state, t, e, damage, events)
			end
		end
	end
end

local function towersAct(state: State, events: { Event })
	for _, t in state.towers do
		local st = t.stats
		if st.damage > 0 and state.time >= t.nextAt then
			local target, tx, tz = pickTarget(state, t)
			if target then
				t.nextAt = state.time + st.cooldown
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
						splashHits(state, t, t.x, t.z, ab.radius or st.range, damage * ab.multiplier, events)
					end
				end
				if not (ability and ab and ab.kind == "sweep") then
					if st.splash then
						splashHits(state, t, tx, tz, st.splash, damage, events)
					else
						hit(state, t, target, damage, events)
					end
				end
				table.insert(events, { type = "attack", tower = t.id, target = target.id, ability = ability, x = tx, z = tz })
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
	towersAct(state, events)
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
