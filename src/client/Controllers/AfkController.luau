--!strict
-- The Hakawati's room (AFK chamber, docs/AFK_CHAMBER.md) on the client:
--  * the intro panel (menu button "AFK", the stair mat in the coffee house): what the room pays,
--    today's lira so far, the player's bonus, and "Go upstairs";
--  * inside the room: a top card with the tale being told, a countdown bar to the next cup of
--    tea, today's lira against the cap and this visit's time, plus "Back to the lane". The lobby
--    HUD is hidden; the storyteller's lines appear in turn above his chair;
--  * a toast for every cup and tale, and a summary on leaving;
--  * a "Tales" list of the season's episode outros, each readable once that episode is cleared
--    (Logic/StoryCards.tales, S1-C06; read-only, the AFK rules are unchanged);
--  * idle handling: Player.Idled asks the server to hop servers before Roblox's 20-minute kick
--    while inside, and (setting "autoAfk") walks an idle lobby player up to the room.
-- Display only: the server owns the clock and the payouts.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Afk = require(Shared.Config.Afk)
local Story = require(Shared.Config.Story)
local StoryCards = require(Shared.Logic.StoryCards)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Root = require(UI.Root)
local RewardText = require(UI.RewardText)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local ToastController = require(script.Parent.ToastController)
local SettingsController = require(script.Parent.SettingsController)

local AfkController = {}

local player = Players.LocalPlayer

-- Intro panel
local modal: Modal.Modal
local introText: TextLabel
local bonusText: TextLabel
local todayText: TextLabel
local enterButton: TextButton

-- In-room HUD
local hud: Frame
local hudTitle: TextLabel
local taleText: TextLabel
local meter: Theme.Meter
local todayLine: TextLabel
local sessionLine: TextLabel
local bonusPill: TextLabel
local leaveButton: TextButton
local talesButton: TextButton
local talesModal: Modal.Modal
local talesList: ScrollingFrame
local bubble: BillboardGui?
local bubbleText: TextLabel?

local inside = false
local carry0 = 0 -- seconds toward the next cup at `recvAt`
local recvAt = 0
local session0 = 0
local mult = 1
local inParty = false
local lastHop = -math.huge
local busy = false
local lastTick = 0

local function fmtTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

local function scaled(reward: any, k: number): { [string]: number }
	local out = {}
	for key, v in reward do
		out[key] = math.floor(v * k + 0.5)
	end
	return out
end

local function afkSnap(): any
	local s = StateController.get() :: any
	return s and s.afk
end

---------------------------------------------------------------- Intro panel

local function renderIntro()
	if not modal or not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local a = afkSnap()
	local k = if a then a.mult else 1
	modal.title.Text = t("afk.room")
	Theme.align(modal.title, rtl)
	introText.Text = t("afk.intro", {
		min = math.floor(Afk.CUP_SECONDS / 60),
		cup = RewardText(t, scaled(Afk.CUP, k)),
		tale = RewardText(t, scaled(Afk.TALE, k)),
		cap = if a then a.cap else Afk.DAILY_CAP_LIRA,
	})
	Theme.align(introText, rtl)
	bonusText.Text = if k > 1 then t("afk.intro.mult", { mult = k }) else t("afk.intro.vip")
	bonusText.TextColor3 = if k > 1 then Theme.colors.confirm else Theme.colors.textMuted
	Theme.align(bonusText, rtl)
	todayText.Text =
		t("afk.today", { n = if a then a.paidToday else 0, cap = if a then a.cap else Afk.DAILY_CAP_LIRA })
	Theme.align(todayText, rtl)
	enterButton.Text = t("afk.enter")
end

function AfkController.open()
	if inside then
		return
	end
	modal.setVisible(true)
	renderIntro()
end

local function requestEnter(reason: string)
	if busy or inside then
		return
	end
	busy = true
	Net.event(Net.Events.AfkEnter):FireServer(reason)
	task.delay(1.5, function()
		busy = false
	end)
end

local function buildIntro()
	modal = Modal.create("Afk", 560, 236)
	local body = modal.body
	Create(
		"UIListLayout",
		{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body }
	)
	introText = Theme.label({
		LayoutOrder = 1,
		TextSize = 14,
		Size = UDim2.new(1, 0, 0, 118), -- six lines at 14 px; AutomaticSize undercounts under the UIScale
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 11,
		Parent = body,
	})
	bonusText = Theme.label({
		LayoutOrder = 2,
		TextSize = 13,
		FontFace = Theme.fontBold,
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 11,
		Parent = body,
	})
	todayText = Theme.label({
		LayoutOrder = 3,
		TextSize = 13,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.quest,
		Size = UDim2.new(1, 0, 0, 18),
		ZIndex = 11,
		Parent = body,
	})
	local row = Create("Frame", {
		LayoutOrder = 4,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.TOUCH),
		ZIndex = 11,
		Parent = body,
	})
	enterButton = Theme.button({
		TextSize = 17,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(240, Theme.TOUCH),
		BackgroundColor3 = Theme.colors.confirm,
		ZIndex = 11,
		Parent = row,
	})
	enterButton.Activated:Connect(function()
		modal.setVisible(false)
		requestEnter("menu")
	end)
end

---------------------------------------------------------------- In-room HUD

local function currentTale(): (string, number)
	local a = afkSnap()
	if not a then
		return Afk.TALES[1], 0
	end
	return Afk.TALES[(a.tales % #Afk.TALES) + 1], a.cups % Afk.CUPS_PER_TALE
end

local function renderHud()
	if not inside then
		return
	end
	local t = LocaleController.t
	local a = afkSnap()
	hudTitle.Text = t("afk.room")
	local taleId, poured = currentTale()
	taleText.Text =
		t("afk.tale", { tale = t("afk.tale." .. taleId), n = poured + 1, total = Afk.CUPS_PER_TALE })
	if a then
		local capped = a.paidToday >= a.cap
		todayLine.Text = if capped then t("afk.capped") else t("afk.today", { n = a.paidToday, cap = a.cap })
		todayLine.TextColor3 = if capped then Theme.colors.gold else Color3.fromHex("#F5E6C8")
	end
	bonusPill.Visible = mult > 1
	bonusPill.Text = t("afk.bonus", { mult = mult })
	leaveButton.Text = t("afk.leave")
	talesButton.Text = t("afk.tales")
end

-- Called every frame (cheaply): the countdown and the visit clock.
local function tickHud()
	if not inside or os.clock() - lastTick < 0.5 then
		return
	end
	lastTick = os.clock()
	local t = LocaleController.t
	local elapsed = os.clock() - recvAt
	local carry = math.min(carry0 + elapsed, Afk.CUP_SECONDS)
	local left = Afk.CUP_SECONDS - carry
	meter.set(carry / Afk.CUP_SECONDS, t("afk.next_cup", { t = fmtTime(left) }))
	sessionLine.Text = t("afk.session", { t = fmtTime(session0 + elapsed) })
end

local function buildHud()
	local root = Root.get()
	hud = Theme.panel({
		Name = "AfkHud",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.fromOffset(420, 146),
		BackgroundColor3 = Color3.fromHex("#2A211B"),
		Visible = false,
		Parent = root,
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = hud,
	})
	hudTitle = Theme.display({ TextSize = 19, Size = UDim2.new(1, 0, 0, 22), Parent = hud })
	hudTitle.TextXAlignment = Enum.TextXAlignment.Center
	bonusPill = Theme.display({
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Size = UDim2.fromOffset(84, 18),
		TextColor3 = Theme.colors.gold,
		Parent = hud,
	})
	bonusPill.TextXAlignment = Enum.TextXAlignment.Right
	taleText = Theme.label({
		TextSize = 14,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.gold,
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 18),
		Parent = hud,
	})
	taleText.TextXAlignment = Enum.TextXAlignment.Center
	meter = Theme.meter(
		{ Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 22), Parent = hud },
		Theme.colors.gold
	)
	todayLine = Theme.label({
		TextSize = 13,
		FontFace = Theme.fontBold,
		Position = UDim2.fromOffset(0, 67),
		Size = UDim2.new(0.6, 0, 0, 16),
		Parent = hud,
	})
	todayLine.TextXAlignment = Enum.TextXAlignment.Left
	sessionLine = Theme.label({
		TextSize = 12,
		TextColor3 = Color3.fromHex("#CDBFA8"),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 67),
		Size = UDim2.new(0.4, 0, 0, 16),
		Parent = hud,
	})
	sessionLine.TextXAlignment = Enum.TextXAlignment.Right
	leaveButton = Theme.button({
		Name = "AfkLeave",
		TextSize = 16,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(220, 42),
		BackgroundColor3 = Theme.colors.danger,
		Parent = hud,
	})
	leaveButton.Activated:Connect(function()
		Net.event(Net.Events.AfkLeave):FireServer()
	end)
	talesButton = Theme.button({
		Name = "AfkTales",
		TextSize = 14,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromOffset(84, 42),
		BackgroundColor3 = Theme.colors.quest,
		Parent = hud,
	})
	talesButton.Activated:Connect(function()
		AfkController.openTales()
	end)
end

---------------------------------------------------------------- The season's tales (S1-C06)

-- Arabic-Indic digits in Arabic (the episode names in Strings use them).
local AR_DIGITS = { "٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩" }
local function digits(n: number): string
	if not LocaleController.isRtl() then
		return tostring(n)
	end
	return (string.gsub(tostring(n), "%d", function(d)
		return AR_DIGITS[tonumber(d) :: number + 1]
	end))
end

local function renderTales()
	if not talesModal or not talesModal.isOpen() then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	talesModal.title.Text = t("afk.tales_title")
	Theme.align(talesModal.title, rtl)
	for _, c in talesList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local snapshot = StateController.get()
	local cleared = snapshot and snapshot.td and snapshot.td.cleared or nil
	for _, tale in StoryCards.tales(Story, cleared) do
		local entry = Create("Frame", { LayoutOrder = tale.number, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 12, Parent = talesList })
		Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = entry })
		local title = Theme.label({
			LayoutOrder = 1,
			Text = t("play.soon_name", { n = digits(tale.number), title = t(tale.titleKey) }),
			TextSize = 15,
			FontFace = Theme.fontBold,
			TextColor3 = if tale.unlocked then Theme.colors.text else Theme.colors.textMuted,
			Size = UDim2.new(1, 0, 0, 20),
			ZIndex = 12,
			Parent = entry,
		})
		local lines = {}
		for _, key in tale.lines do
			table.insert(lines, t(key))
		end
		local body = Theme.label({
			LayoutOrder = 2,
			Text = if tale.unlocked then "“" .. table.concat(lines, " ") .. "”" else t("afk.tale_locked", { n = digits(tale.number) }),
			TextSize = 13,
			TextColor3 = if tale.unlocked then Color3.fromHex("#5A3E22") else Theme.colors.textMuted,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 12,
			Parent = entry,
		})
		Theme.align(title, rtl)
		Theme.align(body, rtl)
	end
end

-- Opens the read-only list of the season's tales (the Tales button in the room; Studio harness T).
function AfkController.openTales()
	if not talesModal then
		local m = Modal.create("AfkTales", 560, 250, { fill = true })
		talesList = Modal.scroller(m.body)
		Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = talesList })
		talesModal = m
	end
	talesModal.setVisible(true)
	renderTales()
	talesList.CanvasPosition = Vector2.zero
end

---------------------------------------------------------------- The storyteller's lines

local function ensureBubble(): boolean
	if bubble and bubble.Parent then
		return true
	end
	local npcs = Workspace:FindFirstChild("Npcs")
	local rig = npcs and npcs:FindFirstChild("hakawati")
	local head = rig and rig:FindFirstChild("Head") :: BasePart?
	if not head then
		return false
	end
	local gui = Create("BillboardGui", {
		Name = "HakawatiLine",
		Size = UDim2.fromOffset(300, 64),
		StudsOffset = Vector3.new(0, 5, 0),
		MaxDistance = 60,
		AlwaysOnTop = true, -- the room sign hangs right behind his head
		Enabled = false,
		Parent = head,
	})
	local frame = Create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromHex("#2A211B"),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("UIStroke", { Color = Theme.colors.gold, Thickness = 1.5 }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	local label = Theme.label({
		TextSize = 15,
		FontFace = Theme.fontBold,
		TextColor3 = Color3.fromHex("#F5E6C8"),
		Size = UDim2.fromScale(1, 1),
		Parent = frame,
	})
	label.TextXAlignment = Enum.TextXAlignment.Center
	bubble, bubbleText = gui, label
	return true
end

local function storyteller()
	local line = 0
	while true do
		task.wait(Afk.LINE_SECONDS)
		if inside and ensureBubble() then
			local taleId = currentTale()
			line = (line % Afk.LINES) + 1
			local b, l = bubble :: BillboardGui, bubbleText :: TextLabel
			l.Text = LocaleController.t("afk.line." .. taleId .. "." .. line)
			b.Enabled = true
			task.delay(Afk.LINE_SECONDS - 3, function()
				if bubble == b then
					b.Enabled = false
				end
			end)
		elseif bubble then
			bubble.Enabled = false
		end
	end
end

---------------------------------------------------------------- State from the server

-- Indoors the lane's afternoon light is too strong: dim the exposure while inside.
local INDOOR_EXPOSURE = -0.8
local savedExposure: number? = nil

local function setIndoor(v: boolean)
	if v and savedExposure == nil then
		savedExposure = Lighting.ExposureCompensation
		TweenService:Create(
			Lighting,
			TweenInfo.new(0.8),
			{ ExposureCompensation = (savedExposure :: number) + INDOOR_EXPOSURE }
		):Play()
	elseif not v and savedExposure ~= nil then
		TweenService:Create(Lighting, TweenInfo.new(0.8), { ExposureCompensation = savedExposure }):Play()
		savedExposure = nil
	end
end

-- Once seated, look over the player's shoulder at the storyteller's dais.
local function aimCamera()
	task.delay(1.2, function()
		local character = player.Character
		local head = character and character:FindFirstChild("Head") :: BasePart?
		local camera = Workspace.CurrentCamera
		if not inside or not head or not camera then
			return
		end
		local o = Afk.ORIGIN
		local dais = Vector3.new(o[1], o[2] + 4, o[3] + 10)
		local flat = Vector3.new(dais.X - head.Position.X, 0, dais.Z - head.Position.Z)
		local dir = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
		camera.CFrame = CFrame.lookAt(head.Position - dir * 9 + Vector3.new(0, 3.5, 0), dais)
	end)
end

local function setInside(v: boolean)
	inside = v
	hud.Visible = v
	LobbyMenuController.setInAfk(v)
	setIndoor(v)
	if v then
		Modal.closeAll()
		aimCamera()
	elseif bubble then
		bubble.Enabled = false
	end
end

local function onState(payload: any)
	if type(payload) ~= "table" then
		return
	end
	local t = LocaleController.t
	if payload.inside then
		local wasInside = inside
		carry0 = tonumber(payload.carry) or 0
		recvAt = os.clock()
		mult = tonumber(payload.mult) or 1
		session0 = if type(payload.session) == "table" then tonumber(payload.session.seconds) or 0 else 0
		if not wasInside then
			setInside(true)
			if payload.reason == "hop" then
				ToastController.show("afk.welcome_back")
			end
		end
		renderHud()
		lastTick = 0
		tickHud()
	else
		setInside(false)
		local sum = payload.summary
		if type(sum) == "table" and (sum.seconds or 0) >= 10 then
			local reward = RewardText(t, sum)
			if reward ~= "" then
				ToastController.show("afk.summary", { t = fmtTime(sum.seconds), reward = reward })
			else
				ToastController.show("afk.summary.none", { t = fmtTime(sum.seconds) })
			end
		end
	end
end

local function onPayout(pay: any)
	if type(pay) ~= "table" or type(pay.granted) ~= "table" then
		return
	end
	local t = LocaleController.t
	local reward = RewardText(t, pay.granted)
	if reward == "" then
		return
	end
	if pay.kind == "tale" and type(pay.tale) == "string" then
		ToastController.show("afk.tale_done", { tale = t("afk.tale." .. pay.tale), reward = reward })
	else
		ToastController.show("afk.cup", { reward = reward })
	end
end

---------------------------------------------------------------- Idle handling

local function inLobby(): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return false
	end
	local p = root.Position
	return math.abs(p.X) < 400 and math.abs(p.Z) < 400 -- the lane; arenas are at x >= 3000
end

local function dialogueOpen(): boolean
	local d = Root.get():FindFirstChild("Dialogue")
	return d ~= nil and (d :: GuiObject).Visible
end

local function onIdled(idleSeconds: number)
	if inside then
		if idleSeconds >= Afk.IDLE_HOP_SECONDS and os.clock() - lastHop > Afk.HOP_COOLDOWN then
			lastHop = os.clock()
			if not RunService:IsStudio() then
				local gui = Create("ScreenGui", { Name = "AfkHop", IgnoreGuiInset = true })
				local frame = Create("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromHex("#2A211B"),
					Parent = gui,
				})
				local label = Theme.display({
					Text = LocaleController.t("afk.hop"),
					TextSize = 28,
					Size = UDim2.fromScale(1, 1),
					Parent = frame,
				})
				label.TextXAlignment = Enum.TextXAlignment.Center
				pcall(function()
					TeleportService:SetTeleportGui(gui)
				end)
			end
			Net.event(Net.Events.AfkHop):FireServer()
		end
	elseif
		idleSeconds >= Afk.AUTO_ENTER_IDLE_SECONDS
		and SettingsController.get("autoAfk") == true
		-- A Studio test run driven without input sets this on the player (DebugService "noAutoAfk"),
		-- so the idle walk never pays the owner's live profile in a Play Solo (LP-D03).
		and not Players.LocalPlayer:GetAttribute("HarnessNoAutoAfk")
	then
		if inLobby() and not inParty and not dialogueOpen() then
			requestEnter("idle")
			ToastController.show("afk.idle_moved")
		end
	end
end

---------------------------------------------------------------- Start

-- Opens the intro panel once each time the player steps onto the stair mat in the coffee house.
local function watchMat()
	local on = false
	while true do
		task.wait(0.3)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local now = false
		if root and not inside then
			for _, mat in CollectionService:GetTagged("AfkGate") do
				if mat:IsA("BasePart") then
					local l = mat.CFrame:PointToObjectSpace(root.Position)
					if
						math.abs(l.X) <= mat.Size.X / 2 + 0.5
						and math.abs(l.Z) <= mat.Size.Z / 2 + 0.5
						and l.Y < 8
					then
						now = true
					end
				end
			end
		end
		if now and not on and not modal.isOpen() and not inParty then
			AfkController.open()
		end
		on = now
	end
end

-- The exit door's prompt text comes from the server in English; localize it here.
local function localizePrompt(part: Instance)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt") or part:WaitForChild("ExitPrompt", 5)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = LocaleController.t("afk.leave")
		prompt.ObjectText = LocaleController.t("afk.room")
	end
end

function AfkController.start()
	buildIntro()
	buildHud()
	LobbyMenuController.register("afk", AfkController.open)
	-- The tales list follows the language and new clears while it is open.
	LocaleController.Changed:Connect(renderTales)
	StateController.Changed:Connect(renderTales)
	Net.event(Net.Events.AfkState).OnClientEvent:Connect(onState)
	Net.event(Net.Events.AfkPayout).OnClientEvent:Connect(onPayout)
	Net.event(Net.Events.QueueState).OnClientEvent:Connect(function(payload: any)
		inParty = payload ~= nil
	end)
	StateController.Changed:Connect(function()
		renderIntro()
		renderHud()
	end)
	LocaleController.Changed:Connect(function()
		renderIntro()
		renderHud()
		for _, part in CollectionService:GetTagged("AfkExit") do
			task.spawn(localizePrompt, part)
		end
	end)
	CollectionService:GetInstanceAddedSignal("AfkExit"):Connect(function(part)
		task.spawn(localizePrompt, part)
	end)
	for _, part in CollectionService:GetTagged("AfkExit") do
		task.spawn(localizePrompt, part)
	end
	player.Idled:Connect(onIdled)
	RunService.Heartbeat:Connect(tickHud)
	task.spawn(watchMat)
	task.spawn(storyteller)
end

return AfkController
