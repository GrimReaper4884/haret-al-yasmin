--!strict
-- Collection and loadout: the owned defenders as cards, a detail view with stats, trait reroll
-- and add/remove from the loadout. The loadout is saved on the server (SetLoadout). The detail also
-- shows the unit's three shabriyeh bead slots (S1-C04): tap a slot, pick one of the unit's kinds,
-- and the server threads it (SetBead, one bead each; it re-checks ownership, slot, kind and cost).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Traits = require(Shared.Config.Traits)
local Beads = require(Shared.Config.Beads)
local IconIds = require(Shared.Config.Icons)
local UnitLogic = require(Shared.Logic.UnitLogic)
local UpgradeView = require(Shared.Logic.UpgradeView)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Button = require(UI.Button)
local Juice = require(UI.Juice)
local Modal = require(UI.Modal)
local UnitCard = require(UI.UnitCard)
local Icons = require(UI.Icons)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local LobbyMenuController = require(script.Parent.LobbyMenuController)
local ToastController = require(script.Parent.ToastController)

local UnitsController = {}

local RARITY_RANK = { secret = 6, mythic = 5, legendary = 4, epic = 3, rare = 2 }
-- Role order for the grid's second sort key and the filter chips (LP-B05).
local ROLE_ORDER = { "melee", "ranged", "splash", "support", "healer", "farm" }
local roleFilter: string? = nil -- nil = every role
local filterRow: Frame
local filterChips: { [string]: TextButton } = {}

local modal: Modal.Modal
local loadoutRow: Frame
local loadoutLabel: TextLabel
local grid: ScrollingFrame
local detail: Frame
local ratesPanel: Frame
local ratesTitle: TextLabel
local ratesText: TextLabel
local ratesText2: TextLabel -- second column (12 traits do not fit one column on a phone)
local ratesNote: TextLabel
local ratesSwitch: TextButton -- 1st / 2nd trait slot, shown once the second slot is open
local ratesSlot = 1
local renderRates: (snapshot: any) -> () -- defined below build(), which wires the slot switch to it
local selected: string? = nil
local beadPanel: Frame -- the bead picker for one slot, over the detail view (S1-C04)
local beadTitle: TextLabel
local beadList: Frame
-- Server answers of SetBead → the toast it shows.
local BEAD_ERRORS = { no_beads = "units.err.no_beads", same_bead = "units.err.same_bead" }
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
	-- 304: the role filter row (LP-B05) took 54 px from the grid.
	modal = Modal.create("Units", 640, 304, { fill = true })
	local body = modal.body
	loadoutLabel = Theme.label({ TextSize = 14, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = body })
	loadoutRow = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 64), ZIndex = 11, Parent = body })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = loadoutRow })
	-- Role filter chips (LP-B05): All, then one glyph per role.
	filterRow = Create("Frame", { Name = "Filters", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 11, Parent = body })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = filterRow })
	local function chip(key: string, order: number, width: number): TextButton
		local b = Theme.button({ Name = "Filter_" .. key, LayoutOrder = order, Text = "", TextSize = 14, Size = UDim2.fromOffset(width, Theme.TOUCH), BackgroundColor3 = Theme.colors.button, ZIndex = 12, Parent = filterRow })
		b.Activated:Connect(function()
			roleFilter = if key == "all" then nil else key
			UnitsController.render()
		end)
		filterChips[key] = b
		return b
	end
	chip("all", 0, 64)
	for i, role in ROLE_ORDER do
		local b = chip(role, i, Theme.TOUCH)
		local pad = b:FindFirstChildOfClass("UIPadding")
		if pad then
			pad:Destroy()
		end
		local glyph = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 13, Parent = b })
		Icons.draw("role_" .. role, glyph)
		for _, d in glyph:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 13
			end
		end
	end
	local gridTop = 88 + Theme.TOUCH + 6
	local gridHolder = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, gridTop), Size = UDim2.new(1, 0, 1, -gridTop), ZIndex = 11, Parent = body })
	grid = Modal.scroller(gridHolder)
	Create("UIGridLayout", { CellSize = UDim2.fromOffset(96, 124), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	detail = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12, Visible = false, Parent = body })
	-- Trait reroll rates (paid random item: trait stones are sold for Robux). Covers the detail view.
	ratesPanel = Theme.panel({ Name = "TraitRates", Size = UDim2.fromScale(1, 1), ZIndex = 14, Visible = false, Parent = body })
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8), Parent = ratesPanel })
	-- Header: title, the slot switch (when two traits are open) and the close button, all 48 px tall.
	ratesTitle = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, -(Theme.TOUCH + 156), 0, Theme.TOUCH), ZIndex = 15, Parent = ratesPanel })
	ratesText = Theme.label({ TextSize = 14, Position = UDim2.fromOffset(0, Theme.TOUCH + 6), Size = UDim2.new(0.5, -6, 0, 116), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15, Parent = ratesPanel })
	ratesText2 = Theme.label({ TextSize = 14, Position = UDim2.new(0.5, 6, 0, Theme.TOUCH + 6), Size = UDim2.new(0.5, -6, 0, 116), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15, Parent = ratesPanel })
	ratesSwitch = Theme.button({ TextSize = 13, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(Theme.TOUCH + 6), 0, 0), Size = UDim2.fromOffset(150, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 15, Visible = false, Parent = ratesPanel })
	ratesNote = Theme.label({ TextSize = 12, TextColor3 = Theme.colors.textMuted, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 44), TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 15, Parent = ratesPanel })
	local close = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 15, Parent = ratesPanel })
	close.Activated:Connect(function()
		ratesPanel.Visible = false
	end)
	-- Bead picker: the unit's kinds for one slot.
	beadPanel = Theme.panel({ Name = "BeadPicker", Size = UDim2.fromScale(1, 1), ZIndex = 14, Visible = false, Parent = body })
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8), Parent = beadPanel })
	beadTitle = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, -(Theme.TOUCH + 8), 0, Theme.TOUCH), ZIndex = 15, Parent = beadPanel })
	beadList = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, Theme.TOUCH + 6), Size = UDim2.new(1, 0, 1, -(Theme.TOUCH + 6)), ZIndex = 15, Parent = beadPanel })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = beadList })
	local closeBeads = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 15, Parent = beadPanel })
	closeBeads.Activated:Connect(function()
		beadPanel.Visible = false
	end)
	ratesSwitch.Activated:Connect(function()
		ratesSlot = 3 - ratesSlot
		local snapshot = StateController.get()
		if snapshot then
			renderRates(snapshot)
		end
	end)
end

-- Enough decimals that the rarest outcome never reads as 0 % (e.g. 0.0025 %).
local function fmtPercent(p: number): string
	local decimals = if p >= 1 then 2 elseif p >= 0.1 then 3 else 4
	return string.format("%." .. decimals .. "f%%", p)
end

local function slot2Open(owned: any): boolean
	return UnitLogic.stars(owned.copies, TD.STAR_COPIES) >= TD.TRAIT2_STARS
end

-- Fills the rates panel for the selected unit and trait slot (odds depend on that slot's current
-- trait: see UnitLogic.rerollOdds). Same weights the server rolls with, read from Config/Traits.
function renderRates(snapshot: any)
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local owned = selected and snapshot.units[selected]
	if not owned then
		ratesPanel.Visible = false
		return
	end
	local open = slot2Open(owned)
	if not open then
		ratesSlot = 1
	end
	local current = if ratesSlot == 2 then owned.trait2 else owned.trait
	local lines = {}
	for _, o in UnitLogic.rerollOdds(Traits.traits, Traits.order, current) do
		local name = t(Traits.traits[o.trait].nameKey)
		if o.trait == current then
			name ..= " " .. t("units.rates_current")
		end
		table.insert(lines, name .. ": " .. fmtPercent(o.percent))
	end
	local half = math.ceil(#lines / 2)
	ratesTitle.Text = t(if ratesSlot == 2 then "units.rates_title2" else "units.rates_title")
	ratesText.Text = table.concat(lines, "\n", 1, half)
	ratesText2.Text = table.concat(lines, "\n", half + 1, #lines)
	ratesNote.Text = t("units.rates_note")
	ratesSwitch.Text = t("units.rates_switch")
	ratesSwitch.Visible = open
	-- Columns start below the header; in Arabic the first column sits on the right. The switch stays
	-- in the header beside the close button.
	local top = Theme.TOUCH + 6
	ratesText.Position = if rtl then UDim2.new(0.5, 6, 0, top) else UDim2.fromOffset(0, top)
	ratesText2.Position = if rtl then UDim2.fromOffset(0, top) else UDim2.new(0.5, 6, 0, top)
	for _, l in { ratesTitle, ratesText, ratesText2, ratesNote } do
		Theme.align(l, rtl)
	end
end

-- One line under a card's name: the attack pattern and how many can stand at once (LP-B05).
local function kindLine(t: any, def: any): string
	local k = UnitLogic.kind(def)
	local pattern = if k.splash then t("kind." .. k.pattern, { r = math.floor(k.splash * 10 + 0.5) / 10 }) else t("kind." .. k.pattern)
	return pattern .. " · " .. t("kind.max", { n = k.maxPlaced })
end

local function r1(n: number): number
	return math.floor(n * 10 + 0.5) / 10
end

-- The detail view's stat block (LP-B05, UnitLogic.statBlock): level 1 → the last level with this
-- player's stars and trait, the ultimate, the economy, what it reaches, the cap, the cost to max
-- and the two level-7 paths.
local function statLine(t: any, unitId: string, def: any, owned: any): string
	local stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES)
	local trait = UnitLogic.ownedTrait(owned, Traits.traits, TD.STAR_COPIES, TD.TRAIT2_STARS)
	local b = UnitLogic.statBlock(def, stars, trait, TD.STAR_BONUS, Traits.caps, TD.SELL_REFUND, Beads)
	local k = UnitLogic.kind(def)
	local lines = {}
	if b.dps[1] > 0 then
		table.insert(lines, t("units.block_dps", { a = math.floor(b.dps[1] + 0.5), b = math.floor(b.dps[2] + 0.5) }))
		table.insert(lines, t("units.block_range", { a = r1(b.range[1]), b = r1(b.range[2]) }))
		table.insert(lines, t("units.block_cooldown", { a = math.floor(b.cooldown[1] * 100 + 0.5) / 100, b = math.floor(b.cooldown[2] * 100 + 0.5) / 100 }))
	end
	if k.ability and k.abilityCooldown then
		table.insert(lines, t("units.block_ability", { name = t("ult." .. unitId), s = k.abilityCooldown }))
	end
	if b.income then
		table.insert(lines, t("units.block_income", { a = b.income[1], b = b.income[2] }))
	end
	if b.bounty then
		table.insert(lines, t("units.block_bounty", { a = b.bounty[1], b = b.bounty[2] }))
	end
	if b.buff then
		table.insert(lines, t("units.block_buff", { a = math.floor((b.buff[1] - 1) * 100 + 0.5), b = math.floor((b.buff[2] - 1) * 100 + 0.5) }))
	end
	if b.heal then
		table.insert(lines, t("units.block_heal", { a = b.heal[1], b = b.heal[2] }))
	end
	for _, r in k.reach do
		table.insert(lines, t("kind.reach." .. r))
	end
	table.insert(lines, t("units.block_placed", { n = k.maxPlaced }))
	table.insert(lines, t("units.block_cost", { n = b.maxLevel, c = b.costToMax, s = b.sellAtMax }))
	local sig = b.signature
	if sig then
		table.insert(lines, t("units.block_signature", { a = t("unit." .. unitId .. ".sig." .. sig.a .. ".name"), b = t("unit." .. unitId .. ".sig." .. sig.b .. ".name") }))
	end
	return table.concat(lines, "\n")
end

local function setLoadout(list: { string })
	request(function()
		return Net.func(Net.Functions.SetLoadout):InvokeServer(list)
	end)
end

-- Threads `kind` on `slot` (SetBead). A refusal shows its toast; success re-renders from the state.
local function setBead(unitId: string, slot: number, kind: string)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return Net.func(Net.Functions.SetBead):InvokeServer(unitId, slot, kind)
		end)
		busy = false
		if ok and type(res) == "table" and res.ok then
			beadPanel.Visible = false
		else
			local err = if ok and type(res) == "table" then res.err else nil
			ToastController.show(BEAD_ERRORS[err] or "notify.error")
		end
	end)
end

local function openBeadPicker(snapshot: any, unitId: string, slot: number)
	local t = LocaleController.t
	local rtl = LocaleController.isRtl()
	local def = (Units :: any)[unitId]
	local owned = snapshot.units[unitId]
	local current = UpgradeView.beadSlots(owned, Beads.slots, Beads.kinds)[slot].kind
	beadTitle.Text = t("units.bead_pick", { n = slot }) .. "\n" .. t("units.beads", { n = snapshot.beads or 0 })
	Theme.align(beadTitle, rtl)
	for _, c in beadList:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, choice in UpgradeView.beadChoices(UnitLogic.beadKinds(def, Beads), current) do
		local row = Theme.button({
			Name = choice.kind,
			LayoutOrder = i,
			Text = t((Beads.kinds :: any)[choice.kind].nameKey) .. (if choice.current then "  ✓" else ""),
			TextSize = 14,
			Size = UDim2.new(1, 0, 0, Theme.TOUCH),
			BackgroundColor3 = if choice.current then Theme.colors.buttonDisabled else Theme.colors.button,
			ZIndex = 15,
			Parent = beadList,
		})
		local pad = row:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingLeft = UDim.new(0, if rtl then 12 else 48)
			pad.PaddingRight = UDim.new(0, if rtl then 48 else 12)
		end
		row.TextXAlignment = if rtl then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
		local icon = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(if rtl then 0 else 1, 0.5), Position = UDim2.new(if rtl then 1 else 0, if rtl then 8 else -8, 0.5, 0), Size = UDim2.fromOffset(32, 32), ZIndex = 16, Parent = row })
		Icons.draw(IconIds.beads[choice.kind] or "bead", icon)
		row.Activated:Connect(function()
			setBead(unitId, slot, choice.kind)
		end)
	end
	beadPanel.Visible = true
	Juice.pop(beadPanel, 0.9)
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
	filterRow.Visible = false
	loadoutRow.Visible = false
	loadoutLabel.Visible = false
	local stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES)
	local card = UnitCard.create(unitId, { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(150, 210) }, { stars = stars, spin = true, zindex = 12 })
	card.Parent = detail
	local x = if rtl then 0 else 160
	-- Right of the card, one scrolling column (name, rarity, description, stats and traits, beads,
	-- rates) over a fixed bottom row (Add/Remove, reroll, back), so the 48 px buttons never collide
	-- whatever the sheet's height (MOBILE_HUD_PLAN B7).
	local col = Modal.scroller(detail)
	col.Position = UDim2.fromOffset(160, 0)
	col.Size = UDim2.new(1, -160, 1, -(Theme.TOUCH + 6))
	col.ZIndex = 13
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = col })
	Create("UIPadding", { PaddingRight = UDim.new(0, 12), Parent = col })
	local name = Theme.label({ LayoutOrder = 1, Text = t(def.nameKey), TextSize = 18, FontFace = Theme.fontBold, TextColor3 = Theme.rarityColor(def.rarity), Size = UDim2.new(1, 0, 0, 22), ZIndex = 13, Parent = col })
	local rarity = Theme.label({ LayoutOrder = 2, Text = t("rarity." .. def.rarity) .. " · " .. t("role." .. def.role) .. " · " .. t("units.stars", { n = stars }), TextSize = 13, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 16), ZIndex = 13, Parent = col })
	local desc = Theme.label({ LayoutOrder = 3, Text = t(def.descKey), TextSize = 13, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 13, Parent = col })
	local statsRow = Create("Frame", { LayoutOrder = 4, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 13, Parent = col })
	local stats = Theme.label({ Text = statLine(t, unitId, def, owned), TextSize = 13, FontFace = Theme.fontBold, Position = UDim2.fromScale(if rtl then 0.5 else 0, 0), Size = UDim2.fromScale(0.5, 0), AutomaticSize = Enum.AutomaticSize.Y, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 13, Parent = statsRow })
	local next = 0
	for _, needed in TD.STAR_COPIES do
		if owned.copies < needed then
			next = needed - owned.copies
			break
		end
	end
	local traitDef = Traits.traits[owned.trait]
	local open = slot2Open(owned)
	local second = if not open
		then t("units.trait2_locked", { n = TD.TRAIT2_STARS })
		elseif owned.trait2 and Traits.traits[owned.trait2] then t("units.trait2", { trait = t(Traits.traits[owned.trait2].nameKey) })
		else t("units.trait2_empty")
	local traitLine = Theme.label({
		Text = t("units.trait", { trait = t(traitDef.nameKey) }) .. "\n" .. second .. (if next > 0 then "\n" .. t("units.copies", { n = next }) else ""),
		TextSize = 13,
		Position = UDim2.fromScale(if rtl then 0 else 0.5, 0),
		Size = UDim2.fromScale(0.5, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = statsRow,
	})
	for _, l in { name, rarity, desc, stats, traitLine } do
		Theme.align(l, rtl)
	end
	-- Shabriyeh beads: three slots under the stats; a tap opens the picker for that slot.
	-- Always right of the card (the card stays on the left in Arabic too); only the order mirrors.
	local beadRow = Create("Frame", { Name = "Beads", LayoutOrder = 5, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 13, Parent = col })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = if rtl then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = beadRow,
	})
	local beadLabel = Theme.label({ LayoutOrder = 0, Text = t("units.beads_title") .. " (" .. tostring(snapshot.beads or 0) .. ")", TextSize = 13, FontFace = Theme.fontBold, Size = UDim2.fromOffset(84, Theme.TOUCH), ZIndex = 13, Parent = beadRow })
	Theme.align(beadLabel, rtl)
	for _, bs in UpgradeView.beadSlots(owned, Beads.slots, Beads.kinds) do
		local slotButton = Theme.button({
			Name = "BeadSlot" .. bs.slot,
			LayoutOrder = if rtl then -bs.slot else bs.slot,
			Text = if bs.kind then "" else "+",
			TextSize = 18,
			Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH),
			BackgroundColor3 = if bs.kind then Theme.colors.panelStroke else Theme.colors.buttonDisabled,
			ZIndex = 13,
			Parent = beadRow,
		})
		if bs.kind then
			local holder = Create("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(30, 30), ZIndex = 14, Parent = slotButton })
			Icons.draw(IconIds.beads[bs.kind] or "bead", holder)
		end
		slotButton.Activated:Connect(function()
			openBeadPicker(snapshot, unitId, bs.slot)
		end)
	end
	if beadPanel.Visible then
		beadPanel.Visible = false -- the state changed under it (a bead was threaded): close it
	end

	-- Rates first: the reroll is a paid random item.
	local ratesRow = Create("Frame", { LayoutOrder = 6, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Theme.TOUCH), ZIndex = 13, Parent = col })
	local rates = Theme.button({
		Text = t("units.rates"),
		TextSize = 14,
		AnchorPoint = Vector2.new(if rtl then 1 else 0, 0),
		Position = UDim2.fromScale(if rtl then 1 else 0, 0),
		Size = UDim2.fromOffset(140, Theme.TOUCH),
		BackgroundColor3 = Theme.colors.quest,
		ZIndex = 13,
		Parent = ratesRow,
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
		Size = UDim2.fromOffset(170, Theme.TOUCH),
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
	-- One reroll button per open slot (the second slot opens at TD.TRAIT2_STARS stars); with two the
	-- stone count moves up to the second trait line.
	local stones = " (" .. t("units.stones", { n = snapshot.traitStones }) .. ")"
	if open then
		traitLine.Text = t("units.trait", { trait = t(traitDef.nameKey) }) .. "\n" .. second .. stones .. (if next > 0 then "\n" .. t("units.copies", { n = next }) else "")
	end
	local slotsOpen = if open then 2 else 1
	local width = if open then 108 else 222 -- clear of the 48 px back button at a 616 px body
	for slot = 1, slotsOpen do
		local label = if not open then t("units.reroll") .. stones else t(if slot == 1 then "units.reroll1" else "units.reroll2")
		local reroll = Theme.button({
			Text = label,
			TextSize = 13,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, x + 180 + (slot - 1) * (width + 6), 1, 0),
			Size = UDim2.fromOffset(width, Theme.TOUCH),
			BackgroundColor3 = if snapshot.traitStones > 0 then Theme.rarity.epic else Theme.colors.buttonDisabled,
			ZIndex = 13,
			Parent = detail,
		})
		reroll.Activated:Connect(function()
			if snapshot.traitStones > 0 then
				request(function()
					return Net.func(Net.Functions.RerollTrait):InvokeServer(unitId, slot)
				end)
			end
		end)
	end
	local back = Theme.button({ Text = "<", TextSize = 16, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = Theme.colors.quest, ZIndex = 13, Parent = detail })
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
	beadPanel.Visible = false
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
			local hit = Button.hit({ Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = card })
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
		local def = (Units :: any)[id]
		if def and (roleFilter == nil or def.role == roleFilter) then
			table.insert(ids, id)
		end
	end
	-- Rarity first, then role (the chips' order), then the id (LP-B05).
	table.sort(ids, function(a, b)
		local da, db = (Units :: any)[a], (Units :: any)[b]
		local ra, rb = RARITY_RANK[da.rarity] or 0, RARITY_RANK[db.rarity] or 0
		if ra ~= rb then
			return ra > rb
		end
		local oa, ob = table.find(ROLE_ORDER, da.role) or 99, table.find(ROLE_ORDER, db.role) or 99
		if oa ~= ob then
			return oa < ob
		end
		return a < b
	end)
	for key, b in filterChips do
		local on = (key == "all" and roleFilter == nil) or key == roleFilter
		b.BackgroundColor3 = if on then Theme.colors.gold else Theme.colors.button
		if key == "all" then
			b.Text = t("units.filter_all")
		end
	end
	filterRow.Visible = true
	for i, id in ids do
		local def = (Units :: any)[id]
		local owned = snapshot.units[id]
		local inLoadout = table.find(snapshot.loadout, id) ~= nil
		local kind = UnitLogic.kind(def)
		local card = UnitCard.create(id, { LayoutOrder = i }, { name = t(def.nameKey), stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES), selected = inLoadout, sub = kindLine(t, def), role = def.role, reach = kind.reach })
		card.Parent = grid
		local hit = Button.hit({ Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = card })
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

-- Studio harness (DebugKeysController): open a unit's detail, its bead picker, and pick a kind.
local pickerSlot = 0
function UnitsController.debugOpen(unitId: string)
	selected = unitId
	modal.setVisible(true)
	UnitsController.render()
end
function UnitsController.debugPicker()
	local snapshot = StateController.get()
	if snapshot and selected then
		pickerSlot = (pickerSlot % Beads.slots) + 1
		openBeadPicker(snapshot, selected, pickerSlot)
	end
end
function UnitsController.debugChoose()
	local first = beadList:FindFirstChildWhichIsA("TextButton")
	if selected and first and pickerSlot > 0 then
		setBead(selected, pickerSlot, first.Name)
	end
end

function UnitsController.start()
	build()
	StateController.Changed:Connect(UnitsController.render)
	LocaleController.Changed:Connect(UnitsController.render)
	LobbyMenuController.register("units", UnitsController.open)
end

return UnitsController
