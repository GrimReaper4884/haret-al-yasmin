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

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Arenas = require(Shared.Config.Arenas)
local UI = script.Parent.Parent.UI
local Theme = require(UI.Theme)
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

function MatchCameraController.toggle()
	if not MatchController.active() then
		return
	end
	overhead = not overhead
	apply()
end

function MatchCameraController.start()
	button = Theme.button({
		Name = "CameraToggle",
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 232),
		Size = UDim2.fromOffset(120, Theme.TOUCH - 4),
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
