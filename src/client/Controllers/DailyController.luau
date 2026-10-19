--!strict
-- Daily reward screen: the 7-day streak as cards, today's highlighted, and a Claim button.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Daily = require(Shared.Config.Daily)
local DailyLogic = require(Shared.Logic.DailyLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Modal = require(UI.Modal)
local Amount = require(UI.Amount)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)

local DailyController = {}

local modal: Modal.Modal
local row: ScrollingFrame
local streakLabel: TextLabel
local claimButton: TextButton
local busy = false

local function build()
	modal = Modal.create("Daily", 700, 206)
	local body = modal.body
	streakLabel = Theme.label({ TextSize = 14, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = body })
	-- The seven days scroll sideways when they do not fit (MOBILE_HUD_PLAN B7).
	local holder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 126), ZIndex = 11, Parent = body })
	row = Modal.scroller(holder, true)
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	claimButton = Theme.button({ TextSize = 16, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(220, Theme.TOUCH), BackgroundColor3 = Theme.colors.accent, ZIndex = 11, Parent = body })
	claimButton.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		task.spawn(function()
			local ok, r = pcall(function()
				return Net.func(Net.Functions.ClaimDaily):InvokeServer()
			end)
			busy = false
			if ok and type(r) == "table" and r.ok then
				LobbyMenuController.rewardFlight(claimButton) -- Theme v2 (LP-C02)
			end
		end)
	end)
end

local function render()
	if not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	modal.title.Text = t("daily.title")
	Theme.align(modal.title, LocaleController.isRtl())
	local status = DailyLogic.status(snapshot, os.time(), Daily :: any)
	streakLabel.Text = t("daily.streak", { n = if status.canClaim then status.streak - 1 else status.streak })
	Theme.align(streakLabel, LocaleController.isRtl())
	for _, c in row:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, reward in Daily do
		local today = i == status.day
		local done = (not status.canClaim and i == status.day) or (i < status.day)
		local card = Create("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(88, 116), BackgroundColor3 = if today then Theme.colors.accent else Theme.colors.panelStroke, BackgroundTransparency = if today then 0.6 else 0.88, BorderSizePixel = 0, ZIndex = 11, Parent = row }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		if today then
			Create("UIStroke", { Color = Theme.colors.accent, Thickness = 3, Parent = card })
		elseif i == #Daily and not done then
			-- The week's prize reads as one: a gold wash and a gold edge.
			card.BackgroundColor3 = Theme.rarity.legendary
			card.BackgroundTransparency = 0.7
			Create("UIStroke", { Color = Theme.rarity.legendary, Thickness = 2, Parent = card })
		end
		local day = Theme.label({ Text = t("daily.day", { n = i }), TextSize = 13, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 20), ZIndex = 12, Parent = card })
		day.TextXAlignment = Enum.TextXAlignment.Center
		-- Up to three stacked rewards (day 7) fit between the day label and the tick.
		local entries = Amount.reward(t, reward)
		local three = #entries > 2
		Amount.row({ Position = UDim2.fromOffset(2, 22), Size = UDim2.new(1, -4, 0, 68), ZIndex = 12, Parent = card }, entries, { iconSize = if three then 20 else 24, textSize = 13, gap = if three then 4 else 6, color = if done then Theme.colors.textMuted else nil, rtl = LocaleController.isRtl() })
		if done then
			local tick = Theme.label({ Text = "✓", TextSize = 22, TextColor3 = Theme.colors.quest, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 24), ZIndex = 12, Parent = card })
			tick.TextXAlignment = Enum.TextXAlignment.Center
		end
	end
	claimButton.Text = if status.canClaim then t("daily.claim") else t("daily.claimed")
	claimButton.BackgroundColor3 = if status.canClaim then Theme.colors.accent else Theme.colors.buttonDisabled
	claimButton.AutoButtonColor = status.canClaim
end

function DailyController.open()
	modal.setVisible(true)
	render()
end

function DailyController.start()
	build()
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	LobbyMenuController.register("daily", DailyController.open)
end

return DailyController
