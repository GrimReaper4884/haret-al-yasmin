--!strict
-- The cinematic side of a match: the gate-closing moment at the start (the leaves swing shut,
-- the bar drops, "the watchman bars the gate"), wave and boss banners, night lighting over the
-- arena (local to this client), music switches and the victory / defeat stings.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared.Config.Enemies)
local Units = require(Shared.Config.Units)
local Vfx = require(Shared.Config.Vfx)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local Root = require(UI.Root)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local AudioController = require(script.Parent.AudioController)

local MatchFxController = {}

local band: Frame
local banner: TextLabel
local sub: TextLabel
local bannerToken = 0
local dayClock = 15.6
local dayBrightness = 2.4
local night = false

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
		ClockTime = if on then 19.4 else dayClock,
		Brightness = if on then 1.4 else dayBrightness,
	}):Play()
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

local function onEvents(events: { any })
	local t = LocaleController.t
	for _, e in events do
		if e.type == "reached" then
			MatchFxController.edgeFlash(Color3.fromHex(Vfx.GATE_HIT.color), Vfx.GATE_HIT.vignette, Vfx.GATE_HIT.vignetteLife)
		elseif e.type == "towerPlaced" then
			towerInfo[e.id] = { unitId = e.unitId, owner = e.owner }
		elseif e.type == "towerSold" then
			towerInfo[e.id] = nil
		elseif e.type == "attack" and e.ability then
			ultimate(e)
		elseif e.type == "waveStart" then
			if e.boss then
				MatchFxController.banner(t("match.boss_wave", { boss = t((Enemies :: any)[e.boss].nameKey) }), t("match.wave_start", { n = e.wave }), 2.6, Theme.colors.hpLow)
				AudioController.music("boss")
			else
				MatchFxController.banner(t("match.wave_start", { n = e.wave }))
				AudioController.sting("wave_start")
			end
		elseif e.type == "waveEnd" then
			AudioController.music("match")
			if e.wave and not (MatchController.info() and (MatchController.info() :: any).totalWaves == e.wave) then
				MatchFxController.banner(t("match.wave_cleared", { n = e.wave }), if e.bonus then t("match.wave_bonus", { n = e.bonus }) else nil, 1.6, Theme.colors.confirm:Lerp(Color3.new(1, 1, 1), 0.3))
			end
		elseif e.type == "won" then
			MatchFxController.banner(t("match.victory"), nil, 4, Theme.colors.gold)
			AudioController.sting("victory")
			AudioController.music(nil)
		elseif e.type == "lost" then
			MatchFxController.banner(t("match.defeat"), nil, 4, Theme.colors.hpLow)
			AudioController.sting("defeat")
			AudioController.music(nil)
		end
	end
end

function MatchFxController.start()
	build()
	buildUltFx()
	MatchController.Started:Connect(function(info: MatchController.Info)
		local t = LocaleController.t
		towerInfo = {}
		setNight(true)
		AudioController.music("match")
		closeGate(info.origin)
		task.delay(0.6, function()
			MatchFxController.banner(t("match.gate_closing"), nil, 3.5)
		end)
	end)
	MatchController.Events:Connect(onEvents)
	MatchController.Ended:Connect(function()
		task.delay(3, function()
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
