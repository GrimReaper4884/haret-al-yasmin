--!strict
-- Match camera. Matches open on foot behind the player's character (the genre default: you walk
-- the arena and place defenders around you); the Settings "Match camera" choice can make them open
-- in the "watchtower" view instead, a tilted top-down view of the whole arena. A toggle in the
-- match HUD (and the V key) switches between the two. Always restored when the match ends.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Arenas = require(Shared.Config.Arenas)
local HitFx = require(Shared.Logic.HitFx)
local UI = script.Parent.Parent.UI
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local Root = require(UI.Root)
local MatchController = require(script.Parent.MatchController)
local LocaleController = require(script.Parent.LocaleController)
local SettingsController = require(script.Parent.SettingsController)

local MatchCameraController = {}

local overhead = false
local button: TextButton
local info: MatchController.Info? = nil

local function overheadCFrame(): CFrame?
	local i = info
	if not i then
		return nil
	end
	local def = Arenas[i.arenaId]
	local b = def.bounds
	local cx, cz = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
	local width = math.max(b[3] - b[1], b[4] - b[2])
	local origin = CFrame.new(i.origin)
	local center = (origin * CFrame.new(cx, 0, cz)).Position
	local eye = center + Vector3.new(0, width * 0.78, width * 0.42)
	return CFrame.lookAt(eye, center)
end

local function apply()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	-- On foot the phone keeps its thumbstick and jump button; the watchtower view hides them so
	-- taps go to placement.
	GuiService.TouchControlsEnabled = not overhead
	if overhead then
		local target = overheadCFrame()
		if target then
			camera.CameraType = Enum.CameraType.Scriptable
			TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { CFrame = target }):Play()
		end
	else
		camera.CameraType = Enum.CameraType.Custom
	end
	if button then
		button.Text = if overhead then LocaleController.t("match.camera_walk") else LocaleController.t("match.camera_overhead")
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
	button = Theme.button({
		Name = "CameraToggle",
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 56 + 4 * Theme.TOUCH + 4 * 6), -- below MatchController's right column (skip, speed, leave, codes)
		Size = UDim2.fromOffset(120, Theme.TOUCH),
		BackgroundColor3 = Theme.colors.textMuted,
		Visible = false,
		ZIndex = 3,
		Parent = Root.get(),
	})
	button.Activated:Connect(MatchCameraController.toggle)
	MatchController.Started:Connect(function(payload: MatchController.Info)
		info = payload
		overhead = SettingsController.get("camera") == "overhead"
		button.Visible = true
		task.delay(0.5, apply)
	end)
	MatchController.Ended:Connect(function()
		overhead = false
		button.Visible = false
		info = nil
		apply()
	end)
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
