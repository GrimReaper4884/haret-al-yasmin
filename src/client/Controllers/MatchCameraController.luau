--!strict
-- Match camera. Matches open on foot behind the player's character (the genre default: you walk
-- the arena and place defenders around you); the Settings "Match camera" choice can make them open
-- in the "watchtower" view instead, a tilted top-down view of the whole arena. The rail's View
-- button (MatchController.railButton "view") and the V key switch between the two. Always restored
-- when the match ends. In the watchtower view (MOBILE_HUD_PLAN B5) one finger pans and two pinch
-- the zoom on touch, WASD / the arrows pan and the wheel zooms on desktop, all clamped to the arena
-- (Logic/HudLayout.clampPan, Config/Hud CAMERA); View recentres a moved view. No momentum.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Arenas = require(Shared.Config.Arenas)
local HitFx = require(Shared.Logic.HitFx)
local HudLayout = require(Shared.Logic.HudLayout)
local Hud = require(Shared.Config.Hud)
local UI = script.Parent.Parent.UI
local Fx = require(UI.Fx)
local MatchController = require(script.Parent.MatchController)
local LocaleController = require(script.Parent.LocaleController)
local SettingsController = require(script.Parent.SettingsController)

local MatchCameraController = {}

local overhead = false
local button: TextButton
local label: TextLabel
local info: MatchController.Info? = nil
-- Watchtower pan (studs, arena space, from the arena's centre) and zoom (× the default distance).
local panX, panZ, zoom = 0, 0, 1

local function overheadCFrame(): CFrame?
	local i = info
	if not i then
		return nil
	end
	local def = Arenas[i.arenaId]
	local b = def.bounds
	local cx, cz = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
	local x, z = HudLayout.clampPan(cx + panX, cz + panZ, b, Hud.CAMERA.BOUNDS_MARGIN)
	panX, panZ = x - cx, z - cz
	local width = math.max(b[3] - b[1], b[4] - b[2]) * zoom
	local origin = CFrame.new(i.origin)
	local center = (origin * CFrame.new(x, 0, z)).Position
	local eye = center + Vector3.new(0, width * 0.78, width * 0.42)
	return CFrame.lookAt(eye, center)
end

-- Moves the watchtower view at once (no tween) after a pan or a zoom.
local function placeOverhead()
	local camera = Workspace.CurrentCamera
	local target = overheadCFrame()
	if camera and target and overhead and camera.CameraType == Enum.CameraType.Scriptable then
		camera.CFrame = target
	end
end

local function panBy(dxPx: number, dyPx: number)
	local k = Hud.CAMERA.PAN_STUDS_PER_PX * zoom
	panX -= dxPx * k
	panZ -= dyPx * k
	placeOverhead()
end

local function zoomTo(z: number)
	zoom = math.clamp(z, Hud.CAMERA.ZOOM.min, Hud.CAMERA.ZOOM.max)
	placeOverhead()
end

local function apply()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	-- On foot the phone keeps its thumbstick and jump button; the watchtower view hides them so
	-- taps go to placement, and so does aiming a defender on touch (MatchController.aiming).
	GuiService.TouchControlsEnabled = not overhead and not MatchController.aiming()
	if overhead then
		local target = overheadCFrame()
		if target then
			camera.CameraType = Enum.CameraType.Scriptable
			TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = target }):Play()
		end
	else
		camera.CameraType = Enum.CameraType.Custom
	end
	if label then
		label.Text = if overhead then LocaleController.t("match.view_walk") else LocaleController.t("match.view_tower")
	end
end

-- A short decaying camera shake (PV-B03: boss deaths). Effects "full" only, never under Reduced Motion.
local shakeAt: number? = nil
local shakeLife = 0
local shakeAmp = 0
local shakeSeed = 0
local applied = CFrame.identity

local function reducedMotion(): boolean
	local ok, v = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and v == true
end

function MatchCameraController.shake(seconds: number, amplitude: number)
	if not Fx.full() or reducedMotion() then
		return
	end
	shakeAt, shakeLife, shakeAmp, shakeSeed = os.clock(), seconds, amplitude, math.random() * 10
end

-- Boss intro (PV-B06): a short push toward `at` and back. The caller checks the cutscenes setting
-- (Logic/MatchMoments); a push already running is not restarted.
local pushing = false
function MatchCameraController.push(at: Vector3, seconds: number, distance: number, height: number)
	local camera = Workspace.CurrentCamera
	if not camera or pushing or reducedMotion() then
		return
	end
	pushing = true
	local prevType = camera.CameraType
	local start = camera.CFrame
	local away = Vector3.new(start.Position.X - at.X, 0, start.Position.Z - at.Z)
	away = if away.Magnitude > 0.1 then away.Unit else Vector3.new(0, 0, 1)
	local goal = CFrame.lookAt(at + away * distance + Vector3.new(0, height, 0), at + Vector3.new(0, 3, 0))
	camera.CameraType = Enum.CameraType.Scriptable
	local leg = math.min(0.45, seconds / 3)
	TweenService:Create(camera, TweenInfo.new(leg, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = goal }):Play()
	task.delay(seconds - leg, function()
		local back = TweenService:Create(camera, TweenInfo.new(leg, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = start })
		back:Play()
		back.Completed:Wait()
		camera.CameraType = prevType
		if overhead then
			apply()
		end
		pushing = false
	end)
end

function MatchCameraController.toggle()
	if not MatchController.active() then
		return
	end
	overhead = not overhead
	apply()
end

-- The View button: in a panned or zoomed watchtower view a tap recentres it (B5's "recentre"; a
-- double tap would land on a rail that has just moved, since leaving the watchtower brings Roblox's
-- jump button back); otherwise it toggles walk / watchtower.
local function onViewButton()
	if overhead and (math.abs(panX) > 0.01 or math.abs(panZ) > 0.01 or math.abs(zoom - 1) > 0.001) then
		panX, panZ, zoom = 0, 0, 1
		apply()
		return
	end
	MatchCameraController.toggle()
end

-- Pan and zoom inputs, live only in the watchtower view and never while a defender is aimed.
local function watchPanZoom()
	local panLast = Vector2.zero
	UserInputService.TouchPan:Connect(function(_touches: { Vector2 }, total: Vector2, _velocity: Vector2, state: Enum.UserInputState, processed: boolean)
		if not overhead or processed or MatchController.aiming() then
			return
		end
		if state == Enum.UserInputState.Begin then
			panLast = Vector2.zero
		end
		local d = total - panLast
		panLast = total
		panBy(d.X, d.Y)
	end)
	local zoomStart = 1
	UserInputService.TouchPinch:Connect(function(_touches: { Vector2 }, scale: number, _velocity: number, state: Enum.UserInputState, processed: boolean)
		if not overhead or processed or MatchController.aiming() or scale <= 0 then
			return
		end
		if state == Enum.UserInputState.Begin then
			zoomStart = zoom
		end
		zoomTo(zoomStart / scale)
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject, processed: boolean)
		if overhead and not processed and input.UserInputType == Enum.UserInputType.MouseWheel then
			zoomTo(zoom * (1 - 0.1 * input.Position.Z))
		end
	end)
	-- WASD / arrows pan the watchtower view on desktop; the character stands still meanwhile.
	local keys = {
		[Enum.KeyCode.W] = Vector2.new(0, 1),
		[Enum.KeyCode.Up] = Vector2.new(0, 1),
		[Enum.KeyCode.S] = Vector2.new(0, -1),
		[Enum.KeyCode.Down] = Vector2.new(0, -1),
		[Enum.KeyCode.A] = Vector2.new(1, 0),
		[Enum.KeyCode.Left] = Vector2.new(1, 0),
		[Enum.KeyCode.D] = Vector2.new(-1, 0),
		[Enum.KeyCode.Right] = Vector2.new(-1, 0),
	}
	local held: { [Enum.KeyCode]: boolean } = {}
	local list = {}
	for k in keys do
		table.insert(list, k)
	end
	ContextActionService:BindActionAtPriority("HaretOverheadPan", function(_name: string, state: Enum.UserInputState, input: InputObject)
		if not overhead or UserInputService:GetFocusedTextBox() then
			held[input.KeyCode] = nil
			return Enum.ContextActionResult.Pass
		end
		held[input.KeyCode] = state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, table.unpack(list))
	RunService.RenderStepped:Connect(function(dt: number)
		if not overhead then
			return
		end
		local v = Vector2.zero
		for k, on in held do
			if on then
				v += keys[k]
			end
		end
		if v.Magnitude > 0 then
			-- ~400 px of drag per second's worth of pan
			panBy(v.X * 400 * dt, v.Y * 400 * dt)
		end
	end)
end

function MatchCameraController.start()
	RunService:BindToRenderStep("HaretShakeUndo", Enum.RenderPriority.Camera.Value - 1, function()
		local camera = Workspace.CurrentCamera
		if camera and applied ~= CFrame.identity then
			camera.CFrame = camera.CFrame * applied:Inverse()
			applied = CFrame.identity
		end
	end)
	RunService:BindToRenderStep("HaretShake", Enum.RenderPriority.Camera.Value + 1, function()
		local camera = Workspace.CurrentCamera
		local at = shakeAt
		if not camera or not at then
			return
		end
		local dx, dy = HitFx.shake(os.clock() - at, shakeLife, shakeAmp, shakeSeed)
		if dx == 0 and dy == 0 then
			shakeAt = nil
			return
		end
		applied = CFrame.new(dx, dy, 0)
		camera.CFrame = camera.CFrame * applied
	end)
	button, label = MatchController.railButton("view")
	MatchController.AimingChanged:Connect(function()
		GuiService.TouchControlsEnabled = not overhead and not MatchController.aiming()
	end)
	button.Activated:Connect(onViewButton)
	watchPanZoom()
	MatchController.Started:Connect(function(payload: MatchController.Info)
		info = payload
		panX, panZ, zoom = 0, 0, 1
		overhead = SettingsController.get("camera") == "overhead"
		task.delay(0.5, apply)
	end)
	MatchController.Ended:Connect(function()
		overhead = false
		info = nil
		apply()
	end)
	apply()
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.V then
			MatchCameraController.toggle()
		end
	end)
	LocaleController.Changed:Connect(apply)
	task.spawn(function()
		while true do
			task.wait(1)
			if overhead and not MatchController.active() then
				overhead = false
				apply()
			end
		end
	end)
end

return MatchCameraController
