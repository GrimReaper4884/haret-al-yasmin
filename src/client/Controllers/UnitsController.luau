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
	ratesText = Theme.label({ TextSize = 14, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(0.5, -6, 0, 116), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15, Parent = ratesPanel })
	ratesText2 = Theme.label({ TextSize = 14, Position = UDim2.new(0.5, 6, 0, 44), Size = UDim2.new(0.5, -6, 0, 116), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15, Parent = ratesPanel })
	ratesSwitch = Theme.button({ TextSize = 13, Position = UDim2.fromOffset(0, 164), Size = UDim2.fromOffset(120, 32), BackgroundColor3 = Theme.colors.quest, ZIndex = 15, Visible = false, Parent = ratesPanel })
	ratesNote = Theme.label({ TextSize = 12, TextColor3 = Theme.colors.textMuted, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 44), TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 15, Parent = ratesPanel })
	local close = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Theme.colors.danger, ZIndex = 15, Parent = ratesPanel })
	close.Activated:Connect(function()
		ratesPanel.Visible = false
	end)
	-- Bead picker: the unit's kinds for one slot.
	beadPanel = Theme.panel({ Name = "BeadPicker", Size = UDim2.fromScale(1, 1), ZIndex = 14, Visible = false, Parent = body })
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 8), Parent = beadPanel })
	beadTitle = Theme.label({ TextSize = 16, FontFace = Theme.fontBold, Size = UDim2.new(1, -48, 0, 40), ZIndex = 15, Parent = beadPanel })
	beadList = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48), ZIndex = 15, Parent = beadPanel })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = beadList })
	local closeBeads = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = Theme.colors.danger, ZIndex = 15, Parent = beadPanel })
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
	-- Columns start below the close button; in Arabic the first column sits on the right, and so does the switch.
	ratesText.Position = if rtl then UDim2.new(0.5, 6, 0, 44) else UDim2.fromOffset(0, 44)
	ratesText2.Position = if rtl then UDim2.fromOffset(0, 44) else UDim2.new(0.5, 6, 0, 44)
	ratesSwitch.Position = if rtl then UDim2.new(1, -120, 0, 164) else UDim2.fromOffset(0, 164)
	for _, l in { ratesTitle, ratesText, ratesText2, ratesNote } do
		Theme.align(l, rtl)
	end
end

local function statLine(t: any, def: any, owned: any): string
	local stars = UnitLogic.stars(owned.copies, TD.STAR_COPIES)
	local trait = UnitLogic.ownedTrait(owned, Traits.traits, TD.STAR_COPIES, TD.TRAIT2_STARS)
	local st = UnitLogic.stats(def, 1, stars, trait, TD.STAR_BONUS, Traits.caps)
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
			Size = UDim2.new(1, 0, 0, Theme.TOUCH - 4),
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
	local open = slot2Open(owned)
	local second = if not open
		then t("units.trait2_locked", { n = TD.TRAIT2_STARS })
		elseif owned.trait2 and Traits.traits[owned.trait2] then t("units.trait2", { trait = t(Traits.traits[owned.trait2].nameKey) })
		else t("units.trait2_empty")
	local traitLine = Theme.label({
		Text = t("units.trait", { trait = t(traitDef.nameKey) }) .. "\n" .. second .. (if next > 0 then "\n" .. t("units.copies", { n = next }) else ""),
		TextSize = 12,
		Position = UDim2.new(0.5, if rtl then -160 else 0, 0, 86),
		Size = UDim2.new(0.5, 0, 0, 44),
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 13,
		Parent = detail,
	})
	for _, l in { name, rarity, desc, stats, traitLine } do
		Theme.align(l, rtl)
	end
	-- Shabriyeh beads: three slots under the stats; a tap opens the picker for that slot.
	local beadRow = Create("Frame", { Name = "Beads", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, 160), Size = UDim2.new(0.5, -80, 0, 42), ZIndex = 13, Parent = detail })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = if rtl then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = beadRow,
	})
	local beadLabel = Theme.label({ LayoutOrder = 0, Text = t("units.beads_title") .. " (" .. tostring(snapshot.beads or 0) .. ")", TextSize = 12, FontFace = Theme.fontBold, Size = UDim2.fromOffset(78, 40), ZIndex = 13, Parent = beadRow })
	Theme.align(beadLabel, rtl)
	for _, bs in UpgradeView.beadSlots(owned, Beads.slots, Beads.kinds) do
		local slotButton = Theme.button({
			Name = "BeadSlot" .. bs.slot,
			LayoutOrder = if rtl then -bs.slot else bs.slot,
			Text = if bs.kind then "" else "+",
			TextSize = 18,
			Size = UDim2.fromOffset(40, 40),
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
	-- One reroll button per open slot (the second slot opens at TD.TRAIT2_STARS stars); with two the
	-- stone count moves up to the second trait line.
	local stones = " (" .. t("units.stones", { n = snapshot.traitStones }) .. ")"
	if open then
		traitLine.Text = t("units.trait", { trait = t(traitDef.nameKey) }) .. "\n" .. second .. stones .. (if next > 0 then "\n" .. t("units.copies", { n = next }) else "")
	end
	local slotsOpen = if open then 2 else 1
	local width = if open then 112 else 230
	for slot = 1, slotsOpen do
		local label = if not open then t("units.reroll") .. stones else t(if slot == 1 then "units.reroll1" else "units.reroll2")
		local reroll = Theme.button({
			Text = label,
			TextSize = if open then 11 else 13,
			TextWrapped = true,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, x + 180 + (slot - 1) * (width + 6), 1, 0),
			Size = UDim2.fromOffset(width, Theme.TOUCH - 6),
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
