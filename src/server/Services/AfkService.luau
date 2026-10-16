--!strict
-- The AFK chamber: the Hakawati's room upstairs in the coffee house (docs/AFK_CHAMBER.md,
-- Config/Afk, Logic/AfkLogic). Server-authoritative: the server seats the player, counts the
-- seconds they spend inside the room, and pays cups of tea and finished tales. The client only
-- asks to enter, to leave, and to hop servers before Roblox's 20-minute idle kick.
--
-- Sitting time is held in memory and written into the profile at every payout, at least every
-- FLUSH_SECONDS, on leaving, and just before the final save (DataService.beforeRelease), so a
-- disconnect loses nothing. The anti-idle hop teleports the player to a fresh server of this
-- place with TeleportData { afk = true }; on arrival they are walked straight back in.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Afk = require(Shared.Config.Afk)
local AfkLogic = require(Shared.Logic.AfkLogic)
local AfkRoom = require(script.Parent.Parent.World.AfkRoom)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MonetizationService = require(script.Parent.MonetizationService)
local MatchService = require(script.Parent.MatchService)
local MatchmakingService = require(script.Parent.MatchmakingService)
local MetaService = require(script.Parent.MetaService)
local Analytics = require(script.Parent.AnalyticsService)

local AfkService = {}

type Earned = { lira: number, qirsh: number, xp: number, traitStones: number, cups: number, tales: number }
type Session = {
	started: number, -- os.clock()
	pending: number, -- sitting seconds not yet written into the profile
	lastFlush: number,
	lastTick: number,
	placing: boolean, -- being moved in (streaming, respawn): no time counts, no bounds check
	seat: Seat?,
	reason: string,
	earned: Earned,
}

local REASONS = { menu = true, idle = true, door = true, dialogue = true, hop = true, debug = true }

local sessions: { [Player]: Session } = {}
local lastHop: { [Player]: number } = {}
local origin: CFrame
local seats: { Seat } = {}
local evState: RemoteEvent
local evPayout: RemoteEvent

local function multiplier(player: Player): number
	return AfkLogic.multiplier(
		Afk,
		MonetizationService.hasPerk(player, "vip"),
		player.MembershipType == Enum.MembershipType.Premium
	)
end

local function characterOf(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character, root, humanoid
end

local function insideRoom(pos: Vector3): boolean
	local l = origin:PointToObjectSpace(pos)
	return math.abs(l.X) <= AfkRoom.HALF_X + 1
		and math.abs(l.Z) <= AfkRoom.HALF_Z + 1
		and l.Y > -6
		and l.Y < AfkRoom.HEIGHT + 2
end

local function unseat(humanoid: Humanoid)
	local seatPart = humanoid.SeatPart
	if seatPart then
		local weld = seatPart:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end
	humanoid.Sit = false
end

-- The first free seat (front rows first), skipping seats another session is walking to.
local function freeSeat(except: Session): Seat?
	local claimed: { [Seat]: boolean } = {}
	for _, s in sessions do
		if s ~= except and s.seat then
			claimed[s.seat] = true
		end
	end
	for _, seat in seats do
		if not claimed[seat] and seat.Occupant == nil then
			return seat
		end
	end
	return nil
end

local function sessionView(s: Session): { [string]: number }
	local e = s.earned
	return {
		seconds = math.floor(os.clock() - s.started),
		lira = e.lira,
		qirsh = e.qirsh,
		xp = e.xp,
		traitStones = e.traitStones,
		cups = e.cups,
		tales = e.tales,
	}
end

local function sendState(player: Player, s: Session)
	local profile = DataService.getProfile(player)
	if not profile or not player.Parent then
		return
	end
	evState:FireClient(player, {
		inside = true,
		reason = s.reason,
		carry = profile.afk.carry + s.pending,
		mult = multiplier(player),
		session = sessionView(s),
	})
end

-- Writes pending sitting time into the profile and pays any completed cups. Returns whether a
-- payout happened. Never yields.
local function flush(player: Player, s: Session): boolean
	s.lastFlush = os.clock()
	if s.pending <= 0 then
		return false
	end
	local seconds = s.pending
	s.pending = 0
	local mult = multiplier(player)
	local ok, _, payouts = DataService.mutate(player, function(p)
		return AfkLogic.accrue(p, seconds, os.time(), Afk, mult, math.random, MetaService.grantCtx())
	end)
	if not ok or not payouts then
		return false
	end
	local profile = DataService.getProfile(player)
	for _, pay in payouts :: { AfkLogic.Payout } do
		local g = pay.granted
		s.earned.lira += g.lira or 0
		s.earned.qirsh += g.qirsh or 0
		s.earned.xp += g.xp or 0
		s.earned.traitStones += g.traitStones or 0
		if pay.kind == "cup" then
			s.earned.cups += 1
		else
			s.earned.tales += 1
		end
		if g.lira and g.lira > 0 and profile then
			Analytics.source(player, g.lira, profile.lira, "afk_" .. pay.kind)
		end
		if player.Parent then
			evPayout:FireClient(player, pay)
		end
	end
	return #(payouts :: { any }) > 0
end

-- Moves the player's character onto a free seat in the room (after streaming the room in).
local function place(player: Player, s: Session)
	s.placing = true
	local deadline = os.clock() + 15
	local character, root, humanoid = characterOf(player)
	while (not root or not humanoid or humanoid.Health <= 0) and os.clock() < deadline do
		task.wait(0.25)
		character, root, humanoid = characterOf(player)
	end
	if sessions[player] ~= s then
		return
	end
	if not character or not root or not humanoid then
		AfkService.leave(player, "no_character", false)
		return
	end
	pcall(function()
		player:RequestStreamAroundAsync(origin.Position, 5)
	end)
	if sessions[player] ~= s or player.Character ~= character then
		return
	end
	unseat(humanoid)
	local seat = s.seat
	if not seat or (seat.Occupant ~= nil and seat.Occupant ~= humanoid) then
		seat = freeSeat(s)
	end
	s.seat = seat
	if seat then
		character:PivotTo(seat.CFrame * CFrame.new(0, 2.5, 0))
		seat:Sit(humanoid)
	else
		-- Every seat taken: stand on the carpet in front of the dais.
		character:PivotTo(
			origin * CFrame.new(math.random(-6, 6), 3, math.random(-6, 0)) * CFrame.Angles(0, math.pi, 0)
		)
	end
	s.lastTick = os.clock()
	s.placing = false
end

local function sendHome(player: Player)
	local character, root, humanoid = characterOf(player)
	if not character or not root or not humanoid then
		return
	end
	unseat(humanoid)
	local r = Afk.RETURN
	local target = CFrame.new(r[1], r[2] + 3.5, r[3]) * CFrame.Angles(0, math.rad(-90), 0) -- facing the square (+X)
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 5)
	end)
	if player.Character == character then
		character:PivotTo(target)
	end
end

function AfkService.isInside(player: Player): boolean
	return sessions[player] ~= nil
end

-- Walks the player up to the room. Returns ok, err.
function AfkService.enter(player: Player, reason: string): (boolean, string?)
	if sessions[player] then
		return true, nil
	end
	if not DataService.getProfile(player) then
		return false, "not_loaded"
	end
	if MatchService.matchOf(player) then
		return false, "in_match"
	end
	local _, root, humanoid = characterOf(player)
	if reason ~= "hop" and (not root or not humanoid or humanoid.Health <= 0) then
		return false, "no_character"
	end
	MatchmakingService.leaveParty(player)
	local now = os.clock()
	local s: Session = {
		started = now,
		pending = 0,
		lastFlush = now,
		lastTick = now,
		placing = true,
		seat = nil,
		reason = reason,
		earned = { lira = 0, qirsh = 0, xp = 0, traitStones = 0, cups = 0, tales = 0 },
	}
	sessions[player] = s
	Analytics.custom(player, "AfkEnter_" .. reason)
	sendState(player, s)
	task.spawn(place, player, s)
	return true, nil
end

-- Ends the visit: writes the time, tells the client (with a summary) and optionally walks the
-- character back down to the coffee house.
function AfkService.leave(player: Player, reason: string, goHome: boolean)
	local s = sessions[player]
	if not s then
		return
	end
	flush(player, s)
	sessions[player] = nil
	local summary = sessionView(s)
	Analytics.custom(player, "AfkMinutes", math.floor(summary.seconds / 60))
	if player.Parent then
		evState:FireClient(player, { inside = false, reason = reason, summary = summary })
	end
	if goHome then
		task.spawn(sendHome, player)
	end
end

local function hop(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	if RunService:IsStudio() then
		PlayerStateService.notify(player, "afk.hop_studio")
		return
	end
	local last = lastHop[player]
	if last and os.clock() - last < Afk.HOP_COOLDOWN then
		return
	end
	lastHop[player] = os.clock()
	flush(player, s)
	local options = Instance.new("TeleportOptions")
	options:SetTeleportData({ afk = true })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if ok then
		Analytics.custom(player, "AfkHop")
	else
		warn("[AfkService] hop failed for " .. player.Name .. ": " .. tostring(err))
		PlayerStateService.notify(player, "afk.hop_failed")
	end
end

local function tick()
	local now = os.clock()
	for player, s in sessions do
		local dt = math.min(now - s.lastTick, 5)
		s.lastTick = now
		if s.placing then
			continue
		end
		local _, root, humanoid = characterOf(player)
		if not root or not humanoid or humanoid.Health <= 0 then
			continue -- respawning: CharacterAdded puts them back
		end
		if not insideRoom(root.Position) then
			AfkService.leave(player, "left_room", false)
			continue
		end
		if now - s.started > Afk.MAX_SESSION_SECONDS then
			AfkService.leave(player, "long", true)
			continue
		end
		s.pending += dt
		local profile = DataService.getProfile(player)
		if
			profile
			and (profile.afk.carry + s.pending >= Afk.CUP_SECONDS or now - s.lastFlush >= Afk.FLUSH_SECONDS)
		then
			if flush(player, s) then
				sendState(player, s)
			end
		end
	end
end

-- Studio test hook: adds sitting time at once (pays cups and tales as if the player had sat).
function AfkService.debugAdvance(player: Player, seconds: number)
	local s = sessions[player]
	if not s then
		return false
	end
	local left = math.clamp(seconds, 0, 24 * 3600)
	while left > 0 do
		local chunk = math.min(left, Afk.FLUSH_SECONDS * 4)
		s.pending += chunk
		left -= chunk
		flush(player, s)
	end
	sendState(player, s)
	return true
end

function AfkService.start()
	evState = Net.event(Net.Events.AfkState)
	evPayout = Net.event(Net.Events.AfkPayout)

	local o = Afk.ORIGIN
	origin = CFrame.new(o[1], o[2], o[3])
	local _, roomSeats, exit = AfkRoom.build(Workspace, origin)
	seats = roomSeats

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ExitPrompt"
	prompt.ActionText = "Back to the lane" -- localized on the client (AfkController)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = exit
	prompt.Triggered:Connect(function(player: Player)
		AfkService.leave(player, "door", true)
	end)

	RemoteGuard.event(Net.Events.AfkEnter, RemoteGuard.STRICT, function(player: Player, reason: any)
		if type(reason) ~= "string" or not REASONS[reason] or reason == "hop" or reason == "debug" then
			return
		end
		local ok, err = AfkService.enter(player, reason)
		if not ok and reason ~= "idle" then
			PlayerStateService.notify(player, "afk.err." .. tostring(err))
		end
	end)
	RemoteGuard.event(Net.Events.AfkLeave, RemoteGuard.STRICT, function(player: Player)
		AfkService.leave(player, "button", true)
	end)
	RemoteGuard.event(Net.Events.AfkHop, RemoteGuard.STRICT, hop)

	-- Nobody in the room can queue for a match (the client hides the menu; this is the guard).
	MatchmakingService.blocked = function(player: Player): string?
		return if sessions[player] then "in_afk" else nil
	end

	TeleportService.TeleportInitFailed:Connect(
		function(player: Player, result: Enum.TeleportResult, message: string)
			if sessions[player] then
				warn("[AfkService] teleport failed: " .. tostring(result) .. " " .. message)
				PlayerStateService.notify(player, "afk.hop_failed")
			end
		end
	)

	-- Back from the anti-idle hop: straight into the room.
	DataService.ProfileLoaded:Connect(function(player: Player)
		local ok, data = pcall(function()
			return player:GetJoinData()
		end)
		local td: any = if ok and type(data) == "table" then (data :: any).TeleportData else nil
		if type(td) == "table" and td.afk == true then
			AfkService.enter(player, "hop")
		end
	end)

	local function hook(player: Player)
		player.CharacterAdded:Connect(function()
			local s = sessions[player]
			if s then
				task.defer(place, player, s)
			end
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	DataService.beforeRelease(function(player: Player)
		local s = sessions[player]
		if s then
			flush(player, s)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local s = sessions[player]
		if s then
			flush(player, s)
			sessions[player] = nil
		end
		lastHop[player] = nil
	end)

	PlayerStateService.addExtra(function(player: Player, snap: { [string]: any })
		local profile = DataService.getProfile(player)
		if profile then
			local a = profile.afk
			local mult = multiplier(player)
			snap.afk = {
				carry = a.carry,
				cups = a.cups,
				tales = a.tales,
				paidToday = AfkLogic.paidToday(profile, os.time()),
				cap = AfkLogic.cap(Afk, mult),
				mult = mult,
				inside = sessions[player] ~= nil,
			}
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return AfkService
