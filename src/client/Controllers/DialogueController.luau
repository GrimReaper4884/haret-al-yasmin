--!strict
-- Shows dialogue nodes sent by the server and reports the chosen option's index.
-- Theme v2 (LP-C04): the speaker's portrait in a brass frame beside the line (its unit portrait when the
-- NPC wears a unit's look, else a live view of the NPC's figure), the line typed out at
-- Hud.DIALOGUE.cps (a tap on it completes it; Arabic types in its own reading order), then the
-- choices slide in one after another. Reduced Motion shows everything at once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Npcs = require(Shared.Config.Npcs)
local Units = require(Shared.Config.Units)
local Enemies = require(Shared.Config.Enemies)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Device = require(UI.Device)
local Juice = require(UI.Juice)
local UnitCard = require(UI.UnitCard)
local Button = require(UI.Button)
local Hud = require(Shared.Config.Hud)
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)

type Payload = { npcId: string, nodeId: string, textKey: string, choices: { string } }

local DialogueController = {}

local panel: Frame
local speaker: TextLabel
local closeButton: TextButton
local body: TextLabel
local choiceList: Frame
local current: Payload? = nil
local awaiting = false
local portraitHolder: Frame
local portraitFor: string? = nil
local typing = 0 -- bumps on every new line; a running typewriter stops when it changes
local typedDone = true

local function build()
	panel = Theme.panel({
		Name = "Dialogue",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromScale(0.92, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Root.get(),
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(620, math.huge), Parent = panel })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	-- Header row: speaker name + close button (mirrored for RTL in render()).
	local header = Create("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.TOUCH),
		Parent = panel,
	})
	speaker = Theme.label({
		Name = "Speaker",
		TextSize = 15,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.quest,
		Size = UDim2.new(1, -(Theme.TOUCH + 4), 1, 0),
		Parent = header,
	})
	closeButton = Theme.button({
		Name = "Close",
		Text = "X",
		TextSize = 18,
		Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
		BackgroundColor3 = Theme.colors.danger,
		Parent = header,
	})
	closeButton.Activated:Connect(function()
		DialogueController.hide(true)
	end)
	-- The portrait in its brass frame beside the line (mirrored in Arabic by render()).
	local D = Hud.DIALOGUE
	local row = Create("Frame", { Name = "Line", LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, D.portrait), AutomaticSize = Enum.AutomaticSize.Y, Parent = panel })
	portraitHolder = Create("Frame", { Name = "Portrait", Size = UDim2.fromOffset(D.portrait, D.portrait), BackgroundColor3 = Theme.v2.woodDark, Parent = row }, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Theme.v2.brass
	frameStroke.Thickness = 3
	frameStroke.Parent = portraitHolder
	body = Theme.label({
		TextSize = 17,
		Position = UDim2.fromOffset(D.portrait + 12, 0),
		Size = UDim2.new(1, -(D.portrait + 12), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = row,
	})
	-- A tap on the line types the rest of it at once.
	local skip = Button.hit({ Name = "TypeSkip", Size = UDim2.fromScale(1, 1), ZIndex = body.ZIndex + 1, Parent = row })
	skip.Activated:Connect(function()
		if not typedDone then
			typing += 1
			local p = current
			if p then
				body.Text = LocaleController.t(p.textKey)
			end
			body.MaxVisibleGraphemes = -1
			typedDone = true
			DialogueController.showChoices()
		end
	end)
	choiceList = Create("Frame", {
		LayoutOrder = 3,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = choiceList })
end

-- On touch the panel fits the band between Roblox's thumbstick and jump zones (B6), else the old
-- 0.92-wide centred panel capped at 620 px.
local function fit()
	if Device.isTouch() and next(Device.reserved()) ~= nil then
		local band = Device.freeBand()
		local scale = Device.scale()
		local w = math.min(620, (band.x1 - band.x0) / scale - 8)
		panel.Size = UDim2.fromOffset(w, 0)
		panel.Position = UDim2.new(0, (band.x0 + band.x1) / 2 / scale, 1, -12)
	else
		panel.Size = UDim2.fromScale(0.92, 0)
		panel.Position = UDim2.new(0.5, 0, 1, -12)
	end
end

-- The speaker's face: the unit portrait of the NPC's look, else a live view of its figure.
local function setPortrait(npcId: string)
	if portraitFor == npcId then
		return
	end
	portraitFor = npcId
	for _, c in portraitHolder:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local npc = (Npcs :: any)[npcId]
	local look = npc and npc.look
	-- A unit's or enemy's look has its portrait; an NPC's own look (LP-D08) uses the live figure below.
	if look and ((Units :: any)[look] or (Enemies :: any)[look]) then
		local face = UnitCard.portrait(look, { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3) })
		face.Parent = portraitHolder
		return
	end
	local folder = Workspace:FindFirstChild("Npcs")
	local model = folder and folder:FindFirstChild(npcId)
	if model and model:IsA("Model") then
		local vp = Create("ViewportFrame", { Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, Parent = portraitHolder }) :: ViewportFrame
		local clone = model:Clone()
		for _, d in clone:GetDescendants() do
			if d:IsA("BaseScript") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
				d:Destroy()
			end
		end
		clone.Parent = vp
		local cam = Instance.new("Camera")
		local head = clone:FindFirstChild("Head")
		local at = if head and head:IsA("BasePart") then head.Position else clone:GetPivot().Position + Vector3.new(0, 4.5, 0)
		local look2 = clone:GetPivot().LookVector
		cam.CFrame = CFrame.lookAt(at + look2 * 3.2 + Vector3.new(0, 0.2, 0), at - Vector3.new(0, 0.3, 0))
		cam.FieldOfView = 40
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
end

-- The choices slide in once the line is typed.
function DialogueController.showChoices()
	local items: { GuiObject } = {}
	for _, c in choiceList:GetChildren() do
		if c:IsA("GuiButton") then
			c.Visible = true
			table.insert(items, c)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	Juice.stagger(items, Hud.DIALOGUE.choiceGap)
end

-- Types the line out at Hud.DIALOGUE.cps; Reduced Motion (or Effects off) shows it whole.
local function typeLine()
	typing += 1
	local token = typing
	local total = utf8.len(body.Text) or #body.Text
	if not Juice.allowed("slide") or total == 0 then
		body.MaxVisibleGraphemes = -1
		typedDone = true
		DialogueController.showChoices()
		return
	end
	typedDone = false
	-- Arabic grows the text itself (a right-aligned label then starts at the right); Roblox's
	-- grapheme reveal would lay a partial RTL line out from the left edge.
	local full = body.Text
	local rtl = LocaleController.isRtl()
	local function show(n: number)
		if rtl then
			local cut = utf8.offset(full, n + 1)
			body.Text = if cut then string.sub(full, 1, cut - 1) else full
		else
			body.MaxVisibleGraphemes = n
		end
	end
	show(0)
	local shown = 0
	local start = os.clock()
	task.spawn(function()
		while token == typing and shown < total do
			RunService.Heartbeat:Wait()
			shown = math.min(total, math.floor((os.clock() - start) * Hud.DIALOGUE.cps))
			if token == typing then
				show(shown)
			end
		end
		if token == typing then
			body.Text = full
			body.MaxVisibleGraphemes = -1
			typedDone = true
			DialogueController.showChoices()
		end
	end)
end

local function render()
	local p = current
	if not p then
		panel.Visible = false
		return
	end
	fit()
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local npc = (Npcs :: any)[p.npcId]
	speaker.Text = if npc then t(npc.nameKey) .. " · " .. t(npc.roleKey) else ""
	body.Text = t(p.textKey)
	setPortrait(p.npcId)
	-- The portrait on the reading side's start: left in English, right in Arabic.
	local D = Hud.DIALOGUE
	portraitHolder.AnchorPoint = if rtl then Vector2.new(1, 0) else Vector2.new(0, 0)
	portraitHolder.Position = if rtl then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 0)
	body.Position = if rtl then UDim2.fromOffset(0, 0) else UDim2.fromOffset(D.portrait + 12, 0)
	body.Size = UDim2.new(1, -(D.portrait + 12), 0, 0)
	body.TextXAlignment = if rtl then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
	Theme.align(speaker, rtl)
	Theme.align(body, rtl)
	-- Mirror the header for RTL: close button on the left, name on the right.
	closeButton.AnchorPoint = if rtl then Vector2.new(0, 0) else Vector2.new(1, 0)
	closeButton.Position = if rtl then UDim2.fromScale(0, 0) else UDim2.fromScale(1, 0)
	speaker.AnchorPoint = if rtl then Vector2.new(1, 0) else Vector2.new(0, 0)
	speaker.Position = if rtl then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 0)

	for _, c in choiceList:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	for i, key in p.choices do
		local b = Theme.button({
			LayoutOrder = i,
			Text = t(key),
			TextSize = 16,
			TextWrapped = true,
			Size = UDim2.new(1, 0, 0, Theme.TOUCH),
			Visible = typedDone,
			Parent = choiceList,
		})
		Theme.align(b, rtl)
		b.Activated:Connect(function()
			if awaiting then
				return
			end
			awaiting = true
			Net.event(Net.Events.DialogueChoose):FireServer(i)
		end)
	end
	panel.Visible = true
end

function DialogueController.hide(tellServer: boolean)
	if current and tellServer then
		Net.event(Net.Events.DialogueClose):FireServer()
	end
	current = nil
	awaiting = false
	panel.Visible = false
end

function DialogueController.isOpen(): boolean
	return current ~= nil
end

function DialogueController.start()
	build()
	Net.event(Net.Events.DialogueShow).OnClientEvent:Connect(function(payload: Payload)
		current = payload
		awaiting = false
		typedDone = false
		render()
		typeLine()
	end)
	Net.event(Net.Events.DialogueHide).OnClientEvent:Connect(function(screen: any)
		DialogueController.hide(false)
		-- A lane NPC's "screen" choice (LP-D02): open that lobby screen.
		local open = if type(screen) == "string" then LobbyMenuController.opener(screen) else nil
		if open then
			open()
		end
	end)
	-- A match takes the whole screen: a dialogue left open on the portal pad closes (and the server's
	-- session with it) instead of covering the match HUD (MH-19).
	MatchController.Started:Connect(function()
		DialogueController.hide(true)
	end)
	LocaleController.Changed:Connect(render)
	Device.Changed:Connect(function()
		if current then
			fit()
		end
	end)
end

return DialogueController
