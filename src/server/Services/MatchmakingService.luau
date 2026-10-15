--!strict
-- Lobby portals: step on a pad to join that mode's party; a countdown starts with the first
-- player and shortens when the party is full. The host (first in) picks the difficulty. Walking
-- off the pad leaves the party. When the countdown ends the party is handed to MatchService.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local MatchRewards = require(Shared.Logic.MatchRewards)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MatchService = require(script.Parent.MatchService)

local MatchmakingService = {}

MatchmakingService.TAG = "Portal"

type Queue = { modeId: string, pad: BasePart, players: { Player }, host: Player?, difficulty: string, startAt: number }

local queues: { [string]: Queue } = {}
local queueOf: { [Player]: Queue } = {}
local evQueue: RemoteEvent

local PAD_RADIUS = 5.5

local function broadcast(q: Queue)
	local names = {}
	for _, p in q.players do
		table.insert(names, p.Name)
	end
	local payload = {
		modeId = q.modeId,
		players = names,
		countdown = math.max(0, q.startAt - os.clock()),
		difficulty = q.difficulty,
		host = if q.host then q.host.Name else nil,
		max = TD.MAX_PLAYERS,
	}
	for _, p in q.players do
		evQueue:FireClient(p, payload)
	end
	q.pad:SetAttribute("Count", #q.players)
end

local function leave(player: Player, notifyOthers: boolean)
	local q = queueOf[player]
	if not q then
		return
	end
	queueOf[player] = nil
	for i, p in q.players do
		if p == player then
			table.remove(q.players, i)
			break
		end
	end
	if q.host == player then
		q.host = q.players[1]
	end
	if #q.players == 0 then
		q.startAt = math.huge
	end
	evQueue:FireClient(player, nil)
	if notifyOthers then
		for _, p in q.players do
			PlayerStateService.notify(p, "queue.left", { name = player.Name })
		end
	end
	broadcast(q)
end

local function join(player: Player, q: Queue)
	if queueOf[player] == q or MatchService.matchOf(player) then
		return
	end
	local profile = DataService.getProfile(player)
	if not profile then
		return
	end
	if queueOf[player] then
		leave(player, true)
	end
	if #q.players >= TD.MAX_PLAYERS then
		return
	end
	local ok, err = MatchRewards.canPlay(profile, q.modeId, Modes :: any, "normal", TD)
	if not ok then
		if err == "locked_mode" then
			local req = Modes[q.modeId].requires
			PlayerStateService.notify(player, "mode.locked", { modeKey = if req then Modes[req].nameKey else "" })
		end
		return
	end
	table.insert(q.players, player)
	queueOf[player] = q
	if #q.players == 1 then
		q.host = player
		q.difficulty = "normal"
		q.startAt = os.clock() + TD.QUEUE_SECONDS
	else
		for _, p in q.players do
			if p ~= player then
				PlayerStateService.notify(p, "queue.joined", { name = player.Name })
			end
		end
	end
	if #q.players >= TD.MAX_PLAYERS then
		q.startAt = math.min(q.startAt, os.clock() + TD.QUEUE_FULL_SECONDS)
	end
	broadcast(q)
end

local function onPad(player: Player, q: Queue): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local d = root.Position - q.pad.Position
	return math.abs(d.X) <= PAD_RADIUS and math.abs(d.Z) <= PAD_RADIUS and math.abs(d.Y) < 12
end

local function launch(q: Queue)
	local party = table.clone(q.players)
	local host = q.host
	if #party == 0 or not host then
		return
	end
	-- The host must have unlocked the chosen difficulty; otherwise fall back to Normal.
	local profile = DataService.getProfile(host)
	local difficulty = q.difficulty
	if not profile or not MatchRewards.canPlay(profile, q.modeId, Modes :: any, difficulty, TD) then
		difficulty = "normal"
	end
	for _, p in party do
		queueOf[p] = nil
		evQueue:FireClient(p, nil)
	end
	q.players = {}
	q.host = nil
	q.startAt = math.huge
	broadcast(q)
	local match, err = MatchService.create(q.modeId, difficulty, party, host)
	if not match then
		for _, p in party do
			PlayerStateService.notify(p, "notify.error")
		end
		warn("[Matchmaking] could not start: " .. tostring(err))
	end
end

local function tick()
	local now = os.clock()
	for _, q in queues do
		-- Drop players who walked away or left the game
		for i = #q.players, 1, -1 do
			local p = q.players[i]
			if not p.Parent or not onPad(p, q) then
				leave(p, true)
			end
		end
		if #q.players > 0 then
			if now >= q.startAt then
				launch(q)
			else
				broadcast(q)
			end
		end
	end
end

local function hookPad(pad: Instance)
	if not pad:IsA("BasePart") then
		return
	end
	local modeId = pad:GetAttribute("ModeId")
	if type(modeId) ~= "string" or not Modes[modeId] then
		return
	end
	local q: Queue = { modeId = modeId, pad = pad, players = {}, host = nil, difficulty = "normal", startAt = math.huge }
	queues[modeId] = q
	pad.Touched:Connect(function(hit: BasePart)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			join(player, q)
		end
	end)
end

function MatchmakingService.start()
	evQueue = Net.event(Net.Events.QueueState)
	for _, pad in CollectionService:GetTagged(MatchmakingService.TAG) do
		hookPad(pad)
	end
	CollectionService:GetInstanceAddedSignal(MatchmakingService.TAG):Connect(hookPad)

	RemoteGuard.event(Net.Events.QueueLeave, RemoteGuard.STRICT, function(player: Player)
		leave(player, true)
	end)
	RemoteGuard.event(Net.Events.QueueSetDifficulty, RemoteGuard.STRICT, function(player: Player, difficulty: any)
		local q = queueOf[player]
		if not q or q.host ~= player or not Validate.isIdentifier(difficulty) or not TD.DIFFICULTIES[difficulty] then
			return
		end
		local profile = DataService.getProfile(player)
		if not profile then
			return
		end
		local ok, err = MatchRewards.canPlay(profile, q.modeId, Modes :: any, difficulty, TD)
		if not ok then
			if err == "locked_difficulty" then
				PlayerStateService.notify(player, "mode.locked_difficulty")
			end
			return
		end
		q.difficulty = difficulty
		broadcast(q)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		leave(player, true)
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			tick()
		end
	end)
end

return MatchmakingService
