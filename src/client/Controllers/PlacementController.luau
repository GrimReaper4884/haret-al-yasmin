--!strict
-- Placing and managing defenders during a match: the loadout bar, a ghost that follows the
-- cursor/finger over the arena ground (green/red for valid/invalid, with its range ring), tap to
-- place, tap a placed defender to open its panel (upgrade, sell, targeting). Validity shown here
-- is a preview: the server re-checks every rule.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Arenas = require(Shared.Config.Arenas)
local Traits = require(Shared.Config.Traits)
local Path = require(Shared.Logic.Path)
local UnitLogic = require(Shared.Logic.UnitLogic)
local RigBuilder = require(Shared.Util.RigBuilder)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local UnitCard = require(UI.UnitCard)
local StateController = require(script.Parent.StateController)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local ToastController = require(script.Parent.ToastController)

local PlacementController = {}

local TARGETING = { "first", "last", "strong", "close" }

local bar: Frame
local placeHint: TextLabel
local towerPanel: Frame
local towerTitle: TextLabel
local towerStats: TextLabel
local upgradeButton: TextButton
local sellButton: TextButton
local targetButton: TextButton

local placing: string? = nil
local ghost: Model? = nil
local ring: Part? = nil
local selected: number? = nil
local selectedRing: Part? = nil
local towers: { [number]: { unitId: string, level: number, owner: string, x: number, z: number, range: number, targeting: string } } = {}
local arenaPath: Path.Path? = nil
local origin: CFrame? = nil
local busy = false

local function build()
	local root = Root.get()
	bar = Create("Frame", { Name = "UnitBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(7 * 78, 92), BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = root })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = bar })
	placeHint = Theme.label({ Name = "PlaceHint", TextSize = 15, FontFace = Theme.fontBold, TextColor3 = Theme.colors.buttonText, TextStrokeTransparency = 0.3, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -104), Size = UDim2.new(0.8, 0, 0, 22), Visible = false, ZIndex = 3, Parent = root })
	placeHint.TextXAlignment = Enum.TextXAlignment.Center

	towerPanel = Theme.panel({ Name = "TowerPanel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(200, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 4, Parent = root })
	Create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = towerPanel })
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = towerPanel })
	towerTitle = Theme.label({ LayoutOrder = 1, TextSize = 15, FontFace = Theme.fontBold, Size = UDim2.new(1, 0, 0, 20), ZIndex = 4, Parent = towerPanel })
	towerStats = Theme.label({ LayoutOrder = 2, TextSize = 12, TextColor3 = Theme.colors.textMuted, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4, Parent = towerPanel })
	upgradeButton = Theme.button({ LayoutOrder = 3, TextSize = 13, Size = UDim2.new(1, 0, 0, 40), ZIndex = 4, Parent = towerPanel })
	targetButton = Theme.button({ LayoutOrder = 4, TextSize = 13, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.colors.quest, ZIndex = 4, Parent = towerPanel })
	sellButton = Theme.button({ LayoutOrder = 5, TextSize = 13, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.colors.danger, ZIndex = 4, Parent = towerPanel })
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
	placing = nil
	placeHint.Visible = false
end

local function clearSelection()
	selected = nil
	towerPanel.Visible = false
	if selectedRing then
		selectedRing:Destroy()
		selectedRing = nil
	end
end

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
	p.Transparency = 0.75
	p.Parent = Workspace
	return p
end

local function myStats(unitId: string, level: number)
	local snapshot = StateController.get()
	local def = (Units :: any)[unitId]
	local owned = snapshot and snapshot.units[unitId]
	local stars = if owned then UnitLogic.stars(owned.copies, TD.STAR_COPIES) else 0
	local trait = if owned then Traits.traits[owned.trait] else nil
	return UnitLogic.stats(def, level, stars, trait, TD.STAR_BONUS)
end

function PlacementController.begin(unitId: string)
	clearSelection()
	clearGhost()
	local def = (Units :: any)[unitId]
	if not def or not origin then
		return
	end
	placing = unitId
	ghost = RigBuilder.build(Workspace, "Ghost", def.visual)
	RigBuilder.setTransparency(ghost :: Model, 0.5)
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
	local unitRay = camera:ViewportPointToRay(screen.X, screen.Y)
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

local function valid(x: number, z: number): boolean
	local info = MatchController.info()
	if not info or not arenaPath then
		return false
	end
	local b = Arenas[info.arenaId].bounds
	if x < b[1] or x > b[3] or z < b[2] or z > b[4] then
		return false
	end
	if Path.distanceTo(arenaPath, x, z) < TD.PATH_HALF_WIDTH then
		return false
	end
	for _, t in towers do
		if (t.x - x) ^ 2 + (t.z - z) ^ 2 < TD.TOWER_SPACING * TD.TOWER_SPACING then
			return false
		end
	end
	return true
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
	for _, d in (ghost :: Model):GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			d.Color = if ok then Color3.fromRGB(120, 220, 140) else Color3.fromRGB(230, 90, 80)
		end
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
	towerTitle.Text = t(def.nameKey) .. " · " .. t("match.level", { n = rec.level }) .. (if mine then "" else "\n" .. rec.owner)
	local st = myStats(rec.unitId, rec.level)
	local lines = {}
	if st.damage > 0 then
		table.insert(lines, t("match.stat_damage", { n = math.floor(st.damage + 0.5) }))
		table.insert(lines, t("match.stat_range", { n = math.floor(st.range * 10 + 0.5) / 10 }))
		table.insert(lines, t("match.stat_cooldown", { n = math.floor(st.cooldown * 100 + 0.5) / 100 }))
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
	towerStats.Text = table.concat(lines, "\n")
	local nextLevel = def.levels[rec.level + 1]
	upgradeButton.Text = if nextLevel then t("match.upgrade", { n = nextLevel.cost }) else t("match.max_level")
	upgradeButton.Visible = mine
	upgradeButton.AutoButtonColor = nextLevel ~= nil
	upgradeButton.BackgroundColor3 = if nextLevel then Theme.colors.button else Theme.colors.buttonDisabled
	targetButton.Text = t("match.target", { mode = t("target." .. rec.targeting) })
	targetButton.Visible = mine and st.damage > 0
	local invested = def.levels[1].cost
	for i = 2, rec.level do
		invested += def.levels[i].cost
	end
	sellButton.Text = t("match.sell", { n = math.floor(invested * TD.SELL_REFUND) })
	sellButton.Visible = mine
	towerPanel.Visible = true
end

local function selectTower(id: number)
	clearGhost()
	clearSelection()
	local rec = towers[id]
	if not rec or not origin then
		return
	end
	selected = id
	local st = myStats(rec.unitId, rec.level)
	local r = makeRing(st.range, Theme.colors.accent)
	r.CFrame = origin * CFrame.new(rec.x, 0.1, rec.z) * CFrame.Angles(0, 0, math.rad(90))
	selectedRing = r
	renderTowerPanel()
end

local function tap(screen: Vector2)
	if not origin then
		return
	end
	if placing then
		local hit = groundHit(screen)
		if hit then
			local l = origin:PointToObjectSpace(hit)
			if valid(l.X, l.Z) then
				call(Net.Functions.PlaceTower, placing, hit.X, hit.Z)
				clearGhost()
			end
		end
		return
	end
	local _, inst = groundHit(screen)
	local model = inst and inst:FindFirstAncestorOfClass("Model")
	local id = model and model:GetAttribute("TowerId")
	if type(id) == "number" and towers[id] then
		selectTower(id)
	else
		clearSelection()
	end
end

local function renderBar()
	for _, c in bar:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local snapshot = StateController.get()
	local info = MatchController.info()
	if not snapshot or not info then
		bar.Visible = false
		return
	end
	local t = LocaleController.t
	local state = MatchController.state()
	for i, unitId in snapshot.loadout do
		local def = (Units :: any)[unitId]
		if def then
			local cost = def.levels[1].cost
			local afford = state ~= nil and state.cash >= cost
			local card = UnitCard.create(unitId, { LayoutOrder = i, Size = UDim2.fromOffset(72, 92) }, { name = t(def.nameKey), sub = "$" .. cost, dim = not afford, zindex = 3 })
			card.Parent = bar
			local hit = Create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = card })
			hit.Activated:Connect(function()
				if placing == unitId then
					clearGhost()
				else
					PlacementController.begin(unitId)
				end
			end)
		end
	end
	bar.Visible = true
end

local function onEvents(events: { any })
	for _, e in events do
		if e.type == "towerPlaced" then
			towers[e.id] = { unitId = e.unitId, level = e.level, owner = e.owner, x = e.x, z = e.z, range = e.range, targeting = "first" }
		elseif e.type == "towerUpgraded" and towers[e.id] then
			towers[e.id].level = e.level
			towers[e.id].range = e.range
			if selected == e.id then
				selectTower(e.id)
			end
		elseif e.type == "towerSold" then
			towers[e.id] = nil
			if selected == e.id then
				clearSelection()
			end
		elseif e.type == "towerTargeting" and towers[e.id] then
			towers[e.id].targeting = e.mode
			if selected == e.id then
				renderTowerPanel()
			end
		end
	end
end

function PlacementController.start()
	build()
	upgradeButton.Activated:Connect(function()
		if selected then
			call(Net.Functions.UpgradeTower, selected)
		end
	end)
	sellButton.Activated:Connect(function()
		if selected then
			call(Net.Functions.SellTower, selected)
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
		origin = CFrame.new(info.origin)
		clearGhost()
		clearSelection()
		renderBar()
	end)
	MatchController.Updated:Connect(function()
		renderBar()
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
