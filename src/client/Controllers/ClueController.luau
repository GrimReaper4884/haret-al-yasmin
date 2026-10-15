--!strict
-- Clue spots: shows the "Inspect" prompt and an outline only while the clue can be found by this
-- player (quest active, clue not yet found), and shows a clue card when the server confirms a find.
-- Purely presentational: the server validates every inspection.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Clues = require(Shared.Config.Clues)
local Palette = require(Shared.Config.Palette)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local ClueController = {}

local TAG = "Clue"
local CARD_SECONDS = 7

type Spot = { model: Model, clueId: string, prompt: ProximityPrompt?, highlight: Highlight }
local spots: { [Model]: Spot } = {}

local card: Frame
local cardTitle: TextLabel
local cardBody: TextLabel
local cardClue: string? = nil
local cardToken = 0

local function findable(clueId: string): boolean
	local def = (Clues :: any)[clueId]
	if not def then
		return false
	end
	local state = StateController.questState(def.quest)
	return (state == "active" or state == "ready") and not StateController.clueFound(def.quest, clueId)
end

local function updateSpot(s: Spot)
	local on = findable(s.clueId)
	s.highlight.Enabled = on
	if s.prompt then
		s.prompt.Enabled = on
		s.prompt.ActionText = LocaleController.t("prompt.inspect")
		s.prompt.ObjectText = LocaleController.t((Clues :: any)[s.clueId].nameKey)
	end
end

local function attach(model: Instance)
	if not model:IsA("Model") or spots[model] then
		return
	end
	local clueId = model:GetAttribute("ClueId")
	local anchor = model:WaitForChild("Anchor", 10)
	if type(clueId) ~= "string" or not anchor then
		return
	end
	local highlight = Create("Highlight", {
		Adornee = model,
		FillTransparency = 1,
		OutlineColor = Palette.copper,
		OutlineTransparency = 0.1,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Enabled = false,
		Parent = model,
	})
	local s: Spot = {
		model = model,
		clueId = clueId,
		prompt = anchor:FindFirstChildOfClass("ProximityPrompt"),
		highlight = highlight,
	}
	spots[model] = s
	updateSpot(s)
end

local function updateAll()
	for _, s in spots do
		updateSpot(s)
	end
end

local function buildCard()
	card = Theme.panel({
		Name = "ClueCard",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.8, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Root.get(),
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(440, math.huge), Parent = card })
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = card,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
	cardTitle = Theme.label({
		LayoutOrder = 1,
		TextSize = 18,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.accent,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = card,
	})
	cardBody = Theme.label({
		LayoutOrder = 2,
		TextSize = 16,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	local ok = Theme.button({
		LayoutOrder = 3,
		TextSize = 16,
		Size = UDim2.new(1, 0, 0, Theme.TOUCH),
		Parent = card,
	})
	ok.Name = "Ok"
	ok.Activated:Connect(function()
		cardClue = nil
		card.Visible = false
	end)
end

local function renderCard()
	local id = cardClue
	if not id then
		card.Visible = false
		return
	end
	local def = (Clues :: any)[id]
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	cardTitle.Text = t(def.nameKey)
	cardBody.Text = t(def.textKey)
	local okButton = card:FindFirstChild("Ok") :: TextButton
	okButton.Text = t("clue.close")
	Theme.align(cardTitle, rtl)
	Theme.align(cardBody, rtl)
	card.Visible = true
end

function ClueController.start()
	buildCard()
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(m)
		task.spawn(attach, m)
	end)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(m)
		spots[m :: Model] = nil
	end)
	for _, m in CollectionService:GetTagged(TAG) do
		task.spawn(attach, m)
	end
	StateController.Changed:Connect(updateAll)
	LocaleController.Changed:Connect(function()
		updateAll()
		renderCard()
	end)

	Net.event(Net.Events.ClueShow).OnClientEvent:Connect(function(clueId: string)
		if type(clueId) ~= "string" or not (Clues :: any)[clueId] then
			return
		end
		cardClue = clueId
		cardToken += 1
		local token = cardToken
		renderCard()
		cardBody.TextTransparency = 1
		TweenService:Create(cardBody, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
		task.delay(CARD_SECONDS, function()
			if cardToken == token then
				cardClue = nil
				card.Visible = false
			end
		end)
	end)
end

return ClueController
