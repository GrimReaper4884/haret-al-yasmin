--!strict
-- The two shapes of the defender panel (docs/MOBILE_HUD_PLAN.md B4). PlacementController renders the
-- selected defender into whichever view Settings `panelSide` picks (auto: the bottom sheet on touch,
-- the side panel on desktop); both expose the same parts, so the panel logic is written once.
--   side:  the left-edge column (the pre-MH panel, desktop).
--   sheet: a bottom sheet in the hotbar's band (the hotbar hides while it is open): portrait, name and
--          level on top with a 48 px close, the stat lines (core stats on one line), the level-7 path
--          cards in their place while choosing, then one row of Upgrade (56 px), Target, Sell and the
--          ultimate with its Auto toggle.

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)

local TowerPanelView = {}

export type View = {
	kind: "side" | "sheet",
	panel: Frame,
	portrait: Frame,
	title: TextLabel,
	level: TextLabel,
	owner: TextLabel,
	stats: TextLabel,
	sigRow: Frame,
	sigCards: { [string]: TextButton },
	upgrade: TextButton,
	target: TextButton,
	sell: TextButton,
	close: TextButton,
	ultRow: GuiObject,
	ult: TextButton,
	ultFill: Frame,
	auto: TextButton,
}

local function noPad(b: TextButton, px: number?)
	local pad = b:FindFirstChildOfClass("UIPadding")
	if pad then
		if px then
			pad.PaddingLeft = UDim.new(0, px)
			pad.PaddingRight = UDim.new(0, px)
		else
			pad:Destroy()
		end
	end
end

-- Two path cards (name, description, cost) in `row`. Sizes: name / description / cost text.
local function pathCards(row: Frame, sizes: { number }): { [string]: TextButton }
	local cards = {}
	for i, pathKey in { "a", "b" } do
		local card = Theme.button({ Name = "Path_" .. pathKey, LayoutOrder = i, Text = "", Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.button, ZIndex = 4, Parent = row })
		noPad(card, 5)
		local nameLabel = Theme.display({ Name = "PathName", TextSize = sizes[1], Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, sizes[1] + 4), ZIndex = 5, Parent = card })
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		local descLabel = Theme.label({ Name = "PathDesc", TextSize = sizes[2], TextColor3 = Color3.fromHex("#FFF1D0"), Position = UDim2.fromOffset(0, sizes[1] + 10), Size = UDim2.new(1, 0, 1, -(sizes[1] + sizes[3] + 18)), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, Parent = card })
		descLabel.TextXAlignment = Enum.TextXAlignment.Center
		local costLabel = Theme.display({ Name = "PathCost", TextSize = sizes[3], TextColor3 = Color3.fromHex("#FFD970"), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, sizes[3] + 3), ZIndex = 5, Parent = card })
		costLabel.TextXAlignment = Enum.TextXAlignment.Center
		cards[pathKey] = card
	end
	return cards
end

-- The left-edge panel (unchanged layout from MH-03).
function TowerPanelView.side(root: Instance): View
	-- Tower panel: left edge, away from the bar (docs/research/ROBLOX_TD_UI_PATTERNS.md §1).
	local panel = Theme.panel({ Name = "TowerPanel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(232, 0), AutomaticSize = Enum.AutomaticSize.Y, Active = true, Visible = false, ZIndex = 4, Parent = root })
	Create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = panel })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	local header = Create("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, ZIndex = 4, Parent = panel })
	local portrait = Create("Frame", { Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, ZIndex = 4, Parent = header })
	local title = Theme.display({ TextSize = 16, Position = UDim2.fromOffset(62, 0), Size = UDim2.new(1, -112, 0, 36), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, Parent = header })
	title.TextXAlignment = Enum.TextXAlignment.Left
	local level = Theme.display({ TextSize = 14, TextColor3 = Color3.fromHex("#FFD970"), Position = UDim2.fromOffset(62, 38), Size = UDim2.new(1, -62, 0, 18), ZIndex = 5, Parent = header })
	level.TextXAlignment = Enum.TextXAlignment.Left
	local close = Theme.button({ Text = "X", TextSize = 18, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 2, 0, -2), Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 6, Parent = header })
	noPad(close)
	local owner = Theme.label({ LayoutOrder = 2, TextSize = 12, FontFace = Theme.fontBold, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 14), Visible = false, ZIndex = 4, Parent = panel })
	local stats = Theme.label({ LayoutOrder = 3, TextSize = 14, FontFace = Theme.fontBold, RichText = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.15, ZIndex = 4, Parent = panel })
	-- Level 7 (STORY_PLAN §7.1): at the last level a unit with a signature offers two path cards; one
	-- tap picks, Upgrade confirms (UpgradeTower with the path; the server re-checks everything).
	local sigRow = Create("Frame", { Name = "Signature", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 92), BackgroundTransparency = 1, Visible = false, ZIndex = 4, Parent = panel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sigRow })
	local cards = pathCards(sigRow, { 14, 11, 13 })
	local upgrade = Theme.button({ LayoutOrder = 5, TextSize = 17, Size = UDim2.new(1, 0, 0, Theme.TOUCH), BackgroundColor3 = Theme.colors.confirm, ZIndex = 4, Parent = panel })
	local row = Create("Frame", { LayoutOrder = 6, Size = UDim2.new(1, 0, 0, Theme.TOUCH), BackgroundTransparency = 1, ZIndex = 4, Parent = panel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = row })
	local target = Theme.button({ TextSize = 13, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.quest, ZIndex = 4, Parent = row })
	local sell = Theme.button({ TextSize = 13, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.danger, ZIndex = 4, Parent = row })
	-- Ultimate: the button fills back up as the cooldown recovers; Auto fires it when ready.
	local ultRow = Create("Frame", { LayoutOrder = 7, Size = UDim2.new(1, 0, 0, Theme.TOUCH), BackgroundTransparency = 1, ZIndex = 4, Parent = panel })
	local ult = Theme.button({ TextSize = 14, Size = UDim2.new(1, -62, 1, 0), BackgroundColor3 = Theme.lira, ClipsDescendants = true, ZIndex = 4, Parent = ultRow })
	local ultFill = Create("Frame", { Name = "Cooldown", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 4, Parent = ult })
	local auto = Theme.button({ TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 56, 1, 0), ZIndex = 4, Parent = ultRow })
	for _, b in { target, sell, ult, auto } do
		noPad(b, 4)
		b.TextWrapped = true
	end
	return { kind = "side", panel = panel, portrait = portrait, title = title, level = level, owner = owner, stats = stats, sigRow = sigRow, sigCards = cards, upgrade = upgrade, target = target, sell = sell, close = close, ultRow = ultRow, ult = ult, ultFill = ultFill, auto = auto }
end

-- The bottom sheet (touch): placed by PlacementController (width and bottom edge from the hotbar's
-- band); its height follows the content.
function TowerPanelView.sheet(root: Instance, primary: number): View
	local panel = Theme.panel({ Name = "TowerSheet", AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(480, 0), AutomaticSize = Enum.AutomaticSize.Y, Active = true, Visible = false, ZIndex = 4, Parent = root })
	Create("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = panel })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	-- Header: portrait, name over the level line, the owner (someone else's defender), close.
	local header = Create("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), BackgroundTransparency = 1, ZIndex = 4, Parent = panel })
	local portrait = Create("Frame", { Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundTransparency = 1, ZIndex = 4, Parent = header })
	local title = Theme.display({ TextSize = 16, Position = UDim2.fromOffset(Theme.TOUCH + 8, 1), Size = UDim2.new(1, -(2 * Theme.TOUCH + 16), 0, 24), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, Parent = header })
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextWrapped = false
	title.TextTruncate = Enum.TextTruncate.AtEnd
	local level = Theme.display({ TextSize = 14, TextColor3 = Color3.fromHex("#FFD970"), Position = UDim2.fromOffset(Theme.TOUCH + 8, 26), Size = UDim2.new(1, -(2 * Theme.TOUCH + 16), 0, 20), ZIndex = 5, Parent = header })
	level.TextXAlignment = Enum.TextXAlignment.Left
	level.TextWrapped = false
	local close = Theme.button({ Text = "X", TextSize = 18, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 6, Parent = header })
	noPad(close)
	local owner = Theme.label({ LayoutOrder = 2, TextSize = 13, FontFace = Theme.fontBold, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 15), Visible = false, ZIndex = 4, Parent = panel })
	local stats = Theme.label({ LayoutOrder = 3, TextSize = 14, FontFace = Theme.fontBold, RichText = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.1, ZIndex = 4, Parent = panel })
	-- Level 7: the two path cards replace the stat block (B4: ≥ 48 px tall, name 14, description 13, cost 14).
	local sigRow = Create("Frame", { Name = "Signature", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1, Visible = false, ZIndex = 4, Parent = panel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sigRow })
	local cards = pathCards(sigRow, { 14, 13, 14 })
	-- One action row: the buttons share the width (UIFlexItem), Upgrade the widest.
	local actions = Create("Frame", { Name = "Actions", LayoutOrder = 5, Size = UDim2.new(1, 0, 0, primary), BackgroundTransparency = 1, ZIndex = 4, Parent = panel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = actions })
	local function grow(gui: GuiObject, ratio: number)
		Create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow, GrowRatio = ratio, Parent = gui })
	end
	local upgrade = Theme.button({ LayoutOrder = 1, TextSize = 15, Size = UDim2.new(0, Theme.TOUCH, 1, 0), BackgroundColor3 = Theme.colors.confirm, ZIndex = 4, Parent = actions })
	grow(upgrade, 1.5)
	local target = Theme.button({ LayoutOrder = 2, TextSize = 14, Size = UDim2.new(0, Theme.TOUCH, 1, 0), BackgroundColor3 = Theme.colors.quest, ZIndex = 4, Parent = actions })
	grow(target, 1)
	local sell = Theme.button({ LayoutOrder = 3, TextSize = 14, Size = UDim2.new(0, Theme.TOUCH, 1, 0), BackgroundColor3 = Theme.colors.danger, ZIndex = 4, Parent = actions })
	grow(sell, 1)
	local ultRow = Create("Frame", { Name = "Ultimate", LayoutOrder = 4, Size = UDim2.new(0, 2 * Theme.TOUCH + 6, 1, 0), BackgroundTransparency = 1, ZIndex = 4, Parent = actions })
	grow(ultRow, 1.8)
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ultRow })
	local ult = Theme.button({ LayoutOrder = 1, TextSize = 13, Size = UDim2.new(0, Theme.TOUCH, 1, 0), BackgroundColor3 = Theme.lira, ClipsDescendants = true, ZIndex = 4, Parent = ultRow })
	grow(ult, 1)
	local ultFill = Create("Frame", { Name = "Cooldown", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 4, Parent = ult })
	local auto = Theme.button({ LayoutOrder = 2, TextSize = 13, Size = UDim2.new(0, Theme.TOUCH, 1, 0), ZIndex = 4, Parent = ultRow })
	for _, b in { upgrade, target, sell, ult, auto } do
		noPad(b, 4)
		b.TextWrapped = true
	end
	return { kind = "sheet", panel = panel, portrait = portrait, title = title, level = level, owner = owner, stats = stats, sigRow = sigRow, sigCards = cards, upgrade = upgrade, target = target, sell = sell, close = close, ultRow = ultRow, ult = ult, ultFill = ultFill, auto = auto }
end

return TowerPanelView
