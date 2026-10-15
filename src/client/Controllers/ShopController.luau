--!strict
-- Shop panel. Shows what the server says the shop sells; every action is a request the server
-- validates (price, funds, ownership, range). Closes itself when the player walks away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Items = require(Shared.Config.Items)
local Shops = require(Shared.Config.Shops)
local Economy = require(Shared.Config.Economy)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Icons = require(UI.Icons)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)

local ShopController = {}

local panel: Frame
local title: TextLabel
local list: Frame
local shopId: string? = nil
local busy = false

local function build()
	panel = Theme.panel({
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = Root.get(),
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(420, math.huge), Parent = panel })
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

	list = Create("Frame", {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
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

local function itemRow(order: number, itemId: string, snapshot: any)
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local def = (Items :: any)[itemId]
	local owned = (snapshot.inventory[itemId] or 0) > 0
	local worn = def.slot ~= nil and snapshot.equipped[def.slot] == itemId

	local row = Create("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Theme.colors.panelStroke,
		BackgroundTransparency = 0.88,
		Size = UDim2.new(1, 0, 0, 88),
		Parent = list,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })

	local iconHolder = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(56, 56),
		AnchorPoint = Vector2.new(if rtl then 1 else 0, 0.5),
		Position = UDim2.new(if rtl then 1 else 0, if rtl then -8 else 8, 0.5, 0),
		Parent = row,
	})
	Icons.draw(def.icon, iconHolder)

	local textX = if rtl then 0 else 70
	local name = Theme.label({
		Text = t(def.nameKey),
		TextSize = 17,
		FontFace = Theme.fontBold,
		Position = UDim2.fromOffset(if rtl then 8 else textX, 8),
		Size = UDim2.new(1, -78, 0, 20),
		Parent = row,
	})
	local desc = Theme.label({
		Text = t(def.descKey),
		TextSize = 13,
		TextColor3 = Theme.colors.textMuted,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(if rtl then 8 else textX, 28),
		Size = UDim2.new(1, -(78 + 120), 0, 52),
		Parent = row,
	})
	Theme.align(name, rtl)
	Theme.align(desc, rtl)
	if rtl then
		desc.Position = UDim2.fromOffset(128, 28)
	end

	local canAfford = snapshot.qirsh >= (def.price or math.huge)
	local text: string
	if not owned then
		text = t("shop.buy", { price = t("hud.currency", { n = def.price }) })
	elseif worn then
		text = t("shop.unequip")
	else
		text = t("shop.equip")
	end
	local action = Theme.button({
		Text = text,
		TextSize = 15,
		AnchorPoint = Vector2.new(if rtl then 0 else 1, 1),
		Position = UDim2.new(if rtl then 0 else 1, if rtl then 8 else -8, 1, -8),
		Size = UDim2.fromOffset(116, Theme.TOUCH - 4),
		BackgroundColor3 = if not owned and not canAfford then Theme.colors.buttonDisabled else Theme.colors.button,
		Parent = row,
	})
	action.TextScaled = false
	action.Activated:Connect(function()
		if not owned then
			request(function()
				return Net.func(Net.Functions.ShopPurchase):InvokeServer(itemId)
			end)
		else
			request(function()
				return Net.func(Net.Functions.SetWorn):InvokeServer(itemId, not worn)
			end)
		end
	end)
end

local function render()
	if not shopId then
		panel.Visible = false
		return
	end
	local shop = (Shops :: any)[shopId]
	local snapshot = StateController.get()
	if not shop or not snapshot then
		return
	end
	title.Text = LocaleController.t(shop.titleKey)
	Theme.align(title, LocaleController.isRtl())
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, itemId in shop.items do
		itemRow(i, itemId, snapshot)
	end
	panel.Visible = true
end

function ShopController.close(tellServer: boolean)
	if shopId and tellServer then
		Net.event(Net.Events.ShopClose):FireServer()
	end
	shopId = nil
	panel.Visible = false
end

-- Close when the player walks away from the shopkeeper.
local function watchRange()
	while true do
		task.wait(0.5)
		local id = shopId
		if id then
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
		shopId = id
		render()
	end)
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	task.spawn(watchRange)
end

return ShopController
