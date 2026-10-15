--!strict
-- Lobby chrome for the tower-defense update: the lira pill next to the coins, and the bottom
-- menu bar (Units, Summon, Diary, Codes, Daily). Hides the whole lobby HUD while a match is on
-- or a dialogue is open, so the phone screen stays clear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Daily = require(Shared.Config.Daily)
local DailyLogic = require(Shared.Logic.DailyLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local LobbyMenuController = {}

local LOBBY_WIDGETS = { "Coins", "Errand", "Language", "Wardrobe", "Lira", "Menu", "TestMode" }

local liraLabel: TextLabel
local bar: Frame
local buttons: { [string]: TextButton } = {}
local badges: { [string]: Frame } = {}
local inMatch = false
local openers: { [string]: () -> () } = {}

-- Other controllers register what their button opens (avoids require cycles).
function LobbyMenuController.register(key: string, open: () -> ())
	openers[key] = open
end

local function build()
	local root = Root.get()
	local pill = Theme.panel({
		Name = "Lira",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.5, -184, 0, 8),
		Size = UDim2.fromOffset(140, Theme.TOUCH - 4),
		Parent = root,
	})
	Theme.label({
		Text = "◆",
		TextColor3 = Theme.lira,
		FontFace = Theme.fontBold,
		TextSize = 22,
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		Parent = pill,
	})
	liraLabel = Theme.label({
		Text = "…",
		FontFace = Theme.fontBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.fromOffset(36, 0),
		Parent = pill,
	})

	bar = Create("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(5 * 58 + 8, 62),
		BackgroundTransparency = 1,
		Parent = root,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bar,
	})
	local items = {
		{ key = "units", icon = "⚔", color = Theme.colors.button },
		{ key = "summon", icon = "✦", color = Theme.rarity.legendary },
		{ key = "pass", icon = "▤", color = Theme.colors.quest },
		{ key = "codes", icon = "#", color = Theme.colors.textMuted },
		{ key = "daily", icon = "☼", color = Theme.colors.accent },
	}
	for i, it in items do
		local b = Theme.button({
			Name = it.key,
			LayoutOrder = i,
			Text = "",
			Size = UDim2.fromOffset(52, 58),
			BackgroundColor3 = it.color,
			Parent = bar,
		})
		local icon = Theme.label({
			Text = it.icon,
			TextSize = 22,
			FontFace = Theme.fontBold,
			TextColor3 = Theme.colors.buttonText,
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.fromOffset(0, 2),
			Parent = b,
		})
		icon.TextXAlignment = Enum.TextXAlignment.Center
		local caption = Theme.label({
			Name = "Caption",
			TextSize = 11,
			FontFace = Theme.fontBold,
			TextColor3 = Theme.colors.buttonText,
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.fromOffset(0, 36),
			Parent = b,
		})
		caption.TextXAlignment = Enum.TextXAlignment.Center
		local badge = Create("Frame", {
			Name = "Badge",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 2, 0, -2),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Theme.colors.danger,
			BorderSizePixel = 0,
			Visible = false,
			Parent = b,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		badges[it.key] = badge
		buttons[it.key] = b
		b.Activated:Connect(function()
			local open = openers[it.key]
			if open then
				open()
			end
		end)
	end
end

local function applyVisibility()
	local root = Root.get()
	local dialogue = root:FindFirstChild("Dialogue")
	local dialogueOpen = dialogue ~= nil and (dialogue :: Frame).Visible
	for _, name in LOBBY_WIDGETS do
		local w = root:FindFirstChild(name)
		if w and w:IsA("GuiObject") then
			if name == "Menu" then
				w.Visible = not inMatch and not dialogueOpen
			elseif name == "TestMode" then
				local snapshot = StateController.get()
				w.Visible = not inMatch and snapshot ~= nil and not snapshot.persistent
			else
				w.Visible = not inMatch
			end
		end
	end
end

function LobbyMenuController.setInMatch(v: boolean)
	inMatch = v
	applyVisibility()
end

local function render()
	local t = LocaleController.t
	local snapshot = StateController.get()
	if snapshot then
		liraLabel.Text = t("hud.lira", { n = snapshot.lira })
		local status = DailyLogic.status(snapshot, os.time(), Daily :: any)
		badges.daily.Visible = status.canClaim
		local pending = false
		if snapshot.pass then
			-- a claimable free tier waiting?
			local PassLogic = require(Shared.Logic.PassLogic)
			local SeasonPass = require(Shared.Config.SeasonPass)
			local level = PassLogic.level(snapshot.pass.xp, SeasonPass.tiers)
			for tier = 1, level do
				if not snapshot.pass.claimedFree[tostring(tier)] then
					pending = true
					break
				end
			end
		end
		badges.pass.Visible = pending
	end
	for key, b in buttons do
		local caption = b:FindFirstChild("Caption") :: TextLabel?
		if caption then
			caption.Text = t("hud." .. key)
		end
	end
	applyVisibility()
end

function LobbyMenuController.start()
	build()
	render()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	task.defer(function()
		local dialogue = Root.get():WaitForChild("Dialogue", 10)
		if dialogue and dialogue:IsA("GuiObject") then
			dialogue:GetPropertyChangedSignal("Visible"):Connect(applyVisibility)
		end
	end)
end

return LobbyMenuController
