--!strict
-- Always-on HUD: coin pill, errand tracker, language toggle, wardrobe and the music mute.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local Clues = require(Shared.Config.Clues)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Juice = require(UI.Juice)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local ShopController = require(script.Parent.ShopController)
local WardrobeController = require(script.Parent.WardrobeController)
local SettingsController = require(script.Parent.SettingsController)

local HudController = {}

local coinLabel: TextLabel
local coinPill: Frame
local questHeader: TextLabel
local questTitle: TextLabel
local questObjective: TextLabel
local questClues: TextLabel
local langButton: TextButton
local wardrobeButton: TextButton
local testBadge: TextLabel
local lastQirsh: number? = nil

local function build()
	local root = Root.get()

	-- Layout: Roblox owns the top-left (menu + chat window) and top-right (player list), so the
	-- coin pill and language toggle sit top-centre and the errand tracker sits on the right edge.
	coinPill, coinLabel = Theme.pill({
		Name = "Coins",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.5, -6, 0, 10),
		Size = UDim2.fromOffset(170, 36),
		Parent = root,
	}, Theme.colors.gold)
	coinLabel.TextColor3 = Color3.fromHex("#FFD970")
	coinLabel.Size = UDim2.new(1, -66, 1, 0)
	-- "+" opens the coin store (Robux purses and passes).
	local storeButton = Theme.button({
		Name = "Store",
		Text = "+",
		TextSize = 22,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 4, 0.5, 0),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Theme.colors.confirm,
		Parent = coinPill,
	})
	local sp = storeButton:FindFirstChildOfClass("UIPadding")
	if sp then
		sp:Destroy()
	end
	storeButton.Activated:Connect(ShopController.openStore)

	local tracker = Theme.panel({
		Name = "Errand",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.45, 0),
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
	questClues = Theme.label({
		LayoutOrder = 4,
		TextSize = 14,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.accent,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = tracker,
	})

	langButton = Theme.button({
		Name = "Language",
		Position = UDim2.new(0.5, 6, 0, 6),
		Size = UDim2.fromOffset(96, Theme.TOUCH - 4),
		TextSize = 18,
		Parent = root,
	})
	langButton.Activated:Connect(LocaleController.toggle)

	wardrobeButton = Theme.button({
		Name = "Wardrobe",
		Position = UDim2.new(0.5, 108, 0, 6),
		Size = UDim2.fromOffset(112, Theme.TOUCH - 4),
		TextSize = 17,
		BackgroundColor3 = Theme.colors.quest,
		Parent = root,
	})
	wardrobeButton.Activated:Connect(WardrobeController.toggle)

	-- One-tap music mute beside the pills (the match HUD has its own next to the gear).
	SettingsController.muteButton({
		Name = "Music",
		Position = UDim2.new(0.5, 226, 0, 4),
		Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
		BackgroundColor3 = Color3.fromHex("#6E5E50"),
		Parent = root,
	})

	-- Shown only when the server runs on the mock store (unpublished place / no API access).
	testBadge = Theme.label({
		Name = "TestMode",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Theme.TOUCH + 10),
		Size = UDim2.fromOffset(320, 18),
		TextSize = 13,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.danger,
		TextStrokeColor3 = Theme.colors.panel,
		TextStrokeTransparency = 0.2,
		Visible = false,
		Parent = root,
	})
end

-- Picks the errand to show: an active quest first, else the completed one with the latest episode.
local function currentQuest(): (string?, string?)
	local snapshot = StateController.get()
	if not snapshot then
		return nil, nil
	end
	local best: string? = nil
	local bestEpisode = -1
	for id, rec in snapshot.quests do
		local def = (Quests :: any)[id]
		if def then
			if rec.state == "active" then
				return id, StateController.questState(id)
			end
			local ep = def.episode or 0
			if ep > bestEpisode then
				best, bestEpisode = id, ep
			end
		end
	end
	return best, if best then "completed" else nil
end

-- "Clues 2/3" followed by the names of the clues found so far, in config order.
local function clueJournal(questId: string): string
	local def = (Quests :: any)[questId]
	if not def or def.kind ~= "investigate" then
		return ""
	end
	local t = LocaleController.t
	local found = {}
	for _, clueId in def.clues do
		if StateController.clueFound(questId, clueId) then
			table.insert(found, clueId)
		end
	end
	table.sort(found, function(a, b)
		return (Clues :: any)[a].order < (Clues :: any)[b].order
	end)
	local lines = { t("hud.clues", { n = #found, total = #def.clues }) }
	for _, clueId in found do
		table.insert(lines, "- " .. t((Clues :: any)[clueId].nameKey))
	end
	return table.concat(lines, "\n")
end

local function render()
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local snapshot = StateController.get()

	if snapshot then
		local function fmt(n: number): string
			return t("hud.currency", { n = n })
		end
		if lastQirsh and snapshot.qirsh ~= lastQirsh then
			-- Count up and punch so earning/spending is noticed.
			Juice.count(coinLabel, lastQirsh, snapshot.qirsh, fmt)
			Juice.punch(coinPill, 0.1)
		else
			coinLabel.Text = fmt(snapshot.qirsh)
		end
		lastQirsh = snapshot.qirsh
	end

	local questId, state = currentQuest()
	if questId and state then
		local def = (Quests :: any)[questId]
		questHeader.Text = if def.episode then t("hud.episode", { n = def.episode }) else t("hud.quest_header")
		questTitle.Text = t(def.titleKey)
		questObjective.Text = t(def.objectiveKeys[state] or def.objectiveKeys.active)
		questClues.Text = if state == "completed" then "" else clueJournal(questId)
	else
		questHeader.Text = t("hud.quest_header")
		questTitle.Text = t("hud.no_quest")
		questObjective.Text = ""
		questClues.Text = ""
	end
	questClues.Visible = questClues.Text ~= ""
	for _, l in { questHeader, questTitle, questObjective, questClues } do
		Theme.align(l, rtl)
	end
	langButton.Text = t("hud.language")
	wardrobeButton.Text = t("hud.wardrobe")
	testBadge.Visible = snapshot ~= nil and not snapshot.persistent
	testBadge.Text = t("notify.persistence_disabled")
end

function HudController.start()
	build()
	render()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
end

return HudController
