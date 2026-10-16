--!strict
-- Summon screen: the active banner and its featured defenders, the player's lira, ×1 / ×10
-- buttons, a Rates panel with every outcome's percentage (shown before any purchase, pity
-- included), and the reveal: the lantern build-up (UI/SummonSequence; skippable, and off with
-- Settings → Summon animation), then the cards (one big card, or ×10 flipping in); a Legendary or
-- Mythic triggers the shabriyeh flash. All rolls happen on the server; this only shows results.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Banners = require(Shared.Config.Banners)
local Traits = require(Shared.Config.Traits)
local SummonLogic = require(Shared.Logic.SummonLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Modal = require(UI.Modal)
local UnitCard = require(UI.UnitCard)
local SummonSequence = require(UI.SummonSequence)
local Juice = require(UI.Juice)
local Fx = require(UI.Fx)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local ShopController = require(script.Parent.ShopController)
local AudioController = require(script.Parent.AudioController)
local SettingsController = require(script.Parent.SettingsController)

local SummonController = {}

local modal: Modal.Modal
local bannerLabel: TextLabel
local rotateLabel: TextLabel
local liraLabel: TextLabel
local featured: Frame
local oneButton: TextButton
local tenButton: TextButton
local ratesButton: TextButton
local ratesPanel: Frame
local ratesText: TextLabel
local pityText: TextLabel
local reveal: Frame
local revealGrid: Frame
local revealAgain: TextButton
local flash: Frame
local busy = false
local lastN = 1

local function ctx(): SummonLogic.Context
	return {
		units = Units :: any,
		banners = Banners :: any,
		odds = TD.ODDS,
		rarityOrder = TD.RARITY_ORDER,
		pityLegendary = TD.PITY_LEGENDARY,
		pityMythic = TD.PITY_MYTHIC,
		featuredShare = TD.FEATURED_SHARE,
		rotation = TD.BANNER_ROTATION,
		traits = Traits,
		rng = math.random,
		now = os.time(),
	}
end

local function fmtTime(seconds: number): string
	local m = math.floor(seconds / 60)
	return string.format("%d:%02d", math.floor(m / 60), m % 60)
end

local function build()
	modal = Modal.create("Summon", 560, 250)
	local body = modal.body
	bannerLabel = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(0.6, 0, 0, 20), ZIndex = 11, Parent = body })
	rotateLabel = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.4, 0, 0, 20), ZIndex = 11, Parent = body })
	rotateLabel.TextXAlignment = Enum.TextXAlignment.Right
	featured = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 150), ZIndex = 11, Parent = body })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = featured })

	local bottom = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 68), ZIndex = 11, Parent = body })
	liraLabel = Theme.label({ TextSize = 15, FontFace = Theme.fontBold, TextColor3 = Theme.lira, Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = bottom })
	liraLabel.TextXAlignment = Enum.TextXAlignment.Center
	local row = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, Theme.TOUCH - 4), ZIndex = 11, Parent = bottom })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	oneButton = Theme.button({ LayoutOrder = 1, TextSize = 14, Size = UDim2.fromOffset(170, Theme.TOUCH - 4), ZIndex = 11, Parent = row })
	tenButton = Theme.button({ LayoutOrder = 2, TextSize = 14, Size = UDim2.fromOffset(170, Theme.TOUCH - 4), BackgroundColor3 = Theme.rarity.legendary, ZIndex = 11, Parent = row })
	ratesButton = Theme.button({ LayoutOrder = 3, TextSize = 14, Size = UDim2.fromOffset(90, Theme.TOUCH - 4), BackgroundColor3 = Theme.colors.quest, ZIndex = 11, Parent = row })

	-- Rates panel (covers the body)
	ratesPanel = Theme.panel({ Name = "Rates", Size = UDim2.fromScale(1, 1), ZIndex = 12, Visible = false, Parent = body })
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8), Parent = ratesPanel })
	local ratesTitle = Theme.label({ Name = "Title", TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 22), ZIndex = 13, Parent = ratesPanel })
	ratesText = Theme.label({ TextSize = 15, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 120), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 13, Parent = ratesPanel })
	pityText = Theme.label({ TextSize = 13, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(0, 150), Size = UDim2.new(1, 0, 0, 40), ZIndex = 13, Parent = ratesPanel })
	local ratesClose = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Theme.colors.danger, ZIndex = 13, Parent = ratesPanel })
	ratesClose.Activated:Connect(function()
		ratesPanel.Visible = false
	end)
	ratesTitle:SetAttribute("Key", "summon.rates_title")

	-- Reveal overlay (full screen)
	reveal = Create("Frame", { Name = "SummonReveal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.colors.text, BackgroundTransparency = 0.25, ZIndex = 20, Visible = false, Parent = Root.get() })
	Modal.registerOverlay(reveal)
	revealGrid = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(5 * 110, 2 * 150), ZIndex = 21, Parent = reveal })
	Create("UIGridLayout", { CellSize = UDim2.fromOffset(100, 140), CellPadding = UDim2.fromOffset(10, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = revealGrid })
	revealAgain = Theme.button({ TextSize = 16, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, -70, 1, -16), Size = UDim2.fromOffset(130, Theme.TOUCH), BackgroundColor3 = Theme.rarity.legendary, ZIndex = 21, Parent = reveal })
	local revealClose = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 70, 1, -16), Size = UDim2.fromOffset(130, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 21, Parent = reveal })
	revealClose.Activated:Connect(function()
		reveal.Visible = false
	end)
	flash = Create("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.lira, BackgroundTransparency = 1, ZIndex = 30, Visible = false, Parent = Root.get() })
	local flashText = Theme.label({ Name = "Text", TextSize = 48, FontFace = Theme.fontBold, TextColor3 = Theme.colors.buttonText, TextStrokeTransparency = 0.2, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 0, 60), ZIndex = 31, Parent = flash })
	flashText.TextXAlignment = Enum.TextXAlignment.Center
end

-- The shabriyeh moment: a gold flash, the cry, and a sting.
function SummonController.shabriyehFlash(text: string)
	flash.Visible = true
	flash.BackgroundTransparency = 0.1
	local label = flash:FindFirstChild("Text") :: TextLabel
	label.Text = text
	label.TextTransparency = 0
	AudioController.sting("shabriyeh")
	TweenService:Create(flash, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	local t = TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		flash.Visible = false
	end)
end

local function card(r: any, i: number, size: Vector2, hero: boolean): Frame
	local t = LocaleController.t
	local def = (Units :: any)[r.unitId]
	local c = UnitCard.create(r.unitId, { LayoutOrder = i }, {
		name = t(def.nameKey),
		-- New units carry the stamp, so the line under them names the rarity instead.
		sub = if hero or r.result == "new" then t("rarity." .. r.rarity) else t("summon.copy"),
		zindex = 21,
		spin = hero,
	})
	c.Size = UDim2.fromOffset(size.X, size.Y)
	if r.result == "new" then
		-- "New in your diary!" stamp across the top corner.
		local stamp = Theme.display({
			Text = t("summon.new_stamp"),
			TextSize = if hero then 18 else 12,
			TextColor3 = Color3.fromHex("#FFD970"),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(1.1, 0, 0, if hero then 26 else 18),
			Rotation = -6,
			BackgroundColor3 = Theme.colors.danger,
			BackgroundTransparency = 0,
			ZIndex = 25,
			Parent = c,
		})
		stamp.TextXAlignment = Enum.TextXAlignment.Center
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = stamp })
		Theme.border(stamp, 2)
	end
	return c
end

-- Shows the cards: one big turning card for a single pull, a 5 × 2 grid that flips in for ×10
-- (tap to show the rest at once). Legendary or better cards punch in with the flash.
local function showCards(results: { any })
	local t = LocaleController.t
	revealAgain.Visible = true
	if #results == 1 then
		revealGrid.Size = UDim2.fromOffset(200, 280)
		local grid = revealGrid:FindFirstChildOfClass("UIGridLayout") :: UIGridLayout
		grid.CellSize = UDim2.fromOffset(190, 270)
		local c = card(results[1], 1, Vector2.new(190, 270), true)
		c.Parent = revealGrid
		Juice.pop(c, 0.4)
		if SummonSequence.rank(results[1].rarity) >= 3 then
			SummonController.shabriyehFlash(t("match.shabriyeh"))
		end
		return
	end
	revealGrid.Size = UDim2.fromOffset(5 * 110, 2 * 150)
	local grid = revealGrid:FindFirstChildOfClass("UIGridLayout") :: UIGridLayout
	grid.CellSize = UDim2.fromOffset(100, 140)
	local cards = {}
	for i, r in results do
		local c = card(r, i, Vector2.new(100, 140), false)
		c.Visible = false
		c.Parent = revealGrid
		cards[i] = c
	end
	local skipped = false
	local skip = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 26, Parent = reveal })
	skip.Activated:Connect(function()
		skipped = true
	end)
	task.spawn(function()
		local best = 0
		for i, r in results do
			local c = cards[i]
			c.Visible = true
			local rank = SummonSequence.rank(r.rarity)
			if skipped then
				continue
			end
			Juice.pop(c, 0.3)
			if rank >= 3 then
				best = math.max(best, rank)
				SummonController.shabriyehFlash(t("match.shabriyeh"))
				task.wait(0.55)
			else
				AudioController.sting("summon_reveal")
				task.wait(0.12)
			end
		end
		skip:Destroy()
		if best >= 3 then
			AudioController.sting("summon_legendary")
		end
	end)
end

function SummonController.showResults(results: { any })
	for _, c in revealGrid:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	reveal.Visible = true
	revealAgain.Text = LocaleController.t("summon.again")
	revealAgain.Visible = false
	local best = "rare"
	for _, r in results do
		if SummonSequence.rank(r.rarity) > SummonSequence.rank(best) then
			best = r.rarity
		end
	end
	if SettingsController.get("skipSummon") == true or not Fx.any() then
		showCards(results)
		return
	end
	revealGrid.Visible = false
	SummonSequence.play(reveal, best, function()
		revealGrid.Visible = true
		showCards(results)
	end, AudioController.sting)
end

local function doSummon(n: number)
	if busy then
		return
	end
	busy = true
	lastN = n
	task.spawn(function()
		local ok, result = pcall(function()
			return Net.func(Net.Functions.Summon):InvokeServer(n)
		end)
		busy = false
		if ok and type(result) == "table" and result.ok and result.results then
			SummonController.showResults(result.results)
		elseif ok and type(result) == "table" and result.err == "no_lira" then
			local snapshot = StateController.get()
			if snapshot and not snapshot.restricted then
				ShopController.openStore()
			end
		end
	end)
end

local render: () -> ()

local function renderRates()
	local t = LocaleController.t
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	local lines = {}
	for _, o in SummonLogic.displayOdds(snapshot.summons, ctx()) do
		table.insert(lines, string.format("%s: %.3f%%", t("rarity." .. o.rarity), o.percent))
	end
	ratesText.Text = table.concat(lines, "\n")
	local s = snapshot.summons
	pityText.Text = t("summon.pity", { l = TD.PITY_LEGENDARY, a = math.max(0, TD.PITY_LEGENDARY - s.sinceLegendary - 1), m = TD.PITY_MYTHIC, b = math.max(0, TD.PITY_MYTHIC - s.sinceMythic - 1) })
	local title = ratesPanel:FindFirstChild("Title") :: TextLabel
	title.Text = t("summon.rates_title")
	ratesPanel.Visible = true
end

render = function()
	if not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	local c = ctx()
	local banner = SummonLogic.activeBanner(c)
	modal.title.Text = t("summon.title")
	bannerLabel.Text = t("summon.banner", { name = t(banner.nameKey) })
	local nextAt = (math.floor(c.now / TD.BANNER_ROTATION) + 1) * TD.BANNER_ROTATION
	rotateLabel.Text = t("summon.rotates", { n = fmtTime(nextAt - c.now) })
	for _, child in featured:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i, unitId in { banner.featuredLegendary, banner.featuredMythic } do
		local def = (Units :: any)[unitId]
		local fcard = UnitCard.create(unitId, { LayoutOrder = i, Size = UDim2.fromOffset(104, 146) }, { name = t(def.nameKey), sub = t("summon.featured"), spin = i == 2 })
		fcard.Parent = featured
	end
	local vip: boolean = snapshot.perks ~= nil and (snapshot.perks :: any).vip == true
	local c1 = SummonLogic.cost(1, TD.SUMMON_COST, TD.SUMMON_TEN_COST, TD.VIP_SUMMON_DISCOUNT, vip)
	local c10 = SummonLogic.cost(10, TD.SUMMON_COST, TD.SUMMON_TEN_COST, TD.VIP_SUMMON_DISCOUNT, vip)
	liraLabel.Text = t("hud.lira", { n = snapshot.lira }) .. (if snapshot.restricted then "  ·  " .. t("summon.restricted") else "")
	oneButton.Text = t("summon.one", { n = c1 })
	tenButton.Text = t("summon.ten", { n = c10 })
	ratesButton.Text = t("summon.rates")
	Theme.align(bannerLabel, rtl)
	Theme.align(modal.title, rtl)
end

function SummonController.open()
	modal.setVisible(true)
	ratesPanel.Visible = false
	render()
end

function SummonController.start()
	build()
	oneButton.Activated:Connect(function()
		doSummon(1)
	end)
	tenButton.Activated:Connect(function()
		doSummon(10)
	end)
	ratesButton.Activated:Connect(renderRates)
	revealAgain.Activated:Connect(function()
		reveal.Visible = false
		doSummon(lastN)
	end)
	StateController.Changed:Connect(render)
	LocaleController.Changed:Connect(render)
	LobbyMenuController.register("summon", SummonController.open)
	task.spawn(function()
		while true do
			task.wait(30)
			render()
		end
	end)
end

return SummonController
