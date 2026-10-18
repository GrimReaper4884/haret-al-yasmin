--!strict
-- Wardrobe / inventory panel: everything the player owns as cards with 3D previews (cosmetics on
-- the tailor's dummy) or drawn icons (errand items). Wearing goes through the server (SetWorn).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Items = require(Shared.Config.Items)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local ItemPreview = require(UI.ItemPreview)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local WardrobeController = {}

local SLOT_ORDER = { head = 1, torso = 2, legs = 3, waist = 4, back = 5 }
local CARD = Vector2.new(124, 178)

local panel: Frame
local title: TextLabel
local grid: ScrollingFrame
local empty: TextLabel
local open = false
local busy = false
local lastKey = "" -- skips rebuilding previews when nothing relevant changed

local function build()
	panel = Theme.panel({
		Name = "Wardrobe",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 10, -- modals draw above the HUD (tracker, coin pill)
		Size = UDim2.fromScale(0.92, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Root.get(),
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(600, math.huge), Parent = panel })
	panel:SetAttribute(Theme.LEGACY_ATTR, true) -- pre-touch sizes until MOBILE_HUD_PLAN MH-13
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local header = Create("Frame", {
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Theme.TOUCH - 8),
		Parent = panel,
	})
	title = Theme.label({
		TextSize = 20,
		FontFace = Theme.fontBold,
		Size = UDim2.new(1, -(Theme.TOUCH + 4), 1, 0),
		Parent = header,
	})
	local close = Theme.button({
		Text = "X",
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(Theme.TOUCH - 8, Theme.TOUCH - 8),
		BackgroundColor3 = Theme.colors.danger,
		Parent = header,
	})
	close.Activated:Connect(function()
		WardrobeController.close()
	end)

	grid = Create("ScrollingFrame", {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 220),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.colors.panelStroke,
		Parent = panel,
	})
	Create("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD.X, CARD.Y),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	empty = Theme.label({
		LayoutOrder = 3,
		TextSize = 15,
		TextColor3 = Theme.colors.textMuted,
		Size = UDim2.new(1, 0, 0, 40),
		Visible = false,
		Parent = panel,
	})
end

local function card(order: number, itemId: string, snapshot: any)
	local t = LocaleController.t
	local def = (Items :: any)[itemId]
	local worn = def.slot ~= nil and snapshot.equipped[def.slot] == itemId

	local c = Create("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Theme.colors.panelStroke,
		BackgroundTransparency = 0.88,
		Parent = grid,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	if worn then
		Create("UIStroke", { Color = Theme.colors.accent, Thickness = 3, Parent = c })
	end

	ItemPreview.create(itemId, {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 96),
		Parent = c,
	})
	local name = Theme.label({
		Text = t(def.nameKey),
		TextSize = 13,
		FontFace = Theme.fontBold,
		Position = UDim2.fromOffset(6, 104),
		Size = UDim2.new(1, -12, 0, 30),
		Parent = c,
	})
	name.TextXAlignment = Enum.TextXAlignment.Center

	if def.kind == "cosmetic" then
		local b = Theme.button({
			Text = if worn then t("shop.unequip") else t("shop.equip"),
			TextSize = 14,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.new(1, -12, 0, 34),
			BackgroundColor3 = if worn then Theme.colors.buttonDisabled else Theme.colors.button,
			Parent = c,
		})
		b.Activated:Connect(function()
			if busy then
				return
			end
			busy = true
			task.spawn(function()
				pcall(function()
					Net.func(Net.Functions.SetWorn):InvokeServer(itemId, not worn)
				end)
				busy = false
			end)
		end)
	else
		local tag = Theme.label({
			Text = t("wardrobe.errand_item"),
			TextSize = 12,
			TextColor3 = Theme.colors.quest,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -12, 0, 24),
			Parent = c,
		})
		tag.TextXAlignment = Enum.TextXAlignment.Center
	end
end

local function render(force: boolean?)
	if not open then
		return
	end
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	-- Rebuild only when ownership, worn items or language changed (previews are not free on mobile).
	local ids = {}
	for id in snapshot.inventory do
		if (Items :: any)[id] then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local da, db = (Items :: any)[a], (Items :: any)[b]
		local sa = if da.slot then SLOT_ORDER[da.slot] or 9 else 0
		local sb = if db.slot then SLOT_ORDER[db.slot] or 9 else 0
		if sa ~= sb then
			return sa < sb
		end
		return a < b
	end)
	local worn = {}
	for slot, id in snapshot.equipped do
		table.insert(worn, slot .. "=" .. id)
	end
	table.sort(worn)
	local key = table.concat(ids, ",") .. "|" .. table.concat(worn, ",") .. "|" .. LocaleController.lang()
	if key == lastKey and not force then
		return
	end
	lastKey = key

	title.Text = LocaleController.t("wardrobe.title")
	Theme.align(title, LocaleController.isRtl())
	for _, c in grid:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, id in ids do
		card(i, id, snapshot)
	end
	empty.Text = LocaleController.t("wardrobe.empty")
	empty.Visible = #ids == 0
	grid.Visible = #ids > 0
end

function WardrobeController.open()
	open = true
	panel.Visible = true
	render(true)
end

function WardrobeController.close()
	open = false
	panel.Visible = false
	lastKey = ""
end

function WardrobeController.toggle()
	if open then
		WardrobeController.close()
	else
		WardrobeController.open()
	end
end

function WardrobeController.start()
	build()
	StateController.Changed:Connect(function()
		render()
	end)
	LocaleController.Changed:Connect(function()
		render()
	end)
end

return WardrobeController
