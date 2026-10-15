--!strict
-- Shows dialogue nodes sent by the server and reports the chosen option's index.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Npcs = require(Shared.Config.Npcs)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local LocaleController = require(script.Parent.LocaleController)

type Payload = { npcId: string, nodeId: string, textKey: string, choices: { string } }

local DialogueController = {}

local panel: Frame
local speaker: TextLabel
local closeButton: TextButton
local body: TextLabel
local choiceList: Frame
local current: Payload? = nil
local awaiting = false

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
		Size = UDim2.new(1, 0, 0, Theme.TOUCH - 8),
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
		Size = UDim2.fromOffset(Theme.TOUCH - 8, Theme.TOUCH - 8),
		BackgroundColor3 = Theme.colors.danger,
		Parent = header,
	})
	closeButton.Activated:Connect(function()
		DialogueController.hide(true)
	end)
	body = Theme.label({
		LayoutOrder = 2,
		TextSize = 17,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = panel,
	})
	choiceList = Create("Frame", {
		LayoutOrder = 3,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = choiceList })
end

local function render()
	local p = current
	if not p then
		panel.Visible = false
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local npc = (Npcs :: any)[p.npcId]
	speaker.Text = if npc then t(npc.nameKey) .. " · " .. t(npc.roleKey) else ""
	body.Text = t(p.textKey)
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
		render()
		body.TextTransparency = 1
		TweenService:Create(body, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	end)
	Net.event(Net.Events.DialogueHide).OnClientEvent:Connect(function()
		DialogueController.hide(false)
	end)
	LocaleController.Changed:Connect(render)
end

return DialogueController
