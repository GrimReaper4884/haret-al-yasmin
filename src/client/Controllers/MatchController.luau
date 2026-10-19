--!strict
-- Match state on the client: MatchStart / MatchState / MatchEvents / MatchEnd, the match HUD
-- (wave, countdown, gate HP, cash, the rail: skip / speed / view, the `≡` match menu) and the result
-- screen. Other controllers subscribe to MatchController.Started / Updated / Events / Ended.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Modes = require(Shared.Config.Modes)
local Story = require(Shared.Config.Story)
local IconIds = require(Shared.Config.Icons)
local Signal = require(Shared.Util.Signal)
local PartyLogic = require(Shared.Logic.PartyLogic)
local MonetizationLogic = require(Shared.Logic.MonetizationLogic)
local MatchRewards = require(Shared.Logic.MatchRewards)
local SeasonPass = require(Shared.Config.SeasonPass)
local MechanicFx = require(Shared.Logic.MechanicFx)
local Vfx = require(Shared.Config.Vfx)
local Hud = require(Shared.Config.Hud)
local HudLayout = require(Shared.Logic.HudLayout)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Button = require(UI.Button)
local Root = require(UI.Root)
local Modal = require(UI.Modal)
local Juice = require(UI.Juice)
local Haptics = require(UI.Haptics)
local Icons = require(UI.Icons)
local Amount = require(UI.Amount)
local Device = require(UI.Device)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local SettingsController = require(script.Parent.SettingsController)
local ToastController = require(script.Parent.ToastController)
local MatchMenuController = require(script.Parent.MatchMenuController)
local ShopController = require(script.Parent.ShopController)

local MatchController = {}

MatchController.Started = Signal.new() -- (payload)
MatchController.Updated = Signal.new() -- (state)
MatchController.Events = Signal.new() -- (events list)
MatchController.Ended = Signal.new() -- (payload)
MatchController.AimingChanged = Signal.new() -- (aiming): a defender is being aimed on touch (B3)

local aimingOnTouch = false

-- PlacementController says when it aims on touch; MatchCameraController hides the thumbstick and
-- jump meanwhile so the camera cannot orbit and the corners hold Place / Cancel.
function MatchController.setAiming(on: boolean)
	if aimingOnTouch ~= on then
		aimingOnTouch = on
		MatchController.AimingChanged:Fire(on)
	end
end

function MatchController.aiming(): boolean
	return aimingOnTouch
end

export type Info = { matchId: number, modeId: string, arenaId: string, origin: Vector3, difficulty: string, players: { string }, totalWaves: number?, host: string }

local info: Info? = nil
local state: any = nil

local hud: Frame
local waveLabel: TextLabel
local countLabel: TextLabel
local gateMeter: Theme.Meter
local burnRow: Frame -- flame pips under the gate bar, one per burn stack (S1-C02)
local burnPips: { Frame } = {}
local lastBurn = 0
local cashLabel: TextLabel
local waveIcon: Frame -- the episode's art (or a drawn gate) at the wave pill's start (LP-C06)
local gateCrack: Frame -- crack lines over the gate meter below MATCH_SKIN.crackAt
local resultSpark: Frame -- the result's cash-per-wave curve
local resultSparkLabel: TextLabel
local cashBox: Frame
local flash: Frame
local skipButton: TextButton
local speedButton: TextButton
local viewButton: TextButton
local defendersButton: TextButton -- opens the Defenders panel (LP-B02, DefendersController)
local menuButton: TextButton
local railContainer: Frame -- holds the rail buttons (hidden while a defender sheet leaves no room)
local railLabels: { [TextButton]: TextLabel } = {}
local result: Modal.Modal
local resultBanner: ImageLabel
local resultOutro: TextLabel
local resultOutroShade: Frame
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

-- Hides the cash pill while a phone sheet holds the bottom band (the Defenders sheet shows the cash).
function MatchController.setCashHidden(on: boolean)
	if cashBox then
		cashBox.Visible = not on
	end
end

function MatchController.active(): boolean
	return info ~= nil
end

-- A rail button and its label ("view" belongs to MatchCameraController, which sets its text).
function MatchController.railButton(name: string): (TextButton, TextLabel)
	local b = if name == "skip" then skipButton elseif name == "speed" then speedButton elseif name == "defenders" then defendersButton else viewButton
	return b, railLabels[b]
end

-- Set by DefendersController: the rail's Defenders button calls it (MatchController can't require
-- that controller: it sits above PlacementController, which requires this one).
MatchController.onDefenders = nil :: (() -> ())?

-- The top of a bottom element taller than the hotbar (the defender sheet), design px, or nil.
local railFloor: number? = nil

-- Places the visible rail buttons and the menu button from Logic/HudLayout (B2): the thumb arc above
-- Roblox's jump button on touch, the right edge (or the left, Settings railSide) on every profile.
local function layoutRail()
	if not hud then
		return
	end
	-- View first, Skip last: the buttons that come and go (Skip between waves) fill the inner column, so
	-- View never moves under a thumb when Skip appears or hides.
	local shown = {}
	for _, b in { viewButton, defendersButton, speedButton, skipButton } do
		if b.Visible then
			table.insert(shown, b)
		end
	end
	local side = SettingsController.get("railSide") or "right"
	-- A defender sheet that leaves no 56 px between the menu button and its top hides the rail
	-- until it closes (short phones).
	local room = if railFloor then railFloor - Hud.RAIL.gap - (Hud.TOP_CLEAR + Hud.RAIL.menu + Hud.RAIL.gap) else math.huge
	railContainer.Visible = room >= Hud.RAIL.button
	local r = HudLayout.rail(Hud, Device.profile(), Device.scale(), Device.safeSize(), side, #shown, Device.reserved(), railFloor)
	for i, b in shown do
		local p = r.buttons[i]
		b.Position = UDim2.fromOffset(p.x, p.y)
		b.Size = UDim2.fromOffset(r.size, r.size)
	end
	menuButton.Position = UDim2.fromOffset(r.menu.x, r.menu.y)
	menuButton.Size = UDim2.fromOffset(r.menu.size, r.menu.size)
end
MatchController.relayout = layoutRail

-- PlacementController: the defender sheet opened (its top, design px) or closed (nil).
function MatchController.setRailFloor(y: number?)
	if railFloor ~= y then
		railFloor = y
		layoutRail()
	end
end

-- A square rail button: icon on top, a short outlined label under it.
local function railButtonOf(name: string, color: Color3, iconName: string): TextButton
	local b = Theme.button({ Name = "Rail_" .. name, Text = "", Size = UDim2.fromOffset(Hud.RAIL.button, Hud.RAIL.button), BackgroundColor3 = color, ZIndex = 3, Parent = railContainer })
	-- Theme v2 (LP-C06): the rail wears the brass edge and, once uploaded, the carved-wood chrome.
	local edge = b:FindFirstChild("Border")
	if edge and edge:IsA("UIStroke") then
		edge.Color = Theme.v2.brass
	end
	Theme.chrome(b, "button")
	local pad = b:FindFirstChildOfClass("UIPadding")
	if pad then
		pad:Destroy()
	end
	local holder = Create("Frame", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 4, Parent = b })
	Icons.draw(iconName, holder)
	for _, d in holder:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = 4
		end
	end
	local label = Theme.display({ Name = "Label", Text = "", TextSize = Hud.TEXT_MIN, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, -4, 0, 16), ZIndex = 4, Parent = b })
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextWrapped = false
	railLabels[b] = label
	return b
end

---------------------------------------------------------------- Speed sheet (LP-A03)

-- The host taps Speed and picks one of TD.SPEEDS. Speeds above the host's ceiling
-- (MonetizationLogic.maxSpeed: VIP, the premium Lane Diary or the Fast Mode pass) carry a lock and
-- open the Store at the Fast Mode pass; the server checks again. Others see the speed only.
local speedSheet: Frame? = nil
local speedCatcher: TextButton? = nil

local function myMaxSpeed(): number
	local snapshot = StateController.get()
	local pass = snapshot and snapshot.pass
	local premium = pass ~= nil and pass.premium == true and pass.season == SeasonPass.season
	return MonetizationLogic.maxSpeed(snapshot and snapshot.perks, premium, TD)
end

local function closeSpeedSheet()
	if speedSheet then
		speedSheet:Destroy()
		speedSheet = nil
	end
	if speedCatcher then
		speedCatcher:Destroy()
		speedCatcher = nil
	end
end

local function openSpeedSheet()
	closeSpeedSheet()
	local t = LocaleController.t
	local cfg = Hud.SPEED_SHEET
	local maxSpeed = myMaxSpeed()
	local current = if state then state.speed or 1 else 1
	local n = #TD.SPEEDS
	local locked = maxSpeed < TD.SPEEDS[n]
	local snapshot: any = StateController.get()
	local unlockKey, errKey = MonetizationLogic.speedUnlockKeys(snapshot and snapshot.restricted)
	local w = cfg.pad * 2 + n * cfg.chip + (n - 1) * cfg.gap
	local h = cfg.pad * 2 + cfg.title + cfg.gap + cfg.chip + (if locked then cfg.gap + cfg.caption else 0)
	-- Beside the Speed button, on the screen's inner side of the rail, kept inside the safe area.
	local design = Device.designSize()
	local bp = speedButton.Position
	local right = (SettingsController.get("railSide") or "right") == "right"
	local x = if right then bp.X.Offset - cfg.gap - w else bp.X.Offset + speedButton.Size.X.Offset + cfg.gap
	local y = math.clamp(bp.Y.Offset + speedButton.Size.Y.Offset / 2 - h / 2, 4, math.max(4, design.y - h - 4))
	local catcher = Button.hit({ Name = "SpeedCatcher", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9, Parent = hud })
	catcher.Activated:Connect(closeSpeedSheet)
	speedCatcher = catcher
	local sheet = Create("Frame", {
		Name = "SpeedSheet",
		Position = UDim2.fromOffset(math.max(4, x), y),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.colors.panel,
		ZIndex = 10,
		Parent = hud,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	Theme.border(sheet, 2.5)
	speedSheet = sheet
	local title = Theme.label({ Text = t("match.speed_title"), FontFace = Theme.fontBold, TextSize = Hud.TEXT_MIN + 2, Position = UDim2.fromOffset(cfg.pad, cfg.pad), Size = UDim2.new(1, -2 * cfg.pad, 0, cfg.title), ZIndex = 11, Parent = sheet })
	Theme.align(title, LocaleController.isRtl())
	for i, speed in TD.SPEEDS do
		local open = speed <= maxSpeed
		local chip = Theme.button({
			Name = "Speed_" .. speed,
			Text = t("match.speed", { n = speed }),
			TextSize = 18,
			Position = UDim2.fromOffset(cfg.pad + (i - 1) * (cfg.chip + cfg.gap), cfg.pad + cfg.title + cfg.gap),
			Size = UDim2.fromOffset(cfg.chip, cfg.chip),
			BackgroundColor3 = if speed == current then Theme.colors.gold elseif open then Theme.colors.button else Theme.colors.buttonDisabled,
			ZIndex = 11,
			Parent = sheet,
		})
		if not open then
			local lock = Create("Frame", { Name = "Lock", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 8, 0, -4), Size = UDim2.fromOffset(cfg.lock, cfg.lock), BackgroundTransparency = 1, ZIndex = 12, Parent = chip })
			Icons.draw("ui_lock", lock)
			for _, d in lock:GetDescendants() do
				if d:IsA("GuiObject") then
					d.ZIndex = 12
				end
			end
		end
		chip.Activated:Connect(function()
			closeSpeedSheet()
			if not open then
				ToastController.show(errKey)
				ShopController.openStore("fast_mode")
			elseif speed ~= current then
				Net.event(Net.Events.SetSpeed):FireServer(speed)
			end
		end)
	end
	if locked then
		local caption = Theme.label({ Text = t(unlockKey), TextSize = Hud.TEXT_MIN, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(cfg.pad, h - cfg.pad - cfg.caption), Size = UDim2.new(1, -2 * cfg.pad, 0, cfg.caption), ZIndex = 11, Parent = sheet })
		caption.TextXAlignment = Enum.TextXAlignment.Center
	end
	Juice.pop(sheet)
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
	-- Theme v2 (LP-C06): the episode's icon at the pill's start and a brass edge.
	local skin = Hud.MATCH_SKIN
	waveIcon = Create("Frame", { Name = "EpisodeIcon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(skin.waveIcon, skin.waveIcon), BackgroundTransparency = 1, ZIndex = 5, Parent = wavePill })
	local pillStroke = wavePill:FindFirstChild("Border")
	if pillStroke and pillStroke:IsA("UIStroke") then
		pillStroke.Color = Theme.v2.brass
	end
	countLabel = Theme.display({ TextSize = 14, TextColor3 = Color3.fromHex("#FFE9B8"), Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 36), ZIndex = 3, Parent = top })
	countLabel.TextXAlignment = Enum.TextXAlignment.Center
	gateMeter = Theme.meter({ Position = UDim2.fromOffset(10, 55), Size = UDim2.new(1, -20, 0, 20), ZIndex = 3, Parent = top }, Theme.colors.hpHigh)
	-- Cracks across the gate bar once it is low (LP-C06): three dark jagged strokes over the fill.
	-- Over the fill (same ZIndex, a later sibling) and under the HP text; clear of the centred label.
	local crackZ = gateMeter.fill.ZIndex
	gateCrack = Create("Frame", { Name = "Crack", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = crackZ, Parent = gateMeter.frame })
	for _, c in { { 0.08, -24, 0.7 }, { 0.12, 30, 0.55 }, { 0.17, -15, 0.45 }, { 0.86, -35, 0.8 }, { 0.9, 20, 0.5 } } do
		Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(c[1], 0.5), Size = UDim2.new(0, 2, c[3], 0), Rotation = c[2], BackgroundColor3 = Color3.fromHex("#1A120B"), BorderSizePixel = 0, ZIndex = crackZ, Parent = gateCrack })
	end
	local pip = Vfx.STORY.burnPip
	burnRow = Create("Frame", { Name = "Burn", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 76), Size = UDim2.fromOffset((pip + 2) * TD.BURN_MAX_STACKS, pip), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = top })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = burnRow })
	for i = 1, TD.BURN_MAX_STACKS do
		local holder = Create("Frame", { LayoutOrder = i, BackgroundTransparency = 1, Size = UDim2.fromOffset(pip, pip), Visible = false, ZIndex = 4, Parent = burnRow })
		Icons.draw("mech_burn", holder)
		table.insert(burnPips, holder)
	end

	-- Cash: bottom centre, just above the unit bar, so cost and wallet read in one glance.
	local cashPill
	cashPill, cashLabel = Theme.pill({ Name = "Cash", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -108), Size = UDim2.fromOffset(150, 36), ZIndex = 3, Parent = hud }, Theme.colors.gold, "cash")
	cashLabel.TextColor3 = Color3.fromHex("#FFD970")
	cashBox = cashPill

	-- The rail (B2): Skip (prep only), Speed (host only), View (walk / watchtower, MatchCameraController),
	-- placed by layoutRail; everything else lives behind the `≡` match menu.
	railContainer = Create("Frame", { Name = "Rail", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = hud })
	skipButton = railButtonOf("skip", Theme.colors.confirm, "act_skip")
	speedButton = railButtonOf("speed", Theme.colors.gold, "act_speed")
	viewButton = railButtonOf("view", Theme.colors.textMuted, "ui_view")
	defendersButton = railButtonOf("defenders", Theme.colors.quest, "ui_defenders")
	railLabels[defendersButton].Text = LocaleController.t("match.defenders")
	defendersButton.Activated:Connect(function()
		local open = MatchController.onDefenders
		if open then
			open()
		end
	end)
	menuButton = Theme.button({ Name = "MatchMenu", Text = "", Size = UDim2.fromOffset(Hud.RAIL.menu, Hud.RAIL.menu), BackgroundColor3 = Color3.fromHex("#6E5E50"), ZIndex = 3, Parent = hud })
	local mp = menuButton:FindFirstChildOfClass("UIPadding")
	if mp then
		mp:Destroy()
	end
	local menuIcon = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 4, Parent = menuButton })
	Icons.draw("ui_menu", menuIcon)
	for _, d in menuIcon:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = 4
		end
	end
	menuButton.Activated:Connect(MatchMenuController.open)
	skipButton.Activated:Connect(function()
		Net.event(Net.Events.VoteSkip):FireServer()
	end)
	speedButton.Activated:Connect(function()
		if not state then
			return
		end
		if state.host ~= Players.LocalPlayer.Name then
			ToastController.show("match.speed_host")
		elseif speedSheet then
			closeSpeedSheet()
		else
			openSpeedSheet()
		end
	end)
	layoutRail()

	-- Full-screen red flash when the gate is hit (own ScreenGui so it covers the safe-area insets).
	local fxGui = Create("ScreenGui", { Name = "HaretFx", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None, DisplayOrder = 5, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	flash = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHex("#C0281E"), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Parent = fxGui })
	Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 0) }), Parent = flash })

	result = Modal.create("MatchResult", 460, 174) -- +24: the cash curve row (LP-C06)
	-- The mode's painted banner (PV-C06) between the title and the rewards.
	resultBanner = Create("ImageLabel", {
		Name = "Banner",
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 110),
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 11,
		Visible = false,
		Parent = result.content,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	Theme.border(resultBanner, 2.5)
	-- The Hakawati's outro over the bottom of the banner after a story win (S1-C01, Config/Story).
	resultOutroShade = Create("Frame", {
		Name = "OutroShade",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0.72),
		ZIndex = 11,
		Parent = resultBanner,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	Create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0.35), NumberSequenceKeypoint.new(1, 0.2) }),
		Parent = resultOutroShade,
	})
	resultOutro = Theme.display({
		Name = "Outro",
		TextSize = 13,
		TextColor3 = Color3.fromHex("#FFF1D0"),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -20, 0.68, 0),
		TextYAlignment = Enum.TextYAlignment.Bottom,
		ZIndex = 12,
		Parent = resultBanner,
	})
	resultOutro.TextXAlignment = Enum.TextXAlignment.Center
	result.body.LayoutOrder = 3
	-- Waves held and the "Rewards" header, then the rewards as icon + number, then first clear and
	-- event currency (three stacked pieces so the icon row never overlaps text).
	local stack = Create("Frame", { Name = "Stack", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 124), ZIndex = 11, Parent = result.body })
	Create("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = stack })
	resultBody = Theme.label({ LayoutOrder = 1, TextSize = 15, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 11, Parent = stack })
	resultBody.TextXAlignment = Enum.TextXAlignment.Center
	resultAmounts = Amount.row({ Name = "Rewards", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 30), ZIndex = 11, Parent = stack }, {})
	resultExtra = Theme.label({ LayoutOrder = 3, TextSize = 15, FontFace = Theme.fontBold, TextColor3 = Theme.colors.quest, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 11, Parent = stack })
	resultExtra.TextXAlignment = Enum.TextXAlignment.Center
	-- The cash each wave brought (LP-C06, MatchRewards.cashCurve from the server's per-wave totals).
	local sk = Hud.MATCH_SKIN.spark
	-- One row: the caption, then the line beside it.
	local sparkRow = Create("Frame", { Name = "CashCurve", LayoutOrder = 4, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, sk.h + 2), ZIndex = 11, Parent = stack })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sparkRow })
	resultSparkLabel = Theme.label({ LayoutOrder = 1, TextSize = 12, TextColor3 = Theme.colors.textMuted, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, sk.h), TextWrapped = false, ZIndex = 11, Parent = sparkRow })
	resultSpark = Create("Frame", { Name = "Line", LayoutOrder = 2, Size = UDim2.fromOffset(sk.w, sk.h), BackgroundColor3 = Theme.v2.woodDark, BackgroundTransparency = 0.88, ZIndex = 11, Parent = sparkRow }, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
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
	Haptics.notify()
end

local lastCash: number? = nil
local lastWave: number? = nil

local function render()
	if not info or not state then
		hud.Visible = false
		lastCash, lastWave = nil, nil
		closeSpeedSheet()
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
	local cracked = frac < Hud.MATCH_SKIN.crackAt
	if cracked and not gateCrack.Visible then
		Juice.shake(gateMeter.frame)
	end
	gateCrack.Visible = cracked
	-- Burn stacks on the gate (Episode 5's torchbearers): one flame each; a new one punches.
	local burn = MechanicFx.burnPips(state.gateBurn, TD.BURN_MAX_STACKS)
	for i, holder in burnPips do
		holder.Visible = i <= burn
	end
	burnRow.Visible = burn > 0
	if burn > lastBurn then
		Juice.punch(burnRow, 0.2)
	end
	lastBurn = burn

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

	local me = Players.LocalPlayer.Name
	-- Everyone sees the speed; only the host's button opens the sheet (LP-A03), the others' is muted.
	-- The episode's icon on the wave pill (its painted art once, else the drawn gate).
	if info and waveIcon:GetAttribute("Mode") ~= info.modeId then
		waveIcon:SetAttribute("Mode", info.modeId)
		waveIcon:ClearAllChildren()
		local art = IconIds.modes[info.modeId]
		if art and art.id > 0 then
			Create("ImageLabel", { Image = "rbxassetid://" .. art.id, ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = waveIcon }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		else
			Icons.draw("ui_play", waveIcon)
		end
	end
	local skipShown, speedShown = state.phase == "prep", true
	local relayout = skipButton.Visible ~= skipShown or speedButton.Visible ~= speedShown
	skipButton.Visible = skipShown
	railLabels[skipButton].Text = t("match.skip_votes", { n = state.votes or 0, total = state.players or 1 })
	speedButton.Visible = speedShown
	speedButton.BackgroundColor3 = if state.host == me then Theme.colors.gold else Theme.colors.textMuted
	railLabels[speedButton].Text = t("match.speed", { n = state.speed or 1 })
	railLabels[defendersButton].Text = t("match.defenders")
	if speedSheet and state.host ~= me then
		closeSpeedSheet()
	end
	if relayout then
		layoutRail()
	end
end

-- On a phone the result sheet puts the banner beside the rewards and buttons so everything fits
-- without scrolling (MOBILE_HUD_PLAN B7); elsewhere the banner stays above them.
local function shapeResult()
	local layout = result.content:FindFirstChildOfClass("UIListLayout")
	local side = Device.isPhone() and resultBanner.Visible
	if layout then
		layout.FillDirection = if side then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	end
	resultBanner.Size = if side then UDim2.new(0.42, 0, 0, 150) else UDim2.new(1, 0, 0, 110)
	result.body.Size = if side then UDim2.new(0.58, -20, 0, 150) else UDim2.new(1, if Device.isPhone() then -12 else 0, 0, 150)
	replayButton.Size = UDim2.fromOffset(if side then 112 else 130, Theme.TOUCH)
	nextButton.Size = UDim2.fromOffset(if side then 112 else 130, Theme.TOUCH)
	backButton.Size = UDim2.fromOffset(if side then 130 else 150, Theme.TOUCH)
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
	-- The cash curve: one segment per wave between the sparkline's points.
	for _, c in resultSpark:GetChildren() do
		if c:IsA("Frame") and c.Name == "Seg" then
			c:Destroy()
		end
	end
	local curve = if type(payload.cashCurve) == "table" then payload.cashCurve else {}
	local sk = Hud.MATCH_SKIN.spark
	local pts = MatchRewards.sparkline(curve, sk.w, sk.h)
	for i = 2, #pts do
		local a, b = pts[i - 1], pts[i]
		local dx, dy = b[1] - a[1], b[2] - a[2]
		local len = math.sqrt(dx * dx + dy * dy)
		Create("Frame", { Name = "Seg", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((a[1] + b[1]) / 2, (a[2] + b[2]) / 2), Size = UDim2.fromOffset(len + 1, sk.thickness), Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = Theme.v2.goldLeaf, BorderSizePixel = 0, ZIndex = 12, Parent = resultSpark })
	end
	local total = 0
	for _, v in curve do
		total += v
	end
	resultSparkLabel.Text = if #curve > 0 then t("match.cash_curve", { n = total }) else ""
	resultSpark.Visible = #pts > 0
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
	local hasArt = art ~= nil and art.id > 0
	local ep = if modeId and payload.won and not payload.left then (Story.episodes :: any)[modeId] else nil
	local outro = {}
	for _, key in if ep then ep.outro else {} do
		table.insert(outro, t(key))
	end
	resultOutro.Text = table.concat(outro, " ")
	resultOutroShade.Visible = #outro > 0
	resultOutro.Visible = #outro > 0
	-- Without a painted banner the outro sits on a plain dark plate.
	resultBanner.Visible = hasArt or #outro > 0
	resultBanner.Image = if art and hasArt then "rbxassetid://" .. tostring(art.id) else ""
	resultBanner.BackgroundTransparency = if hasArt then 1 else 0
	resultBanner.BackgroundColor3 = Theme.colors.text
	-- On a painting the outro sits low over the shade; on the plain plate it is centred.
	resultOutro.AnchorPoint = if hasArt then Vector2.new(0.5, 1) else Vector2.new(0.5, 0.5)
	resultOutro.Position = if hasArt then UDim2.new(0.5, 0, 1, -6) else UDim2.fromScale(0.5, 0.5)
	resultOutro.Size = if hasArt then UDim2.new(1, -20, 0.68, 0) else UDim2.new(1, -24, 1, -12)
	resultOutro.TextYAlignment = if hasArt then Enum.TextYAlignment.Bottom else Enum.TextYAlignment.Center
	resultOutro.TextSize = if hasArt then 13 else 15
	local snapshot: any = StateController.get()
	replayButton.Visible = not payload.left and modeId ~= nil
	nextButton.Visible = not payload.left
		and modeId ~= nil
		and PartyLogic.nextMode(Modes :: any, modeId) ~= nil
		and (payload.won == true or (snapshot ~= nil and snapshot.td.cleared[modeId] ~= nil))
	shapeResult()
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
	MatchMenuController.close()
	ToastController.setTop(nil)
	LobbyMenuController.setInMatch(false)
	Device.blockTouchControls("overhead", false)
	Device.blockTouchControls("aim", false)
	render()
end

function MatchController.start()
	build()
	Net.event(Net.Events.MatchStart).OnClientEvent:Connect(function(payload: Info)
		info = payload
		state = nil
		Modal.closeAll()
		ToastController.setTop(Hud.TOAST.matchTop)
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
	Device.Changed:Connect(layoutRail)
	Device.Changed:Connect(shapeResult)
	SettingsController.Changed:Connect(function(key: string)
		if key == "railSide" then
			layoutRail()
		end
	end)
end

return MatchController
