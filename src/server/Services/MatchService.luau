--!strict
-- Runs tower-defense matches: one Heartbeat loop steps every live TdSim, fans events out to the
-- party, validates every tower action, pays rewards at the end and sends everyone home.
-- The client only sends intents (place here, upgrade this, vote skip); every number comes from
-- Config and the server-side state.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Enemies = require(Shared.Config.Enemies)
local Waves = require(Shared.Config.Waves)
local Arenas = require(Shared.Config.Arenas)
local Modes = require(Shared.Config.Modes)
local Traits = require(Shared.Config.Traits)
local Beads = require(Shared.Config.Beads)
local Items = require(Shared.Config.Items)
local Economy = require(Shared.Config.Economy)
local Hud = require(Shared.Config.Hud)
local DeviceTelemetry = require(Shared.Logic.DeviceTelemetry)
local TdSim = require(Shared.Logic.TdSim)
local TdTowers = require(Shared.Logic.TdTowers)
local WaveLogic = require(Shared.Logic.WaveLogic)
local UnitLogic = require(Shared.Logic.UnitLogic)
local MatchRewards = require(Shared.Logic.MatchRewards)
local Grants = require(Shared.Logic.Grants)
local Validate = require(Shared.Logic.Validate)
local MonetizationLogic = require(Shared.Logic.MonetizationLogic)
local Settings = require(Shared.Logic.Settings)
local EventLogic = require(Shared.Logic.EventLogic)
local Events = require(Shared.Config.Events)
local Signal = require(Shared.Util.Signal)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MonetizationService = require(script.Parent.MonetizationService)
local ArenaService = require(script.Parent.ArenaService)
local Analytics = require(script.Parent.AnalyticsService)
local FunnelService = require(script.Parent.FunnelService)

local MatchService = {}

MatchService.Ended = Signal.new() -- (match)

export type Match = {
	id: number,
	modeId: string,
	mode: any,
	difficulty: string,
	slot: ArenaService.Slot,
	state: TdSim.State,
	players: { [Player]: string }, -- player → sim key
	byKey: { [string]: Player },
	order: { Player },
	host: Player?,
	speed: number,
	votes: { [Player]: boolean },
	accum: number,
	posAt: number,
	ended: boolean,
	outcome: any?,
	eventBuffer: { any },
	buffShown: { [number]: number }, -- tower id → the support buff on its badge (absent = none)
	buffCount: { [number]: number }, -- tower id → how many supports that buff adds up (LP-A02)
	cashTotals: { [string]: { number } }, -- sim key → cash + spent at each wave end (the result's curve, LP-C06)
	revealShown: { [number]: number }, -- tower id → the lantern tower letting it see stealth (absent = none)
	sabotaged: { [number]: number }, -- tower id → game time its sabotage ends (towerDisabled; D-038)
	script: any?, -- the episode's scripted beats (Config/Waves episodes[id].script): the ally's turn
	placeCounts: { [Player]: DeviceTelemetry.Counts }, -- placed / invalid / cancelled this match (MH-17)
}

local matches: { [number]: Match } = {}
local byPlayer: { [Player]: Match } = {}
local nextMatchId = 1

local evState: RemoteEvent
local evEvents: RemoteEvent
local evStart: RemoteEvent
local evEnd: RemoteEvent
local evHome: RemoteEvent
local evPositions: UnreliableRemoteEvent

local function keyOf(player: Player): string
	return tostring(player.UserId)
end

local function rulesFor(match: Match): TdTowers.Rules
	return {
		bounds = Arenas[match.slot.arenaId].bounds,
		pathHalfWidth = TD.PATH_HALF_WIDTH,
		spacing = TD.TOWER_SPACING,
		towerCap = TD.TOWER_CAP,
		sellRefund = TD.SELL_REFUND,
		starBonus = TD.STAR_BONUS,
		traitCaps = Traits.caps,
	}
end

local function stateSnapshot(match: Match, player: Player): { [string]: any }
	local s = match.state
	local me = s.players[match.players[player] or ""]
	local votes = 0
	for _ in match.votes do
		votes += 1
	end
	local others = {}
	for p, key in match.players do
		local ps = s.players[key]
		others[p.Name] = if ps then ps.cash else 0
	end
	return {
		phase = s.phase,
		wave = s.wave,
		totalWaves = s.totalWaves,
		countdown = TdSim.countdown(s),
		gateHp = s.gateHp,
		gateMax = s.gateMax,
		gateBurn = s.gateBurn.stacks,
		cash = if me then me.cash else 0,
		speed = match.speed,
		votes = votes,
		players = #match.order,
		host = if match.host then match.host.Name else nil,
		cashByPlayer = others,
	}
end

local function pushState(match: Match)
	for p in match.players do
		evState:FireClient(p, stateSnapshot(match, p))
	end
end

local function queueEvent(match: Match, e: any)
	table.insert(match.eventBuffer, e)
end

-- Records `player`'s skip vote for this countdown; when every player has voted the next wave
-- starts now and everyone gets the skip bonus. Returns false if the vote doesn't count.
local function castSkipVote(match: Match, player: Player): boolean
	if match.ended or match.state.phase ~= "prep" or match.votes[player] then
		return false
	end
	match.votes[player] = true
	queueEvent(match, { type = "voteSkip", name = player.Name })
	local all = true
	for p in match.players do
		if not match.votes[p] then
			all = false
		end
	end
	if all then
		for _, ps in match.state.players do
			ps.cash += TD.SKIP_BONUS
		end
		TdSim.skipCountdown(match.state)
	end
	return true
end

-- Auto skip (setting): vote for every player who has it on, in the countdowns between waves only;
-- the setup before wave 1 is left alone so there is time to place defenders.
local function autoSkipVotes(match: Match): boolean
	if match.ended or match.state.phase ~= "prep" or match.state.wave <= 1 then
		return false
	end
	local any = false
	for p in match.players do
		local profile = DataService.getProfile(p)
		if profile and Settings.get(profile.settings, "autoSkip") and castSkipVote(match, p) then
			any = true
		end
	end
	return any
end

local function flushEvents(match: Match)
	if #match.eventBuffer == 0 then
		return
	end
	local batch = match.eventBuffer
	match.eventBuffer = {}
	for p in match.players do
		evEvents:FireClient(p, batch)
	end
end

-- Unreliable events over ~900 bytes are dropped whole, which froze every enemy model in big
-- waves while towers kept hitting their real positions. Send at most POSITIONS_PER_PACKET
-- enemies per packet; each packet starts with the send number so the client can tell when a
-- whole round has arrived.
local POSITIONS_PER_PACKET = 24
local positionSeq = 0
local function sendPositions(match: Match)
	positionSeq += 1
	local packets = {}
	local packed = { positionSeq }
	for _, e in match.state.enemies do
		if #packed > POSITIONS_PER_PACKET * 3 then
			table.insert(packets, packed)
			packed = { positionSeq }
		end
		table.insert(packed, e.id)
		table.insert(packed, math.floor(e.dist * 10 + 0.5) / 10)
		table.insert(packed, math.floor(math.clamp(e.hp / e.maxHp, 0, 1) * 100))
	end
	table.insert(packets, packed)
	for p in match.players do
		for _, packet in packets do
			evPositions:FireClient(p, packet)
		end
	end
end

-- Back to the lane, and the client drops the match HUD at once (it used to wait for its own
-- result-screen timer, so the match UI showed in the lobby after "Back" or the auto-return).
local function teleportHome(player: Player, matchId: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.CFrame = CFrame.new(0, 3.5, 80) * CFrame.Angles(0, math.rad(180), 0)
	end
	evHome:FireClient(player, matchId)
end

local function rewardPlayer(match: Match, player: Player, outcome: any): any
	local profile = DataService.getProfile(player)
	if not profile then
		return nil
	end
	local vip = MonetizationService.hasPerk(player, "vip")
	local key = match.players[player]
	local ps = match.state.players[key]
	local reward = MatchRewards.compute(match.modeId, match.mode, match.difficulty, outcome, profile, vip, TD, math.random)
	-- Event modes also pay the event's currency while the event runs.
	local eventId = if match.mode.kind == "event" then EventLogic.forMode(Events, match.modeId, os.time()) else nil
	local eventDef = if eventId then Events[eventId] else nil
	local eventGain = 0
	DataService.mutate(player, function(p)
		if eventId and eventDef then
			eventGain = EventLogic.addCurrency(p, eventId, eventDef, EventLogic.matchCurrency(eventDef, outcome.won, outcome.wavesCleared))
		end
		-- Beads first: they read the first-clear state that record() is about to update (S1-S11).
		local beads = MatchRewards.beads(p, match.modeId, match.mode, match.difficulty, outcome, Beads, TD, os.time() // 86400)
		;(reward :: any).beads = beads
		-- Episode 9's secret unit roll (S1-S12), granted in this same mutation.
		local secret = MatchRewards.secretDrop(p, match.modeId, match.mode, match.difficulty, outcome, TD.SECRET_DROP, TD, math.random)
		;(reward :: any).secretUnit = secret
		MatchRewards.record(p, match.modeId, match.mode, match.difficulty, outcome, if ps then ps.kills else 0, TD)
		Grants.apply(p, { lira = reward.lira, qirsh = reward.qirsh, xp = reward.xp, traitStones = reward.traitStones, beads = beads, unit = secret or reward.unit }, {
			maxQirsh = Economy.MAX_QIRSH,
			maxLira = TD.MAX_LIRA,
			maxStones = TD.MAX_TRAIT_STONES,
			items = Items :: any,
			units = Units :: any,
			traits = Traits,
			rng = math.random,
			now = os.time(),
			maxBeads = Beads.maxBeads,
		})
		return true
	end, { src = "match:" .. match.modeId })
	Analytics.custom(player, (if outcome.won then "MatchWon_" else "MatchLost_") .. match.modeId .. "_" .. match.difficulty, outcome.wavesCleared)
	PlayerStateService.notify(player, "notify.match_rewards", { lira = reward.lira, qirsh = reward.qirsh, xp = reward.xp })
	local secret = (reward :: any).secretUnit
	if secret and (Units :: any)[secret] then
		PlayerStateService.notify(player, "notify.secret_unit", { unitKey = (Units :: any)[secret].nameKey })
	elseif reward.unit and (Units :: any)[reward.unit] then
		-- A first-clear story gift (TD.STORY_FIRST_CLEAR, e.g. Umm Baki after Episode 6).
		PlayerStateService.notify(player, "notify.gift_unit", { unitKey = (Units :: any)[reward.unit].nameKey })
	end
	if eventGain > 0 and eventDef then
		(reward :: any).eventCurrency = eventGain;
		(reward :: any).eventCurrencyKey = eventDef.currencyKey
	end
	return reward
end

-- Idempotent: the last player pressing Back on the result screen (LeaveMatch) destroys the match
-- before finish()'s delayed cleanup runs; a second release would free an arena slot that another
-- party may already have been given.
local function destroyMatch(match: Match)
	if matches[match.id] ~= match then
		return
	end
	matches[match.id] = nil
	for p in match.players do
		byPlayer[p] = nil
	end
	ArenaService.release(match.slot)
end

-- Placement telemetry (MOBILE_HUD_PLAN MH-17): one count table per player per match, logged as
-- place_outcome_<outcome> events tagged with the player's device when the match ends for them.
local function countPlacement(match: Match, player: Player, outcome: DeviceTelemetry.Outcome?)
	if not outcome or match.ended then
		return
	end
	local counts = match.placeCounts[player]
	if not counts then
		counts = DeviceTelemetry.newCounts()
		match.placeCounts[player] = counts
	end
	DeviceTelemetry.add(Hud, counts, outcome)
end

local function flushPlacements(match: Match, player: Player)
	local counts = match.placeCounts[player]
	if not counts then
		return
	end
	match.placeCounts[player] = nil
	for _, e in DeviceTelemetry.events(counts, PlayerStateService.device(player)) do
		Analytics.custom(player, e.name, e.value, e.profile)
	end
end

local function finish(match: Match, won: boolean)
	if match.ended then
		return
	end
	match.ended = true
	local outcome = { won = won, wavesCleared = match.state.wavesCleared, totalWaves = match.state.totalWaves }
	match.outcome = outcome
	flushEvents(match)
	pushState(match)
	for _, p in match.order do
		if match.players[p] then
			flushPlacements(match, p)
			local reward = rewardPlayer(match, p, outcome)
			local key = match.players[p]
			local curve = MatchRewards.cashCurve(match.cashTotals[key] or {}, math.floor(TD.START_CASH * WaveLogic.partyScale(TD, #match.order).cash + 0.5))
			evEnd:FireClient(p, { won = won, waves = outcome.wavesCleared, reward = reward, cashCurve = curve })
			if won and match.mode.kind == "story" then
				FunnelService.reach(p, "clear")
			end
		end
	end
	MatchService.Ended:Fire(match)
	task.delay(TD.RESULT_SECONDS, function()
		for p in match.players do
			byPlayer[p] = nil
			teleportHome(p, match.id)
		end
		destroyMatch(match)
	end)
end

-- Removes a player from a match (leave button, disconnect). Their towers stay: the party
-- keeps the defence they paid for.
local function removePlayer(match: Match, player: Player, goHome: boolean)
	local key = match.players[player]
	if not key then
		return
	end
	flushPlacements(match, player)
	match.players[player] = nil
	match.byKey[key] = nil
	match.votes[player] = nil
	byPlayer[player] = nil
	for i, p in match.order do
		if p == player then
			table.remove(match.order, i)
			break
		end
	end
	if match.host == player then
		match.host = match.order[1]
	end
	if goHome and player.Parent then
		if not match.ended then
			-- Leaving early still pays for the waves held, as a loss.
			local outcome = { won = false, wavesCleared = match.state.wavesCleared, totalWaves = match.state.totalWaves }
			local reward = rewardPlayer(match, player, outcome)
			evEnd:FireClient(player, { won = false, waves = outcome.wavesCleared, reward = reward, left = true })
		end
		teleportHome(player, match.id)
	end
	if next(match.players) == nil then
		if not match.ended then
			match.ended = true
			MatchService.Ended:Fire(match)
		end
		destroyMatch(match)
	else
		pushState(match)
	end
end

------------------------------------------------------------------------------------------
-- Creating a match

function MatchService.create(modeId: string, difficulty: string, party: { Player }, host: Player): (Match?, string?)
	local mode = Modes[modeId]
	local diff = TD.DIFFICULTIES[difficulty]
	if not mode or not diff then
		return nil, "bad_mode"
	end
	local slot = ArenaService.allocate(mode.arena)
	if not slot then
		return nil, "server_full"
	end
	local keys = {}
	for _, p in party do
		table.insert(keys, keyOf(p))
	end
	local episode = if mode.kind == "story" then Waves.episodes[mode.episode] elseif mode.kind == "event" then (Waves :: any).events[mode.event] else nil
	local total = if episode then episode.waves else nil
	local arena = Arenas[mode.arena]
	-- Bigger parties face tougher enemies (and may split the cash), so 4 players aren't 4× stronger.
	local scale = WaveLogic.partyScale(TD, #keys)
	-- Twin-road arenas send enemies down both roads only in modes tuned for it (Modes.twinRoads, S1-M05):
	-- the saha also lists its side alley, but Episodes 4 and 6 were balanced on the stair road alone.
	local roads = if (mode :: any).twinRoads and arena.paths then arena.paths else arena.path
	local state = TdSim.new(roads, keys, math.floor(TD.START_CASH * scale.cash + 0.5), diff.gate, total, TD.PREP_SECONDS, {
		between = TD.BETWEEN_WAVES,
		waveBonusBase = TD.WAVE_BONUS_BASE * scale.cash,
		waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE * scale.cash,
		rewardMul = diff.reward,
		enemies = Enemies :: any,
		stunChainMax = TD.STUN_CHAIN_MAX,
		buffCap = TD.BUFF_CAP,
		hasteFloor = TD.HASTE_FLOOR,
		stunImmunity = TD.STUN_IMMUNITY,
		maxSpeedMul = WaveLogic.MAX_SPEED_MUL,
		burnMax = TD.BURN_MAX_STACKS,
		burnTick = TD.BURN_TICK,
		burnDamage = TD.BURN_DAMAGE,
		burnFor = TD.BURN_SECONDS,
	}, function(wave: number)
		if episode then
			return WaveLogic.story(episode, wave, diff, scale, Enemies :: any)
		end
		return WaveLogic.infinite(Waves.infinite, wave, diff, scale, Enemies :: any)
	end)

	local match: Match = {
		id = nextMatchId,
		modeId = modeId,
		mode = mode,
		difficulty = difficulty,
		slot = slot,
		state = state,
		players = {},
		byKey = {},
		order = {},
		host = host,
		speed = 1,
		votes = {},
		accum = 0,
		posAt = 0,
		ended = false,
		outcome = nil,
		script = if episode then (episode :: any).script else nil,
		eventBuffer = {},
		buffShown = {},
		buffCount = {},
		cashTotals = {},
		revealShown = {},
		placeCounts = {},
		sabotaged = {},
	}
	nextMatchId += 1
	matches[match.id] = match
	local names = {}
	for k, p in party do
		local profile = DataService.getProfile(p)
		local ps = state.players[keyOf(p)]
		if ps and profile then
			ps.autoAbility = Settings.get(profile.settings, "autoUlt")
		end
		match.players[p] = keyOf(p)
		match.byKey[keyOf(p)] = p
		table.insert(match.order, p)
		byPlayer[p] = match
		table.insert(names, p.Name)
		local character = p.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.CFrame = ArenaService.spawnCFrame(slot, k)
		end
	end
	local payload = {
		matchId = match.id,
		modeId = modeId,
		arenaId = mode.arena,
		origin = slot.origin.Position,
		difficulty = difficulty,
		players = names,
		totalWaves = total,
		host = host.Name,
	}
	for p in match.players do
		evStart:FireClient(p, payload)
		Analytics.custom(p, "MatchStart_" .. modeId .. "_" .. difficulty)
		FunnelService.reach(p, "portal")
	end
	pushState(match)
	return match, nil
end

function MatchService.matchOf(player: Player): Match?
	return byPlayer[player]
end

-- Studio test hook: sets the gate HP (DebugService only).
function MatchService.debugSetGate(player: Player, hp: number)
	local match = byPlayer[player]
	if match and not match.ended then
		match.state.gateHp = math.clamp(math.floor(hp), 1, match.state.gateMax)
		pushState(match)
	end
end

-- Studio test hook: adds match cash to a player (DebugService only).
-- Adds wave cash to the player's share of their current match (codes, debug). False when not in one.
function MatchService.addCash(player: Player, amount: number): boolean
	local match = byPlayer[player]
	local key = match and match.players[player]
	local ps = key and match and match.state.players[key]
	if match and ps then
		ps.cash += amount
		pushState(match)
		return true
	end
	return false
end

function MatchService.debugAddCash(player: Player, amount: number)
	MatchService.addCash(player, amount)
end

-- Studio test hook (DebugService only): stands a story ally (no owner, no profile change) at the
-- player's feet, e.g. Al-Adashari to watch his Oath without granting him (S1-S12).
function MatchService.debugAlly(player: Player, unitId: string, level: number): (boolean, string?)
	local match = byPlayer[player]
	local def = (Units :: any)[unitId]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not match or match.ended or not def or not root then
		return false, "not in a match / unknown unit"
	end
	local lx, lz = ArenaService.toLocal(match.slot, root.Position)
	local ally = TdTowers.addAlly(match.state, unitId, def, level, lx, lz, rulesFor(match), 0)
	ArenaService.buildTower(match.slot, ally, "")
	queueEvent(match, { type = "towerPlaced", id = ally.id, owner = nil, ally = true, unitId = unitId, x = lx, z = lz, level = ally.level, range = ally.stats.range })
	return true, nil
end

-- Studio test hook (DebugService only): queues the given attackers into the running wave, one every
-- `gap` seconds from now, at the wave's HP multiplier. Lets a play-test meet enemies no wave script
-- uses yet (S1-S03). Returns false outside a wave.
function MatchService.debugSpawn(player: Player, enemyIds: { string }, gap: number): (boolean, string?)
	local match = byPlayer[player]
	if not match or match.ended or match.state.phase ~= "wave" then
		return false, "not in a wave"
	end
	local s = match.state
	local now = s.time - s.waveStartedAt
	local hpMul = if s.queue[1] then s.queue[1].hpMul else 1
	for k, id in enemyIds do
		if not (Enemies :: any)[id] then
			return false, "unknown enemy " .. id
		end
		table.insert(s.queue, s.queueIndex + k - 1, { at = now + (k - 1) * gap, enemy = id, hpMul = hpMul, speedMul = 1, boss = (Enemies :: any)[id].boss })
	end
	return true, nil
end

function MatchService.count(): number
	local n = 0
	for _ in matches do
		n += 1
	end
	return n
end

------------------------------------------------------------------------------------------
-- Tower actions (RemoteFunctions)

local function towerContext(player: Player): (Match?, any?, string?)
	local match = byPlayer[player]
	if not match or match.ended then
		return nil, nil, "not_in_match"
	end
	local profile = DataService.getProfile(player)
	if not profile then
		return nil, nil, "not_loaded"
	end
	return match, profile, nil
end

-- Support buffs change whenever a tower is placed, upgraded, sold, sabotaged or back: badge every
-- defender whose damage supports multiply (TdSim.buffInfo, the same rule the simulation uses: the
-- stacked, capped total and how many supports count) and tell clients.
local function refreshBuffs(match: Match)
	for _, t in match.state.towers do
		local info = if t.stats.damage > 0 then TdSim.buffInfo(match.state, t) else nil
		local b = if info then info.mul else 1
		local n = if info and b > 1 then info.count else 0
		if b ~= (match.buffShown[t.id] or 1) or n ~= (match.buffCount[t.id] or 0) then
			if b > 1 then
				match.buffShown[t.id] = b
				match.buffCount[t.id] = n
			else
				match.buffShown[t.id] = nil
				match.buffCount[t.id] = nil
			end
			local model = ArenaService.findTower(match.slot, t.id)
			if model then
				ArenaService.setBuff(model, b, n)
			end
			queueEvent(match, { type = "towerBuff", id = t.id, buff = b, count = n })
		end
		-- Natour's lantern (TdSim.revealerFor): a defender that can't see stealth on its own is told
		-- which lantern lets it, so its panel can say "sees hidden thieves thanks to …".
		local r = if t.stats.damage > 0 and not t.stats.hitsStealth then TdSim.revealerFor(match.state, t) else nil
		local rid = if r then r.id else nil
		if rid ~= match.revealShown[t.id] then
			if rid then
				match.revealShown[t.id] = rid
			else
				match.revealShown[t.id] = nil
			end
			queueEvent(match, { type = "towerReveal", id = t.id, by = if r then r.unitId else nil, byTower = rid })
		end
	end
end

local function placeTower(player: Player, unitId: any, x: any, z: any): { [string]: any }
	local match, profile, err = towerContext(player)
	if not match or not profile then
		return { ok = false, err = err }
	end
	if not Validate.isIdentifier(unitId) or not Validate.isFiniteNumber(x) or not Validate.isFiniteNumber(z) then
		return { ok = false, err = "bad_request" }
	end
	local def = (Units :: any)[unitId]
	if not def or not profile.units[unitId] or not table.find(profile.loadout, unitId) then
		return { ok = false, err = "not_in_loadout" }
	end
	local lx, lz = ArenaService.toLocal(match.slot, Vector3.new(x, 0, z))
	local owned = profile.units[unitId]
	local stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES)
	local trait = UnitLogic.ownedTrait(owned, Traits.traits, TD.STAR_COPIES, TD.TRAIT2_STARS)
	local bead = UnitLogic.beadBonus(owned.beads, Beads)
	local key = match.players[player]
	local ok, perr, tower = TdTowers.place(match.state, key, unitId, def, lx, lz, stars, trait, rulesFor(match), bead)
	if not ok then
		return { ok = false, err = perr }
	end
	ArenaService.buildTower(match.slot, tower, player.Name)
	queueEvent(match, { type = "towerPlaced", id = tower.id, owner = player.Name, unitId = unitId, x = lx, z = lz, level = 1, range = tower.stats.range })
	refreshBuffs(match)
	flushEvents(match)
	pushState(match)
	return { ok = true, towerId = tower.id }
end

-- Studio test hook: places a loadout unit at arena-local coordinates, bypassing the client raycast
-- but not the rules (DebugService only).
function MatchService.debugPlace(player: Player, unitId: string, lx: number, lz: number): (boolean, string?)
	local match = byPlayer[player]
	if not match then
		return false, "not_in_match"
	end
	local world = match.slot.origin * CFrame.new(lx, 0, lz)
	local r = placeTower(player, unitId, world.Position.X, world.Position.Z)
	return r.ok == true, r.err
end

-- path: nil, or "a" | "b" for the level-7 signature (TdTowers refuses it anywhere else).
local function upgradeTower(player: Player, towerId: any, path: any): { [string]: any }
	if path ~= nil and path ~= "a" and path ~= "b" then
		return { ok = false, err = "bad_request" }
	end
	local match, _, err = towerContext(player)
	if not match then
		return { ok = false, err = err }
	end
	local key = match.players[player]
	local tower = nil
	for _, t in match.state.towers do
		if t.id == towerId then
			tower = t
		end
	end
	if not tower then
		return { ok = false, err = "not_yours" }
	end
	local ok, uerr = TdTowers.upgrade(match.state, key, towerId, (Units :: any)[tower.unitId], rulesFor(match), path)
	if not ok then
		return { ok = false, err = uerr }
	end
	local model = ArenaService.findTower(match.slot, towerId)
	if model then
		model:SetAttribute("Level", tower.level)
		model:SetAttribute("Range", tower.stats.range)
	end
	queueEvent(match, { type = "towerUpgraded", id = towerId, level = tower.level, range = tower.stats.range, path = tower.path })
	refreshBuffs(match)
	flushEvents(match)
	pushState(match)
	return { ok = true, level = tower.level }
end

local function sellTower(player: Player, towerId: any): { [string]: any }
	local match, _, err = towerContext(player)
	if not match then
		return { ok = false, err = err }
	end
	local ok, serr, refund = TdTowers.sell(match.state, match.players[player], towerId, rulesFor(match))
	if not ok then
		return { ok = false, err = serr }
	end
	local model = ArenaService.findTower(match.slot, towerId)
	if model then
		model:Destroy()
	end
	queueEvent(match, { type = "towerSold", id = towerId })
	match.buffShown[towerId] = nil
	match.buffCount[towerId] = nil
	match.revealShown[towerId] = nil
	refreshBuffs(match)
	flushEvents(match)
	pushState(match)
	return { ok = true, refund = refund }
end

------------------------------------------------------------------------------------------
-- Loop

local MAX_STEPS_PER_FRAME = 6

local function stepMatch(match: Match, dt: number)
	if match.ended then
		return
	end
	match.accum += dt * match.speed
	local steps = 0
	local changed = false
	local autoSkip = false
	while match.accum >= TD.TICK and steps < MAX_STEPS_PER_FRAME do
		match.accum -= TD.TICK
		steps += 1
		local events = TdSim.step(match.state, TD.TICK)
		for _, e in events do
			local t = e.type
			if t == "waveStart" then
				match.votes = {}
				changed = true
				queueEvent(match, e)
				-- Story beats: Al-Adashari turns at the gate (Episode 8) or guards it from wave 1 (Episode 9).
				local ally = TdTowers.runScript(match.state, match.script, e.wave, Units :: any, rulesFor(match), (Arenas[match.slot.arenaId] :: any).allySpot)
				if ally then
					ArenaService.buildTower(match.slot, ally, "")
					queueEvent(match, { type = "towerPlaced", id = ally.id, owner = nil, ally = true, unitId = ally.unitId, x = ally.x, z = ally.z, level = ally.level, range = ally.stats.range })
					queueEvent(match, { type = "ally", id = ally.id, unitId = ally.unitId, shield = match.state.allyShield })
				end
			elseif t == "towerDisabled" then
				-- A saboteur's shot: the tower can't attack and, if it is a lantern, goes dark
				if type(e.tower) == "number" and type(e.untilT) == "number" then
					match.sabotaged[e.tower] = e.untilT
				end
				queueEvent(match, e)
				refreshBuffs(match)
			elseif t == "waveEnd" or t == "reached" or t == "gateBurn" then
				changed = true
				queueEvent(match, e)
				if t == "waveEnd" then
					autoSkip = true
					-- Each player's running total for the result screen's curve (LP-C06).
					for key, ps in match.state.players do
						local list = match.cashTotals[key] or {}
						table.insert(list, ps.cash + ps.spent)
						match.cashTotals[key] = list
					end
					-- The sim clears every sabotage at wave end
					for id in match.sabotaged do
						queueEvent(match, { type = "towerEnabled", id = id })
					end
					if next(match.sabotaged) ~= nil then
						table.clear(match.sabotaged)
						refreshBuffs(match)
					end
					for p in match.players do
						FunnelService.waveCleared(p, e.wave)
					end
				end
			elseif t == "death" then
				local owner = match.byKey[e.owner]
				e.owner = if owner then owner.Name else nil
				changed = true
				queueEvent(match, e)
			elseif t == "won" then
				queueEvent(match, e)
				finish(match, true)
				return
			elseif t == "lost" then
				queueEvent(match, e)
				finish(match, false)
				return
			else
				queueEvent(match, e)
			end
		end
	end
	-- Sabotage wearing off mid-wave: the tower is back (and a lantern lights up again)
	local back = false
	for id, untilT in match.sabotaged do
		if match.state.time >= untilT then
			match.sabotaged[id] = nil
			queueEvent(match, { type = "towerEnabled", id = id })
			back = true
		end
	end
	if back then
		refreshBuffs(match)
	end
	if match.accum > TD.TICK * MAX_STEPS_PER_FRAME then
		match.accum = 0 -- the server fell behind; drop time instead of spiralling
	end
	if autoSkip and autoSkipVotes(match) then
		changed = true
	end
	flushEvents(match)
	local now = os.clock()
	if now - match.posAt >= TD.POSITION_RATE then
		match.posAt = now
		sendPositions(match)
		if match.state.phase == "prep" or changed then
			pushState(match)
		end
	elseif changed then
		pushState(match)
	end
end

function MatchService.start()
	evState = Net.event(Net.Events.MatchState)
	evEvents = Net.event(Net.Events.MatchEvents)
	evStart = Net.event(Net.Events.MatchStart)
	evEnd = Net.event(Net.Events.MatchEnd)
	evHome = Net.event(Net.Events.MatchHome)
	evPositions = Net.unreliable(Net.Events.EnemyPositions)

	RemoteGuard.func(Net.Functions.PlaceTower, RemoteGuard.DEFAULT, function(player: Player, unitId: any, x: any, z: any)
		local r = placeTower(player, unitId, x, z)
		local match = byPlayer[player]
		if match then
			countPlacement(match, player, DeviceTelemetry.classify(Hud, r.ok == true, r.err))
		end
		return r
	end)
	RemoteGuard.event(Net.Events.PlaceCancelled, Hud.TELEMETRY.cancelLimit, function(player: Player)
		local match = byPlayer[player]
		if match then
			countPlacement(match, player, "cancelled")
		end
	end)
	RemoteGuard.func(Net.Functions.UpgradeTower, RemoteGuard.DEFAULT, upgradeTower)
	RemoteGuard.func(Net.Functions.SellTower, RemoteGuard.DEFAULT, sellTower)

	RemoteGuard.event(Net.Events.SetTargeting, RemoteGuard.DEFAULT, function(player: Player, towerId: any, mode: any)
		local match = byPlayer[player]
		if match and not match.ended then
			if TdTowers.setTargeting(match.state, match.players[player], towerId, mode) then
				queueEvent(match, { type = "towerTargeting", id = towerId, mode = mode })
			end
		end
	end)

	-- The owner taps a defender's ultimate (validated by TdTowers.useAbility: owner, ability,
	-- cooldown, match still running).
	RemoteGuard.event(Net.Events.UseAbility, RemoteGuard.DEFAULT, function(player: Player, towerId: any)
		local match = byPlayer[player]
		if not match or match.ended or not Validate.isPositiveInteger(towerId) then
			return
		end
		local ok, err = TdTowers.useAbility(match.state, match.players[player], towerId)
		if not ok and err == "not_ready" then
			PlayerStateService.notify(player, "match.err.ult_not_ready")
		end
	end)

	-- One defender's own auto ultimate (LP-B01, the Defenders panel): overrides the player's setting
	-- for that defender (TdTowers.setAutoAbility checks owner, boolean, ability and phase).
	RemoteGuard.event(Net.Events.SetAutoAbility, TD.AUTO_ABILITY_LIMIT, function(player: Player, towerId: any, on: any)
		local match = byPlayer[player]
		if not match or match.ended or not Validate.isPositiveInteger(towerId) or type(on) ~= "boolean" then
			return
		end
		if TdTowers.setAutoAbility(match.state, match.players[player], towerId, on) then
			queueEvent(match, { type = "towerAuto", id = towerId, on = on })
		end
	end)

	-- Auto ultimate follows the player's setting, live (the HUD toggle writes the setting).
	DataService.ProfileChanged:Connect(function(player: Player)
		local match = byPlayer[player]
		local profile = DataService.getProfile(player)
		if match and profile then
			local ps = match.state.players[match.players[player]]
			if ps then
				ps.autoAbility = Settings.get(profile.settings, "autoUlt")
			end
			-- Turning auto skip on during a countdown votes straight away
			if autoSkipVotes(match) then
				pushState(match)
			end
		end
	end)

	RemoteGuard.event(Net.Events.VoteSkip, RemoteGuard.STRICT, function(player: Player)
		local match = byPlayer[player]
		if match and castSkipVote(match, player) then
			pushState(match)
		end
	end)

	RemoteGuard.event(Net.Events.SetSpeed, RemoteGuard.STRICT, function(player: Player, speed: any)
		local match = byPlayer[player]
		if not match or match.ended or match.host ~= player then
			return
		end
		-- One of TD.SPEEDS, and within what the host's passes allow (LP-A03).
		local ok, why = MonetizationLogic.checkSpeed(speed, MonetizationService.maxSpeed(player), TD)
		if not ok then
			if why == "needs_pass" then
				PlayerStateService.notify(player, "match.err.fast_pass")
			end
			return
		end
		match.speed = speed
		pushState(match)
	end)

	RemoteGuard.event(Net.Events.LeaveMatch, RemoteGuard.STRICT, function(player: Player)
		local match = byPlayer[player]
		if match then
			removePlayer(match, player, true)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local match = byPlayer[player]
		if match then
			removePlayer(match, player, false)
		end
	end)

	-- Respawns inside a match land on the arena pad, not at the lane gate.
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			local match = byPlayer[player]
			if match and not match.ended then
				local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
				if root then
					task.wait()
					root.CFrame = ArenaService.spawnCFrame(match.slot, 1)
				end
			end
		end)
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		for _, match in matches do
			stepMatch(match, math.min(dt, 0.25))
		end
	end)
end

return MatchService
