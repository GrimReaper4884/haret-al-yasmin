--!strict
-- The single ScreenGui all controllers draw into. Layouts are authored in offsets for a landscape
-- phone's safe area at UIScale 1; UI/Device sets the one UIScale from the layout profile, the safe-area
-- size and the player's uiScale preset (Logic/HudLayout.scale).

local Players = game:GetService("Players")

local Create = require(script.Parent.Create)

local Root = {}

local gui: ScreenGui? = nil

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
	Create("UIScale", { Parent = screen })
	gui = screen
	return screen
end

return Root
