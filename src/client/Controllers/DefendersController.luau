--!strict
-- The Defenders panel (docs/LOOK_AND_PLAY_PLAN.md §6.1, LP-B02): the rail's Defenders button opens a
-- list of every placed defender, the player's own newest first, the party's below (read-only). A row
-- shows the portrait, name, level and one stat line (damage per second, wave income, the boost it
-- gives, with the boost it gets "+25% ·2"), then the ultimate with its cooldown, its own Auto switch,
-- Upgrade with the price, Sell in two taps (the first turns it red with the refund) and Target.
-- Tapping a portrait closes the panel, pans the watchtower to that defender and selects it (its own
-- panel keeps the level-7 path chooser). Desktop: a left column; touch: a centred sheet. Both end
-- above the cash pill, so the hotbar and the cash stay in view. Every action goes through
-- PlacementController (the same remotes and checks as the defender panel).
-- Header (LP-B03): "Auto all" on/off, sort chips (newest, cost, level) and Sell all (farms only or
-- everything, behind a second step). A row's lock keeps it out of Sell all and holds its Sell
-- button; a row whose ultimate is ready glows gold.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Hud = require(Shared.Config.Hud)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local Juice = require(UI.Juice)
local Device = require(UI.Device)
local UnitCard = require(UI.UnitCard)
local Icons = require(UI.Icons)
local ToastController = require(script.Parent.ToastController)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local MatchCameraController = require(script.Parent.MatchCameraController)
local PlacementController = require(script.Parent.PlacementController)

local DefendersController = {}

type Row = {
	frame: Frame,
	line: TextLabel,
	buttons: Frame?,
	ult: TextButton?,
	ultFill: Frame?,
	auto: TextButton?,
	upgrade: TextButton?,
	sell: TextButton?,
	target: TextButton?,
	lock: TextButton?,
	sureUntil: number,
	mine: boolean,
	ready: boolean, -- its ultimate is ready (the row glows)
}

local panel: Frame
local title: TextLabel
local count: TextLabel
local list: ScrollingFrame
local empty: TextLabel
local rows: { [number]: Row } = {}
local alliesHeader: TextLabel
local open = false
local dirty = true
local touchShape: boolean? = nil -- the shape the rows were built for
local controls: Frame -- Auto all, the sort chips, Sell all
local confirmRow: Frame -- Sell all's second step: farms only / everything / cancel
local autoAll: TextButton
local sortChips: { [string]: TextButton } = {}
local sellAll: TextButton
local locked: { [number]: boolean } = {} -- client-side locks (no remote): out of Sell all
local sortMode = "placed" -- "placed" | "cost" | "level"
local SORTS = { "placed", "cost", "level" }
local batching = false -- Auto all or Sell all is sending its requests

local function round(n: number): number
	return math.floor(n + 0.5)
end

local function cfg()
	return Hud.DEFENDERS
end

local function shapeKey(): "touch" | "desktop"
	return if Device.isTouch() then "touch" else "desktop"
end

-- A GUI object's box in the HUD's design px.
local function box(gui: GuiObject): (number, number, number, number)
	local screen = Root.get()
	local s = Device.scale()
	local x0 = (gui.AbsolutePosition.X - screen.AbsolutePosition.X) / s
	local y0 = (gui.AbsolutePosition.Y - screen.AbsolutePosition.Y) / s
	return x0, y0, x0 + gui.AbsoluteSize.X / s, y0 + gui.AbsoluteSize.Y / s
end

-- Places the panel (design px). Desktop: a left column from under the top clear down to the bottom
-- margin, narrowed so it never reaches the hotbar or the cash pill (if it can't be narrow enough it
-- ends above them). Touch: a centred sheet between the rails, ending above the cash pill.
local function layout()
	local c = cfg()
	local bh = c.button[shapeKey()]
	controls.Size = UDim2.new(1, -12, 0, bh)
	confirmRow.Size = controls.Size
	list.Position = UDim2.fromOffset(6, c.header + bh + 2 * c.gap + 6)
	list.Size = UDim2.new(1, -12, 1, -(c.header + bh + 2 * c.gap + 12))
	local design = Device.designSize()
	local pill = MatchController.cashPill()
	local hotbar = PlacementController.hotbar()
	local pillTop = design.y - 120
	local leftmost = design.x
	if pill then
		local px0, py0 = box(pill)
		pillTop, leftmost = py0, px0
	end
	if hotbar and hotbar.Visible then
		local hx0, hy0 = box(hotbar)
		pillTop = math.min(pillTop, hy0)
		leftmost = math.min(leftmost, hx0)
	end
	local railW = Hud.RAIL.margin + 2 * Hud.RAIL.button + Hud.RAIL.gap
	if Device.profile() == "touch-phone" then
		-- A phone is too short to end above the cash pill: like the defender sheet, the sheet takes the
		-- hotbar's band (the hotbar, the cash pill and the thumbstick hide while it is open; the cash
		-- shows in its header).
		local w = math.min(Hud.SHEET_MAX_W, design.x - 2 * (railW + c.gap))
		local top, bottom = Hud.TOP_CLEAR, design.y - Hud.SHEET_MARGIN
		panel.Position = UDim2.fromOffset((design.x - w) / 2, top)
		panel.Size = UDim2.fromOffset(w, bottom - top)
	elseif Device.isTouch() then
		local w = math.min(Hud.SHEET_MAX_W, design.x - 2 * (railW + c.gap))
		local bottom = pillTop - c.gap
		local top = math.max(Hud.TOP_CLEAR, bottom - design.y * c.heightFrac)
		panel.Position = UDim2.fromOffset((design.x - w) / 2, top)
		panel.Size = UDim2.fromOffset(w, bottom - top)
	else
		local x = Hud.RAIL.margin
		local top = Hud.TOP_CLEAR + 40
		local room = leftmost - 2 * c.gap - x
		local w = math.min(c.width, design.x / 2 - railW)
		local bottom = design.y - Hud.RAIL.margin
		if room >= c.width * 0.75 then
			w = math.min(w, room)
		else
			bottom = pillTop - c.gap
		end
		panel.Position = UDim2.fromOffset(x, top)
		panel.Size = UDim2.fromOffset(w, bottom - top)
	end
end

local function clearRows()
	for _, r in rows do
		r.frame:Destroy()
	end
	table.clear(rows)
end

local function smallButton(parent: Instance, order: number, color: Color3, grow: number): TextButton
	local b = Theme.button({ LayoutOrder = order, Text = "", TextSize = 14, Size = UDim2.new(0, 36, 1, 0), BackgroundColor3 = color, ZIndex = 8, Parent = parent })
	local pad = b:FindFirstChildOfClass("UIPadding")
	if pad then
		pad.PaddingLeft = UDim.new(0, 3)
		pad.PaddingRight = UDim.new(0, 3)
	end
	b.TextWrapped = true
	Create("UIFlexItem", { FlexMode = Enum.UIFlexMode.Grow, GrowRatio = grow, Parent = b })
	return b
end

local function buildRow(info: PlacementController.TowerInfo): Row
	local c = cfg()
	local shape = shapeKey()
	local h, ph, bh, lh = c.row[shape], c.portrait[shape], c.button[shape], c.line[shape]
	local frame = Create("Frame", {
		Name = "Tower_" .. info.id,
		Size = UDim2.new(1, -6, 0, if info.mine then h else ph + 8),
		BackgroundColor3 = Theme.colors.panelStroke,
		BackgroundTransparency = 0.88,
		ZIndex = 7,
		Parent = list,
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	-- The portrait: a tap focuses the watchtower on this defender and opens its own panel.
	local face = Create("TextButton", { Name = "Focus", Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(ph, ph), ZIndex = 8, Parent = frame })
	local portrait = UnitCard.portrait(info.unitId, { Size = UDim2.fromScale(1, 1), ZIndex = 8 })
	portrait.Parent = face
	local id = info.id
	face.Activated:Connect(function()
		DefendersController.close()
		MatchCameraController.focus(info.x, info.z)
		PlacementController.focus(id)
	end)
	local x0 = ph + 10
	local line = Theme.label({ Name = "Line", RichText = true, TextSize = if shape == "touch" then 15 else 13, FontFace = Theme.fontBold, LineHeight = 1.05, Position = UDim2.fromOffset(x0, 4), Size = UDim2.new(1, -(x0 + 4), 0, if info.mine then lh else ph), TextWrapped = false, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 8, Parent = frame })
	line.TextTruncate = Enum.TextTruncate.AtEnd
	local row: Row = { frame = frame, line = line, sureUntil = 0, mine = info.mine, ready = false }
	if not info.mine then
		return row
	end
	local buttons = Create("Frame", { Name = "Buttons", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, x0, 1, -4), Size = UDim2.new(1, -(x0 + 4), 0, bh), BackgroundTransparency = 1, ZIndex = 8, Parent = frame })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = buttons })
	row.buttons = buttons
	local def = (Units :: any)[info.unitId]
	if def and def.ability then
		local ult = smallButton(buttons, 1, Theme.lira, 1)
		ult.ClipsDescendants = true
		row.ultFill = Create("Frame", { Name = "Cooldown", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 8, Parent = ult })
		ult.Activated:Connect(function()
			if PlacementController.useUltimate(id) then
				Juice.punch(ult)
			else
				Juice.shake(ult)
			end
		end)
		local auto = smallButton(buttons, 2, Theme.colors.confirm, 1)
		auto.Activated:Connect(function()
			for _, t in PlacementController.list() do
				if t.id == id then
					PlacementController.setAuto(id, not t.auto)
					break
				end
			end
		end)
		row.ult, row.auto = ult, auto
	end
	local upgrade = smallButton(buttons, 3, Theme.colors.confirm, 1.4)
	upgrade.Activated:Connect(function()
		local state = MatchController.state()
		for _, t in PlacementController.list() do
			if t.id == id then
				if t.step == "level" and t.nextCost and state and state.cash < t.nextCost then
					Juice.shake(frame)
					return
				end
				if t.step == "max" then
					return
				end
				PlacementController.upgrade(id)
				if t.step == "choose" then
					DefendersController.close()
				end
				break
			end
		end
	end)
	local sell = smallButton(buttons, 4, Theme.colors.danger, 1.2)
	sell.Activated:Connect(function()
		if locked[id] then
			Juice.shake(sell)
			ToastController.show("defenders.locked")
			return
		end
		if os.clock() < row.sureUntil then
			row.sureUntil = 0
			PlacementController.sell(id)
		else
			row.sureUntil = os.clock() + c.sellConfirmS
			dirty = true
			Juice.punch(sell)
		end
	end)
	row.upgrade, row.sell = upgrade, sell
	local lock = smallButton(buttons, 6, Theme.colors.textMuted, 0.8)
	local lockIcon = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 9, Parent = lock })
	Icons.draw("ui_lock", lockIcon)
	for _, d in lockIcon:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = 9
		end
	end
	lock.Activated:Connect(function()
		if locked[id] then
			locked[id] = nil
		else
			locked[id] = true
		end
		row.sureUntil = 0
		dirty = true
		Juice.punch(lock)
	end)
	row.lock = lock
	if def and def.levels[1].damage > 0 then
		local target = smallButton(buttons, 5, Theme.colors.quest, 1.2)
		target.Activated:Connect(function()
			PlacementController.cycleTarget(id)
		end)
		row.target = target
	end
	return row
end

local function statText(info: PlacementController.TowerInfo): string
	local t = LocaleController.t
	local parts = {}
	if info.damage > 0 then
		table.insert(parts, t("defenders.dps", { n = round(info.damage * info.buff / math.max(info.cooldown, 0.05)) }))
		if info.buff > 1 then
			local n = round((info.buff - 1) * 100)
			local boost = if info.buffCount > 1 then t("defenders.buffed", { n = n, k = info.buffCount }) else t("defenders.buffed_one", { n = n })
			table.insert(parts, '<font color="#3E9A2E">' .. boost .. "</font>")
		end
	end
	if info.income then
		table.insert(parts, t("defenders.income", { n = info.income }))
	end
	if info.supportBuff then
		table.insert(parts, t("defenders.gives", { n = round((info.supportBuff - 1) * 100) }))
	end
	if info.heal then
		table.insert(parts, t("defenders.heals", { n = info.heal }))
	end
	return table.concat(parts, "  ·  ")
end

-- Brings the rows in line with the placed defenders: new ones get a row, sold ones lose theirs,
-- every row's texts and states follow (cash, cooldowns, auto, targeting).
local function sync()
	local t = LocaleController.t
	local shape = Device.isTouch()
	if touchShape ~= shape then
		clearRows()
		touchShape = shape
	end
	local infos = PlacementController.list()
	-- The player's own first; within them the chosen order (newest is the list's own order).
	if sortMode ~= "placed" then
		table.sort(infos, function(a, b)
			if a.mine ~= b.mine then
				return a.mine
			end
			local ka = if sortMode == "cost" then a.refund else a.level
			local kb = if sortMode == "cost" then b.refund else b.level
			if ka ~= kb then
				return ka > kb
			end
			return a.id > b.id
		end)
	end
	local seen: { [number]: boolean } = {}
	local autoCount, autoOn = 0, 0
	local state = MatchController.state()
	local cash = if state then state.cash else 0
	local mineCount, others = 0, 0
	for i, info in infos do
		seen[info.id] = true
		local row = rows[info.id]
		if not row then
			row = buildRow(info)
			rows[info.id] = row
		end
		if info.mine then
			mineCount += 1
		else
			others += 1
		end
		row.frame.LayoutOrder = if info.mine then i else 1000 + i
		local def = (Units :: any)[info.unitId]
		local name = if def then t(def.nameKey) else info.unitId
		local head = "<b>" .. name .. "</b>  " .. t("defenders.level", { n = info.level, max = info.maxLevel })
		if info.signature then
			head ..= "  ★ " .. t(info.signature)
		end
		if not info.mine then
			head ..= "  ·  " .. info.owner
		end
		local stat = statText(info)
		row.line.Text = if stat ~= "" then head .. "\n" .. stat else head
		Theme.align(row.line, LocaleController.isRtl())
		if row.ult and row.auto then
			autoCount += 1
			autoOn += if info.auto then 1 else 0
			row.ult.Text = t("defenders.ult")
			row.auto.Text = t("match.ult_auto") .. "\n" .. (if info.auto then t("settings.on") else t("settings.off"))
			row.auto.BackgroundColor3 = if info.auto then Theme.colors.confirm else Theme.colors.buttonDisabled
		end
		if row.upgrade then
			if info.step == "level" and info.nextCost then
				row.upgrade.Text = t("defenders.up", { n = info.nextCost })
				row.upgrade.BackgroundColor3 = if cash >= info.nextCost then Theme.colors.confirm else Theme.colors.buttonDisabled
			elseif info.step == "choose" then
				row.upgrade.Text = t("defenders.choose")
				row.upgrade.BackgroundColor3 = Theme.colors.gold
			else
				row.upgrade.Text = t("defenders.max")
				row.upgrade.BackgroundColor3 = Theme.colors.buttonDisabled
			end
		end
		if row.sell then
			local sure = os.clock() < row.sureUntil
			row.sell.Text = if sure then t("defenders.sell_sure", { n = info.refund }) else t("defenders.sell")
			row.sell.BackgroundColor3 = if locked[info.id] then Theme.colors.buttonDisabled elseif sure then Color3.fromHex("#E0402F") else Theme.colors.danger
		end
		if row.lock then
			row.lock.BackgroundColor3 = if locked[info.id] then Theme.colors.gold else Theme.colors.textMuted
		end
		if row.target then
			row.target.Text = t("target." .. info.targeting)
		end
	end
	for id, row in rows do
		if not seen[id] then
			row.frame:Destroy()
			rows[id] = nil
			locked[id] = nil
		end
	end
	autoAll.Text = t("defenders.auto_all", { state = if autoCount > 0 and autoOn == autoCount then t("settings.on") else t("settings.off") })
	autoAll.BackgroundColor3 = if autoCount > 0 and autoOn == autoCount then Theme.colors.confirm else Theme.colors.buttonDisabled
	for _, key in SORTS do
		local chip = sortChips[key]
		chip.Text = t("defenders.sort_" .. key)
		chip.BackgroundColor3 = if key == sortMode then Theme.colors.gold else Theme.colors.button
	end
	sellAll.Text = t("defenders.sell_all")
	title.Text = t("defenders.title")
	count.Text = t("defenders.count", { n = mineCount, max = TD.TOWER_CAP }) .. "  ·  " .. t("defenders.cash", { n = cash })
	alliesHeader.Text = t("defenders.allies")
	alliesHeader.Visible = others > 0
	empty.Text = t("defenders.empty")
	empty.Visible = mineCount == 0
	local rtl = LocaleController.isRtl()
	Theme.align(title, rtl)
	Theme.align(count, rtl)
	Theme.align(alliesHeader, rtl)
end

-- The cooldown fill of every ultimate, and the Sell buttons whose "Sure?" ran out.
local function tick()
	local now = os.clock()
	local infos: { PlacementController.TowerInfo }? = nil
	for id, row in rows do
		local fill = row.ultFill
		if fill and row.ult then
			infos = infos or PlacementController.list()
			for _, info in infos :: { PlacementController.TowerInfo } do
				if info.id == id then
					local total = info.abilityCooldown or 1
					local left = math.max(0, info.readyAt - now)
					fill.Size = UDim2.fromScale(math.clamp(left / total, 0, 1), 1)
					row.ult.BackgroundColor3 = if left <= 0 then Theme.lira else Theme.colors.buttonDisabled
					row.ready = left <= 0
					break
				end
			end
		end
		if row.sureUntil > 0 and now >= row.sureUntil then
			row.sureUntil = 0
			dirty = true
		end
		-- A ready ultimate: the row glows gold (a slow pulse; steady without motion).
		if row.ready then
			local k = if Juice.allowed("shine") then 0.5 + 0.5 * math.sin(now * 2 * math.pi / cfg().pulseS) else 1
			row.frame.BackgroundColor3 = Theme.colors.gold
			row.frame.BackgroundTransparency = 0.82 - 0.3 * k
		else
			row.frame.BackgroundColor3 = Theme.colors.panelStroke
			row.frame.BackgroundTransparency = 0.88
		end
	end
end

-- Sends one request per defender, `gap` apart (the server's buckets never see a burst).
local function batch(ids: { number }, send: (number) -> ())
	if batching then
		return
	end
	batching = true
	task.spawn(function()
		for _, id in ids do
			local t0 = os.clock()
			while PlacementController.busy() and os.clock() - t0 < 3 do
				task.wait(0.05)
			end
			send(id)
			task.wait(cfg().batchGapS)
		end
		batching = false
		dirty = true
	end)
end

-- Auto all: every one of the player's ultimates on, or (when all are on already) off.
local function toggleAutoAll()
	local infos = PlacementController.list()
	local any, allOn = false, true
	for _, info in infos do
		if info.mine and info.abilityCooldown then
			any = true
			allOn = allOn and info.auto
		end
	end
	if not any then
		return
	end
	local want = not allOn
	local ids = {}
	for _, info in infos do
		if info.mine and info.abilityCooldown and info.auto ~= want then
			table.insert(ids, info.id)
		end
	end
	batch(ids, function(id)
		PlacementController.setAuto(id, want)
	end)
end

-- Sell all: the player's unlocked defenders (farms only, or every one).
local function sellAllOf(farmsOnly: boolean)
	local ids = {}
	for _, info in PlacementController.list() do
		if info.mine and not locked[info.id] and (not farmsOnly or info.role == "farm") then
			table.insert(ids, info.id)
		end
	end
	batch(ids, PlacementController.sell)
end

local function showConfirm(on: boolean)
	controls.Visible = not on
	confirmRow.Visible = on
end

-- On a phone the sheet holds the bottom band: the hotbar, the cash pill and the thumbstick step aside.
local function holdBand(on: boolean)
	local phone = on and Device.profile() == "touch-phone"
	PlacementController.hideBar("defenders", phone)
	MatchController.setCashHidden(phone)
	Device.blockTouchControls("defenders", phone)
end

function DefendersController.close()
	if not open then
		return
	end
	open = false
	panel.Visible = false
	showConfirm(false)
	holdBand(false)
end

function DefendersController.open()
	if not MatchController.active() then
		return
	end
	PlacementController.deselect()
	open = true
	holdBand(true)
	layout()
	dirty = false
	sync()
	panel.Visible = true
	Juice.pop(panel, 0.9)
end

function DefendersController.toggle()
	if open then
		DefendersController.close()
	else
		DefendersController.open()
	end
end

function DefendersController.isOpen(): boolean
	return open
end

local function build()
	local c = cfg()
	panel = Theme.panel({ Name = "DefendersPanel", Size = UDim2.fromOffset(c.width, 300), Visible = false, Active = true, ZIndex = 6, Parent = Root.get() })
	title = Theme.display({ Name = "Title", TextSize = 18, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24 - Theme.TOUCH, 0, 22), ZIndex = 7, Parent = panel })
	count = Theme.label({ Name = "Count", TextSize = 14, FontFace = Theme.fontBold, TextColor3 = Theme.colors.textMuted, Position = UDim2.fromOffset(12, 26), Size = UDim2.new(1, -24 - Theme.TOUCH, 0, 16), ZIndex = 7, Parent = panel })
	local close = Theme.button({ Name = "Close", Text = "X", TextSize = 18, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(Theme.TOUCH, Theme.TOUCH), BackgroundColor3 = Theme.colors.danger, ZIndex = 8, Parent = panel })
	local pad = close:FindFirstChildOfClass("UIPadding")
	if pad then
		pad:Destroy()
	end
	close.Activated:Connect(DefendersController.close)
	-- The header's controls and Sell all's second step share one line under the title.
	local function line(name: string): Frame
		local f = Create("Frame", { Name = name, Position = UDim2.fromOffset(6, c.header + c.gap), Size = UDim2.new(1, -12, 0, c.button.desktop), BackgroundTransparency = 1, ZIndex = 7, Parent = panel })
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f })
		return f
	end
	controls = line("Controls")
	autoAll = smallButton(controls, 1, Theme.colors.confirm, 1.4)
	autoAll.Activated:Connect(toggleAutoAll)
	for i, key in SORTS do
		local chip = smallButton(controls, 1 + i, Theme.colors.button, 1)
		chip.Activated:Connect(function()
			sortMode = key
			dirty = true
		end)
		sortChips[key] = chip
	end
	sellAll = smallButton(controls, 5, Theme.colors.danger, 1.2)
	sellAll.Activated:Connect(function()
		showConfirm(true)
	end)
	confirmRow = line("SellAllConfirm")
	confirmRow.Visible = false
	local farms = smallButton(confirmRow, 1, Theme.colors.danger, 1.4)
	local every = smallButton(confirmRow, 2, Color3.fromHex("#E0402F"), 1.4)
	local cancel = smallButton(confirmRow, 3, Theme.colors.button, 1)
	farms.Activated:Connect(function()
		showConfirm(false)
		sellAllOf(true)
	end)
	every.Activated:Connect(function()
		showConfirm(false)
		sellAllOf(false)
	end)
	cancel.Activated:Connect(function()
		showConfirm(false)
	end)
	local function confirmTexts()
		local t = LocaleController.t
		farms.Text = t("defenders.sell_farms")
		every.Text = t("defenders.sell_every")
		cancel.Text = t("match.cancel")
	end
	confirmTexts()
	LocaleController.Changed:Connect(confirmTexts)
	list = Create("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromOffset(6, c.header + 12),
		Size = UDim2.new(1, -12, 1, -(c.header + 18)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.colors.panelStroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 7,
		Parent = panel,
	})
	Create("UIListLayout", { Padding = UDim.new(0, c.gap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	empty = Theme.label({ Name = "Empty", LayoutOrder = 0, TextSize = 14, TextWrapped = true, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, -6, 0, 40), ZIndex = 7, Parent = list })
	alliesHeader = Theme.label({ Name = "Allies", LayoutOrder = 1000, TextSize = 14, FontFace = Theme.fontBold, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, -6, 0, 20), Visible = false, ZIndex = 7, Parent = list })
end

function DefendersController.start()
	build()
	MatchController.onDefenders = DefendersController.toggle
	PlacementController.Changed:Connect(function()
		dirty = true
	end)
	MatchController.Updated:Connect(function()
		dirty = true
	end)
	MatchController.Started:Connect(function()
		DefendersController.close()
		clearRows()
	end)
	MatchController.Ended:Connect(function()
		DefendersController.close()
	end)
	LocaleController.Changed:Connect(function()
		dirty = true
	end)
	Device.Changed:Connect(function()
		if open then
			holdBand(true)
			layout()
			dirty = true
		end
	end)
	-- One pass ten times a second, only while open: re-sync when something changed, and the fills.
	task.spawn(function()
		while true do
			task.wait(0.1)
			if open then
				if dirty then
					dirty = false
					sync()
				end
				tick()
			end
		end
	end)
	-- A defender selected on the field takes the left column back (its own panel).
	PlacementController.Selected:Connect(function()
		DefendersController.close()
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		DefendersController.close()
	end)
end

return DefendersController
