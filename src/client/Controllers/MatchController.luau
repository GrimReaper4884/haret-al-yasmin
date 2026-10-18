--!strict
-- Match state on the client: MatchStart / MatchState / MatchEvents / MatchEnd, the match HUD
-- (wave, countdown, gate HP, cash, skip/speed/leave) and the result screen. Other controllers
-- subscribe to MatchController.Started / Updated / Events / Ended.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local IconIds = require(Shared.Config.Icons)
local Signal = require(Shared.Util.Signal)
local PartyLogic = require(Shared.Logic.PartyLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Modal = require(UI.Modal)
local Juice = require(UI.Juice)
local Icons = require(UI.Icons)
local Amount = require(UI.Amount)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local SettingsController = require(script.Parent.SettingsController)
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
local gateMeter: Theme.Meter
local cashLabel: TextLabel
local cashBox: Frame
local flash: Frame
local skipButton: TextButton
local speedButton: TextButton
local leaveButton: TextButton
local codesButton: TextButton
local result: Modal.Modal
local resultBanner: ImageLabel
local resultBody: TextLabel
local resultAmounts: Frame
local resultExtra: TextLabel
local replayButton: TextButton
local nextButton: TextButton
local replayBusy = false
local backButton: TextButton

function MatchController.info(): Info?
	return info
end

function MatchController.state(): any
	return state
end

-- The cash pill (the reward coins fly into it, PV-B03).
function MatchController.cashPill(): Frame?
	return cashBox
end

function MatchController.active(): boolean
	return info ~= nil
end

local function build()
	local root = Root.get()
	hud = Create("Frame", { Name = "MatchHud", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = root })

	-- Top centre: wave pill, status line, gate HP meter (docs/research/ROBLOX_TD_UI_PATTERNS.md §1)
	local top = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(300, 80), BackgroundTransparency = 1, ZIndex = 3, Parent = hud })
	local wavePill = Create("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromHex("#2A1E14"), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3, Parent = top }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	Theme.border(wavePill, 2.5)
	waveLabel = Theme.display({ TextSize = 22, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = wavePill })
	waveLabel.TextXAlignment = Enum.TextXAlignment.Center
	countLabel = Theme.display({ TextSize = 14, TextColor3 = Color3.fromHex("#FFE9B8"), Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 36), ZIndex = 3, Parent = top })
	countLabel.TextXAlignment = Enum.TextXAlignment.Center
	gateMeter = Theme.meter({ Position = UDim2.fromOffset(10, 55), Size = UDim2.new(1, -20, 0, 20), ZIndex = 3, Parent = top }, Theme.colors.hpHigh)

	-- Cash: bottom centre, just above the unit bar, so cost and wallet read in one glance.
	local cashPill
	cashPill, cashLabel = Theme.pill({ Name = "Cash", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -108), Size = UDim2.fromOffset(150, 36), ZIndex = 3, Parent = hud }, Theme.colors.gold, "cash")
	cashLabel.TextColor3 = Color3.fromHex("#FFD970")
	cashBox = cashPill

	-- Right column: skip, speed, leave, codes
	local col = Create("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 60), Size = UDim2.fromOffset(112, 220), BackgroundTransparency = 1, ZIndex = 3, Parent = hud })
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
	skipButton = Theme.button({ LayoutOrder = 1, TextSize = 16, Size = UDim2.new(1, 0, 0, Theme.TOUCH), BackgroundColor3 = Theme.colors.confirm, ZIndex = 3, Parent = col })
	speedButton = Theme.button({ LayoutOrder = 2, TextSize = 20, Size = UDim2.new(1, 0, 0, Theme.TOUCH), BackgroundColor3 = Theme.colors.gold, ZIndex = 3, Parent = col })
	-- Leave, with the settings gear beside it (effects, camera, auto ultimate mid-match).
	local lastRow = Create("Frame", { LayoutOrder = 3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 6), ZIndex = 3, Parent = col })
	leaveButton = Theme.button({ TextSize = 15, Size = UDim2.new(1, -(Theme.TOUCH - 6) - 6, 1, 0), BackgroundColor3 = Theme.colors.danger, ZIndex = 3, Parent = lastRow })
	local gear = Theme.button({ Name = "Settings", Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(Theme.TOUCH - 6, Theme.TOUCH - 6), BackgroundColor3 = Color3.fromHex("#6E5E50"), ZIndex = 3, Parent = lastRow })
	local gp = gear:FindFirstChildOfClass("UIPadding")
	if gp then
		gp:Destroy()
	end
	local gearIcon = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 4, Parent = gear })
	Icons.draw("ui_settings", gearIcon)
	-- Music mute just left of the column, level with the gear.
	SettingsController.muteButton({
		Name = "Music",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromOffset(-6, -3),
		Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
		BackgroundColor3 = Color3.fromHex("#6E5E50"),
		ZIndex = 3,
		Parent = lastRow,
	}, true)
	gear.Activated:Connect(function()
		local open = LobbyMenuController.opener("settings")
		if open then
			open()
		end
	end)
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
	-- Codes mid-match (match-cash codes only work here); the lobby menu is hidden during a match.
	codesButton = Theme.button({ Name = "Codes", LayoutOrder = 4, TextSize = 15, Size = UDim2.new(1, 0, 0, Theme.TOUCH - 6), BackgroundColor3 = Color3.fromHex("#5E6F7D"), ZIndex = 3, Parent = col })
	codesButton.Activated:Connect(function()
		local open = LobbyMenuController.opener("codes")
		if open then
			open()
		end
	end)

	-- Full-screen red flash when the gate is hit (own ScreenGui so it covers the safe-area insets).
	local fxGui = Create("ScreenGui", { Name = "HaretFx", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None, DisplayOrder = 5, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	flash = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHex("#C0281E"), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Parent = fxGui })
	Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 0) }), Parent = flash })

	result = Modal.create("MatchResult", 460, 150)
	-- The mode's painted banner (PV-C06) between the title and the rewards.
	resultBanner = Create("ImageLabel", {
		Name = "Banner",
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 110),
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 11,
		Visible = false,
		Parent = result.panel,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	Theme.border(resultBanner, 2.5)
	result.body.LayoutOrder = 3
	-- Waves held and the "Rewards" header, then the rewards as icon + number, then first clear and
	-- event currency (three stacked pieces so the icon row never overlaps text).
	local stack = Create("Frame", { Name = "Stack", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 100), ZIndex = 11, Parent = result.body })
	Create("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = stack })
	resultBody = Theme.label({ LayoutOrder = 1, TextSize = 15, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 11, Parent = stack })
	resultBody.TextXAlignment = Enum.TextXAlignment.Center
	resultAmounts = Amount.row({ Name = "Rewards", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 30), ZIndex = 11, Parent = stack }, {})
	resultExtra = Theme.label({ LayoutOrder = 3, TextSize = 15, FontFace = Theme.fontBold, TextColor3 = Theme.colors.quest, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 11, Parent = stack })
	resultExtra.TextXAlignment = Enum.TextXAlignment.Center
	-- Replay · Next · Back to the lane (the genre's end screen: keep playing without walking back).
	local row = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 11, Parent = result.body })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	replayButton = Theme.button({ LayoutOrder = 1, TextSize = 16, Size = UDim2.fromOffset(130, Theme.TOUCH), BackgroundColor3 = Theme.colors.accent, ZIndex = 11, Parent = row })
	nextButton = Theme.button({ LayoutOrder = 2, TextSize = 16, Size = UDim2.fromOffset(130, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = row })
	backButton = Theme.button({ LayoutOrder = 3, TextSize = 16, Size = UDim2.fromOffset(150, Theme.TOUCH), BackgroundColor3 = Theme.colors.confirm, ZIndex = 11, Parent = row })
	backButton.Activated:Connect(function()
		result.setVisible(false)
		Net.event(Net.Events.LeaveMatch):FireServer()
	end)
	local function again(kind: string, button: TextButton)
		if replayBusy then
			return
		end
		replayBusy = true
		task.spawn(function()
			local ok, res = pcall(function()
				return Net.func(Net.Functions.PartyReplay):InvokeServer(kind)
			end)
			if ok and type(res) == "table" and res.ok then
				button.Text = LocaleController.t("match.replay_waiting")
				replayButton.Active = false
				nextButton.Active = false
			else
				replayBusy = false
				Juice.shake(button)
			end
		end)
	end
	replayButton.Activated:Connect(function()
		again("replay", replayButton)
	end)
	nextButton.Activated:Connect(function()
		again("next", nextButton)
	end)
end

local function gateHitFlash()
	flash.BackgroundTransparency = 0.45
	TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	Juice.shake(gateMeter.frame)
end

local lastCash: number? = nil
local lastWave: number? = nil

local function render()
	if not info or not state then
		hud.Visible = false
		lastCash, lastWave = nil, nil
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
	gateMeter.fill.BackgroundColor3 = if frac > 0.5 then Theme.colors.hpHigh elseif frac > 0.25 then Theme.colors.hpMid else Theme.colors.hpLow
	gateMeter.set(frac, t("match.gate") .. "  " .. state.gateHp .. " / " .. state.gateMax)

	local cash = state.cash
	-- The cash icon carries the unit; the pill shows the number only.
	local function fmt(n: number): string
		return tostring(n)
	end
	if lastCash and cash ~= lastCash then
		Juice.count(cashLabel, lastCash, cash, fmt)
		if cash > lastCash then
			Juice.punch(cashBox, 0.12)
		end
	else
		cashLabel.Text = fmt(cash)
	end
	lastCash = cash
	if lastWave and state.wave ~= lastWave and state.wave > 0 then
		Juice.punch(waveLabel, 0.25)
	end
	lastWave = state.wave

	skipButton.Visible = state.phase == "prep"
	skipButton.Text = t("match.skip", { n = state.votes or 0, total = state.players or 1 })
	local me = Players.LocalPlayer.Name
	speedButton.Visible = state.host == me
	speedButton.Text = t("match.speed", { n = state.speed or 1 })
	leaveButton.Text = t("match.leave")
	codesButton.Text = t("codes.title")
end

local function showResult(payload: any)
	local t = LocaleController.t
	result.title.Text = if payload.won then t("match.victory") else t("match.defeat")
	result.title.TextColor3 = if payload.won then Theme.colors.quest else Theme.colors.danger
	local lines = { t("match.waves_held", { n = payload.waves or 0 }) }
	local extra = {}
	local r = payload.reward
	if r then
		table.insert(lines, t("match.rewards"))
		if r.firstClear then
			table.insert(extra, t("match.first_clear"))
		end
		if r.eventCurrency and r.eventCurrencyKey then
			table.insert(extra, "+" .. t(r.eventCurrencyKey, { n = r.eventCurrency }))
		end
	end
	resultBody.Text = table.concat(lines, "\n")
	resultExtra.Text = table.concat(extra, "\n")
	resultAmounts.Visible = r ~= nil
	local rewardEntries = if r then Amount.reward(t, { lira = r.lira, qirsh = r.qirsh, xp = r.xp, traitStones = r.traitStones }) else {}
	Amount.fill(resultAmounts, rewardEntries, { textSize = 16, iconSize = 26, rtl = LocaleController.isRtl(), display = true })
	backButton.Text = t("match.back")
	replayBusy = false
	replayButton.Active = true
	nextButton.Active = true
	replayButton.Text = t("match.replay")
	nextButton.Text = t("match.next")
	local modeId = if info then info.modeId else nil
	local art = if modeId then IconIds.modes[modeId] else nil
	resultBanner.Visible = art ~= nil and art.id > 0
	if art and art.id > 0 then
		resultBanner.Image = "rbxassetid://" .. tostring(art.id)
	end
	local snapshot: any = StateController.get()
	replayButton.Visible = not payload.left and modeId ~= nil
	nextButton.Visible = not payload.left
		and modeId ~= nil
		and PartyLogic.nextMode(Modes :: any, modeId) ~= nil
		and (payload.won == true or (snapshot ~= nil and snapshot.td.cleared[modeId] ~= nil))
	result.setVisible(true)
end

local function onEvents(events: { any })
	for _, e in events do
		if e.type == "voteSkip" then
			ToastController.show("match.vote_skip", { name = e.name })
		elseif e.type == "reached" then
			gateHitFlash()
		end
	end
	MatchController.Events:Fire(events)
end

local function backToLobby()
	info = nil
	state = nil
	result.setVisible(false)
	LobbyMenuController.setInMatch(false)
	GuiService.TouchControlsEnabled = true
	render()
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
		if payload.left then
			backToLobby()
		else
			-- The server teleports us home after TD.RESULT_SECONDS and says so (MatchHome); this
			-- timer is only the fallback if that message is lost.
			local endedId = if info then info.matchId else nil
			task.delay(TD.RESULT_SECONDS + 0.5, function()
				if info and info.matchId == endedId then
					backToLobby()
				end
			end)
		end
	end)
	Net.event(Net.Events.MatchHome).OnClientEvent:Connect(function(matchId: any)
		if info and info.matchId == matchId then
			backToLobby()
		end
	end)
	LocaleController.Changed:Connect(render)
end

return MatchController
