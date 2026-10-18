--!strict
-- The cinematic side of a match: the gate-closing moment at the start (the leaves swing shut,
-- the bar drops, "the watchman bars the gate"), wave and boss banners, night lighting over the
-- arena (local to this client), music switches and the victory / defeat stings.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared.Config.Enemies)
local Units = require(Shared.Config.Units)
local Vfx = require(Shared.Config.Vfx)
local LightLook = require(Shared.Config.Lighting)
local Arenas = require(Shared.Config.Arenas)
local Story = require(Shared.Config.Story)
local Locale = require(Shared.Util.Locale)
local MatchMoments = require(Shared.Logic.MatchMoments)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local Root = require(UI.Root)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local AudioController = require(script.Parent.AudioController)
local SettingsController = require(script.Parent.SettingsController)
local MatchCameraController = require(script.Parent.MatchCameraController)
local PlacementController = require(script.Parent.PlacementController)
local RigAnimController = require(script.Parent.RigAnimController)
local CoinFlight = require(UI.CoinFlight)

local MatchFxController = {}

local band: Frame
local banner: TextLabel
local sub: TextLabel
local bannerToken = 0
local dayClock = 15.6
local dayBrightness = 2.4
local night = false
local duskMode = false -- this match opens at dusk and falls to night (Config/Lighting.dusk, S1-C05)
local allyMarks: { [number]: BasePart } = {} -- story allies: tower id → gold ring (with the nameplate)

local function build()
	-- A dark band across the screen (faded at both ends) carrying a big outlined title.
	band = Create("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.33),
		Size = UDim2.new(1.2, 0, 0, 74),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 6,
		Parent = Root.get(),
	})
	Create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0),
			NumberSequenceKeypoint.new(0.7, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = band,
	})
	banner = Theme.display({ TextSize = 36, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 42), ZIndex = 7, Parent = band })
	banner.TextXAlignment = Enum.TextXAlignment.Center
	sub = Theme.display({ TextSize = 17, TextColor3 = Color3.fromHex("#FFD970"), Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 22), ZIndex = 7, Parent = band })
	sub.TextXAlignment = Enum.TextXAlignment.Center
end

-- Slides a banner in from the left, holds, slides it out to the right. `color` tints the title
-- and the band (boss waves are red).
function MatchFxController.banner(text: string, subText: string?, hold: number?, color: Color3?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.new(1, 1, 1)
	band.BackgroundColor3 = if color then color:Lerp(Color3.new(0, 0, 0), 0.6) else Color3.new(0, 0, 0)
	sub.Text = subText or ""
	sub.Visible = subText ~= nil
	band.Size = UDim2.new(1.2, 0, 0, if subText then 74 else 52)
	band.Position = UDim2.fromScale(-0.6, 0.33)
	band.Visible = true
	TweenService:Create(band, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.33) }):Play()
	task.delay(hold or 2.2, function()
		if token ~= bannerToken then
			return
		end
		local out = TweenService:Create(band, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(1.6, 0.33) })
		out:Play()
		out.Completed:Connect(function()
			if token == bannerToken then
				band.Visible = false
			end
		end)
	end)
end

local function setNight(on: boolean)
	if on == night then
		return
	end
	night = on
	if on then
		dayClock = Lighting.ClockTime
		dayBrightness = Lighting.Brightness
	end
	TweenService:Create(Lighting, TweenInfo.new(2.5, Enum.EasingStyle.Sine), {
		ClockTime = if on then LightLook.night.clockTime else dayClock,
		Brightness = if on then LightLook.night.brightness else dayBrightness,
	}):Play()
	-- PV-E01: denser haze and a slightly cool grade at night (client only; Config/Lighting).
	local N = LightLook.night
	local tw = TweenInfo.new(N.blend, Enum.EasingStyle.Sine)
	local haze = Lighting:FindFirstChild("LaneHaze")
	if haze and haze:IsA("Atmosphere") then
		local D = LightLook.day
		TweenService:Create(haze, tw, {
			Density = if on then N.density else D.density,
			Color = Color3.fromHex(if on then N.hazeColor else D.hazeColor),
			Decay = Color3.fromHex(if on then N.hazeDecay else D.hazeDecay),
		}):Play()
	end
	local grade = Lighting:FindFirstChild("NightGrade")
	if not grade then
		local n = Instance.new("ColorCorrectionEffect")
		n.Name = "NightGrade"
		n.Parent = Lighting
		grade = n
	end
	TweenService:Create(grade :: ColorCorrectionEffect, tw, {
		TintColor = if on then Color3.fromHex(N.tint) else Color3.new(1, 1, 1),
		Contrast = if on then N.contrast else 0,
	}):Play()
end

-- Episode 9's light (S1-C05): `f` = 0 is dusk (Config/Lighting.dusk), 1 is the match night; each
-- wave start moves it on (MatchMoments.nightFraction). setNight(false) restores the day after.
local function setDuskMix(f: number)
	if not night then
		night = true
		dayClock = Lighting.ClockTime
		dayBrightness = Lighting.Brightness
	end
	local D, N = LightLook.dusk, LightLook.night
	local function lerp(a: number, b: number): number
		return a + (b - a) * f
	end
	local tw = TweenInfo.new(N.blend, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, tw, { ClockTime = lerp(D.clockTime, N.clockTime), Brightness = lerp(D.brightness, N.brightness) }):Play()
	local haze = Lighting:FindFirstChild("LaneHaze")
	if haze and haze:IsA("Atmosphere") then
		TweenService:Create(haze, tw, {
			Density = lerp(D.density, N.density),
			Color = Color3.fromHex(D.hazeColor):Lerp(Color3.fromHex(N.hazeColor), f),
			Decay = Color3.fromHex(D.hazeDecay):Lerp(Color3.fromHex(N.hazeDecay), f),
		}):Play()
	end
	local grade = Lighting:FindFirstChild("NightGrade")
	if not grade then
		local n = Instance.new("ColorCorrectionEffect")
		n.Name = "NightGrade"
		n.Parent = Lighting
		grade = n
	end
	TweenService:Create(grade :: ColorCorrectionEffect, tw, {
		TintColor = Color3.fromHex(D.tint):Lerp(Color3.fromHex(N.tint), f),
		Contrast = lerp(D.contrast, N.contrast),
	}):Play()
end

-- A story ally (Al-Adashari): a gold ring at his feet and his name over him, for the match.
local function allyMark(id: number, unitId: string, at: Vector3)
	if allyMarks[id] then
		return
	end
	local t = LocaleController.t
	local cfg = Vfx.STORY.ally
	local ring = Create("Part", {
		Name = "AllyRing_" .. id,
		Shape = Enum.PartType.Cylinder,
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromHex(cfg.color),
		Transparency = cfg.transparency,
		Size = Vector3.new(cfg.height, cfg.radius * 2, cfg.radius * 2),
		CFrame = CFrame.new(at + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Parent = Workspace,
	})
	-- The nameplate hangs on an attachment over his head (a flat ring's own frame points sideways).
	local over = Create("Attachment", { Name = "Name", Parent = ring })
	over.WorldCFrame = CFrame.new(at + Vector3.new(0, cfg.nameHeight, 0))
	local gui = Create("BillboardGui", { Adornee = over, Size = UDim2.fromOffset(220, 40), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 180, Parent = ring })
	local def = (Units :: any)[unitId]
	local name = Theme.display({ Text = if def then t(def.nameKey) else unitId, TextSize = cfg.nameSize, TextColor3 = Color3.fromHex(cfg.color), Size = UDim2.new(1, 0, 0, 22), Parent = gui })
	name.TextXAlignment = Enum.TextXAlignment.Center
	local role = Theme.display({ Text = t("match.ally"), TextSize = 12, TextColor3 = Color3.fromHex("#FFF1D0"), Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 16), Parent = gui })
	role.TextXAlignment = Enum.TextXAlignment.Center
	allyMarks[id] = ring
end

local function clearAllies()
	for _, ring in allyMarks do
		ring:Destroy()
	end
	allyMarks = {}
end

-- Finds this match's gate doors in the arena model nearest the origin.
local function findDoors(origin: Vector3): Model?
	local arenas = Workspace:FindFirstChild("Arenas")
	if not arenas then
		return nil
	end
	for _, arena in arenas:GetChildren() do
		local gate = arena:FindFirstChild("GateWall")
		local anchor = gate and gate:FindFirstChild("GateAnchor")
		if anchor and anchor:IsA("BasePart") and (anchor.Position - origin).Magnitude < 400 then
			local doors = gate and gate:FindFirstChild("Doors")
			return if doors and doors:IsA("Model") then doors else nil
		end
	end
	return nil
end

-- The gate-closing ritual: leaves swing from open to shut, then the bar drops into its hooks.
local function closeGate(origin: Vector3)
	task.spawn(function()
		local doors: Model? = nil
		for _ = 1, 20 do
			doors = findDoors(origin)
			if doors then
				break
			end
			task.wait(0.25)
		end
		if not doors then
			return
		end
		local bar = doors:FindFirstChild("Bar") :: BasePart?
		for _, leafName in { "LeafW", "LeafE" } do
			local leaf = doors:FindFirstChild(leafName) :: BasePart?
			if leaf then
				local closed = leaf.CFrame
				local sideAttr = leaf:GetAttribute("Side")
				local side: number = if type(sideAttr) == "number" then sideAttr else 1
				local hinge = closed * CFrame.new(side * leaf.Size.X / 2, 0, 0)
				local open = hinge * CFrame.Angles(0, math.rad(side * 100), 0) * CFrame.new(-side * leaf.Size.X / 2, 0, 0)
				leaf.CFrame = open
				TweenService:Create(leaf, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = closed }):Play()
			end
		end
		if bar then
			local rest = bar.CFrame
			bar.CFrame = rest * CFrame.new(0, 8, 0)
			bar.Transparency = 0
			task.delay(1.5, function()
				TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = rest }):Play()
				AudioController.sting("gate_close")
			end)
		end
	end)
end

-- A thief reached the gate (PV-B03): the leaves shudder on their hinges and dust kicks up at the
-- foot of the doors. A leaf that is already shuddering is left alone; the dust is pooled parts.
local shuddering: { [BasePart]: boolean } = {}
local function gateShudder()
	local info = MatchController.info()
	local doors = if info and Fx.any() then findDoors(info.origin) else nil
	if not doors then
		return
	end
	local cfg = Vfx.GATE_SHUDDER
	for _, leafName in { "LeafW", "LeafE" } do
		local leaf = doors:FindFirstChild(leafName)
		if leaf and leaf:IsA("BasePart") and not shuddering[leaf] then
			shuddering[leaf] = true
			local rest = leaf.CFrame
			local sideAttr = leaf:GetAttribute("Side")
			local side: number = if type(sideAttr) == "number" then sideAttr else 1
			local hinge = rest * CFrame.new(side * leaf.Size.X / 2, 0, 0)
			local function at(deg: number): CFrame
				return hinge * CFrame.Angles(0, math.rad(side * deg), 0) * CFrame.new(-side * leaf.Size.X / 2, 0, 0)
			end
			task.spawn(function()
				local steps = { cfg.angle, -cfg.angle * 0.6, cfg.angle * 0.3, 0 }
				for _, deg in steps do
					leaf.CFrame = at(deg)
					task.wait(cfg.life / #steps)
				end
				leaf.CFrame = rest
				shuddering[leaf] = nil
			end)
		end
	end
	if not Fx.full() then
		return
	end
	local base = doors:GetPivot()
	-- Puffs scatter along the foot of the doors, pushed toward the road (the arena centre side).
	local toward = (info :: any).origin - base.Position
	toward = Vector3.new(toward.X, 0, toward.Z)
	toward = if toward.Magnitude > 0.1 then toward.Unit else Vector3.zero
	local width = doors:GetExtentsSize().X
	for i = 1, Fx.allow(cfg.dust) do
		local puff = Fx.part(Enum.PartType.Ball)
		if not puff then
			break
		end
		puff.Material = Enum.Material.SmoothPlastic
		puff.Color = Color3.fromHex(cfg.dustColor)
		puff.Transparency = 0.3
		puff.Size = Vector3.one * cfg.dustSize
		local spread = ((i - 0.5) / cfg.dust - 0.5) * width * 0.8 + (math.random() - 0.5) * 1.2
		local start = (base * CFrame.new(spread, 0, 0)).Position + toward * (1 + math.random() * 1.5)
		local ground = Vector3.new(start.X, base.Position.Y - doors:GetExtentsSize().Y / 2 + 0.6, start.Z)
		puff.CFrame = CFrame.new(ground)
		Fx.fade(puff, cfg.dustLife, { Size = Vector3.one * cfg.dustSize * 2.4, Transparency = 1, CFrame = CFrame.new(ground + Vector3.new(0, cfg.dustRise, 0)) })
	end
end

---------------------------------------------------------------- Ultimates
-- docs/research/ANIME_VANGUARDS_STUDY.md §4: the name in a big banner, a rarity-coloured edge
-- flash and a quick zoom punch for your own defenders' ultimates. Effects "reduced" keeps only the
-- banner; "off" shows nothing here (the world strike still plays in EnemyRenderController).

local towerInfo: { [number]: { unitId: string, owner: string } } = {}
local vignette: Frame
local lastUlt = 0

local function buildUltFx()
	local gui = Create("ScreenGui", { Name = "HaretUltFx", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.None, DisplayOrder = 4, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	vignette = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.lira, BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Parent = gui })
	Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.9), NumberSequenceKeypoint.new(0.7, 0.9), NumberSequenceKeypoint.new(1, 0) }), Parent = vignette })
end

local function zoomPunch()
	local camera = Workspace.CurrentCamera
	if not camera or camera.CameraType ~= Enum.CameraType.Custom then
		return
	end
	local fov = camera.FieldOfView
	local tin = TweenService:Create(camera, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = fov - 9 })
	tin:Play()
	tin.Completed:Once(function()
		TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = fov }):Play()
	end)
end

local function ultimate(e: any)
	local info = towerInfo[e.tower]
	if not info or info.owner ~= Players.LocalPlayer.Name or not Fx.any() then
		return
	end
	local now = os.clock()
	if now - lastUlt < 1.2 then
		return
	end
	lastUlt = now
	local t = LocaleController.t
	local def = (Units :: any)[info.unitId]
	local color = Theme.rarityColor(def.rarity)
	MatchFxController.banner(t("ult." .. info.unitId), t(def.nameKey), 1.3, color:Lerp(Color3.new(1, 1, 1), 0.25))
	if Fx.full() then
		vignette.BackgroundColor3 = color
		vignette.BackgroundTransparency = 0.35
		TweenService:Create(vignette, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		zoomPunch()
	end
end

-- The screen edge blinks `color` for `life` seconds (gate hits; ultimates use their own colour).
local lastEdge = 0
function MatchFxController.edgeFlash(color: Color3, alpha: number, life: number)
	if not Fx.full() then
		return
	end
	local now = os.clock()
	if now - lastEdge < 0.15 then
		return -- several thieves in one step: one blink
	end
	lastEdge = now
	vignette.BackgroundColor3 = color
	vignette.BackgroundTransparency = 1 - alpha
	TweenService:Create(vignette, TweenInfo.new(life, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
end

---------------------------------------------------------------- Tower moments (PV-B05)

local towerAt: { [number]: Vector3 } = {}
local glow: Highlight? = nil

local function reducedMotion(): boolean
	local ok, v = pcall(function()
		return (game:GetService("GuiService") :: any).ReducedMotionEnabled
	end)
	return ok and v == true
end

-- A defender lands: a dust ring at its feet and a few jasmine petals.
local function towerLanded(at: Vector3)
	if not Fx.full() then
		return
	end
	local c = Vfx.TOWER
	local ring = Fx.part(Enum.PartType.Cylinder)
	if ring then
		ring.Material = Enum.Material.SmoothPlastic
		ring.Color = Color3.fromHex(c.dustColor)
		ring.Transparency = 0.3
		ring.Size = Vector3.new(0.3, 1.5, 1.5)
		ring.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		Fx.fade(ring, c.dustLife, { Size = Vector3.new(0.1, c.dustRadius * 2, c.dustRadius * 2), Transparency = 1 })
	end
	for i = 1, Fx.allow(c.petals) do
		local p = Fx.part()
		if not p then
			break
		end
		local a = i / c.petals * math.pi * 2 + math.random() * 0.6
		local start = at + Vector3.new(math.cos(a) * 0.8, 2.5, math.sin(a) * 0.8)
		p.Color = Color3.fromHex(c.petalColor)
		p.Size = Vector3.new(0.4, 0.08, 0.3)
		p.Transparency = 0.05
		p.CFrame = CFrame.new(start) * CFrame.Angles(math.random() * 3, a, 0)
		local goal = start + Vector3.new(math.cos(a) * 1.8, 1.2, math.sin(a) * 1.8)
		Fx.fade(p, c.petalLife, { CFrame = CFrame.new(goal) * CFrame.Angles(math.random() * 6, a + 3, math.random() * 6), Transparency = 1 }, Enum.EasingStyle.Sine)
	end
end

-- A 1 -> punch -> 1 scale punch on a defender's figure (local only; ends on its exact old scale).
local punching: { [Model]: boolean } = {}
local function punchModel(model: Model)
	if punching[model] or reducedMotion() then
		return
	end
	punching[model] = true
	local c = Vfx.TOWER
	local s0 = model:GetScale()
	task.spawn(function()
		local t0 = os.clock()
		while model.Parent do
			local k = (os.clock() - t0) / c.punchLife
			if k >= 1 then
				break
			end
			model:ScaleTo(s0 * (1 + (c.punch - 1) * math.sin(k * math.pi)))
			RunService.Heartbeat:Wait()
		end
		if model.Parent then
			model:ScaleTo(s0)
		end
		punching[model] = nil
	end)
end

-- An upgrade: gold sparks burst upward, the figure punches, and from glowLevel a brief gold glow.
local function towerUpgraded(towerId: number, level: number)
	local at = towerAt[towerId]
	if not at or not Fx.full() then
		return
	end
	local c = Vfx.TOWER
	for i = 1, Fx.allow(c.stars) do
		local s = Fx.part()
		if not s then
			break
		end
		local a = i / c.stars * math.pi * 2
		local start = at + Vector3.new(0, 2.2, 0)
		s.Color = Color3.fromHex(c.starColor)
		s.Size = Vector3.one * 0.45
		s.Transparency = 0
		s.CFrame = CFrame.new(start) * CFrame.Angles(0, a, math.rad(45))
		local goal = start + Vector3.new(math.cos(a) * 2.4, 2.6 + math.random(), math.sin(a) * 2.4)
		Fx.fade(s, c.starLife, { CFrame = CFrame.new(goal) * CFrame.Angles(0, a + 2, math.rad(45)), Size = Vector3.one * 0.12, Transparency = 1 })
	end
	local model = RigAnimController.findTower(towerId)
	if model then
		punchModel(model)
		if level >= c.glowLevel then
			local h = glow
			if not h then
				local n = Instance.new("Highlight")
				n.Name = "UpgradeGlow"
				n.FillColor = Color3.fromHex(c.glowColor)
				n.OutlineColor = Color3.fromHex(c.glowColor)
				n.FillTransparency = 0.55
				n.DepthMode = Enum.HighlightDepthMode.Occluded
				n.Enabled = false
				n.Parent = Workspace
				glow = n
				h = n
			end
			local hl = h :: Highlight
			hl.Adornee = model
			hl.Enabled = true
			task.delay(c.glowLife, function()
				if hl.Adornee == model then
					hl.Enabled = false
					hl.Adornee = nil
				end
			end)
		end
	end
end

-- Selling your defender: a shower of cash coins into the cash pill.
local function towerSold(at: Vector3)
	local pill = MatchController.cashPill()
	if not pill or not Fx.any() then
		return
	end
	local c = Vfx.TOWER
	for i = 1, c.coins do
		task.delay((i - 1) * c.coinGap, function()
			local jitter = Vector3.new((math.random() - 0.5) * 2, 2 + math.random() * 1.5, (math.random() - 0.5) * 2)
			CoinFlight.fly(at + jitter, pill)
		end)
	end
end

---------------------------------------------------------------- Moments (PV-B06)

local topBand: Frame
local topTitle: TextLabel
local topSub: TextLabel
local topToken = 0
local grade: ColorCorrectionEffect? = nil
local boosted: { [Light]: number } = {}
local atmoBase: number? = nil

local function buildTop()
	topBand = Create("Frame", {
		Name = "WaveClear",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -10),
		Size = UDim2.fromOffset(360, 60),
		BackgroundColor3 = Theme.colors.confirm:Lerp(Color3.new(0, 0, 0), 0.45),
		BackgroundTransparency = 0.15,
		Visible = false,
		ZIndex = 20,
		Parent = Root.get(),
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 14) }) })
	Theme.border(topBand, 2.5)
	topTitle = Theme.display({ TextSize = 24, Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 4), ZIndex = 21, Parent = topBand })
	topTitle.TextXAlignment = Enum.TextXAlignment.Center
	topSub = Theme.display({ TextSize = 15, TextColor3 = Color3.fromHex("#FFE9B8"), Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 36), ZIndex = 21, Parent = topBand })
	topSub.TextXAlignment = Enum.TextXAlignment.Center
end

-- "Wave n cleared · +cash" slides down from the top edge, holds, slides back up.
local function topBanner(text: string, subText: string?, hold: number)
	topToken += 1
	local token = topToken
	topTitle.Text = text
	topSub.Text = subText or ""
	topBand.Size = UDim2.fromOffset(360, if subText then 60 else 42)
	topBand.Position = UDim2.new(0.5, 0, 0, -10)
	topBand.Visible = true
	-- It drops over the wave panel (top centre): toasts and the wave banner use the space below.
	TweenService:Create(topBand, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, if subText then 66 else 50) }):Play()
	task.delay(hold, function()
		if token ~= topToken then
			return
		end
		local up = TweenService:Create(topBand, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -10) })
		up:Play()
		up.Completed:Connect(function()
			if token == topToken then
				topBand.Visible = false
			end
		end)
	end)
end

local function colorGrade(): ColorCorrectionEffect
	local g = grade
	if g and g.Parent then
		return g
	end
	local n = Instance.new("ColorCorrectionEffect")
	n.Name = "HaretMoments"
	n.Parent = Lighting
	grade = n
	return n
end

-- The arena model nearest the match origin (lanterns live in it).
local function arenaModel(origin: Vector3): Instance?
	local arenas = Workspace:FindFirstChild("Arenas")
	if not arenas then
		return nil
	end
	for _, arena in arenas:GetChildren() do
		local gate = arena:FindFirstChild("GateWall")
		local anchor = gate and gate:FindFirstChild("GateAnchor")
		if anchor and anchor:IsA("BasePart") and (anchor.Position - origin).Magnitude < 400 then
			return arena
		end
	end
	return nil
end

-- Last wave: the night warms, the haze thickens a little and the lanterns brighten.
local function finalWave(origin: Vector3)
	local m = Vfx.MOMENTS
	local tw = TweenInfo.new(m.finalLife, Enum.EasingStyle.Sine)
	TweenService:Create(colorGrade(), tw, { TintColor = Color3.fromHex(m.finalTint) }):Play()
	local atmo = Lighting:FindFirstChild("LaneHaze") :: Atmosphere?
	if atmo then
		atmoBase = atmoBase or atmo.Density
		TweenService:Create(atmo, tw, { Density = math.min(1, (atmoBase :: number) + m.finalDensity) }):Play()
	end
	local arena = arenaModel(origin)
	if arena then
		-- AmbienceController multiplies each lantern by its "Boost" attribute while it flickers.
		for _, l in arena:GetDescendants() do
			if l:IsA("PointLight") or l:IsA("SpotLight") then
				boosted[l] = 1
				l:SetAttribute("Boost", m.lanternBoost)
			end
		end
	end
end

local function restoreMoments()
	local g = grade
	if g then
		g.TintColor = Color3.new(1, 1, 1)
		g.Saturation = 0
	end
	local atmo = Lighting:FindFirstChild("LaneHaze") :: Atmosphere?
	if atmo and atmoBase then
		atmo.Density = atmoBase
	end
	atmoBase = nil
	for l in boosted do
		if l.Parent then
			l:SetAttribute("Boost", nil)
		end
	end
	boosted = {}
end

-- Victory: two 'arada ribbons spiral up from the gate, then petals drift down over the arena.
local function victoryFx(origin: Vector3)
	local m = Vfx.MOMENTS
	local doors = findDoors(origin)
	local base = if doors then doors:GetPivot().Position else origin
	for r, hex in m.ribbonColors do
		local segs: { BasePart } = {}
		for _ = 1, Fx.allow(m.ribbonSegments) do
			local p = Fx.part()
			if not p then
				break
			end
			p.Color = Color3.fromHex(hex)
			p.Size = Vector3.new(0.7, 0.15, 2.6)
			table.insert(segs, p)
		end
		local phase = if r == 1 then 0 else math.pi
		task.spawn(function()
			local t0 = os.clock()
			while true do
				local k = (os.clock() - t0) / m.ribbonLife
				if k >= 1 then
					break
				end
				for i, p in segs do
					local u = math.max(0, k - (i - 1) * 0.035)
					local a = phase + u * 9
					local pos = base + Vector3.new(math.cos(a) * (2 + u * 4), 2 + u * 22, math.sin(a) * (2 + u * 4))
					local ahead = phase + (u + 0.02) * 9
					local nxt = base + Vector3.new(math.cos(ahead) * (2 + u * 4), 2 + (u + 0.02) * 22, math.sin(ahead) * (2 + u * 4))
					p.CFrame = CFrame.lookAt(pos, nxt)
					p.Transparency = math.clamp((k - 0.6) / 0.4, 0, 1)
				end
				RunService.Heartbeat:Wait()
			end
			for _, p in segs do
				Fx.release(p)
			end
		end)
	end
	task.spawn(function()
		local t0 = os.clock()
		local center = origin
		while os.clock() - t0 < m.petalSeconds do
			for _ = 1, Fx.allow(m.petalsPer) do
				local p = Fx.part()
				if not p then
					break
				end
				local x = (math.random() - 0.5) * 2 * m.petalSpread
				local z = (math.random() - 0.5) * 2 * m.petalSpread
				local top = center + Vector3.new(x, m.petalHeight, z)
				p.Color = Color3.fromHex(Vfx.DEATH.petalColors[math.random(1, #Vfx.DEATH.petalColors)])
				p.Size = Vector3.new(0.45, 0.08, 0.35)
				p.CFrame = CFrame.new(top) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
				local drift = Vector3.new((math.random() - 0.5) * 6, 0, (math.random() - 0.5) * 6)
				Fx.fade(p, m.petalFall, { CFrame = CFrame.new(top - Vector3.new(0, m.petalHeight - 1, 0) + drift) * CFrame.Angles(math.random() * 9, math.random() * 9, 0), Transparency = 0.6 }, Enum.EasingStyle.Linear)
			end
			task.wait(m.petalEvery)
		end
	end)
end

local function defeatFx()
	local g = colorGrade()
	local m = Vfx.MOMENTS
	TweenService:Create(g, TweenInfo.new(0.3), { Saturation = -1 }):Play()
	task.delay(m.defeatLife, function()
		TweenService:Create(g, TweenInfo.new(0.6), { Saturation = 0 }):Play()
	end)
end

local function playMoment(mo: MatchMoments.Moment)
	local t = LocaleController.t
	local info = MatchController.info()
	if mo.kind == "waveStart" then
		MatchFxController.banner(t("match.wave_start", { n = mo.wave }))
		AudioController.sting("wave_start")
	elseif mo.kind == "bossIntro" then
		local def = (Enemies :: any)[mo.boss]
		local both = Locale.get("en", def.nameKey) .. "  ·  " .. Locale.get("ar", def.nameKey)
		MatchFxController.banner(t("match.boss_wave", { boss = t(def.nameKey) }), both, 2.6, Theme.colors.hpLow)
		AudioController.music("boss")
		if mo.camera and info then
			local path = Arenas[info.arenaId].path
			local spawnAt = (CFrame.new(info.origin) * CFrame.new(path[1][1], 0, path[1][2])).Position
			local m = Vfx.MOMENTS
			MatchCameraController.push(spawnAt, m.bossPush, m.pushDistance, m.pushHeight)
		end
	elseif mo.kind == "allyTurn" then
		-- He reaches our gate… and turns (Episode 8): the Hakawati's line, a gold pulse at him, and
		-- the camera pushed toward him (not with cutscenes off or Reduced Motion).
		local at = if mo.id then towerAt[mo.id] else nil
		MatchFxController.banner(t(mo.line or ""), t("play.hakawati"), Vfx.MOMENTS.allyLineHold, Theme.colors.gold)
		if at and Fx.any() then
			local cfg = Vfx.STORY.ally
			local pulse = Fx.part(Enum.PartType.Cylinder, true)
			if pulse then
				pulse.Color = Color3.fromHex(cfg.color)
				pulse.Transparency = 0.1
				pulse.Size = Vector3.new(0.3, 2, 2)
				pulse.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
				Fx.fade(pulse, cfg.pulseLife, { Size = Vector3.new(0.3, cfg.pulse * 2, cfg.pulse * 2), Transparency = 1 })
			end
		end
		if mo.camera and at then
			local m = Vfx.MOMENTS
			MatchCameraController.push(at, m.allyPush, m.allyPushDistance, m.allyPushHeight)
		end
	elseif mo.kind == "finalWave" then
		if mo.fx and info then
			finalWave(info.origin)
		end
	elseif mo.kind == "waveClear" then
		AudioController.music("match")
		topBanner(t("match.wave_cleared", { n = mo.wave }), if mo.bonus then t("match.wave_bonus", { n = mo.bonus }) else nil, Vfx.MOMENTS.clearHold)
		AudioController.sting("wave_clear")
	elseif mo.kind == "victory" then
		MatchFxController.banner(t("match.victory"), nil, 4, Theme.colors.gold)
		AudioController.sting("victory")
		AudioController.music(nil)
		if mo.fx and info then
			victoryFx(info.origin)
		end
	elseif mo.kind == "defeat" then
		MatchFxController.banner(t("match.defeat"), nil, 4, Theme.colors.hpLow)
		AudioController.sting("defeat")
		AudioController.music(nil)
		if mo.fx then
			defeatFx()
		end
	end
end

local function onEvents(events: { any })
	for _, e in events do
		if e.type == "reached" then
			MatchFxController.edgeFlash(Color3.fromHex(Vfx.GATE_HIT.color), Vfx.GATE_HIT.vignette, Vfx.GATE_HIT.vignetteLife)
			gateShudder()
		elseif e.type == "towerPlaced" then
			towerInfo[e.id] = { unitId = e.unitId, owner = e.owner }
			local info = MatchController.info()
			if info and type(e.x) == "number" and type(e.z) == "number" then
				local at = (CFrame.new(info.origin) * CFrame.new(e.x, 0, e.z)).Position
				towerAt[e.id] = at
				towerLanded(at)
			end
			if e.owner == Players.LocalPlayer.Name then
				PlacementController.popSlot(e.unitId)
			end
			if e.ally == true and type(e.unitId) == "string" and towerAt[e.id] then
				allyMark(e.id, e.unitId, towerAt[e.id])
			end
		elseif e.type == "towerUpgraded" then
			towerUpgraded(e.id, if type(e.level) == "number" then e.level else 1)
		elseif e.type == "towerSold" then
			local ti = towerInfo[e.id]
			local at = towerAt[e.id]
			if ti and at and ti.owner == Players.LocalPlayer.Name then
				towerSold(at)
			end
			towerInfo[e.id] = nil
			towerAt[e.id] = nil
		elseif e.type == "attack" and e.ability then
			ultimate(e)
		elseif e.type == "waveStart" or e.type == "waveEnd" or e.type == "won" or e.type == "lost" or e.type == "ally" then
			if e.type == "waveEnd" then
				AudioController.music("match")
			end
			if e.type == "waveStart" and duskMode and type(e.wave) == "number" then
				setDuskMix(MatchMoments.nightFraction(e.wave, LightLook.dusk.nightByWave))
			end
			local info = MatchController.info()
			local ep = if info then (Story.episodes :: any)[info.modeId] else nil
			local ctx: MatchMoments.Ctx = {
				-- The live state carries the wave total (Info.totalWaves is optional).
				totalWaves = (MatchController.state() or {}).totalWaves or (if info then info.totalWaves else nil),
				cutscenes = SettingsController.get("cutscenes") ~= false,
				effects = Fx.level(),
				reducedMotion = reducedMotion(),
				allyLine = if ep and ep.moments then ep.moments.ally_turn else nil,
			}
			for _, mo in MatchMoments.fromEvent(e, ctx) do
				playMoment(mo)
			end
		end
	end
end

function MatchFxController.start()
	build()
	buildTop()
	buildUltFx()
	MatchController.Started:Connect(function(info: MatchController.Info)
		local t = LocaleController.t
		towerInfo = {}
		clearAllies()
		duskMode = LightLook.dusk.modes[info.modeId] == true
		if duskMode then
			setDuskMix(0)
		else
			setNight(true)
		end
		AudioController.music("match")
		closeGate(info.origin)
		task.delay(0.6, function()
			MatchFxController.banner(t("match.gate_closing"), nil, 3.5)
		end)
	end)
	MatchController.Events:Connect(onEvents)
	MatchController.Ended:Connect(function()
		task.delay(3, function()
			restoreMoments()
			clearAllies()
			duskMode = false
			setNight(false)
			AudioController.music("lobby")
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(2)
			if night and not MatchController.active() then
				setNight(false)
				AudioController.music("lobby")
			end
		end
	end)
end

return MatchFxController
