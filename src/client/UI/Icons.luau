--!strict
-- Item icons drawn from UI primitives (no uploaded images). Items.icon names one of these;
-- unknown names fall back to rendering the name as text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Create = require(script.Parent.Create)

local Icons = {}

local drawers: { [string]: (Frame) -> () } = {
	tarboosh = function(holder)
		-- Truncated cone: a slightly wider base under a rounded crown, plus a black tassel.
		Create("Frame", {
			BackgroundColor3 = Palette.fabricRed,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.88),
			Size = UDim2.fromScale(0.62, 0.62),
			Parent = holder,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Create("UIGradient", {
				Color = ColorSequence.new(Palette.fabricRed, Color3.fromHex("#7A211D")),
				Rotation = 0,
			}),
		})
		Create("Frame", {
			BackgroundColor3 = Color3.fromHex("#7A211D"),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.27),
			Size = UDim2.fromScale(0.5, 0.08),
			Parent = holder,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		Create("Frame", {
			BackgroundColor3 = Palette.ink,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.62, 0.26),
			Size = UDim2.fromScale(0.06, 0.38),
			Rotation = 12,
			Parent = holder,
		})
	end,
	basket = function(holder)
		Create("Frame", {
			BackgroundColor3 = Palette.wood,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.85),
			Size = UDim2.fromScale(0.75, 0.4),
			Parent = holder,
		}, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
		Create("Frame", {
			BackgroundColor3 = Palette.copper,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.48),
			Size = UDim2.fromScale(0.6, 0.18),
			Parent = holder,
		}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end,
}

function Icons.draw(name: string, holder: Frame)
	local drawer = drawers[name]
	if drawer then
		drawer(holder)
		return
	end
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = name,
		TextScaled = true,
		Parent = holder,
	})
	label.TextColor3 = Palette.ink
end

return Icons
