--!strict
-- Season pass ("Lane Diary"): level and XP bar, a horizontal strip of tiers with free and
-- premium rewards, claim buttons, and the premium / skip purchase buttons (server-prompted).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local SeasonPass = require(Shared.Config.SeasonPass)
local PassLogic = require(Shared.Logic.PassLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Juice = require(UI.Juice)
local Modal = require(UI.Modal)
local Amount = require(UI.Amount)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)

local PassController = {}

local modal: Modal.Modal
local levelLabel: TextLabel
local xpBar: Frame
local xpFill: Frame
local xpLabel: TextLabel
local lastXp: number? = nil
local endsLabel: TextLabel
local strip: ScrollingFrame
local premiumButton: TextButton
local skipButton: TextButton
local busy = false

local function claim(tier: number, track: string)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		pcall(function()
			return Net.func(Net.Functions.ClaimPass):InvokeServer(tier, track)
		end)
		busy = false
	end)
end

local function build()
	modal = Modal.create("Pass", 720, 250)
	local body = modal.body
	levelLabel = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(0.5, 0, 0, 20), ZIndex = 11, Parent = body })
	endsLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, 0, 0, 20), ZIndex = 11, Parent = body })
	endsLabel.TextXAlignment = Enum.TextXAlignment.Right
	xpBar = Create("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 11, Parent = body }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	xpFill = Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.colors.quest, BorderSizePixel = 0, ZIndex = 12, Parent = xpBar }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	xpLabel = Theme.label({ TextSize = 11, FontFace = Theme.fontBold, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = xpBar })
	xpLabel.TextXAlignment = Enum.TextXAlignment.Center
	local holder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 150), ZIndex = 11, Parent = body })
	strip = Modal.scroller(holder, true)
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip })
	local row = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, Theme.TOUCH - 6), ZIndex = 11, Parent = body })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	premiumButton = Theme.button({ LayoutOrder = 1, TextSize = 14, Size = UDim2.fromOffset(220, Theme.TOUCH - 6), BackgroundColor3 = Theme.rarity.legendary, ZIndex = 11, Parent = row })
	skipButton = Theme.button({ LayoutOrder = 2, TextSize = 14, Size = UDim2.fromOffset(180, Theme.TOUCH - 6), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = row })
	premiumButton.Activated:Connect(function()
		Net.event(Net.Events.RequestProduct):FireServer("pass_premium_s1")
	end)
	skipButton.Activated:Connect(function()
		Net.event(Net.Events.RequestProduct):FireServer("pass_skip_10")
	end)
end

local function tierColumn(t: any, snapshot: any, tier: number, level: number)
	local def = SeasonPass.tiers[tier]
	local col = Create("Frame", { LayoutOrder = tier, Size = UDim2.fromOffset(118, 146), BackgroundColor3 = if tier <= level then Theme.colors.quest else Theme.colors.panelStroke, BackgroundTransparency = if tier <= level then 0.8 else 0.9, BorderSizePixel = 0, ZIndex = 11, Parent = strip }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	local head = Theme.label({ Text = t("pass.level", { n = tier }), TextSize = 13, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 18), ZIndex = 12, Parent = col })
	head.TextXAlignment = Enum.TextXAlignment.Center
	local function trackBlock(y: number, track: string, reward: any)
		local claimed = (if track == "free" then snapshot.pass.claimedFree else snapshot.pass.claimedPremium)[tostring(tier)] == true
		local lockedPremium = track == "premium" and not snapshot.pass.premium
		local label = Theme.label({ Text = t("pass." .. track), TextSize = 11, Position = UDim2.fromOffset(4, y), Size = UDim2.new(1, -8, 0, 12), TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = if track == "premium" then Theme.rarity.legendary else Theme.colors.text, ZIndex = 12, Parent = col })
		label.TextXAlignment = Enum.TextXAlignment.Center
		Amount.row({ Position = UDim2.fromOffset(2, y + 12), Size = UDim2.new(1, -4, 0, 24), ZIndex = 12, Parent = col }, Amount.reward(t, reward), { iconSize = 24, textSize = 12, rtl = LocaleController.isRtl() })
		local text = if claimed then t("pass.claimed") elseif tier > level then t("pass.locked") elseif lockedPremium then t("pass.premium") else t("pass.claim")
		local enabled = not claimed and tier <= level and not lockedPremium
		local b = Theme.button({ Text = text, TextSize = 12, Position = UDim2.fromOffset(6, y + 36), Size = UDim2.new(1, -12, 0, 26), BackgroundColor3 = if enabled then Theme.colors.button else Theme.colors.buttonDisabled, AutoButtonColor = enabled, ZIndex = 12, Parent = col })
		b.Activated:Connect(function()
			if enabled then
				claim(tier, track)
			end
		end)
	end
	trackBlock(20, "free", def.free)
	trackBlock(84, "premium", def.premium)
end

function PassController.render()
	if not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	modal.title.Text = t(SeasonPass.nameKey) -- the season's own name (S1-C06: "… Season 1: The Night Guard")
	Theme.align(modal.title, LocaleController.isRtl())
	local level, into, need = PassLogic.level(snapshot.pass.xp, SeasonPass.tiers)
	levelLabel.Text = t("pass.level", { n = level })
	xpLabel.Text = if need > 0 then t("pass.xp", { n = into, total = need }) else "MAX"
	xpFill.Size = UDim2.fromScale(if need > 0 then into / need else 1, 1)
	if lastXp and snapshot.pass.xp > lastXp then
		Juice.shineOnce(xpFill)
	end
	lastXp = snapshot.pass.xp
	local days = math.max(0, math.floor((SeasonPass.endsAt - os.time()) / 86400))
	endsLabel.Text = t("pass.ends", { n = days })
	premiumButton.Text = if snapshot.pass.premium then t("pass.premium") .. " ✓" else t("pass.buy_premium")
	premiumButton.AutoButtonColor = not snapshot.pass.premium
	skipButton.Text = t("pass.skip")
	-- Both pay lira/stones for Robux: not sold where paid random items are restricted
	-- (MonetizationLogic.fundsRandomItems; the server refuses the prompt too).
	premiumButton.Visible = snapshot.pass.premium or not snapshot.restricted
	skipButton.Visible = not snapshot.restricted
	for _, c in strip:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for tier = 1, SeasonPass.levels do
		tierColumn(t, snapshot, tier, level)
	end
	-- Scroll to the current level
	strip.CanvasPosition = Vector2.new(math.max(0, (level - 1) * 124), 0)
end

function PassController.open()
	modal.setVisible(true)
	PassController.render()
end

function PassController.start()
	build()
	StateController.Changed:Connect(PassController.render)
	LocaleController.Changed:Connect(PassController.render)
	LobbyMenuController.register("pass", PassController.open)
end

return PassController
