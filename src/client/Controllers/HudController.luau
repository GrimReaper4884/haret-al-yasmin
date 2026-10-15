--!strict
-- Always-on HUD: coin pill, errand tracker and language toggle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local HudController = {}

local coinLabel: TextLabel
local coinPill: Frame
local questHeader: TextLabel
local questTitle: TextLabel
local questObjective: TextLabel
local langButton: TextButton
local lastQirsh: number? = nil

local function build()
	local root = Root.get()

	coinPill = Theme.panel({
		Name = "Coins",
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.fromOffset(150, Theme.TOUCH - 4),
		Parent = root,
	})
	Theme.label({
		Name = "Icon",
		Text = "◉",
		TextColor3 = Theme.colors.accent,
		FontFace = Theme.fontBold,
		TextSize = 24,
		Size = UDim2.new(0, 36, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		Parent = coinPill,
	})
	coinLabel = Theme.label({
		Name = "Amount",
		Text = "…",
		FontFace = Theme.fontBold,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -46, 1, 0),
		Position = UDim2.fromOffset(42, 0),
		Parent = coinPill,
	})

	local tracker = Theme.panel({
		Name = "Errand",
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = root,
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		Parent = tracker,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tracker })
	questHeader = Theme.label({
		LayoutOrder = 1,
		TextSize = 13,
		TextColor3 = Theme.colors.quest,
		FontFace = Theme.fontBold,
		Size = UDim2.new(1, 0, 0, 16),
		Parent = tracker,
	})
	questTitle = Theme.label({
		LayoutOrder = 2,
		TextSize = 16,
		FontFace = Theme.fontBold,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = tracker,
	})
	questObjective = Theme.label({
		LayoutOrder = 3,
		TextSize = 14,
		TextColor3 = Theme.colors.textMuted,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = tracker,
	})

	langButton = Theme.button({
		Name = "Language",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(96, Theme.TOUCH - 4),
		TextSize = 18,
		Parent = root,
	})
	langButton.Activated:Connect(LocaleController.toggle)
end

-- Picks the errand to show: the first active quest, else the most recently completed one.
local function currentQuest(): (string?, string?)
	local snapshot = StateController.get()
	if not snapshot then
		return nil, nil
	end
	local completed: string? = nil
	for id, rec in snapshot.quests do
		if (Quests :: any)[id] then
			if rec.state == "active" then
				return id, "active"
			end
			completed = id
		end
	end
	return completed, if completed then "completed" else nil
end

local function render()
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local snapshot = StateController.get()

	if snapshot then
		coinLabel.Text = t("hud.currency", { n = snapshot.qirsh })
		if lastQirsh and snapshot.qirsh ~= lastQirsh then
			-- Small pulse so earning/spending is noticed.
			local stroke = coinPill:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Theme.colors.accent
				stroke.Thickness = 4
				TweenService:Create(stroke, TweenInfo.new(0.6), { Thickness = 2, Color = Theme.colors.panelStroke }):Play()
			end
		end
		lastQirsh = snapshot.qirsh
	end

	questHeader.Text = t("hud.quest_header")
	local questId, state = currentQuest()
	if questId and state then
		local def = (Quests :: any)[questId]
		questTitle.Text = t(def.titleKey)
		questObjective.Text = t(def.objectiveKeys[state])
	else
		questTitle.Text = t("hud.no_quest")
		questObjective.Text = ""
	end
	for _, l in { questHeader, questTitle, questObjective } do
		Theme.align(l, rtl)
	end
	langButton.Text = t("hud.language")
end

function HudController.start()
	build()
	render()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
end

return HudController
