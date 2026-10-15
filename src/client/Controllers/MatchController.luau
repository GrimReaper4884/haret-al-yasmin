--!strict
-- Match state on the client: MatchStart / MatchState / MatchEvents / MatchEnd, the match HUD
-- (wave, countdown, gate HP, cash, skip/speed/leave) and the result screen. Other controllers
-- subscribe to MatchController.Started / Updated / Events / Ended.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local Enemies = require(Shared.Config.Enemies)
local Signal = require(Shared.Util.Signal)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Modal = require(UI.Modal)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local ToastController = require(script.Parent.ToastController)

local MatchController = {}

MatchController.Started = Signal.new() -- (payload)
MatchController.Updated = Signal.new() -- (state)
MatchController.Events = Signal.new() -- (events list)
MatchController.Ended = Signal.new() -- (payload)

export type Info = { matchId: number, modeId: string, arenaId: string, origin: Vector3, difficulty: string, players: { string }, totalWaves: number?, host: string }

local info: Info? = nil
local state: any = nil

local hud: Frame
local waveLabel: TextLabel
local countLabel: TextLabel
local gateBar: Frame
local gateFill: Frame
local gateLabel: TextLabel
local cashLabel: TextLabel
local skipButton: TextButton
local speedButton: TextButton
local leaveButton: TextButton
local result: Modal.Modal
local resultBody: TextLabel
local backButton: TextButton

function MatchController.info(): Info?
	return info
end

function MatchController.state(): any
	return state
end

function MatchController.active(): boolean
	return info ~= nil
end

local function build()
	local root = Root.get()
	hud = Create("Frame", { Name = "MatchHud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = root })
	-- Top centre: wave + countdown
	local top = Theme.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(300, 64), ZIndex = 3, Parent = hud })
	waveLabel = Theme.label({ TextSize = 18, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 4), ZIndex = 3, Parent = top })
	waveLabel.TextXAlignment = Enum.TextXAlignment.Center
	countLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 26), ZIndex = 3, Parent = top })
	countLabel.TextXAlignment = Enum.TextXAlignment.Center
	gateBar = Create("Frame", { Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 12), BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 3, Parent = top }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	gateFill = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.colors.quest, BorderSizePixel = 0, ZIndex = 4, Parent = gateBar }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	gateLabel = Theme.label({ TextSize = 10, FontFace = Theme.fontBold, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = gateBar })
	gateLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Cash pill, left of the top panel
	local cashPill = Theme.panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.5, -158, 0, 8), Size = UDim2.fromOffset(130, Theme.TOUCH - 4), ZIndex = 3, Parent = hud })
	cashLabel = Theme.label({ TextSize = 20, FontFace = Theme.fontBold, TextColor3 = Theme.colors.accent, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = cashPill })
	cashLabel.TextXAlignment = Enum.TextXAlignment.Center

	-- Right column: skip, speed, leave
	local col = Create("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 60), Size = UDim2.fromOffset(120, 170), BackgroundTransparency = 1, ZIndex = 3, Parent = hud })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
	skipButton = Theme.button({ LayoutOrder = 1, TextSize = 14, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 4), BackgroundColor3 = Theme.colors.quest, ZIndex = 3, Parent = col })
	speedButton = Theme.button({ LayoutOrder = 2, TextSize = 16, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 4), ZIndex = 3, Parent = col })
	leaveButton = Theme.button({ LayoutOrder = 3, TextSize = 14, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 4), BackgroundColor3 = Theme.colors.danger, ZIndex = 3, Parent = col })
	skipButton.Activated:Connect(function()
		Net.event(Net.Events.VoteSkip):FireServer()
	end)
	speedButton.Activated:Connect(function()
		if not state then
			return
		end
		local snapshot = StateController.get()
		local maxSpeed = if snapshot and snapshot.perks and snapshot.perks.fast then TD.PASS_SPEED else TD.FREE_SPEED
		local nextSpeed = (state.speed or 1) + 1
		if nextSpeed > maxSpeed then
			nextSpeed = 1
		end
		Net.event(Net.Events.SetSpeed):FireServer(nextSpeed)
	end)
	leaveButton.Activated:Connect(function()
		Net.event(Net.Events.LeaveMatch):FireServer()
	end)

	result = Modal.create("MatchResult", 460, 150)
	resultBody = Theme.label({ TextSize = 15, Size = UDim2.new(1, 0, 0, 100), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 11, Parent = result.body })
	resultBody.TextXAlignment = Enum.TextXAlignment.Center
	backButton = Theme.button({ TextSize = 15, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(220, Theme.TOUCH - 4), ZIndex = 11, Parent = result.body })
	backButton.Activated:Connect(function()
		result.setVisible(false)
		Net.event(Net.Events.LeaveMatch):FireServer()
	end)
end

local function render()
	if not info or not state then
		hud.Visible = false
		return
	end
	local t = LocaleController.t
	hud.Visible = true
	if state.totalWaves then
		waveLabel.Text = t("match.wave", { n = state.wave, total = state.totalWaves })
	else
		waveLabel.Text = t("match.wave_infinite", { n = state.wave })
	end
	if state.phase == "prep" then
		countLabel.Text = t("match.next_in", { n = math.ceil(state.countdown or 0) })
	else
		countLabel.Text = t((Modes :: any)[info.modeId].nameKey) .. " · " .. t("difficulty." .. info.difficulty)
	end
	local frac = if state.gateMax > 0 then state.gateHp / state.gateMax else 0
	gateFill.Size = UDim2.fromScale(frac, 1)
	gateFill.BackgroundColor3 = if frac > 0.5 then Theme.colors.quest elseif frac > 0.25 then Theme.colors.accent else Theme.colors.danger
	gateLabel.Text = t("match.gate") .. " " .. state.gateHp .. "/" .. state.gateMax
	cashLabel.Text = t("match.cash", { n = state.cash })
	skipButton.Visible = state.phase == "prep"
	skipButton.Text = t("match.skip", { n = state.votes or 0, total = state.players or 1 })
	local me = Players.LocalPlayer.Name
	speedButton.Visible = state.host == me
	speedButton.Text = t("match.speed", { n = state.speed or 1 })
	leaveButton.Text = t("match.leave")
end

local function showResult(payload: any)
	local t = LocaleController.t
	result.title.Text = if payload.won then t("match.victory") else t("match.defeat")
	result.title.TextColor3 = if payload.won then Theme.colors.quest else Theme.colors.danger
	local lines = { t("match.waves_held", { n = payload.waves or 0 }) }
	local r = payload.reward
	if r then
		table.insert(lines, "")
		table.insert(lines, t("match.rewards"))
		table.insert(lines, t("reward.lira", { n = r.lira }) .. " · " .. t("reward.qirsh", { n = r.qirsh }) .. " · " .. t("reward.xp", { n = r.xp }))
		if r.traitStones and r.traitStones > 0 then
			table.insert(lines, t("reward.stones", { n = r.traitStones }))
		end
		if r.firstClear then
			table.insert(lines, t("match.first_clear"))
		end
	end
	resultBody.Text = table.concat(lines, "\n")
	backButton.Text = t("match.back")
	result.setVisible(true)
end

local function onEvents(events: { any })
	local t = LocaleController.t
	for _, e in events do
		if e.type == "voteSkip" then
			ToastController.show("match.vote_skip", { name = e.name })
		elseif e.type == "waveStart" and e.boss then
			ToastController.show("match.boss_wave", { bossKey = (Enemies :: any)[e.boss].nameKey })
		elseif e.type == "reached" then
			ToastController.show("match.gate_breached")
		end
	end
	MatchController.Events:Fire(events)
	-- keep lint quiet about t when no toast fired
	local _ = t
end

function MatchController.start()
	build()
	Net.event(Net.Events.MatchStart).OnClientEvent:Connect(function(payload: Info)
		info = payload
		state = nil
		Modal.closeAll()
		LobbyMenuController.setInMatch(true)
		MatchController.Started:Fire(payload)
		render()
	end)
	Net.event(Net.Events.MatchState).OnClientEvent:Connect(function(s: any)
		state = s
		MatchController.Updated:Fire(s)
		render()
	end)
	Net.event(Net.Events.MatchEvents).OnClientEvent:Connect(function(events: { any })
		if type(events) == "table" then
			onEvents(events)
		end
	end)
	Net.event(Net.Events.MatchEnd).OnClientEvent:Connect(function(payload: any)
		showResult(payload)
		MatchController.Ended:Fire(payload)
		local function backToLobby()
			info = nil
			state = nil
			result.setVisible(false)
			LobbyMenuController.setInMatch(false)
			render()
		end
		if payload.left then
			backToLobby()
		else
			-- The server teleports us home after TD.RESULT_SECONDS; the lobby HUD comes back then.
			local endedId = if info then info.matchId else nil
			task.delay(TD.RESULT_SECONDS + 0.5, function()
				if info and info.matchId == endedId then
					backToLobby()
				end
			end)
		end
	end)
	LocaleController.Changed:Connect(render)
end

return MatchController
