--!strict
-- Limited-time events (Config/Events) on the client: the Event button on the lobby rail (only
-- while one runs), the event board (what it is, time left, the player's event currency, the shop,
-- and Play → straight into Play → Event), and the event filter for the Play panel. Purchases are
-- requested from the server, which checks the event, stock and currency (Logic/EventLogic).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Events = require(Shared.Config.Events)
local Items = require(Shared.Config.Items)
local IconIds = require(Shared.Config.Icons)
local EventLogic = require(Shared.Logic.EventLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Juice = require(UI.Juice)
local Amount = require(UI.Amount)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local PlayController = require(script.Parent.PlayController)
local ToastController = require(script.Parent.ToastController)

local EventController = {}

local ERR_KEYS = {
	not_enough = "event.err.not_enough",
	sold_out = "event.err.sold_out",
	event_over = "event.over",
}

local modal: Modal.Modal
local banner: ImageLabel
local nameLabel: TextLabel
local descLabel: TextLabel
local timeLabel: TextLabel
local currencyLabel: TextLabel
local shopList: ScrollingFrame
local playButton: TextButton
local busy = false
local BANNER_H = 76

local function current(): (string?, any)
	local ids = EventLogic.active(Events :: any, os.time())
	local id = ids[1]
	return id, if id then (Events :: any)[id] else nil
end

local function fmtLeft(seconds: number): string
	local t = LocaleController.t
	local d = seconds // 86400
	local h = (seconds % 86400) // 3600
	local m = (seconds % 3600) // 60
	if d > 0 then
		return t("event.left_dh", { d = d, h = h })
	end
	return t("event.left_hm", { h = h, m = m })
end

local function render()
	if not modal or not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local id, def = current()
	modal.title.Text = t("event.title")
	Theme.align(modal.title, rtl)
	for _, c in shopList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	if not id or not def then
		nameLabel.Text = t("play.event_none")
		descLabel.Text = ""
		timeLabel.Text = ""
		currencyLabel.Text = ""
		banner.Image = ""
		playButton.Visible = false
		return
	end
	local snapshot = StateController.get()
	local rec = snapshot and snapshot.events and (snapshot.events :: any)[id]
	local have = if rec then rec.currency else 0
	nameLabel.Text = t(def.nameKey)
	descLabel.Text = t(def.descKey)
	timeLabel.Text = fmtLeft(math.max(0, def.endsAt - os.time()))
	currencyLabel.Text = t(def.currencyKey, { n = have })
	for _, l in { nameLabel, descLabel, currencyLabel } do
		Theme.align(l, rtl)
	end
	-- The time left sits at the far edge of the banner (the left one in Arabic).
	timeLabel.TextXAlignment = if rtl then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
	-- The event's painted banner (PV-C06) behind its name; the plain wood strip until one exists.
	local art = IconIds.modes[def.modeId]
	banner.Image = if art and art.id > 0 then "rbxassetid://" .. art.id else ""
	playButton.Text = t("event.play")
	playButton.Visible = true
	for i, entry in def.shop do
		local bought = if rec and rec.bought[entry.key] then rec.bought[entry.key] else 0
		local soldOut = bought >= entry.stock
		local row = Create("Frame", { LayoutOrder = i, BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.85, Size = UDim2.new(1, -12, 0, Theme.TOUCH + 4), ZIndex = 12, Parent = shopList }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		-- What it gives as icons, its stock as a quiet note beside the price.
		Amount.row({ Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -240, 1, 0), ZIndex = 13, Parent = row }, Amount.reward(t, entry.reward), {
			iconSize = 28,
			textSize = 15,
			bold = true,
			align = Enum.HorizontalAlignment.Left,
			rtl = rtl,
			zIndex = 13,
		})
		local owned = entry.reward.item and (Items :: any)[entry.reward.item] and snapshot and snapshot.inventory[entry.reward.item]
		local stock = Theme.label({
			Text = if owned then t("event.owned") else t("event.stock", { n = entry.stock - bought, max = entry.stock }),
			TextSize = 13,
			TextColor3 = Theme.colors.textMuted,
			AnchorPoint = Vector2.new(if rtl then 0 else 1, 0.5),
			Position = UDim2.new(if rtl then 0 else 1, if rtl then 140 else -140, 0.5, 0),
			Size = UDim2.fromOffset(90, 20),
			ZIndex = 13,
			Parent = row,
		})
		stock.TextXAlignment = if rtl then Enum.TextXAlignment.Left else Enum.TextXAlignment.Right
		local afford = have >= entry.cost
		local buy = Theme.button({
			Text = if soldOut then t("event.sold_out") else t(def.currencyKey, { n = entry.cost }),
			TextSize = 13,
			AnchorPoint = Vector2.new(if rtl then 0 else 1, 0.5),
			Position = UDim2.new(if rtl then 0 else 1, if rtl then 4 else -4, 0.5, 0),
			Size = UDim2.fromOffset(128, Theme.TOUCH),
			BackgroundColor3 = if soldOut or not afford then Theme.colors.buttonDisabled else Theme.colors.confirm,
			ZIndex = 13,
			Parent = row,
		})
		buy.Activated:Connect(function()
			if busy or soldOut then
				return
			end
			if not afford then
				Juice.shake(buy)
				ToastController.show("event.err.not_enough")
				return
			end
			busy = true
			task.spawn(function()
				local ok, res = pcall(function()
					return Net.func(Net.Functions.EventBuy):InvokeServer(id, entry.key)
				end)
				busy = false
				if ok and type(res) == "table" then
					if res.ok then
						Juice.punch(buy)
						ToastController.show("event.bought", { itemKey = entry.nameKey })
					elseif res.err and ERR_KEYS[res.err] then
						ToastController.show(ERR_KEYS[res.err])
					end
				end
			end)
		end)
	end
end

local function build()
	modal = Modal.create("Event", 620, 300, { fill = true })
	local body = modal.body
	-- Banner: the event's art, darkened towards the bottom so the outlined name reads on it.
	banner = Create("ImageLabel", {
		Name = "Banner",
		BackgroundColor3 = Theme.v2.woodDark,
		Size = UDim2.new(1, 0, 0, BANNER_H),
		ScaleType = Enum.ScaleType.Crop,
		ImageColor3 = Color3.fromRGB(200, 195, 190),
		ZIndex = 11,
		Parent = body,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	Theme.border(banner, 2.5)
	Create("Frame", {
		Name = "Shade",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
		Parent = banner,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
		Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.75), NumberSequenceKeypoint.new(1, 0.25) }) }),
	})
	Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = banner })
	nameLabel = Theme.display({ TextSize = 24, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(0.7, 0, 0, 30), ZIndex = 12, Parent = banner })
	timeLabel = Theme.display({ TextSize = 15, TextColor3 = Color3.fromHex("#FFD970"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(1, 0, 0, 22), ZIndex = 12, Parent = banner })
	descLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, TextWrapped = true, Position = UDim2.fromOffset(0, BANNER_H + 6), Size = UDim2.new(1, 0, 0, 34), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Parent = body })
	local top = BANNER_H + 44
	currencyLabel = Theme.display({ TextSize = 20, TextColor3 = Color3.fromHex("#C8E07A"), Position = UDim2.fromOffset(0, top + 12), Size = UDim2.new(0.6, 0, 0, 24), ZIndex = 12, Parent = body })
	playButton = Theme.button({ TextSize = 15, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, top), Size = UDim2.fromOffset(170, Theme.TOUCH), BackgroundColor3 = Color3.fromHex("#2F7D6B"), ZIndex = 12, Parent = body })
	playButton.Activated:Connect(function()
		PlayController.open("event")
	end)
	-- The shop scrolls once its 52 px rows outgrow the body (MOBILE_HUD_PLAN B7).
	local shopTop = top + Theme.TOUCH + 8
	local shopHolder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, shopTop), Size = UDim2.new(1, 0, 1, -shopTop), ZIndex = 12, Parent = body })
	shopList = Modal.scroller(shopHolder)
	shopList.ZIndex = 12
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = shopList })
end

function EventController.open()
	modal.setVisible(true)
	render()
end

local function updateRail()
	local id = current()
	LobbyMenuController.setVisibleEntry("event", id ~= nil)
end

function EventController.start()
	build()
	LobbyMenuController.register("event", EventController.open)
	PlayController.setEventFilter(function(modeId: string): boolean
		return EventLogic.forMode(Events :: any, modeId, os.time()) ~= nil
	end)
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	updateRail()
	task.spawn(function()
		while true do
			task.wait(30)
			updateRail()
			render()
		end
	end)
end

return EventController
