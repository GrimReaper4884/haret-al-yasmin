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
local Device = require(UI.Device)
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
local holder: Frame
local legend: Frame
local buttonRow: Frame
local premiumButton: TextButton
local skipButton: TextButton
local busy = false

-- Phone sheet (MH-20): a 48 px top row (level, XP bar and season end beside Premium and Skip), then
-- tier columns whose 48 px claim buttons carry the reward, so both tracks show without scrolling
-- the sheet at 640x282 (head + two buttons + gap = PHONE.column; PHONE.strip adds the strip's bar).
local PHONE = { legend = 60, head = 16, gap = 4, column = 116, strip = 128, premium = 180, skip = 140 }
local COLUMN_W, COLUMN_GAP = 118, 6

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
	-- fill: on a phone the body is the sheet's height and shapePass packs both tracks into it.
	modal = Modal.create("Pass", 720, 262, { fill = true })
	local body = modal.body
	-- Top: the level and the season end on the left, Premium and Skip (48 px) on the right (MOBILE_HUD_PLAN B7).
	levelLabel = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, -400, 0, 22), ZIndex = 11, Parent = body })
	endsLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, -400, 0, 18), ZIndex = 11, Parent = body })
	endsLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpBar = Create("Frame", { Position = UDim2.fromOffset(0, Theme.TOUCH + 4), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 11, Parent = body }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	xpFill = Create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.colors.quest, BorderSizePixel = 0, ZIndex = 12, Parent = xpBar }, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	xpLabel = Theme.label({ TextSize = 11, FontFace = Theme.fontBold, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = xpBar })
	xpLabel.TextXAlignment = Enum.TextXAlignment.Center
	holder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, Theme.TOUCH + 24), Size = UDim2.new(1, 0, 0, 190), ZIndex = 11, Parent = body })
	strip = Modal.scroller(holder, true)
	-- Phones: the track names stand once at the left of the strip instead of in every column.
	legend = Create("Frame", { Name = "Legend", BackgroundTransparency = 1, Size = UDim2.new(0, PHONE.legend, 1, 0), Visible = false, ZIndex = 11, Parent = holder })
	for i, track in { "free", "premium" } do
		local y = PHONE.head + (i - 1) * (Theme.TOUCH + PHONE.gap)
		Theme.label({ Name = track, TextSize = 12, FontFace = Theme.fontBold, TextWrapped = true, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, -4, 0, Theme.TOUCH), TextColor3 = if track == "premium" then Theme.rarity.legendary else Theme.colors.text, ZIndex = 12, Parent = legend })
	end
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, COLUMN_GAP), SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip })
	local row = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(392, Theme.TOUCH), ZIndex = 11, Parent = body })
	buttonRow = row
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	premiumButton = Theme.button({ LayoutOrder = 1, TextSize = 14, Size = UDim2.fromOffset(210, Theme.TOUCH), BackgroundColor3 = Theme.rarity.legendary, ZIndex = 11, Parent = row })
	skipButton = Theme.button({ LayoutOrder = 2, TextSize = 14, Size = UDim2.fromOffset(170, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = row })
	premiumButton.Activated:Connect(function()
		Net.event(Net.Events.RequestProduct):FireServer("pass_premium_s1")
	end)
	skipButton.Activated:Connect(function()
		Net.event(Net.Events.RequestProduct):FireServer("pass_skip_10")
	end)
end

-- Phone: the top row and the compact strip; elsewhere the original 262 px body.
local function shapePass()
	if not holder then
		return
	end
	local phone = Device.isPhone()
	local rowW = if phone then PHONE.premium + PHONE.skip + 8 else 392
	levelLabel.TextSize = if phone then 14 else 16
	levelLabel.Size = UDim2.new(1, -(rowW + 8), 0, if phone then 18 else 22)
	endsLabel.TextSize = if phone then 12 else 13
	endsLabel.Position = UDim2.fromOffset(0, if phone then 35 else 24)
	endsLabel.Size = UDim2.new(1, -(rowW + 8), 0, if phone then 13 else 18)
	xpBar.Position = UDim2.fromOffset(0, if phone then 21 else Theme.TOUCH + 4)
	xpBar.Size = if phone then UDim2.new(1, -(rowW + 8), 0, 12) else UDim2.new(1, 0, 0, 14)
	buttonRow.Size = UDim2.fromOffset(rowW, Theme.TOUCH)
	premiumButton.Size = UDim2.fromOffset(if phone then PHONE.premium else 210, Theme.TOUCH)
	skipButton.Size = UDim2.fromOffset(if phone then PHONE.skip else 170, Theme.TOUCH)
	holder.Position = UDim2.fromOffset(0, if phone then Theme.TOUCH + 6 else Theme.TOUCH + 24)
	holder.Size = UDim2.new(1, 0, 0, if phone then PHONE.strip else 190)
	legend.Visible = phone
	strip.Position = UDim2.fromOffset(if phone then PHONE.legend else 0, 0)
	strip.Size = UDim2.new(1, if phone then -PHONE.legend else 0, 1, 0)
end

local function tierColumn(t: any, snapshot: any, tier: number, level: number)
	local def = SeasonPass.tiers[tier]
	local phone = Device.isPhone()
	local col = Create("Frame", { LayoutOrder = tier, Size = UDim2.fromOffset(COLUMN_W, if phone then PHONE.column else 186), BackgroundColor3 = if tier <= level then Theme.colors.quest else Theme.colors.panelStroke, BackgroundTransparency = if tier <= level then 0.8 else 0.9, BorderSizePixel = 0, ZIndex = 11, Parent = strip }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	local head = Theme.label({ Text = t("pass.level", { n = tier }), TextSize = if phone then 12 else 13, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, if phone then PHONE.head else 18), ZIndex = 12, Parent = col })
	head.TextXAlignment = Enum.TextXAlignment.Center
	local function trackBlock(y: number, track: string, reward: any)
		local claimed = (if track == "free" then snapshot.pass.claimedFree else snapshot.pass.claimedPremium)[tostring(tier)] == true
		local lockedPremium = track == "premium" and not snapshot.pass.premium
		local text = if claimed then t("pass.claimed") elseif tier > level then t("pass.locked") elseif lockedPremium then t("pass.premium") else t("pass.claim")
		local enabled = not claimed and tier <= level and not lockedPremium
		if phone then
			-- The reward on the button's top line, its state under it (the legend names the track).
			local pb = Theme.button({ Name = track, Text = text, TextSize = 12, TextYAlignment = Enum.TextYAlignment.Bottom, Position = UDim2.fromOffset(6, y), Size = UDim2.new(1, -12, 0, Theme.TOUCH), BackgroundColor3 = if enabled then Theme.colors.button else Theme.colors.buttonDisabled, AutoButtonColor = enabled, ZIndex = 12, Parent = col })
			local pad = pb:FindFirstChildOfClass("UIPadding")
			if pad then
				pad.PaddingBottom = UDim.new(0, 4)
			end
			Amount.row({ Position = UDim2.fromOffset(-10, 3), Size = UDim2.new(1, 20, 0, 20), ZIndex = 13, Parent = pb }, Amount.reward(t, reward), { iconSize = 18, textSize = 11, zIndex = 13, rtl = LocaleController.isRtl() })
			pb.Activated:Connect(function()
				if enabled then
					claim(tier, track)
				end
			end)
			return
		end
		local label = Theme.label({ Text = t("pass." .. track), TextSize = 11, Position = UDim2.fromOffset(4, y), Size = UDim2.new(1, -8, 0, 12), TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = if track == "premium" then Theme.rarity.legendary else Theme.colors.text, ZIndex = 12, Parent = col })
		label.TextXAlignment = Enum.TextXAlignment.Center
		Amount.row({ Position = UDim2.fromOffset(2, y + 12), Size = UDim2.new(1, -4, 0, 22), ZIndex = 12, Parent = col }, Amount.reward(t, reward), { iconSize = 22, textSize = 12, rtl = LocaleController.isRtl() })
		local b = Theme.button({ Text = text, TextSize = 12, Position = UDim2.fromOffset(6, y + 36), Size = UDim2.new(1, -12, 0, Theme.TOUCH), BackgroundColor3 = if enabled then Theme.colors.button else Theme.colors.buttonDisabled, AutoButtonColor = enabled, ZIndex = 12, Parent = col })
		b.Activated:Connect(function()
			if enabled then
				claim(tier, track)
			end
		end)
	end
	if phone then
		trackBlock(PHONE.head, "free", def.free)
		trackBlock(PHONE.head + Theme.TOUCH + PHONE.gap, "premium", def.premium)
	else
		trackBlock(20, "free", def.free)
		trackBlock(102, "premium", def.premium)
	end
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
	for _, track in { "free", "premium" } do
		local l = legend:FindFirstChild(track) :: TextLabel?
		if l then
			l.Text = t("pass." .. track)
		end
	end
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
	-- Scroll to the oldest tier with a claim waiting, else the current level (MH-20).
	local focus = PassLogic.firstClaimable(snapshot, SeasonPass.tiers) or level
	strip.CanvasPosition = Vector2.new(math.max(0, (focus - 1) * (COLUMN_W + COLUMN_GAP)), 0)
end

function PassController.open()
	modal.setVisible(true)
	PassController.render()
end

function PassController.start()
	build()
	shapePass()
	Device.Changed:Connect(function()
		shapePass()
		PassController.render()
	end)
	StateController.Changed:Connect(PassController.render)
	LocaleController.Changed:Connect(PassController.render)
	LobbyMenuController.register("pass", PassController.open)
end

return PassController
