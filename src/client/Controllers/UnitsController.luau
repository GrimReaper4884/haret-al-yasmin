--!strict
-- Collection and loadout: the owned defenders as cards, a detail view with stats, trait reroll
-- and add/remove from the loadout. The loadout is saved on the server (SetLoadout).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Traits = require(Shared.Config.Traits)
local UnitLogic = require(Shared.Logic.UnitLogic)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Juice = require(UI.Juice)
local Modal = require(UI.Modal)
local UnitCard = require(UI.UnitCard)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)

local UnitsController = {}

local RARITY_RANK = { secret = 6, mythic = 5, legendary = 4, epic = 3, rare = 2 }

local modal: Modal.Modal
local loadoutRow: Frame
local loadoutLabel: TextLabel
local grid: ScrollingFrame
local detail: Frame
local ratesPanel: Frame
local ratesTitle: TextLabel
local ratesText: TextLabel
local ratesNote: TextLabel
local selected: string? = nil
local busy = false

local function request(fn: () -> any)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		pcall(fn)
		busy = false
	end)
end

local function build()
	modal = Modal.create("Units", 640, 250)
	local body = modal.body
	loadoutLabel = Theme.label({ TextSize = 14, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = body })
	loadoutRow = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 64), ZIndex = 11, Parent = body })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = loadoutRow })
	local gridHolder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 1, -90), ZIndex = 11, Parent = body })
	grid = Modal.scroller(gridHolder)
	Create("UIGridLayout", { CellSize = UDim2.fromOffset(96, 124), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	detail = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12, Visible = false, Parent = body })
	-- Trait reroll rates (paid random item: trait stones are sold for Robux). Covers the detail view.
	ratesPanel = Theme.panel({ Name = "TraitRates", Size = UDim2.fromScale(1, 1), ZIndex = 14, Visible = false, Parent = body })
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8), Parent = ratesPanel })
	ratesTitle = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, -48, 0, 22), ZIndex = 15, Parent = ratesPanel })
	ratesText = Theme.label({ TextSize = 14, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 148), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15, Parent = ratesPanel })
	ratesNote = Theme.label({ TextSize = 12, TextColor3 = Theme.colors.textMuted, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 44), TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 15, Parent = ratesPanel })
	local close = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Theme.colors.danger, ZIndex = 15, Parent = ratesPanel })
	close.Activated:Connect(function()
		ratesPanel.Visible = false
	end)
end

-- Enough decimals that the rarest outcome never reads as 0 % (e.g. 0.0025 %).
local function fmtPercent(p: number): string
	local decimals = if p >= 1 then 2 elseif p >= 0.1 then 3 else 4
	return string.format("%." .. decimals .. "f%%", p)
end

-- Fills the rates panel for the selected unit (odds depend on its current trait: see
-- UnitLogic.rerollOdds). Same weights the server rolls with.
local function renderRates(snapshot: any)
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local owned = selected and snapshot.units[selected]
	if not owned then
		ratesPanel.Visible = false
		return
	end
	local lines = {}
	for _, o in UnitLogic.rerollOdds(Traits.traits, Traits.order, owned.trait) do
		local name = t(Traits.traits[o.trait].nameKey)
		if o.trait == owned.trait then
			name ..= " " .. t("units.rates_current")
		end
		table.insert(lines, name .. ": " .. fmtPercent(o.percent))
	end
	ratesTitle.Text = t("units.rates_title")
	ratesText.Text = table.concat(lines, "\n")
	ratesNote.Text = t("units.rates_note")
	for _, l in { ratesTitle, ratesText, ratesNote } do
		Theme.align(l, rtl)
	end
end

local function statLine(t: any, def: any, owned: any): string
	local stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES)
	local trait = Traits.traits[owned.trait]
	local st = UnitLogic.stats(def, 1, stars, trait, TD.STAR_BONUS)
	local lines = {}
	if st.damage > 0 then
		table.insert(lines, t("match.stat_damage", { n = math.floor(st.damage + 0.5) }))
		table.insert(lines, t("match.stat_range", { n = math.floor(st.range * 10 + 0.5) / 10 }))
		table.insert(lines, t("match.stat_cooldown", { n = math.floor(st.cooldown * 100 + 0.5) / 100 }))
	end
	if st.revealsStealth then
		table.insert(lines, t("match.reveals_stealth"))
	end
	if st.income then
		table.insert(lines, t("match.stat_income", { n = st.income }))
	end
	if st.buff then
		table.insert(lines, t("match.stat_buff", { n = math.floor((st.buff - 1) * 100 + 0.5) }))
	end
	if st.heal then
		table.insert(lines, t("match.stat_heal", { n = st.heal }))
	end
	return table.concat(lines, "\n")
end

local function setLoadout(list: { string })
	request(function()
		return Net.func(Net.Functions.SetLoadout):InvokeServer(list)
	end)
end

local function renderDetail(snapshot: any)
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	for _, c in detail:GetChildren() do
		c:Destroy()
	end
	local unitId = selected
	if not unitId then
		return
	end
	local def = (Units :: any)[unitId]
	local owned = snapshot.units[unitId]
	if not def or not owned then
		return
	end
	detail.Visible = true
	grid.Visible = false
	loadoutRow.Visible = false
	loadoutLabel.Visible = false
	local stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES)
	local card = UnitCard.create(unitId, { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(150, 210) }, { stars = stars, spin = true, zindex = 12 })
	card.Parent = detail
	local x = if rtl then 0 else 160
	local name = Theme.label({ Text = t(def.nameKey), TextSize = 18, FontFace = Theme.fontBold, TextColor3 = Theme.rarityColor(def.rarity), Position = UDim2.fromOffset(x, 0), Size = UDim2.new(1, -160, 0, 22), ZIndex = 13, Parent = detail })
	local rarity = Theme.label({ Text = t("rarity." .. def.rarity) .. " · " .. t("role." .. def.role) .. " · " .. t("units.stars", { n = stars }), TextSize = 13, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(x, 22), Size = UDim2.new(1, -160, 0, 16), ZIndex = 13, Parent = detail })
	local desc = Theme.label({ Text = t(def.descKey), TextSize = 13, Position = UDim2.fromOffset(x, 40), Size = UDim2.new(1, -160, 0, 44), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 13, Parent = detail })
	local stats = Theme.label({ Text = statLine(t, def, owned), TextSize = 13, FontFace = Theme.fontBold, Position = UDim2.fromOffset(x, 86), Size = UDim2.new(0.5, -80, 0, 70), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 13, Parent = detail })
	local next = 0
	for _, needed in TD.STAR_COPIES do
		if owned.copies < needed then
			next = needed - owned.copies
			break
		end
	end
	local traitDef = Traits.traits[owned.trait]
	local traitLine = Theme.label({
		Text = t("units.trait", { trait = t(traitDef.nameKey) }) .. (if next > 0 then "\n" .. t("units.copies", { n = next }) else ""),
		TextSize = 13,
		Position = UDim2.new(0.5, if rtl then -160 else 0, 0, 86),
		Size = UDim2.new(0.5, 0, 0, 40),
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = detail,
	})
	for _, l in { name, rarity, desc, stats, traitLine } do
		Theme.align(l, rtl)
	end
	-- Rates first: the reroll is a paid random item.
	local rates = Theme.button({
		Text = t("units.rates"),
		TextSize = 13,
		Position = UDim2.new(0.5, if rtl then -160 else 0, 0, 130),
		Size = UDim2.fromOffset(120, 32),
		BackgroundColor3 = Theme.colors.quest,
		ZIndex = 13,
		Parent = detail,
	})
	rates.Activated:Connect(function()
		renderRates(snapshot)
		ratesPanel.Visible = true
	end)
	if ratesPanel.Visible then
		renderRates(snapshot) -- the trait may have just changed
	end

	local inLoadout = table.find(snapshot.loadout, unitId) ~= nil
	local slots = snapshot.loadoutSlots or TD.LOADOUT_SLOTS
	local full = #snapshot.loadout >= slots
	local toggle = Theme.button({
		Text = if inLoadout then t("units.remove") else (if full then t("units.loadout_full") else t("units.add")),
		TextSize = 14,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, x, 1, 0),
		Size = UDim2.fromOffset(170, Theme.TOUCH - 6),
		BackgroundColor3 = if inLoadout then Theme.colors.danger else (if full then Theme.colors.buttonDisabled else Theme.colors.button),
		ZIndex = 13,
		Parent = detail,
	})
	toggle.Activated:Connect(function()
		local list = table.clone(snapshot.loadout)
		if inLoadout then
			local i = table.find(list, unitId)
			if i then
				table.remove(list, i)
			end
		elseif not full then
			table.insert(list, unitId)
		else
			return
		end
		setLoadout(list)
	end)
	local reroll = Theme.button({
		Text = t("units.reroll") .. " (" .. t("units.stones", { n = snapshot.traitStones }) .. ")",
		TextSize = 13,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, x + 180, 1, 0),
		Size = UDim2.fromOffset(230, Theme.TOUCH - 6),
		BackgroundColor3 = if snapshot.traitStones > 0 then Theme.rarity.epic else Theme.colors.buttonDisabled,
		ZIndex = 13,
		Parent = detail,
	})
	reroll.Activated:Connect(function()
		if snapshot.traitStones > 0 then
			request(function()
				return Net.func(Net.Functions.RerollTrait):InvokeServer(unitId)
			end)
		end
	end)
	local back = Theme.button({ Text = "<", TextSize = 16, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(44, Theme.TOUCH - 6), BackgroundColor3 = Theme.colors.quest, ZIndex = 13, Parent = detail })
	back.Activated:Connect(function()
		selected = nil
		UnitsController.render()
	end)
end

function UnitsController.render()
	if not modal.isOpen() then
		return
	end
	local t = LocaleController.t
	local snapshot = StateController.get()
	if not snapshot then
		return
	end
	modal.title.Text = t("units.title")
	Theme.align(modal.title, LocaleController.isRtl())
	if selected and snapshot.units[selected] then
		renderDetail(snapshot)
		return
	end
	selected = nil
	detail.Visible = false
	ratesPanel.Visible = false
	grid.Visible = true
	loadoutRow.Visible = true
	loadoutLabel.Visible = true
	local slots = snapshot.loadoutSlots or TD.LOADOUT_SLOTS
	loadoutLabel.Text = t("units.loadout", { n = #snapshot.loadout, max = slots })
	Theme.align(loadoutLabel, LocaleController.isRtl())
	for _, c in loadoutRow:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i = 1, slots do
		local unitId = snapshot.loadout[i]
		if unitId and (Units :: any)[unitId] then
			local card = UnitCard.create(unitId, { LayoutOrder = i, Size = UDim2.fromOffset(52, 60) }, { zindex = 11 })
			card.Parent = loadoutRow
			local hit = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = card })
			Juice.press(hit)
			hit.Activated:Connect(function()
				selected = unitId
				UnitsController.render()
			end)
		else
			Create("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(52, 60), BackgroundColor3 = Theme.colors.panelStroke, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 11, Parent = loadoutRow }, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		end
	end
	for _, c in grid:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local ids = {}
	for id in snapshot.units do
		if (Units :: any)[id] then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local ra, rb = RARITY_RANK[(Units :: any)[a].rarity] or 0, RARITY_RANK[(Units :: any)[b].rarity] or 0
		if ra ~= rb then
			return ra > rb
		end
		return a < b
	end)
	for i, id in ids do
		local def = (Units :: any)[id]
		local owned = snapshot.units[id]
		local inLoadout = table.find(snapshot.loadout, id) ~= nil
		local card = UnitCard.create(id, { LayoutOrder = i }, { name = t(def.nameKey), stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES), selected = inLoadout, sub = t("rarity." .. def.rarity) })
		card.Parent = grid
		local hit = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = card })
		Juice.press(hit)
		Juice.tilt(card, hit)
		hit.Activated:Connect(function()
			selected = id
			UnitsController.render()
		end)
	end
end

function UnitsController.open()
	selected = nil
	modal.setVisible(true)
	UnitsController.render()
end

function UnitsController.start()
	build()
	StateController.Changed:Connect(UnitsController.render)
	LocaleController.Changed:Connect(UnitsController.render)
	LobbyMenuController.register("units", UnitsController.open)
end

return UnitsController
