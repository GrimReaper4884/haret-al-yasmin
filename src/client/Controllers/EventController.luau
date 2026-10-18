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
local EventLogic = require(Shared.Logic.EventLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Juice = require(UI.Juice)
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
local nameLabel: TextLabel
local descLabel: TextLabel
local timeLabel: TextLabel
local currencyLabel: TextLabel
local shopList: ScrollingFrame
local playButton: TextButton
local busy = false

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
	for _, l in { nameLabel, descLabel, timeLabel, currencyLabel } do
		Theme.align(l, rtl)
	end
	playButton.Text = t("event.play")
	playButton.Visible = true
	for i, entry in def.shop do
		local bought = if rec and rec.bought[entry.key] then rec.bought[entry.key] else 0
		local soldOut = bought >= entry.stock
		local row = Create("Frame", { LayoutOrder = i, BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.85, Size = UDim2.new(1, -12, 0, Theme.TOUCH + 4), ZIndex = 12, Parent = shopList }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		local name = entry.nameKey
		local label = Theme.label({
			Text = t(name) .. "   ·   " .. t("event.stock", { n = entry.stock - bought, max = entry.stock }),
			TextSize = 13,
			FontFace = Theme.fontBold,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -140, 1, 0),
			ZIndex = 13,
			Parent = row,
		})
		Theme.align(label, rtl)
		if entry.reward.item and (Items :: any)[entry.reward.item] and snapshot and snapshot.inventory[entry.reward.item] then
			label.Text ..= "   ·   " .. t("event.owned")
		end
		local afford = have >= entry.cost
		local buy = Theme.button({
			Text = if soldOut then t("event.sold_out") else t(def.currencyKey, { n = entry.cost }),
			TextSize = 13,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
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
	modal = Modal.create("Event", 620, 250, { fill = true })
	local body = modal.body
	nameLabel = Theme.display({ TextSize = 20, Size = UDim2.new(0.6, 0, 0, 24), ZIndex = 12, Parent = body })
	timeLabel = Theme.display({ TextSize = 14, TextColor3 = Color3.fromHex("#FFD970"), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.4, 0, 0, 24), ZIndex = 12, Parent = body })
	descLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 32), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 12, Parent = body })
	currencyLabel = Theme.display({ TextSize = 16, TextColor3 = Color3.fromHex("#C8E07A"), Position = UDim2.fromOffset(0, 60), Size = UDim2.new(0.6, 0, 0, 22), ZIndex = 12, Parent = body })
	playButton = Theme.button({ TextSize = 15, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 56), Size = UDim2.fromOffset(170, Theme.TOUCH), BackgroundColor3 = Color3.fromHex("#2F7D6B"), ZIndex = 12, Parent = body })
	playButton.Activated:Connect(function()
		PlayController.open("event")
	end)
	-- The shop scrolls once its 52 px rows outgrow the body (MOBILE_HUD_PLAN B7).
	local shopHolder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 110), Size = UDim2.new(1, 0, 1, -110), ZIndex = 12, Parent = body })
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
