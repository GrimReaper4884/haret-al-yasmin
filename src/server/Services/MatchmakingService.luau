--!strict
-- Lobby parties (the Play panel). A player creates a party for a mode and difficulty, or joins an
-- open one from the list; a countdown starts on creation, shortens when the party is full or the
-- host taps Start, and then the party is handed to MatchService. From the result screen, Replay
-- and Next make a party for the same (or the following) episode that the rest of the old team
-- can join with one tap. Every request is validated here: unlocks against the profile, host-only
-- actions against the host, sizes against TD.MAX_PLAYERS.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local MatchRewards = require(Shared.Logic.MatchRewards)
local PartyLogic = require(Shared.Logic.PartyLogic)
local EventLogic = require(Shared.Logic.EventLogic)
local Events = require(Shared.Config.Events)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MatchService = require(script.Parent.MatchService)

local MatchmakingService = {}

-- Set by AfkService: returns an error key while a player may not queue (sitting in the AFK room).
MatchmakingService.blocked = nil :: ((Player) -> string?)?

type Party = PartyLogic.Party<Player> & { replayKey: string? }

local START_SOON = 3 -- seconds after the host taps Start

local parties: { [number]: Party } = {}
local partyOf: { [Player]: Party } = {}
local nextId = 1
local listDirty = true
-- What each player last played (for Replay / Next), and the replay party of each finished match.
local lastPlayed: { [Player]: { modeId: string, difficulty: string, matchId: number, homeAt: number } } = {}
local replayParties: { [string]: Party } = {}

local evQueue: RemoteEvent
local evList: RemoteEvent

local function names(party: Party): { string }
	local out = {}
	for _, p in party.players do
		table.insert(out, p.Name)
	end
	return out
end

local function broadcast(party: Party)
	local payload = {
		partyId = party.id,
		modeId = party.modeId,
		players = names(party),
		countdown = math.max(0, party.startAt - os.clock()),
		difficulty = party.difficulty,
		host = if party.host then party.host.Name else nil,
		max = TD.MAX_PLAYERS,
	}
	for _, p in party.players do
		evQueue:FireClient(p, payload)
	end
	listDirty = true
end

local function sendList()
	listDirty = false
	local list = {}
	for _, party in parties do
		table.insert(list, {
			id = party.id,
			modeId = party.modeId,
			difficulty = party.difficulty,
			host = if party.host then party.host.Name else "",
			count = #party.players,
			max = TD.MAX_PLAYERS,
			countdown = math.max(0, math.floor(party.startAt - os.clock())),
		})
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	evList:FireAllClients(list)
end

local function drop(party: Party)
	parties[party.id] = nil
	if party.replayKey then
		replayParties[party.replayKey] = nil
	end
	listDirty = true
end

local function leave(player: Player, notifyOthers: boolean)
	local party = partyOf[player]
	if not party then
		return
	end
	partyOf[player] = nil
	local empty = PartyLogic.leave(party, player)
	evQueue:FireClient(player, nil)
	if empty then
		drop(party)
		return
	end
	if notifyOthers then
		for _, p in party.players do
			PlayerStateService.notify(p, "queue.left", { name = player.Name })
		end
	end
	broadcast(party)
end

local function lockedNotice(player: Player, modeId: string, err: string?)
	if err == "locked_mode" then
		local req = Modes[modeId].requires
		PlayerStateService.notify(player, "mode.locked", { modeKey = if req then Modes[req].nameKey else "" })
	elseif err == "locked_difficulty" then
		PlayerStateService.notify(player, "mode.locked_difficulty")
	elseif err == "event_over" then
		PlayerStateService.notify(player, "event.over")
	end
end

-- Everyone in a party plays the host's difficulty, so a member only needs the mode unlocked.
local function canEnter(player: Player, modeId: string, difficulty: string): (boolean, string?)
	local profile = DataService.getProfile(player)
	if not profile then
		return false, "no_profile"
	end
	local mode = Modes[modeId]
	if mode and mode.kind == "event" then
		if difficulty ~= "normal" then
			return false, "bad_difficulty"
		end
		if not EventLogic.forMode(Events, modeId, os.time()) then
			return false, "event_over"
		end
	end
	return MatchRewards.canPlay(profile, modeId, Modes :: any, difficulty, TD)
end

local function create(player: Player, modeId: string, difficulty: string, startDelay: number?): (Party?, string?)
	if MatchService.matchOf(player) and not lastPlayed[player] then
		return nil, "in_match"
	end
	local ok, err = canEnter(player, modeId, difficulty)
	if not ok then
		lockedNotice(player, modeId, err)
		return nil, err
	end
	leave(player, true)
	local party: Party = PartyLogic.new(nextId, modeId, difficulty, player, os.clock(), startDelay or TD.QUEUE_SECONDS) :: any
	nextId += 1
	parties[party.id] = party
	partyOf[player] = party
	broadcast(party)
	return party, nil
end

local function join(player: Player, party: Party): (boolean, string?)
	if partyOf[player] == party then
		return true, nil
	end
	local ok, err = canEnter(player, party.modeId, "normal")
	if not ok then
		lockedNotice(player, party.modeId, err)
		return false, err
	end
	leave(player, true)
	local joined, jerr = PartyLogic.join(party, player, TD.MAX_PLAYERS, os.clock(), TD.QUEUE_FULL_SECONDS)
	if not joined then
		return false, jerr
	end
	partyOf[player] = party
	for _, p in party.players do
		if p ~= player then
			PlayerStateService.notify(p, "queue.joined", { name = player.Name })
		end
	end
	broadcast(party)
	return true, nil
end

local function launch(party: Party)
	-- Wait for anyone still on a result screen to come home.
	for _, p in party.players do
		if MatchService.matchOf(p) then
			party.startAt = os.clock() + 1
			return
		end
	end
	local host = party.host
	if #party.players == 0 or not host then
		drop(party)
		return
	end
	-- The host must have unlocked the chosen difficulty; otherwise fall back to Normal.
	local difficulty = party.difficulty
	if not canEnter(host, party.modeId, difficulty) then
		difficulty = "normal"
	end
	local members = table.clone(party.players)
	for _, p in members do
		partyOf[p] = nil
		lastPlayed[p] = nil
		evQueue:FireClient(p, nil)
	end
	drop(party)
	local match, err = MatchService.create(party.modeId, difficulty, members, host)
	if not match then
		for _, p in members do
			PlayerStateService.notify(p, "notify.error")
		end
		warn("[Matchmaking] could not start: " .. tostring(err))
	end
end

local function tick()
	local now = os.clock()
	for _, party in parties do
		for i = #party.players, 1, -1 do
			local p = party.players[i]
			if not p.Parent then
				leave(p, true)
			end
		end
		if parties[party.id] then
			if now >= party.startAt then
				launch(party)
			else
				broadcast(party)
			end
		end
	end
	if listDirty then
		sendList()
	end
end

-- Replay ("replay") or Next ("next") from the result screen.
local function replay(player: Player, kind: string): { [string]: any }
	local last = lastPlayed[player]
	if not last then
		return { ok = false, err = "nothing_to_replay" }
	end
	local modeId = last.modeId
	local difficulty = last.difficulty
	if kind == "next" then
		local nextMode = PartyLogic.nextMode(Modes :: any, modeId)
		if not nextMode then
			return { ok = false, err = "no_next" }
		end
		modeId = nextMode
		if not canEnter(player, modeId, difficulty) then
			difficulty = "normal"
		end
	end
	local key = string.format("%d:%s", last.matchId, kind)
	local existing = replayParties[key]
	if existing and parties[existing.id] then
		local ok, err = join(player, existing)
		return { ok = ok, err = err }
	end
	-- Launch a few seconds after everyone is home from the result screen.
	local delay = math.max(TD.QUEUE_FULL_SECONDS, last.homeAt - os.clock() + TD.QUEUE_FULL_SECONDS)
	local party, err = create(player, modeId, difficulty, delay)
	if not party then
		return { ok = false, err = err }
	end
	party.replayKey = key
	replayParties[key] = party
	return { ok = true }
end

-- Takes the player out of any party they are queued in (entering the AFK room).
function MatchmakingService.leaveParty(player: Player)
	leave(player, true)
end

function MatchmakingService.start()
	evQueue = Net.event(Net.Events.QueueState)
	evList = Net.event(Net.Events.PartyList)

	RemoteGuard.func(Net.Functions.PartyCreate, RemoteGuard.STRICT, function(player: Player, modeId: any, difficulty: any)
		if not Validate.isIdentifier(modeId) or not Modes[modeId] or not Validate.isIdentifier(difficulty) or not TD.DIFFICULTIES[difficulty] then
			return { ok = false, err = "bad_request" }
		end
		if MatchService.matchOf(player) then
			return { ok = false, err = "in_match" }
		end
		local blocked = MatchmakingService.blocked and MatchmakingService.blocked(player)
		if blocked then
			return { ok = false, err = blocked }
		end
		local party, err = create(player, modeId, difficulty)
		return { ok = party ~= nil, err = err }
	end)
	RemoteGuard.func(Net.Functions.PartyJoin, RemoteGuard.STRICT, function(player: Player, partyId: any)
		if not Validate.isPositiveInteger(partyId) then
			return { ok = false, err = "bad_request" }
		end
		local party = parties[partyId]
		if not party then
			return { ok = false, err = "gone" }
		end
		if MatchService.matchOf(player) then
			return { ok = false, err = "in_match" }
		end
		local blocked = MatchmakingService.blocked and MatchmakingService.blocked(player)
		if blocked then
			return { ok = false, err = blocked }
		end
		local ok, err = join(player, party)
		return { ok = ok, err = err }
	end)
	RemoteGuard.func(Net.Functions.PartyReplay, RemoteGuard.STRICT, function(player: Player, kind: any)
		if kind ~= "replay" and kind ~= "next" then
			return { ok = false, err = "bad_request" }
		end
		return replay(player, kind)
	end)
	RemoteGuard.event(Net.Events.QueueLeave, RemoteGuard.STRICT, function(player: Player)
		leave(player, true)
	end)
	RemoteGuard.event(Net.Events.PartyStart, RemoteGuard.STRICT, function(player: Player)
		local party = partyOf[player]
		if party and PartyLogic.startSoon(party, player, os.clock(), START_SOON) then
			broadcast(party)
		end
	end)
	RemoteGuard.event(Net.Events.QueueSetDifficulty, RemoteGuard.STRICT, function(player: Player, difficulty: any)
		local party = partyOf[player]
		if not party or party.host ~= player or not Validate.isIdentifier(difficulty) or not TD.DIFFICULTIES[difficulty] then
			return
		end
		local ok, err = canEnter(player, party.modeId, difficulty)
		if not ok then
			lockedNotice(player, party.modeId, err)
			return
		end
		party.difficulty = difficulty
		broadcast(party)
	end)

	-- Remember each finished match for Replay / Next.
	MatchService.Ended:Connect(function(match: any)
		local homeAt = os.clock() + TD.RESULT_SECONDS
		for p in match.players do
			lastPlayed[p] = { modeId = match.modeId, difficulty = match.difficulty, matchId = match.id, homeAt = homeAt }
		end
	end)

	Players.PlayerAdded:Connect(function()
		listDirty = true
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		leave(player, true)
		lastPlayed[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			tick()
		end
	end)
end

return MatchmakingService
