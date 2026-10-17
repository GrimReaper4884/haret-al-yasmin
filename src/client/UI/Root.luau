--!strict
-- The single ScreenGui all controllers draw into. Layouts are authored in offsets for a phone
-- in landscape (~844×390) and a UIScale adapts them to the viewport, clamped for big screens.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Create = require(script.Parent.Create)

local Root = {}

local gui: ScreenGui? = nil

local function fitScale(scale: UIScale)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local v = camera.ViewportSize
	-- Phone landscape height ≈ 390 → 1.0; tablets/desktop grow up to 1.5; tiny screens down to 0.8.
	scale.Scale = math.clamp(math.min(v.Y / 390, v.X / 760), 0.8, 1.5)
end

function Root.get(): ScreenGui
	if gui then
		return gui
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = Create("ScreenGui", {
		Name = "HaretHud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Parent = playerGui,
	})
	local scale = Create("UIScale", { Parent = screen })
	fitScale(scale)
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			fitScale(scale)
		end)
	end
	gui = screen
	return screen
end

return Root
