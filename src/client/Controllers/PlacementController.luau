--!strict
-- Placing and managing defenders during a match: the loadout bar, a ghost that follows the
-- cursor/finger over the arena ground (green/red for valid/invalid, with its range ring), tap to
-- place, tap a placed defender to open its panel (upgrade, sell, targeting). Validity shown here
-- is a preview: the server re-checks every rule.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Looks = require(Shared.Config.CharacterLooks)
local Arenas = require(Shared.Config.Arenas)
local Vfx = require(Shared.Config.Vfx)
local Traits = require(Shared.Config.Traits)
local Path = require(Shared.Logic.Path)
local UnitLogic = require(Shared.Logic.UnitLogic)
local UpgradeView = require(Shared.Logic.UpgradeView)
local RigBuilder = require(Shared.Util.RigBuilder)
local BoneAnim = require(Shared.Anim.BoneAnim)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Icons = require(UI.Icons)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local UnitCard = require(UI.UnitCard)
local Juice = require(UI.Juice)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local ToastController = require(script.Parent.ToastController)
local SettingsController = require(script.Parent.SettingsController)
local RigAnimController = require(script.Parent.RigAnimController)
local EnemyRenderController = require(script.Parent.EnemyRenderController)

local PlacementController = {}

local TARGETING = { "first", "last", "strong", "close" }

local bar: Frame
local placeHint: TextLabel
local cancelButton: TextButton
local towerPanel: Frame
local towerPortrait: Frame
local towerTitle: TextLabel
local towerLevel: TextLabel
local towerOwner: TextLabel
local towerStats: TextLabel
local upgradeButton: TextButton
local sigRow: Frame -- the level-7 chooser: two path cards over the Upgrade button (S1-C04)
local sigCards: { [string]: TextButton } = {}
local sigPick: string? = nil -- the path card tapped on the selected defender, confirmed by Upgrade
local sellButton: TextButton
local targetButton: TextButton
local closeButton: TextButton
local ultRow: Frame
local ultButton: TextButton
local ultFill: Frame
local autoButton: TextButton

-- One slot per loadout unit, built once per match/loadout (a 3D portrait each), then only
-- re-tinted as cash changes.
type Slot = { frame: Frame, cost: TextLabel, count: TextLabel, dim: Frame, stroke: UIStroke, unitId: string, price: number }
local slots: { Slot } = {}
local slotKey = ""
local ghostLight: Highlight? = nil

local pickSlot: (unitId: string, price: number, frame: Frame) -> ()
local placing: string? = nil
local ghost: Model? = nil
local ring: Part? = nil
local selected: number? = nil
local selectedRing: Part? = nil
local towers: { [number]: { unitId: string, level: number, owner: string, x: number, z: number, range: number, targeting: string, readyAt: number, buff: number?, revealedBy: string?, revealedByTower: number?, sabotaged: boolean?, path: string? } } = {}
local arenaPath: Path.Path? = nil
local arenaPaths: { Path.Path } = {} -- every road: the ghost keeps clear of all of them (S1-S07)
local origin: CFrame? = nil
local busy = false

local function build()
	local root = Root.get()
	bar = Create("Frame", { Name = "UnitBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(7 * 74, 92), BackgroundTransparency = 1, Active = true, Visible = false, ZIndex = 3, Parent = root })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	placeHint = Theme.display({ Name = "PlaceHint", TextSize = 16, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.new(0.8, 0, 0, 22), Visible = false, ZIndex = 3, Parent = root })
	placeHint.TextXAlignment = Enum.TextXAlignment.Center
	cancelButton = Theme.button({ Name = "CancelPlace", Text = "X", TextSize = 22, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.5, 7 * 74 / 2 + 8, 1, -24), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Theme.colors.danger, Visible = false, ZIndex = 4, Parent = root })

	-- Tower panel: left edge, away from the bar (docs/research/ROBLOX_TD_UI_PATTERNS.md §1).
	towerPanel = Theme.panel({ Name = "TowerPanel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 6), Size = UDim2.fromOffset(232, 0), AutomaticSize = Enum.AutomaticSize.Y, Active = true, Visible = false, ZIndex = 4, Parent = root })
	Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = towerPanel })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = towerPanel })
	local header = Create("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, ZIndex = 4, Parent = towerPanel })
	towerPortrait = Create("Frame", { Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, ZIndex = 4, Parent = header })
	towerTitle = Theme.display({ TextSize = 16, Position = UDim2.fromOffset(62, 0), Size = UDim2.new(1, -90, 0, 36), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, Parent = header })
	towerTitle.TextXAlignment = Enum.TextXAlignment.Left
	towerLevel = Theme.display({ TextSize = 14, TextColor3 = Color3.fromHex("#FFD970"), Position = UDim2.fromOffset(62, 38), Size = UDim2.new(1, -62, 0, 18), ZIndex = 5, Parent = header })
	towerLevel.TextXAlignment = Enum.TextXAlignment.Left
	closeButton = Theme.button({ Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 4, 0, -4), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.colors.danger, ZIndex = 6, Parent = header })
	local cp = closeButton:FindFirstChildOfClass("UIPadding")
	if cp then
		cp:Destroy()
	end
	towerOwner = Theme.label({ LayoutOrder = 2, TextSize = 12, FontFace = Theme.fontBold, TextColor3 = Theme.colors.textMuted, Size = UDim2.new(1, 0, 0, 14), Visible = false, ZIndex = 4, Parent = towerPanel })
	towerStats = Theme.label({ LayoutOrder = 3, TextSize = 14, FontFace = Theme.fontBold, RichText = true, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.15, ZIndex = 4, Parent = towerPanel })
	-- Level 7 (STORY_PLAN §7.1): at the last level a unit with a signature offers two path cards; one
	-- tap picks, Upgrade confirms (UpgradeTower with the path; the server re-checks everything).
	sigRow = Create("Frame", { Name = "Signature", LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 92), BackgroundTransparency = 1, Visible = false, ZIndex = 4, Parent = towerPanel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sigRow })
	for i, pathKey in { "a", "b" } do
		local card = Theme.button({ Name = "Path_" .. pathKey, LayoutOrder = i, Text = "", Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.button, ZIndex = 4, Parent = sigRow })
		local pad = card:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingLeft = UDim.new(0, 5)
			pad.PaddingRight = UDim.new(0, 5)
		end
		local nameLabel = Theme.display({ Name = "PathName", TextSize = 14, Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 18), ZIndex = 5, Parent = card })
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		local descLabel = Theme.label({ Name = "PathDesc", TextSize = 11, TextColor3 = Color3.fromHex("#FFF1D0"), Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 1, -46), TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5, Parent = card })
		descLabel.TextXAlignment = Enum.TextXAlignment.Center
		local costLabel = Theme.display({ Name = "PathCost", TextSize = 13, TextColor3 = Color3.fromHex("#FFD970"), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 16), ZIndex = 5, Parent = card })
		costLabel.TextXAlignment = Enum.TextXAlignment.Center
		sigCards[pathKey] = card
	end
	upgradeButton = Theme.button({ LayoutOrder = 5, TextSize = 17, Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = Theme.colors.confirm, ZIndex = 4, Parent = towerPanel })
	local row = Create("Frame", { LayoutOrder = 6, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 4, Parent = towerPanel })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Parent = row })
	targetButton = Theme.button({ TextSize = 13, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.quest, ZIndex = 4, Parent = row })
	sellButton = Theme.button({ TextSize = 13, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = Theme.colors.danger, ZIndex = 4, Parent = row })
	-- Ultimate: the button fills back up as the cooldown recovers; Auto fires it when ready.
	ultRow = Create("Frame", { LayoutOrder = 7, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ZIndex = 4, Parent = towerPanel })
	ultButton = Theme.button({ TextSize = 14, Size = UDim2.new(1, -62, 1, 0), BackgroundColor3 = Theme.lira, ClipsDescendants = true, ZIndex = 4, Parent = ultRow })
	ultFill = Create("Frame", { Name = "Cooldown", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 4, Parent = ultButton })
	autoButton = Theme.button({ TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 56, 1, 0), ZIndex = 4, Parent = ultRow })
	for _, b in { targetButton, sellButton, ultButton, autoButton } do
		local pad = b:FindFirstChildOfClass("UIPadding")
		if pad then
			pad.PaddingLeft = UDim.new(0, 4)
			pad.PaddingRight = UDim.new(0, 4)
		end
		b.TextWrapped = true
	end
end

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if ring then
		ring:Destroy()
		ring = nil
	end
	ghostLight = nil
	placing = nil
	placeHint.Visible = false
	cancelButton.Visible = false
	for _, slot in slots do
		slot.stroke.Color = Theme.colors.outline
		slot.stroke.Thickness = 2.5
		slot.frame.Position = UDim2.fromOffset(0, 0)
	end
end

local function clearSelection()
	selected = nil
	sigPick = nil
	EnemyRenderController.setSelectedTower(nil)
	towerPanel.Visible = false
	if selectedRing then
		selectedRing:Destroy()
		selectedRing = nil
	end
end

-- The range preview (PV-B05): a soft disc with an ablaq edge of alternating basalt and cream
-- dashes, welded to the disc so moving the disc (the ghost follows the cursor) carries the edge.
local function makeRing(radius: number, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = "RangeRing"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.1, radius * 2, radius * 2)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.85
	local cfg = Vfx.TOWER
	local n = cfg.dashes
	local len = 2 * math.pi * radius / n * 0.8
	for i = 1, n do
		local a = (i - 1) / n * 2 * math.pi
		local d = Instance.new("Part")
		d.Name = "Dash"
		d.Anchored = false
		d.Massless = true
		d.CanCollide = false
		d.CanQuery = false
		d.CanTouch = false
		d.CastShadow = false
		d.Material = Enum.Material.SmoothPlastic
		d.Color = Color3.fromHex(if i % 2 == 0 then cfg.dashDark else cfg.dashLight)
		d.Size = Vector3.new(0.14, 0.32, len)
		-- The disc's axis is its local X; the edge lies in its local Y/Z plane.
		d.CFrame = p.CFrame * CFrame.new(0, radius * math.cos(a), radius * math.sin(a)) * CFrame.Angles(a, 0, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = p
		w.Part1 = d
		w.Parent = d
		d.Parent = p
	end
	p.Parent = Workspace
	return p
end

-- My merged trait for a unit (both slots once the second is open), as the server places it.
local function myTrait(unitId: string): any?
	local snapshot = StateController.get()
	local owned = snapshot and snapshot.units[unitId]
	return UnitLogic.ownedTrait(owned, Traits.traits, TD.STAR_COPIES, TD.TRAIT2_STARS)
end

-- A price as the server charges it (the miser trait pays less).
local function myCost(unitId: string, cost: number): number
	return UnitLogic.costFor(cost, myTrait(unitId))
end

local function myStats(unitId: string, level: number, path: string?)
	local snapshot = StateController.get()
	local def = (Units :: any)[unitId]
	local owned = snapshot and snapshot.units[unitId]
	local stars = if owned then UnitLogic.stars(owned.copies, TD.STAR_COPIES) else 0
	return UnitLogic.stats(def, level, stars, myTrait(unitId), TD.STAR_BONUS, Traits.caps, path)
end

function PlacementController.begin(unitId: string)
	clearSelection()
	clearGhost()
	local def = (Units :: any)[unitId]
	if not def or not origin then
		return
	end
	placing = unitId
	ghost = RigBuilder.build(Workspace, "Ghost", def.visual, unitId)
	RigBuilder.setTransparency(ghost :: Model, 0.35)
	local hl = Instance.new("Highlight")
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.Parent = ghost
	ghostLight = hl
	-- Imported figures show their T-pose bind pose unless a clip plays; the ghost isn't in a
	-- towers folder, so hand it to RigAnimController (baked clips) or play its published idle.
	local look = (Looks :: any)[unitId]
	local animator = (ghost :: Model):FindFirstChildWhichIsA("Animator", true)
	if (ghost :: Model):GetAttribute("Imported") and BoneAnim.has(unitId) then
		RigAnimController.adopt(ghost :: Model)
	elseif animator and look and look.anims and look.anims.idle then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(look.anims.idle)
		pcall(function()
			local t = (animator :: Animator):LoadAnimation(anim)
			t.Looped = true
			t:Play(0)
		end)
	end
	cancelButton.Visible = true
	for _, slot in slots do
		local on = slot.unitId == unitId
		slot.stroke.Color = if on then Theme.colors.gold else Theme.colors.outline
		slot.stroke.Thickness = if on then 3.5 else 2.5
		slot.frame.Position = UDim2.fromOffset(0, if on then -8 else 0)
	end
	local st = myStats(unitId, 1)
	ring = makeRing(st.range, Theme.colors.quest)
	placeHint.Visible = true
	placeHint.Text = LocaleController.t("match.place", { unit = LocaleController.t(def.nameKey) })
end

-- Raycast from the screen position onto the arena ground. Returns the world hit, or nil.
local function groundHit(screen: Vector2): (Vector3?, Instance?)
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil, nil
	end
	-- InputObject / TouchTap positions exclude the top-bar inset, so use the Screen variant
	local unitRay = camera:ScreenPointToRay(screen.X, screen.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = { Players.LocalPlayer.Character :: Instance?, ghost, ring, selectedRing }
	local list = {}
	for _, v in exclude do
		if v then
			table.insert(list, v)
		end
	end
	local render = Workspace:FindFirstChild("EnemyRender")
	if render then
		table.insert(list, render)
	end
	params.FilterDescendantsInstances = list
	local hit = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 600, params)
	if hit then
		return hit.Position, hit.Instance
	end
	return nil, nil
end

local function valid(x: number, z: number): (boolean, string?)
	local info = MatchController.info()
	if not info or not arenaPath then
		return false, nil
	end
	local b = Arenas[info.arenaId].bounds
	if x < b[1] or x > b[3] or z < b[2] or z > b[4] then
		return false, "out_of_bounds"
	end
	if Path.distanceToAll(arenaPaths, x, z) < TD.PATH_HALF_WIDTH then
		return false, "on_path"
	end
	for _, t in towers do
		if (t.x - x) ^ 2 + (t.z - z) ^ 2 < TD.TOWER_SPACING * TD.TOWER_SPACING then
			return false, "too_close"
		end
	end
	return true, nil
end

-- The defender drawn under a screen point: distance from the point to each defender's on-screen
-- body (feet to head), so a click on a torso or head works from the low walking camera too. Rig
-- parts are not queryable, so a raycast alone only finds the ground behind them.
local PICK_PX = 34
local PICK_HEIGHT = 5
local function towerAtScreen(screen: Vector2): number?
	local camera = Workspace.CurrentCamera
	if not camera or not origin then
		return nil
	end
	local best, bestD = nil, PICK_PX
	for tid, rec in towers do
		local feet = camera:WorldToScreenPoint((origin * CFrame.new(rec.x, 0, rec.z)).Position)
		local head = camera:WorldToScreenPoint((origin * CFrame.new(rec.x, PICK_HEIGHT, rec.z)).Position)
		if feet.Z > 0 and head.Z > 0 then
			local a, b = Vector2.new(feet.X, feet.Y), Vector2.new(head.X, head.Y)
			local ab = b - a
			local k = if ab:Dot(ab) > 0 then math.clamp((screen - a):Dot(ab) / ab:Dot(ab), 0, 1) else 0
			local d = (screen - (a + ab * k)).Magnitude
			if d < bestD then
				best, bestD = tid, d
			end
		end
	end
	return best
end

local lastScreen: Vector2? = nil

local function updateGhost()
	if not ghost or not origin or not lastScreen then
		return
	end
	local hit = groundHit(lastScreen)
	if not hit then
		return
	end
	local l = origin:PointToObjectSpace(hit)
	local ok = valid(l.X, l.Z)
	local pos = Vector3.new(hit.X, 0, hit.Z)
	ghost:PivotTo(CFrame.new(pos))
	if ring then
		ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Color = if ok then Theme.colors.quest else Theme.colors.danger
	end
	local hl = ghostLight
	if hl then
		hl.FillColor = if ok then Color3.fromRGB(110, 230, 130) else Color3.fromRGB(235, 80, 70)
	end
end

local ERR_KEYS = {
	on_path = "match.err.on_path",
	too_close = "match.err.too_close",
	cannot_afford = "match.err.cannot_afford",
	unit_cap = "match.err.unit_cap",
	tower_cap = "match.err.tower_cap",
	out_of_bounds = "match.err.out_of_bounds",
	not_in_loadout = "match.err.not_in_loadout",
	max_level = "match.err.max_level",
	match_over = "match.err.match_over",
	bad_path = "match.err.bad_path",
	bad_request = "notify.error",
}

local function call(fnName: string, ...: any)
	if busy then
		return
	end
	busy = true
	local args = table.pack(...)
	task.spawn(function()
		local ok, r = pcall(function()
			return Net.func(fnName):InvokeServer(table.unpack(args, 1, args.n))
		end)
		busy = false
		if ok and type(r) == "table" and not r.ok and r.err and ERR_KEYS[r.err] then
			ToastController.show(ERR_KEYS[r.err])
		end
	end)
end

local GAIN = "#3E9A2E"
local LOSS = "#B5372B" -- readable on the parchment panel (the old #FF8A7A was for a dark panel)

-- "12 → 18" with the gain in green when there is a next level.
local function statLine(label: string, now: number, nxt: number?, suffix: string?): string
	local sfx = suffix or ""
	local line = label .. "  <b>" .. now .. sfx .. "</b>"
	if nxt and nxt ~= now then
		line ..= '  <font color="' .. GAIN .. '">→ ' .. nxt .. sfx .. "</font>"
	end
	return line
end

local function round(n: number, places: number): number
	local k = 10 ^ places
	return math.floor(n * k + 0.5) / k
end

local portraitFor: string? = nil

local function renderTowerPanel()
	local id = selected
	local t = LocaleController.t
	local rec = if id then towers[id] else nil
	if not rec then
		towerPanel.Visible = false
		return
	end
	local def = (Units :: any)[rec.unitId]
	local mine = rec.owner == Players.LocalPlayer.Name
	local rarityColor = Theme.rarityColor(def.rarity)
	if portraitFor ~= rec.unitId then
		portraitFor = rec.unitId
		for _, c in towerPortrait:GetChildren() do
			c:Destroy()
		end
		local face = UnitCard.portrait(rec.unitId, { Size = UDim2.fromScale(1, 1), ZIndex = 5 })
		face.BackgroundColor3 = rarityColor
		face.BackgroundTransparency = 0.2
		Theme.border(face, 2.5)
		face.Parent = towerPortrait
	end
	towerTitle.Text = t(def.nameKey)
	towerTitle.TextColor3 = rarityColor:Lerp(Color3.new(1, 1, 1), 0.35)
	local maxLevel = #def.levels
	local shown = math.min(rec.level, maxLevel)
	local sig = if rec.path and def.signature then def.signature[rec.path] else nil
	-- With a signature the dots give way to its name (the line is one row wide).
	towerLevel.Text = if sig
		then t("match.level", { n = shown }) .. " / " .. maxLevel .. "  ★ " .. t("unit." .. rec.unitId .. ".sig." .. sig.key .. ".name")
		else t("match.level", { n = shown }) .. " / " .. maxLevel .. "  " .. string.rep("●", shown) .. string.rep("○", maxLevel - shown)
	towerOwner.Visible = not mine
	towerOwner.Text = rec.owner

	local st = myStats(rec.unitId, rec.level, rec.path)
	local nextLevel = def.levels[rec.level + 1]
	local nx = if nextLevel then myStats(rec.unitId, rec.level + 1) else nil
	local lines = {}
	local buff = rec.buff or 1 -- from nearby supports (server-computed, towerBuff events)
	if st.damage > 0 then
		table.insert(lines, statLine(t("match.stat_damage", { n = "" }), round(st.damage * buff, 0), nx and round(nx.damage * buff, 0)))
		if buff > 1 then
			table.insert(lines, '<font color="' .. GAIN .. '">' .. t("match.buffed", { n = round((buff - 1) * 100, 0) }) .. "</font>")
		end
		table.insert(lines, statLine(t("match.stat_range", { n = "" }), round(st.range, 1), nx and round(nx.range, 1)))
		table.insert(lines, statLine(t("match.stat_speed_label"), round(st.cooldown, 2), nx and round(nx.cooldown, 2), "s"))
		-- Stealth enemies walk past defenders that can't see them; say so up front. A defender inside
		-- a Natour's lantern (server-computed, towerReveal events) sees them and says whose light it is.
		local lit = not st.hitsStealth and rec.revealedBy ~= nil
		local sees = st.hitsStealth or lit
		local seesText
		if lit then
			local by = (Units :: any)[rec.revealedBy]
			seesText = t("match.sees_stealth_lit", { name = if by then t(by.nameKey) else rec.revealedBy })
		else
			seesText = t(if sees then "match.sees_stealth" else "match.no_stealth")
		end
		table.insert(lines, string.format('<font color="%s">%s</font>', if sees then GAIN else LOSS, seesText))
	end
	if rec.sabotaged then
		table.insert(lines, '<font color="' .. LOSS .. '">' .. t("match.sabotaged") .. "</font>")
	end
	if st.revealsStealth and rec.sabotaged then
		table.insert(lines, '<font color="' .. LOSS .. '">' .. t("match.lantern_out") .. "</font>")
	elseif st.revealsStealth then
		local n = 0
		for _, other in towers do
			if other.revealedByTower == selected then
				n += 1
			end
		end
		table.insert(lines, '<font color="' .. GAIN .. '">' .. t("match.reveals_stealth") .. "</font>")
		if n > 0 then
			table.insert(lines, t("match.reveals_count", { n = n }))
		end
	end
	if st.income then
		table.insert(lines, statLine(t("match.stat_income", { n = "" }), st.income, nx and nx.income))
	end
	if st.buff then
		table.insert(lines, statLine(t("match.stat_buff", { n = "" }), round((st.buff - 1) * 100, 0), nx and nx.buff and round((nx.buff - 1) * 100, 0), "%"))
	end
	if st.heal then
		table.insert(lines, statLine(t("match.stat_heal", { n = "" }), st.heal, nx and nx.heal))
	end
	towerStats.Text = table.concat(lines, "\n")

	local state = MatchController.state()
	local cash = if state then state.cash else 0
	local step = UpgradeView.step(def, rec.level, rec.path)
	sigRow.Visible = mine and step == "choose"
	-- While choosing, the cards say what changes; the stat lines step aside so the panel fits a phone.
	towerStats.Visible = not sigRow.Visible
	if step == "choose" then
		-- The two path cards; the tapped one glows gold, Upgrade confirms it at its price.
		local trait = myTrait(rec.unitId)
		for pathKey, card in sigCards do
			local p = def.signature[pathKey]
			local cost = UpgradeView.signatureCost(def, pathKey, trait, UnitLogic.costFor) or 0
			local base = "unit." .. rec.unitId .. ".sig." .. p.key
			local nameLabel = card:FindFirstChild("PathName") :: TextLabel
			local descLabel = card:FindFirstChild("PathDesc") :: TextLabel
			local costLabel = card:FindFirstChild("PathCost") :: TextLabel
			nameLabel.Text = t(base .. ".name")
			descLabel.Text = t(base .. ".desc")
			costLabel.Text = t("match.sig_cost", { n = cost })
			card.BackgroundColor3 = if sigPick == pathKey then rarityColor:Lerp(Color3.new(0, 0, 0), 0.25) else Theme.colors.button
			local border = card:FindFirstChild("Border") :: UIStroke?
			if border then
				border.Color = if sigPick == pathKey then Theme.colors.gold else Theme.colors.panelStroke
				border.Thickness = if sigPick == pathKey then 3.5 else 2
			end
		end
		local pickCost = if sigPick then UpgradeView.signatureCost(def, sigPick, trait, UnitLogic.costFor) or 0 else 0
		local afford = sigPick ~= nil and cash >= pickCost
		upgradeButton.Text = if sigPick then t("match.sig_confirm", { n = pickCost }) else t("match.sig_pick")
		upgradeButton.BackgroundColor3 = if afford then Theme.colors.confirm else Theme.colors.buttonDisabled
		upgradeButton.TextColor3 = if sigPick and not afford then Color3.fromHex("#FFD0C8") else Color3.new(1, 1, 1)
	else
		local nextCost = if nextLevel then myCost(rec.unitId, nextLevel.cost) else 0
		local afford = nextLevel ~= nil and cash >= nextCost
		upgradeButton.Text = if nextLevel then t("match.upgrade", { n = nextCost }) else t("match.max_level")
		upgradeButton.BackgroundColor3 = if afford then Theme.colors.confirm else Theme.colors.buttonDisabled
		upgradeButton.TextColor3 = if nextLevel and not afford then Color3.fromHex("#FFD0C8") else Color3.new(1, 1, 1)
	end
	upgradeButton.Visible = mine
	targetButton.Text = t("match.target", { mode = t("target." .. rec.targeting) })
	targetButton.Visible = mine and st.damage > 0
	local invested = UpgradeView.invested(def, rec.level, rec.path, myTrait(rec.unitId), UnitLogic.costFor)
	sellButton.Text = t("match.sell", { n = math.floor(invested * TD.SELL_REFUND) })
	sellButton.Visible = mine
	local ab = def.ability
	ultRow.Visible = mine and ab ~= nil
	if ab then
		local auto = SettingsController.get("autoUlt") == true
		ultButton.Text = t("ult." .. rec.unitId)
		autoButton.Text = t("match.ult_auto") .. "\n" .. (if auto then t("settings.on") else t("settings.off"))
		autoButton.BackgroundColor3 = if auto then Theme.colors.confirm else Theme.colors.buttonDisabled
	end
	if not towerPanel.Visible then
		towerPanel.Visible = true
		Juice.pop(towerPanel, 0.85)
	end
end

local function selectTower(id: number)
	clearGhost()
	clearSelection()
	local rec = towers[id]
	if not rec or not origin then
		return
	end
	if selected ~= id then
		sigPick = nil -- a path card picked on another defender doesn't carry over
	end
	selected = id
	EnemyRenderController.setSelectedTower(id)
	local st = myStats(rec.unitId, rec.level, rec.path)
	local r = makeRing(st.range, Theme.colors.accent)
	r.CFrame = origin * CFrame.new(rec.x, 0.1, rec.z) * CFrame.Angles(0, 0, math.rad(90))
	selectedRing = r
	renderTowerPanel()
end

local function tap(screen: Vector2)
	if not origin then
		return
	end
	local onTower = towerAtScreen(screen)
	if placing then
		local hit = groundHit(screen)
		local ok, why = false, nil
		if hit then
			local l = origin:PointToObjectSpace(hit)
			ok, why = valid(l.X, l.Z)
			if ok then
				call(Net.Functions.PlaceTower, placing, hit.X, hit.Z)
				clearGhost()
				return
			end
		end
		if onTower then
			-- Clicking one of the defenders while placing: stop placing and open its panel.
			clearGhost()
			selectTower(onTower)
		elseif why and ERR_KEYS[why] then
			ToastController.show(ERR_KEYS[why])
		end
		return
	end
	if onTower then
		selectTower(onTower)
		return
	end
	-- Pick the defender nearest the tapped ground point (fingers are fat; models are thin).
	local hit, inst = groundHit(screen)
	local model = inst and inst:FindFirstAncestorOfClass("Model")
	local direct = model and model:GetAttribute("TowerId")
	if type(direct) == "number" and towers[direct] then
		selectTower(direct)
		return
	end
	local best, bestD = nil, 3.5 * 3.5
	if hit then
		local l = origin:PointToObjectSpace(hit)
		for tid, rec in towers do
			local d = (rec.x - l.X) ^ 2 + (rec.z - l.Z) ^ 2
			if d < bestD then
				best, bestD = tid, d
			end
		end
	end
	if best then
		selectTower(best)
	else
		clearSelection()
	end
end

-- Re-tints slots for the current cash and how many of each unit I have placed.
local function refreshBar()
	local state = MatchController.state()
	local cash = if state then state.cash else 0
	local me = Players.LocalPlayer.Name
	for _, slot in slots do
		local afford = cash >= slot.price
		slot.cost.TextColor3 = if afford then Color3.fromHex("#FFD970") else Color3.fromHex("#FF6B5E")
		slot.dim.Visible = not afford
		local placed = 0
		for _, rec in towers do
			if rec.owner == me and rec.unitId == slot.unitId then
				placed += 1
			end
		end
		local def = (Units :: any)[slot.unitId]
		slot.count.Text = placed .. "/" .. def.maxPlaced
		slot.count.TextColor3 = if placed >= def.maxPlaced then Color3.fromHex("#FF6B5E") else Color3.new(1, 1, 1)
	end
end

-- A hotbar slot was clicked or its number key pressed: start (or stop) placing that unit.
pickSlot = function(unitId: string, price: number, frame: Frame)
	local state = MatchController.state()
	if state and state.cash < price then
		Juice.shake(frame)
		ToastController.show("match.err.cannot_afford")
		return
	end
	if placing == unitId then
		clearGhost()
	else
		clearSelection()
		PlacementController.begin(unitId)
	end
end

-- 1-9 (and the keypad) pick hotbar slots; Q cancels placing / closes the defender panel.
local NUMBER_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.KeypadFive] = 5,
	[Enum.KeyCode.KeypadSix] = 6,
	[Enum.KeyCode.KeypadSeven] = 7,
	[Enum.KeyCode.KeypadEight] = 8,
	[Enum.KeyCode.KeypadNine] = 9,
}

local function slotFor(i: number, unitId: string): Slot
	local def = (Units :: any)[unitId]
	local color = Theme.rarityColor(def.rarity)
	local price = myCost(unitId, def.levels[1].cost)
	local holder = Create("Frame", { LayoutOrder = i, Size = UDim2.fromOffset(68, 84), BackgroundTransparency = 1, ZIndex = 3 })
	local frame = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 3, Parent = holder }, { Create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	Create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.45, 0.45, 0.45)), Parent = frame })
	local stroke = Theme.border(frame, 2.5)
	local face = UnitCard.portrait(unitId, { Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -24), ZIndex = 4 })
	face.BackgroundTransparency = 1
	face.Parent = frame
	local dim = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, ZIndex = 6, Parent = frame }, { Create("UICorner", { CornerRadius = UDim.new(0, 12) }) })
	-- Cost: the cash icon and the number, centred along the card's bottom edge.
	local costRow = Create("Frame", { Name = "Cost", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -2), Size = UDim2.new(1, 0, 0, 20), ZIndex = 7, Parent = frame })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = costRow })
	local costIcon = Create("Frame", { LayoutOrder = 1, BackgroundTransparency = 1, Size = UDim2.fromOffset(18, 18), ZIndex = 7, Parent = costRow })
	Icons.draw("cash", costIcon)
	for _, d in costIcon:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = 7
		end
	end
	local cost = Theme.display({ LayoutOrder = 2, Text = tostring(price), TextSize = 16, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), ZIndex = 7, Parent = costRow })
	cost.TextWrapped = false
	local count = Theme.display({ Text = "", TextSize = 12, Position = UDim2.fromOffset(5, 3), Size = UDim2.fromOffset(40, 14), ZIndex = 7, Parent = frame })
	count.TextXAlignment = Enum.TextXAlignment.Left
	if def.rarity == "legendary" or def.rarity == "mythic" or def.rarity == "secret" then
		Juice.shine(frame, 3)
	end
	if def.ability then
		-- Gold gem (PV-C04): this defender has an ultimate.
		local badge = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -9, 0, 9), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 7, Parent = frame })
		Icons.draw("gem", badge, "#" .. Theme.lira:ToHex())
	end
	if UserInputService.KeyboardEnabled and i <= 9 then
		-- Number key that picks this slot (bottom-left; the count is top-left, the ultimate badge top-right)
		local key = Theme.display({ Text = tostring(i), TextSize = 13, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 5, 1, -22), Size = UDim2.fromOffset(14, 14), ZIndex = 7, Parent = frame })
		key.TextXAlignment = Enum.TextXAlignment.Left
	end
	local hit = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 8, Parent = frame })
	Juice.press(hit)
	hit.Activated:Connect(function()
		pickSlot(unitId, price, frame)
	end)
	holder.Parent = bar
	return { frame = frame, cost = cost, count = count, dim = dim, stroke = stroke, unitId = unitId, price = price }
end

-- Pops the loadout card of `unitId` (a defender of yours just landed, PV-B05).
function PlacementController.popSlot(unitId: string)
	for _, s in slots do
		if s.unitId == unitId then
			Juice.punch(s.frame, 0.18)
			return
		end
	end
end

local function renderBar()
	local snapshot = StateController.get()
	local info = MatchController.info()
	if not snapshot or not info then
		bar.Visible = false
		return
	end
	local key = table.concat(snapshot.loadout, ",")
	if key ~= slotKey or #slots == 0 then
		slotKey = key
		for _, c in bar:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		slots = {}
		for i, unitId in snapshot.loadout do
			if (Units :: any)[unitId] then
				table.insert(slots, slotFor(i, unitId))
			end
		end
	end
	refreshBar()
	bar.Visible = true
end

local function onEvents(events: { any })
	for _, e in events do
		if e.type == "towerPlaced" then
			towers[e.id] = { unitId = e.unitId, level = e.level, owner = e.owner, x = e.x, z = e.z, range = e.range, targeting = "first", readyAt = 0 }
		elseif e.type == "towerUpgraded" and towers[e.id] then
			towers[e.id].level = e.level
			towers[e.id].range = e.range
			towers[e.id].path = if e.path == "a" or e.path == "b" then e.path else towers[e.id].path
			if selected == e.id then
				selectTower(e.id)
			end
		elseif e.type == "towerSold" then
			towers[e.id] = nil
			if selected == e.id then
				clearSelection()
			end
		elseif e.type == "attack" and e.ability and towers[e.tower] then
			-- Game time runs at the match speed; the cooldown on screen is in real seconds.
			local rec = towers[e.tower]
			local def = (Units :: any)[rec.unitId]
			local state = MatchController.state()
			local speed = if state and state.speed then state.speed else 1
			if def and def.ability then
				rec.readyAt = os.clock() + def.ability.cooldown / speed
			end
		elseif e.type == "towerBuff" and towers[e.id] then
			towers[e.id].buff = if type(e.buff) == "number" and e.buff > 1 then e.buff else nil
			if selected == e.id then
				renderTowerPanel()
			end
		elseif e.type == "towerDisabled" or e.type == "towerEnabled" then
			-- A saboteur's shot (its lantern goes dark too) and the tower coming back (D-038)
			local id = if e.type == "towerDisabled" then e.tower else e.id
			local rec = towers[id]
			if rec then
				rec.sabotaged = e.type == "towerDisabled"
				if selected == id then
					renderTowerPanel()
				end
			end
		elseif e.type == "towerReveal" and towers[e.id] then
			local rec = towers[e.id]
			local before = rec.revealedByTower
			rec.revealedBy = if type(e.by) == "string" then e.by else nil
			rec.revealedByTower = if type(e.byTower) == "number" then e.byTower else nil
			if selected ~= nil and (selected == e.id or selected == before or selected == rec.revealedByTower) then
				renderTowerPanel()
			end
		elseif e.type == "towerTargeting" and towers[e.id] then
			towers[e.id].targeting = e.mode
			if selected == e.id then
				renderTowerPanel()
			end
		end
	end
	if #slots > 0 then
		refreshBar()
	end
end

function PlacementController.start()
	build()
	local function pressUpgrade()
		local rec = selected and towers[selected]
		if not rec then
			return
		end
		local def = (Units :: any)[rec.unitId]
		if UpgradeView.step(def, rec.level, rec.path) == "choose" then
			if sigPick then
				call(Net.Functions.UpgradeTower, selected, sigPick)
			else
				Juice.shake(sigRow)
			end
			return
		end
		call(Net.Functions.UpgradeTower, selected)
	end
	upgradeButton.Activated:Connect(pressUpgrade)
	-- Studio harness (DebugKeysController): open a defender's panel, cycle the path card, press
	-- Upgrade, or send a wrong path through the same call (its refusal shows the error toast).
	if RunService:IsStudio() then
		PlacementController.debugSelect = function(id: number)
			selectTower(id)
		end
		PlacementController.debugPick = function()
			sigPick = if sigPick == "a" then "b" else "a"
			renderTowerPanel()
		end
		PlacementController.debugPress = pressUpgrade
		PlacementController.debugWrongPath = function()
			if selected then
				call(Net.Functions.UpgradeTower, selected, "c")
			end
		end
	end
	for pathKey, card in sigCards do
		card.Activated:Connect(function()
			sigPick = pathKey
			Juice.punch(card, 0.08)
			renderTowerPanel()
		end)
	end
	sellButton.Activated:Connect(function()
		if selected then
			call(Net.Functions.SellTower, selected)
		end
	end)
	ultButton.Activated:Connect(function()
		local rec = selected and towers[selected]
		if not rec then
			return
		end
		if os.clock() < rec.readyAt then
			Juice.shake(ultButton)
			return
		end
		Net.event(Net.Events.UseAbility):FireServer(selected)
		Juice.punch(ultButton)
	end)
	autoButton.Activated:Connect(function()
		SettingsController.set("autoUlt", not (SettingsController.get("autoUlt") == true))
	end)
	SettingsController.Changed:Connect(function(key: string)
		if key == "autoUlt" and selected then
			renderTowerPanel()
		end
	end)
	-- Hold Upgrade to keep buying levels (one every 0.3 s after a short delay).
	local holding = 0
	upgradeButton.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		holding += 1
		local token = holding
		task.delay(0.45, function()
			while holding == token and selected and towerPanel.Visible do
				local rec = towers[selected]
				if not rec or UpgradeView.step((Units :: any)[rec.unitId], rec.level, rec.path) ~= "level" then
					break -- holding never buys a signature: that is a choice
				end
				call(Net.Functions.UpgradeTower, selected)
				task.wait(0.3)
			end
		end)
	end)
	upgradeButton.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding += 1
		end
	end)
	-- Ultimate cooldown fill (cheap: one frame size, ten times a second, only while visible).
	task.spawn(function()
		while true do
			task.wait(0.1)
			local rec = selected and towers[selected]
			if rec and ultRow.Visible then
				local def = (Units :: any)[rec.unitId]
				local state = MatchController.state()
				local speed = if state and state.speed then state.speed else 1
				local total = if def and def.ability then def.ability.cooldown / speed else 1
				local left = math.max(0, rec.readyAt - os.clock())
				ultFill.Size = UDim2.fromScale(math.clamp(left / total, 0, 1), 1)
				ultButton.BackgroundColor3 = if left <= 0 then Theme.lira else Theme.colors.buttonDisabled
			end
		end
	end)
	targetButton.Activated:Connect(function()
		local id = selected
		local rec = if id then towers[id] else nil
		if rec and id then
			local idx = table.find(TARGETING, rec.targeting) or 1
			local nextMode = TARGETING[idx % #TARGETING + 1]
			Net.event(Net.Events.SetTargeting):FireServer(id, nextMode)
		end
	end)

	MatchController.Started:Connect(function(info: MatchController.Info)
		towers = {}
		arenaPath = Path.build(Arenas[info.arenaId].path)
		arenaPaths = Path.buildAll(Arenas[info.arenaId] :: any)
		origin = CFrame.new(info.origin)
		clearGhost()
		clearSelection()
		slotKey = ""
		renderBar()
	end)
	MatchController.Updated:Connect(function()
		if #slots == 0 then
			renderBar()
		else
			refreshBar()
		end
		if selected then
			renderTowerPanel()
		end
	end)
	cancelButton.Activated:Connect(clearGhost)
	closeButton.Activated:Connect(function()
		clearSelection()
	end)
	MatchController.Events:Connect(onEvents)
	MatchController.Ended:Connect(function()
		clearGhost()
		clearSelection()
		bar.Visible = false
	end)
	task.spawn(function()
		-- bar hides once the lobby is back
		while true do
			task.wait(1)
			if not MatchController.active() and bar.Visible then
				bar.Visible = false
				towers = {}
				origin = nil
			end
		end
	end)
	StateController.Changed:Connect(function()
		if MatchController.active() then
			renderBar()
		end
	end)
	LocaleController.Changed:Connect(function()
		if MatchController.active() then
			renderBar()
			renderTowerPanel()
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			lastScreen = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not MatchController.active() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			tap(Vector2.new(input.Position.X, input.Position.Y))
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			local n = NUMBER_KEYS[input.KeyCode]
			local slot = n and slots[n]
			if slot then
				if not lastScreen then
					local m = UserInputService:GetMouseLocation()
					local inset = GuiService:GetGuiInset()
					lastScreen = m - inset
				end
				pickSlot(slot.unitId, slot.price, slot.frame)
			elseif input.KeyCode == Enum.KeyCode.Q then
				clearGhost()
				clearSelection()
			end
		elseif input.UserInputType == Enum.UserInputType.Touch then
			lastScreen = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	UserInputService.TouchTap:Connect(function(positions: { Vector2 }, processed: boolean)
		if processed or not MatchController.active() or #positions == 0 then
			return
		end
		lastScreen = positions[1]
		updateGhost()
		tap(positions[1])
	end)
	RunService.RenderStepped:Connect(function()
		if ghost then
			updateGhost()
		end
	end)
end

return PlacementController
