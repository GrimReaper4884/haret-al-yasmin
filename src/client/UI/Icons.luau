--!strict
-- Icons: the painted image from Config/Icons when its id is set, otherwise a drawer built from UI
-- primitives (Items.icon names a drawer, Items.iconColor tints it). Unknown names fall back to text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local IconIds = require(ReplicatedStorage:WaitForChild("Shared").Config.Icons)
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

-- An outlined shape for the bold menu icons.
local OUTLINE = Color3.fromHex("#22180F")
local function rectO(holder: Frame, color: Color3, x: number, y: number, w: number, h: number, radius: number?, rot: number?): Frame
	local f = rect(holder, color, x, y, w, h, radius, rot)
	Create("UIStroke", { Color = OUTLINE, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
	return f
end

local WHITE = Color3.fromHex("#FBF8F1")
local GOLD = Color3.fromHex("#F2C14E")

-- A speaker (box + stepped cone on a dark silhouette) with three sound arcs: rings clipped to
-- their right half.
local function speaker(h: Frame)
	local body = Color3.fromHex("#D8DCE0")
	local shape = { { 0.2, 0.14, 0.3 }, { 0.3, 0.08, 0.44 }, { 0.37, 0.08, 0.58 }, { 0.43, 0.06, 0.72 } }
	for _, r in shape do
		rect(h, OUTLINE, r[1], 0.5, r[2] + 0.1, r[3] + 0.1, 0.2)
	end
	for _, r in shape do
		rect(h, body, r[1], 0.5, r[2] + 0.005, r[3], 0.2)
	end
	local clip = Create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.5, 1),
		Parent = h,
	})
	for k, d in { 0.3, 0.54, 0.78 } do
		Create("Frame", {
			Name = "Arc" .. k,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(-0.04, 0.5),
			Size = UDim2.fromScale(d * 2, d),
			Parent = clip,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Create("UIStroke", { Color = WHITE, Thickness = 2, Transparency = (k - 1) * 0.15 }),
		})
	end
end

local drawers: { [string]: (Frame, Color3) -> () } = {
	-- Menu rail icons (lobby). Bold, outlined, readable at 30 px.
	ui_units = function(h, _c)
		rectO(h, Color3.fromHex("#D8DCE0"), 0.42, 0.42, 0.12, 0.72, 0.3, 45)
		rectO(h, GOLD, 0.6, 0.6, 0.36, 0.1, 0.5, 45)
		rectO(h, Palette.fabricRed, 0.7, 0.7, 0.42, 0.46, 1)
		rectO(h, GOLD, 0.7, 0.7, 0.16, 0.16, 1)
	end,
	ui_summon = function(h, _c)
		rectO(h, GOLD, 0.5, 0.5, 0.56, 0.56, 0.12, 0)
		rectO(h, GOLD, 0.5, 0.5, 0.56, 0.56, 0.12, 45)
		rect(h, WHITE, 0.5, 0.5, 0.24, 0.24, 1)
	end,
	ui_pass = function(h, _c)
		rectO(h, Color3.fromHex("#EADFC8"), 0.5, 0.52, 0.66, 0.74, 0.12)
		rect(h, Palette.tile, 0.5, 0.36, 0.46, 0.08, 0.5)
		rect(h, Palette.ink, 0.5, 0.52, 0.46, 0.06, 0.5)
		rect(h, Palette.ink, 0.5, 0.64, 0.36, 0.06, 0.5)
		rectO(h, Palette.fabricRed, 0.72, 0.18, 0.14, 0.3, 0.2)
	end,
	ui_codes = function(h, _c)
		rectO(h, Color3.fromHex("#4FB3A8"), 0.5, 0.5, 0.78, 0.48, 0.15, -12)
		rect(h, WHITE, 0.5, 0.5, 0.06, 0.38, 0.5, -12)
		rect(h, WHITE, 0.32, 0.47, 0.18, 0.08, 0.5, -12)
		rect(h, WHITE, 0.68, 0.53, 0.18, 0.08, 0.5, -12)
	end,
	ui_play = function(h, _c)
		-- An ablaq arch: two pillars, a striped lintel and a gold flag.
		rectO(h, Color3.fromHex("#EADFC8"), 0.26, 0.6, 0.16, 0.66, 0.15)
		rectO(h, Color3.fromHex("#EADFC8"), 0.74, 0.6, 0.16, 0.66, 0.15)
		rectO(h, Color3.fromHex("#EADFC8"), 0.5, 0.26, 0.74, 0.18, 0.3)
		rect(h, Palette.basalt, 0.38, 0.26, 0.1, 0.16, 0)
		rect(h, Palette.basalt, 0.62, 0.26, 0.1, 0.16, 0)
		rectO(h, GOLD, 0.5, 0.62, 0.22, 0.3, 0.2)
	end,
	ui_event = function(h, _c)
		-- A hanging crescent lantern.
		rect(h, Palette.ink, 0.5, 0.12, 0.05, 0.16, 0)
		rectO(h, GOLD, 0.5, 0.56, 0.5, 0.62, 0.35)
		rect(h, Color3.fromHex("#FFF2B8"), 0.5, 0.56, 0.28, 0.38, 0.4)
		rectO(h, Color3.fromHex("#2F7D6B"), 0.5, 0.25, 0.3, 0.1, 0.5)
	end,
	ui_settings = function(h, _c)
		-- A gear: four rotated teeth bars around a hub.
		for k = 0, 3 do
			rectO(h, Color3.fromHex("#D8DCE0"), 0.5, 0.5, 0.2, 0.86, 0.2, k * 45)
		end
		rectO(h, Color3.fromHex("#D8DCE0"), 0.5, 0.5, 0.6, 0.6, 1)
		rectO(h, Color3.fromHex("#6E5E50"), 0.5, 0.5, 0.26, 0.26, 1)
	end,
	ui_afk = function(h, _c)
		-- A glass of tea on a brass saucer, with steam.
		rectO(h, GOLD, 0.5, 0.86, 0.78, 0.1, 1)
		rectO(h, Color3.fromHex("#F5E6C8"), 0.5, 0.6, 0.42, 0.44, 0.25)
		rect(h, Color3.fromHex("#B5532A"), 0.5, 0.66, 0.34, 0.28, 0.25)
		rect(h, WHITE, 0.4, 0.22, 0.06, 0.2, 0.5, 15)
		rect(h, WHITE, 0.58, 0.18, 0.06, 0.22, 0.5, -15)
	end,
	ui_daily = function(h, _c)
		rectO(h, Palette.fabricRed, 0.5, 0.62, 0.66, 0.5, 0.12)
		rectO(h, Palette.fabricRed, 0.5, 0.36, 0.76, 0.16, 0.12)
		rect(h, GOLD, 0.5, 0.56, 0.12, 0.62, 0)
		rectO(h, GOLD, 0.4, 0.2, 0.2, 0.14, 1, -25)
		rectO(h, GOLD, 0.6, 0.2, 0.2, 0.14, 1, 25)
	end,
	ui_music = function(h, _c)
		speaker(h)
	end,
	ui_music_off = function(h, _c)
		speaker(h)
		-- The red slash across the whole speaker.
		rectO(h, Color3.fromHex("#E0433A"), 0.5, 0.5, 0.13, 1.02, 0.5, -45)
	end,

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
	lira = function(h, _c)
		rectO(h, Color3.fromHex("#C9A13B"), 0.5, 0.5, 0.6, 0.6, 1)
		rect(h, Color3.fromHex("#E8D07A"), 0.5, 0.5, 0.36, 0.36, 1)
	end,
	stone = function(h, _c)
		rect(h, Color3.fromHex("#7B3FA0"), 0.5, 0.55, 0.5, 0.5, 0.2, 45)
		rect(h, Color3.fromHex("#B98BD6"), 0.5, 0.5, 0.2, 0.2, 0.2, 45)
	end,
	pass = function(h, _c)
		rect(h, Palette.tile, 0.5, 0.5, 0.78, 0.56, 0.15)
		rect(h, Color3.fromHex("#C9A13B"), 0.5, 0.5, 0.3, 0.3, 1)
	end,
	-- Placeholders for the PV-C03 currency kit until the painted images are uploaded.
	qirsh = function(h, _c)
		rectO(h, Palette.copper, 0.5, 0.5, 0.62, 0.62, 1)
		rect(h, Color3.fromHex("#8A5426"), 0.5, 0.5, 0.26, 0.26, 1)
	end,
	cash = function(h, _c)
		rectO(h, Color3.fromHex("#D9A441"), 0.5, 0.5, 0.62, 0.62, 1)
		rect(h, Palette.basalt, 0.5, 0.54, 0.18, 0.22, 0.2)
		rect(h, Palette.basalt, 0.5, 0.42, 0.24, 0.08, 1)
	end,
	stones_3 = function(h, _c)
		rectO(h, Color3.fromHex("#C9A13B"), 0.5, 0.74, 0.86, 0.18, 1)
		for _, x in { 0.3, 0.5, 0.7 } do
			rectO(h, Color3.fromHex("#7B3FA0"), x, if x == 0.5 then 0.48 else 0.56, 0.24, 0.24, 0.2, 45)
		end
	end,
	xp = function(h, _c)
		rectO(h, Color3.fromHex("#EADFC8"), 0.46, 0.52, 0.56, 0.72, 0.1)
		rect(h, Palette.ink, 0.46, 0.4, 0.36, 0.05, 0.5)
		rect(h, Palette.ink, 0.46, 0.52, 0.36, 0.05, 0.5)
		rectO(h, Palette.fabricRed, 0.7, 0.74, 0.22, 0.22, 1)
	end,
	ticket = function(h, _c)
		rectO(h, Color3.fromHex("#F1E9DA"), 0.5, 0.5, 0.82, 0.5, 0.12, -10)
		rectO(h, GOLD, 0.5, 0.5, 0.2, 0.28, 0.35, -10)
	end,
	lira_stack = function(h, _c)
		for k = 0, 2 do
			rectO(h, Color3.fromHex("#C9A13B"), 0.5, 0.74 - k * 0.16, 0.7, 0.2, 1)
		end
		rectO(h, Color3.fromHex("#E8D07A"), 0.5, 0.3, 0.7, 0.2, 1)
	end,
	qirsh_pouch = function(h, _c)
		rectO(h, Palette.wood, 0.5, 0.58, 0.62, 0.6, 0.4)
		rect(h, Palette.woodDark, 0.5, 0.3, 0.4, 0.08, 1)
		rectO(h, Palette.copper, 0.78, 0.78, 0.26, 0.26, 1)
	end,
}

-- An uploaded painted image for `name` (Config/Icons id > 0), fitted to the holder.
local function image(name: string, holder: Frame): boolean
	local def = IconIds.images[name]
	if not def or def.id == 0 then
		return false
	end
	local img = Create("ImageLabel", {
		Name = "Image",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = "rbxassetid://" .. tostring(def.id),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	if def.tint then
		img.ImageColor3 = Color3.fromHex(def.tint)
	end
	return true
end

-- Draws icon `name` into `holder`: the uploaded image when Config/Icons has an id, else the
-- primitive drawer (tinted by colorHex), else the name as text.
function Icons.draw(name: string, holder: Frame, colorHex: string?)
	if image(name, holder) then
		return
	end
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
