--!strict
-- The cinematic side of a match: the gate-closing moment at the start (the leaves swing shut,
-- the bar drops, "the watchman bars the gate"), wave and boss banners, night lighting over the
-- arena (local to this client), music switches and the victory / defeat stings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared.Config.Enemies)
local UI = script.Parent.Parent.UI
local Theme = require(UI.Theme)
local Root = require(UI.Root)
local LocaleController = require(script.Parent.LocaleController)
local MatchController = require(script.Parent.MatchController)
local AudioController = require(script.Parent.AudioController)

local MatchFxController = {}

local banner: TextLabel
local sub: TextLabel
local dayClock = 15.6
local dayBrightness = 2.4
local night = false

local function build()
	banner = Theme.label({
		Name = "Banner",
		TextSize = 40,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.colors.buttonText,
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = Theme.colors.text,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(1, 0, 0, 50),
		TextTransparency = 1,
		ZIndex = 6,
		Parent = Root.get(),
	})
	banner.TextXAlignment = Enum.TextXAlignment.Center
	sub = Theme.label({
		Name = "BannerSub",
		TextSize = 18,
		FontFace = Theme.fontBold,
		TextColor3 = Theme.lira,
		TextStrokeTransparency = 0.3,
		TextStrokeColor3 = Theme.colors.text,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(1, 0, 0, 24),
		TextTransparency = 1,
		ZIndex = 6,
		Parent = Root.get(),
	})
	sub.TextXAlignment = Enum.TextXAlignment.Center
end

function MatchFxController.banner(text: string, subText: string?, hold: number?)
	banner.Text = text
	sub.Text = subText or ""
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0.2
	sub.TextTransparency = if subText then 0 else 1
	sub.TextStrokeTransparency = if subText then 0.3 else 1
	banner.Position = UDim2.fromScale(0.5, 0.26)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.3) }):Play()
	task.delay(hold or 2.2, function()
		TweenService:Create(banner, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(sub, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
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

local function onEvents(events: { any })
	local t = LocaleController.t
	for _, e in events do
		if e.type == "waveStart" then
			if e.boss then
				MatchFxController.banner(t("match.boss_wave", { boss = t((Enemies :: any)[e.boss].nameKey) }), t("match.wave_start", { n = e.wave }), 2.6)
				AudioController.music("boss")
			else
				MatchFxController.banner(t("match.wave_start", { n = e.wave }))
				AudioController.sting("wave_start")
			end
		elseif e.type == "waveEnd" then
			AudioController.music("match")
		elseif e.type == "won" then
			MatchFxController.banner(t("match.victory"), nil, 4)
			AudioController.sting("victory")
			AudioController.music(nil)
		elseif e.type == "lost" then
			MatchFxController.banner(t("match.defeat"), nil, 4)
			AudioController.sting("defeat")
			AudioController.music(nil)
		end
	end
end

function MatchFxController.start()
	build()
	MatchController.Started:Connect(function(info: MatchController.Info)
		local t = LocaleController.t
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
