--!strict
-- Item icons drawn from UI primitives (no uploaded images). Items.icon names a drawer and
-- Items.iconColor tints it. Unknown names fall back to text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Create = require(script.Parent.Create)

local Icons = {}

local function darker(c: Color3): Color3
	local h, s, v = c:ToHSV()
	return Color3.fromHSV(h, s, v * 0.7)
end

local function rect(holder: Frame, color: Color3, x: number, y: number, w: number, h: number, radius: number?, rot: number?): Frame
	return Create("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(w, h),
		Rotation = rot or 0,
		Parent = holder,
	}, { Create("UICorner", { CornerRadius = UDim.new(radius or 0.15, 0) }) })
end

local drawers: { [string]: (Frame, Color3) -> () } = {
	tarboosh = function(h, c)
		rect(h, c, 0.5, 0.58, 0.6, 0.6, 0.12)
		rect(h, darker(c), 0.5, 0.29, 0.5, 0.08, 1)
		rect(h, Palette.ink, 0.66, 0.45, 0.06, 0.36, 0.5, 12)
	end,
	cap = function(h, c)
		rect(h, c, 0.5, 0.6, 0.66, 0.34, 0.5)
		rect(h, darker(c), 0.5, 0.74, 0.7, 0.07, 1)
	end,
	hatta = function(h, c)
		rect(h, c, 0.5, 0.55, 0.72, 0.62, 0.2)
		rect(h, Palette.ink, 0.5, 0.36, 0.7, 0.09, 1)
		rect(h, Palette.fabricRed, 0.5, 0.62, 0.7, 0.04, 0)
		rect(h, Palette.fabricRed, 0.5, 0.75, 0.7, 0.04, 0)
	end,
	vest = function(h, c)
		rect(h, c, 0.36, 0.55, 0.26, 0.66, 0.15)
		rect(h, c, 0.64, 0.55, 0.26, 0.66, 0.15)
		rect(h, Color3.fromHex("#C9A13B"), 0.5, 0.55, 0.04, 0.6, 0)
	end,
	robe = function(h, c)
		rect(h, c, 0.5, 0.55, 0.56, 0.82, 0.12)
		rect(h, darker(c), 0.42, 0.6, 0.04, 0.7, 0)
		rect(h, darker(c), 0.58, 0.6, 0.04, 0.7, 0)
	end,
	trousers = function(h, c)
		rect(h, c, 0.36, 0.55, 0.3, 0.7, 0.35)
		rect(h, c, 0.64, 0.55, 0.3, 0.7, 0.35)
		rect(h, c, 0.5, 0.26, 0.6, 0.14, 0.1)
	end,
	sash = function(h, c)
		rect(h, c, 0.5, 0.45, 0.78, 0.2, 0.2)
		rect(h, darker(c), 0.66, 0.65, 0.12, 0.38, 0.3, 10)
	end,
	cloak = function(h, c)
		rect(h, c, 0.5, 0.56, 0.7, 0.8, 0.12)
		rect(h, darker(c), 0.5, 0.2, 0.5, 0.1, 1)
	end,
	coins = function(h, _c)
		rect(h, Palette.copper, 0.4, 0.62, 0.42, 0.42, 1)
		rect(h, Color3.fromHex("#C9A13B"), 0.6, 0.45, 0.42, 0.42, 1)
	end,
	basket = function(h, _c)
		rect(h, Palette.wood, 0.5, 0.66, 0.75, 0.4, 0.2)
		rect(h, Palette.copper, 0.5, 0.42, 0.6, 0.18, 1)
	end,
	pass = function(h, _c)
		rect(h, Palette.tile, 0.5, 0.5, 0.78, 0.56, 0.15)
		rect(h, Color3.fromHex("#C9A13B"), 0.5, 0.5, 0.3, 0.3, 1)
	end,
}

function Icons.draw(name: string, holder: Frame, colorHex: string?)
	local drawer = drawers[name]
	local color = if colorHex then Color3.fromHex(colorHex) else Palette.copper
	if drawer then
		drawer(holder, color)
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
