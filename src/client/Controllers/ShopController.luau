--!strict
-- Shop panel, two modes:
--   "shop"  — an NPC shop opened by the server (ShopShow); qirsh items and Robux-only items.
--   "store" — the coin store opened from the HUD "+" button; qirsh packs and game passes.
-- Every action is a request the server validates (price, funds, ownership, range, product live).
-- Robux prices shown here come from MarketplaceService, never from config.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Items = require(Shared.Config.Items)
local Shops = require(Shared.Config.Shops)
local Products = require(Shared.Config.Products)
local Economy = require(Shared.Config.Economy)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Icons = require(UI.Icons)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local ShopController = {}

local LIST_HEIGHT = 262 -- px at UIScale 1; fits a landscape phone with header and padding

local panel: Frame
local title: TextLabel
local list: ScrollingFrame
local mode: "shop" | "store" | nil = nil
local shopId: string? = nil
local busy = false

-- Robux price cache: product/pass id → price (or false while unknown/failed)
local robuxPrice: { [string]: number | boolean } = {}

local function build()
	panel = Theme.panel({
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.9, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Root.get(),
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(440, math.huge), Parent = panel })
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
		ShopController.close(true)
	end)

	list = Create("ScrollingFrame", {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, LIST_HEIGHT),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.colors.panelStroke,
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	Create("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = list })
end

local function request(fn: () -> any)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local ok, err = pcall(fn)
		if not ok then
			warn("[Shop] request failed: " .. tostring(err))
		end
		busy = false
	end)
end

local render: () -> ()

-- Fetches a Robux price once per id; re-renders when it arrives.
local function priceOf(kind: "product" | "pass", id: number): number?
	if id <= 0 then
		return nil
	end
	local key = kind .. id
	local cached = robuxPrice[key]
	if cached == nil then
		robuxPrice[key] = false
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(
					id,
					if kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
				)
			end)
			robuxPrice[key] = if ok and info and info.PriceInRobux then info.PriceInRobux else false
			render()
		end)
		return nil
	end
	return if type(cached) == "number" then cached else nil
end

type RowSpec = {
	order: number,
	icon: string,
	iconColor: string?,
	name: string,
	desc: string,
	buttonText: string,
	enabled: boolean,
	premium: boolean,
	onClick: () -> (),
}

local function row(spec: RowSpec)
	local rtl = LocaleController.isRtl()
	local r = Create("Frame", {
		LayoutOrder = spec.order,
		BackgroundColor3 = if spec.premium then Color3.fromHex("#C9A13B") else Theme.colors.panelStroke,
		BackgroundTransparency = if spec.premium then 0.75 else 0.88,
		Size = UDim2.new(1, 0, 0, 88),
		Parent = list,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	local iconHolder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(56, 56),
		AnchorPoint = Vector2.new(if rtl then 1 else 0, 0.5),
		Position = UDim2.new(if rtl then 1 else 0, if rtl then -8 else 8, 0.5, 0),
		Parent = r,
	})
	Icons.draw(spec.icon, iconHolder, spec.iconColor)

	local name = Theme.label({
		Text = spec.name,
		TextSize = 17,
		FontFace = Theme.fontBold,
		Position = UDim2.fromOffset(if rtl then 8 else 70, 8),
		Size = UDim2.new(1, -78, 0, 20),
		Parent = r,
	})
	local desc = Theme.label({
		Text = spec.desc,
		TextSize = 13,
		TextColor3 = Theme.colors.textMuted,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(if rtl then 128 else 70, 28),
		Size = UDim2.new(1, -(78 + 120), 0, 52),
		Parent = r,
	})
	Theme.align(name, rtl)
	Theme.align(desc, rtl)

	local action = Theme.button({
		Text = spec.buttonText,
		TextSize = 15,
		AnchorPoint = Vector2.new(if rtl then 0 else 1, 1),
		Position = UDim2.new(if rtl then 0 else 1, if rtl then 8 else -8, 1, -8),
		Size = UDim2.fromOffset(116, Theme.TOUCH - 4),
		BackgroundColor3 = if spec.enabled then Theme.colors.button else Theme.colors.buttonDisabled,
		AutoButtonColor = spec.enabled,
		Parent = r,
	})
	action.Activated:Connect(function()
		if spec.enabled then
			spec.onClick()
		end
	end)
end

local function shopRows(snapshot: any, shop: any)
	local t = LocaleController.t
	for i, itemId in shop.items do
		local def = (Items :: any)[itemId]
		local owned = (snapshot.inventory[itemId] or 0) > 0
		local worn = def.slot ~= nil and snapshot.equipped[def.slot] == itemId
		local spec: RowSpec = {
			order = i,
			icon = def.icon,
			iconColor = def.iconColor,
			name = t(def.nameKey),
			desc = t(def.descKey),
			buttonText = "",
			enabled = true,
			premium = def.product ~= nil,
			onClick = function() end,
		}
		if owned then
			spec.buttonText = if worn then t("shop.unequip") else t("shop.equip")
			spec.onClick = function()
				request(function()
					return Net.func(Net.Functions.SetWorn):InvokeServer(itemId, not worn)
				end)
			end
		elseif def.price then
			spec.buttonText = t("shop.buy", { price = t("hud.currency", { n = def.price }) })
			spec.enabled = snapshot.qirsh >= def.price
			spec.onClick = function()
				request(function()
					return Net.func(Net.Functions.ShopPurchase):InvokeServer(itemId)
				end)
			end
		elseif def.product then
			local product = (Products.devProducts :: any)[def.product]
			local price = product and priceOf("product", product.productId)
			spec.buttonText = if price then t("store.robux", { n = price }) else t("store.soon")
			spec.enabled = price ~= nil
			spec.onClick = function()
				Net.event(Net.Events.RequestProduct):FireServer(def.product)
			end
		end
		row(spec)
	end
end

local function storeRows()
	local t = LocaleController.t
	local order = 0
	for _, key in Products.storeOrder do
		local product = (Products.devProducts :: any)[key]
		local price = priceOf("product", product.productId)
		order += 1
		row({
			order = order,
			icon = "coins",
			name = t(product.nameKey),
			desc = t("hud.currency", { n = product.amount }),
			buttonText = if price then t("store.robux", { n = price }) else t("store.soon"),
			enabled = price ~= nil,
			premium = false,
			onClick = function()
				Net.event(Net.Events.RequestProduct):FireServer(key)
			end,
		})
	end
	for key, pass in Products.gamePasses :: any do
		local price = priceOf("pass", pass.gamePassId)
		order += 1
		row({
			order = order,
			icon = "pass",
			name = t(pass.nameKey),
			desc = t(pass.descKey),
			buttonText = if price then t("store.robux", { n = price }) else t("store.soon"),
			enabled = price ~= nil,
			premium = true,
			onClick = function()
				Net.event(Net.Events.RequestPass):FireServer(key)
			end,
		})
	end
end

render = function()
	if not mode then
		panel.Visible = false
		return
	end
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	if mode == "shop" then
		local shop = (Shops :: any)[shopId]
		if not shop then
			return
		end
		title.Text = LocaleController.t(shop.titleKey)
		shopRows(snapshot, shop)
	else
		title.Text = LocaleController.t("store.title")
		storeRows()
	end
	Theme.align(title, LocaleController.isRtl())
	panel.Visible = true
end

function ShopController.close(tellServer: boolean)
	if mode == "shop" and tellServer then
		Net.event(Net.Events.ShopClose):FireServer()
	end
	mode = nil
	shopId = nil
	panel.Visible = false
end

function ShopController.openStore()
	if mode == "shop" then
		ShopController.close(true)
	end
	mode = "store"
	list.CanvasPosition = Vector2.zero
	render()
end

-- Close an NPC shop when the player walks away from the shopkeeper.
local function watchRange()
	while true do
		task.wait(0.5)
		local id = shopId
		if mode == "shop" and id then
			local npcFolder = Workspace:FindFirstChild("Npcs")
			local npc = npcFolder and npcFolder:FindFirstChild((Shops :: any)[id].npc)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if npc and root and npc:IsA("Model") and root:IsA("BasePart") then
				if (npc:GetPivot().Position - root.Position).Magnitude > Economy.INTERACT_RANGE then
					ShopController.close(true)
				end
			end
		end
	end
end

function ShopController.start()
	build()
	Net.event(Net.Events.ShopShow).OnClientEvent:Connect(function(id: string)
		mode = "shop"
		shopId = id
		list.CanvasPosition = Vector2.zero
		render()
	end)
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	task.spawn(watchRange)
end

return ShopController
