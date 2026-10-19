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

-- A glass bead on its thread, in `hex`, with a highlight (the shabriyeh beads, S1-C04).
local function beadOf(h: Frame, hex: string)
	rect(h, Palette.woodDark, 0.5, 0.5, 0.06, 0.9, 0.5)
	rectO(h, Color3.fromHex(hex), 0.5, 0.5, 0.62, 0.62, 1)
	rect(h, Color3.fromHex("#FFFFFF"), 0.4, 0.38, 0.16, 0.16, 1).BackgroundTransparency = 0.35
end

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
	fanous = function(h, c)
		-- A little brass lantern with amber glass (the Lantern Nights cosmetic, LP-D12).
		rect(h, Palette.ink, 0.5, 0.1, 0.05, 0.14, 0)
		rectO(h, c, 0.5, 0.24, 0.42, 0.12, 0.3)
		rectO(h, c, 0.5, 0.56, 0.5, 0.54, 0.2)
		rect(h, Color3.fromHex("#F2B84B"), 0.5, 0.56, 0.34, 0.42, 0.15)
		rectO(h, c, 0.5, 0.88, 0.56, 0.1, 0.3)
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
	-- PV-C04 fallbacks (painted versions in assets/marketing/icons, ids in Config/Icons).
	ui_shop = function(h, _c)
		rectO(h, Palette.copper, 0.5, 0.45, 0.08, 0.6, 0.5)
		rectO(h, Palette.copper, 0.5, 0.25, 0.8, 0.07, 0.5)
		rectO(h, Palette.copper, 0.2, 0.55, 0.3, 0.12, 1)
		rectO(h, Palette.copper, 0.8, 0.55, 0.3, 0.12, 1)
		rectO(h, Palette.copper, 0.5, 0.82, 0.44, 0.1, 0.5)
	end,
	act_upgrade = function(h, _c)
		rectO(h, Color3.fromHex("#4CAF50"), 0.45, 0.6, 0.22, 0.5, 0.2)
		rectO(h, Color3.fromHex("#4CAF50"), 0.45, 0.32, 0.4, 0.4, 0.15, 45)
		rectO(h, GOLD, 0.75, 0.75, 0.24, 0.24, 0.2, 45)
	end,
	act_sell = function(h, _c)
		rectO(h, Palette.wood, 0.5, 0.62, 0.6, 0.55, 0.4)
		rectO(h, GOLD, 0.5, 0.22, 0.24, 0.24, 1)
	end,
	act_target = function(h, _c)
		rectO(h, WHITE, 0.5, 0.5, 0.86, 0.5, 1)
		rectO(h, Palette.copper, 0.5, 0.5, 0.36, 0.36, 1)
		rect(h, Palette.ink, 0.5, 0.5, 0.15, 0.15, 1)
	end,
	act_speed = function(h, _c)
		rectO(h, Color3.fromHex("#F1E2C2"), 0.5, 0.24, 0.6, 0.16, 1)
		rectO(h, Palette.fabricRed, 0.5, 0.48, 0.5, 0.36, 0.3)
		rectO(h, Palette.fabricRed, 0.5, 0.76, 0.26, 0.3, 0.2)
	end,
	act_skip = function(h, _c)
		for _, x in { 0.36, 0.64 } do
			rectO(h, Color3.fromHex("#F2A83A"), x, 0.38, 0.12, 0.36, 0.3, -40)
			rectO(h, Color3.fromHex("#F2A83A"), x, 0.62, 0.12, 0.36, 0.3, 40)
		end
	end,
	act_leave = function(h, _c)
		rectO(h, Palette.stoneWarm, 0.5, 0.52, 0.66, 0.82, 0.25)
		rectO(h, Palette.wood, 0.5, 0.56, 0.48, 0.7, 0.2)
		rect(h, GOLD, 0.62, 0.56, 0.08, 0.08, 1)
	end,
	role_melee = function(h, _c)
		rectO(h, Color3.fromHex("#D8DCE0"), 0.45, 0.42, 0.14, 0.62, 0.5, 20)
		rectO(h, GOLD, 0.58, 0.76, 0.34, 0.1, 0.5, 20)
		rectO(h, Palette.wood, 0.63, 0.88, 0.1, 0.18, 0.4, 20)
	end,
	role_ranged = function(h, _c)
		rectO(h, Palette.copper, 0.5, 0.58, 0.5, 0.2, 1)
		rect(h, Palette.wood, 0.3, 0.3, 0.05, 0.5, 0.5, -20)
		rect(h, Palette.wood, 0.7, 0.3, 0.05, 0.5, 0.5, 20)
		rectO(h, Color3.fromHex("#A79E92"), 0.5, 0.56, 0.18, 0.18, 1)
	end,
	role_splash = function(h, _c)
		rectO(h, Palette.wood, 0.4, 0.66, 0.1, 0.6, 0.5, 35)
		rectO(h, Color3.fromHex("#E8C778"), 0.66, 0.32, 0.46, 0.46, 1)
	end,
	role_support = function(h, _c)
		rectO(h, GOLD, 0.5, 0.56, 0.44, 0.56, 0.3)
		rect(h, Color3.fromHex("#FFF2B8"), 0.5, 0.56, 0.24, 0.32, 0.4)
		rectO(h, GOLD, 0.5, 0.2, 0.2, 0.12, 0.5)
	end,
	role_healer = function(h, _c)
		rectO(h, Color3.fromHex("#9BE3A6"), 0.5, 0.6, 0.5, 0.56, 0.35)
		rectO(h, Palette.wood, 0.5, 0.24, 0.26, 0.14, 0.3)
	end,
	role_farm = function(h, _c)
		rectO(h, GOLD, 0.48, 0.62, 0.44, 0.5, 0.4)
		rectO(h, GOLD, 0.48, 0.28, 0.2, 0.2, 0.4)
		rectO(h, GOLD, 0.8, 0.46, 0.1, 0.36, 0.5, 35)
	end,
	gem = function(h, c)
		rectO(h, c, 0.5, 0.5, 0.5, 0.5, 0.15, 45)
		rect(h, WHITE, 0.42, 0.42, 0.14, 0.14, 0.3, 45)
	end,
	-- Enemy markers on health bars (PV-A04): armour and stealth.
	shield = function(h, _c)
		rectO(h, Color3.fromHex("#B8BEC6"), 0.5, 0.45, 0.7, 0.62, 0.25)
		rectO(h, Color3.fromHex("#B8BEC6"), 0.5, 0.72, 0.4, 0.4, 0.2, 45)
		rect(h, Color3.fromHex("#6E7782"), 0.5, 0.55, 0.12, 0.6, 0.5)
	end,
	eye = function(h, _c)
		rectO(h, WHITE, 0.5, 0.5, 0.86, 0.5, 1)
		rectO(h, Color3.fromHex("#6B4FA0"), 0.5, 0.5, 0.36, 0.36, 1)
		rect(h, Palette.ink, 0.5, 0.5, 0.15, 0.15, 1)
	end,
	-- Story mechanics on the Play panel (S1-C01, Config/Icons.mechanics) until painted versions exist.
	mech_armor = function(h, _c)
		local steel = Color3.fromHex("#AEB6BF")
		rectO(h, steel, 0.27, 0.3, 0.26, 0.2, 0.4)
		rectO(h, steel, 0.73, 0.3, 0.26, 0.2, 0.4)
		rectO(h, steel, 0.5, 0.56, 0.56, 0.64, 0.3)
		rect(h, Color3.fromHex("#6E7782"), 0.5, 0.56, 0.08, 0.52, 0.5)
	end,
	mech_fast = function(h, _c)
		for _, x in { 0.3, 0.52, 0.74 } do
			rectO(h, GOLD, x, 0.37, 0.1, 0.34, 0.5, -40)
			rectO(h, GOLD, x, 0.63, 0.1, 0.34, 0.5, 40)
		end
	end,
	mech_sapper = function(h, _c)
		rectO(h, Palette.basalt, 0.44, 0.6, 0.56, 0.56, 1)
		rect(h, WHITE, 0.34, 0.5, 0.12, 0.12, 1)
		rect(h, Palette.wood, 0.7, 0.3, 0.07, 0.26, 0.5, 35)
		rectO(h, GOLD, 0.8, 0.16, 0.16, 0.16, 1)
	end,
	mech_swarm = function(h, _c)
		local red = Color3.fromHex("#9A3B2E")
		for _, p in { { 0.25, 0.3 }, { 0.62, 0.22 }, { 0.42, 0.55 }, { 0.78, 0.55 }, { 0.24, 0.78 }, { 0.6, 0.82 } } do
			rectO(h, red, p[1], p[2], 0.2, 0.2, 1)
		end
	end,
	mech_drum = function(h, _c)
		rect(h, Palette.wood, 0.3, 0.2, 0.06, 0.34, 0.5, -35)
		rect(h, Palette.wood, 0.7, 0.2, 0.06, 0.34, 0.5, 35)
		rectO(h, Palette.fabricRed, 0.5, 0.64, 0.7, 0.42, 0.2)
		rectO(h, Color3.fromHex("#EADFC8"), 0.5, 0.44, 0.7, 0.18, 1)
	end,
	mech_roads = function(h, _c)
		local sand = Color3.fromHex("#D9C29A")
		rectO(h, sand, 0.32, 0.32, 0.16, 0.52, 0.3, -32)
		rectO(h, sand, 0.68, 0.32, 0.16, 0.52, 0.3, 32)
		rectO(h, sand, 0.5, 0.74, 0.18, 0.44, 0.3)
		rect(h, sand, 0.5, 0.54, 0.24, 0.16, 0.3)
	end,
	mech_burn = function(h, _c)
		local orange = Color3.fromHex("#E8642C")
		rectO(h, orange, 0.5, 0.36, 0.16, 0.36, 1)
		rectO(h, orange, 0.5, 0.62, 0.48, 0.48, 0.45, 45)
		rect(h, Color3.fromHex("#F7C948"), 0.5, 0.68, 0.22, 0.22, 0.45, 45)
	end,
	-- A gold "?" filling a dark disc, so it still reads at the 12 px health-bar marker size.
	mech_disguise = function(h, _c)
		rectO(h, Color3.fromHex("#3A3346"), 0.5, 0.5, 0.92, 0.92, 1)
		Create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromScale(0.78, 0.78),
			Text = "?",
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			TextColor3 = GOLD,
			ZIndex = h.ZIndex,
			Parent = h,
		})
	end,
	mech_teleport = function(h, _c)
		local violet = Color3.fromHex("#7B5CC4")
		for _, x in { 0.16, 0.34, 0.52 } do
			rect(h, violet, x, 0.5, 0.12, 0.12, 0.5)
		end
		rectO(h, violet, 0.74, 0.38, 0.1, 0.3, 0.5, -45)
		rectO(h, violet, 0.74, 0.62, 0.1, 0.3, 0.5, 45)
	end,
	mech_sabotage = function(h, _c)
		local red = Color3.fromHex("#C0281E")
		local ring = rect(h, red, 0.5, 0.5, 0.7, 0.7, 1)
		ring.BackgroundTransparency = 1
		Create("UIStroke", { Color = red, Thickness = 2.5, Parent = ring })
		rect(h, red, 0.5, 0.5, 0.06, 0.92, 0.5)
		rect(h, red, 0.5, 0.5, 0.92, 0.06, 0.5)
		rect(h, red, 0.5, 0.5, 0.14, 0.14, 1)
	end,
	mech_summon = function(h, _c)
		local blue = Color3.fromHex("#4A5C8C")
		for _, p in { { 0.24, 0.13 }, { 0.76, 0.13 }, { 0.5, 0.17 } } do
			local big = p[1] == 0.5
			rectO(h, blue, p[1], 0.78, if big then 0.32 else 0.24, 0.3, 0.4)
			rectO(h, Color3.fromHex("#E2B98F"), p[1], 0.52, p[2] * 1.6, p[2] * 1.6, 1)
		end
		rectO(h, GOLD, 0.82, 0.22, 0.24, 0.07, 0.5)
		rectO(h, GOLD, 0.82, 0.22, 0.07, 0.24, 0.5)
	end,
	mech_split = function(h, _c)
		rectO(h, Palette.wood, 0.5, 0.46, 0.76, 0.36, 0.15)
		rect(h, Palette.woodDark, 0.5, 0.46, 0.06, 0.36, 0)
		rectO(h, Palette.basalt, 0.28, 0.74, 0.24, 0.24, 1)
		rectO(h, Palette.basalt, 0.72, 0.74, 0.24, 0.24, 1)
	end,
	mech_heal = function(h, _c)
		local green = Color3.fromHex("#3FA05A")
		rectO(h, green, 0.5, 0.5, 0.3, 0.8, 0.2)
		rectO(h, green, 0.5, 0.5, 0.8, 0.3, 0.2)
		rect(h, green, 0.5, 0.5, 0.28, 0.28, 0)
	end,
	bead = function(h, _c)
		rect(h, Palette.woodDark, 0.5, 0.5, 0.06, 0.9, 0.5)
		rectO(h, Color3.fromHex("#2F7FB8"), 0.5, 0.5, 0.62, 0.62, 1)
		rect(h, Color3.fromHex("#BFE3F7"), 0.4, 0.38, 0.18, 0.18, 1)
	end,
	-- One glass colour per bead kind (Config/Icons.beads, S1-C04).
	bead_range = function(h, _c)
		beadOf(h, "#2F7FB8")
	end,
	bead_cooldown = function(h, _c)
		beadOf(h, "#3FA05A")
	end,
	bead_cash = function(h, _c)
		beadOf(h, "#E0A82E")
	end,
	bead_heal = function(h, _c)
		beadOf(h, "#C0503A")
	end,
	bead_buff = function(h, _c)
		beadOf(h, "#8A4FC0")
	end,
	mech_ally = function(h, _c)
		local ring = rect(h, GOLD, 0.5, 0.5, 0.84, 0.84, 1)
		ring.BackgroundTransparency = 1
		Create("UIStroke", { Color = GOLD, Thickness = 3, Parent = ring })
		rectO(h, Palette.woodDark, 0.5, 0.26, 0.2, 0.08, 0.3)
		rectO(h, Color3.fromHex("#F2A93B"), 0.5, 0.5, 0.3, 0.38, 0.35)
		rect(h, Color3.fromHex("#FFF0B8"), 0.5, 0.5, 0.12, 0.18, 0.5)
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
	-- Three bars: the match menu (MH-04).
	ui_menu = function(h, _c)
		for k = 0, 2 do
			rectO(h, WHITE, 0.5, 0.26 + k * 0.24, 0.72, 0.13, 0.5)
		end
	end,
	-- Three dots: the lobby's More sheet on a phone (MH-11).
	ui_more = function(h, _c)
		for k = 0, 2 do
			rectO(h, WHITE, 0.22 + k * 0.28, 0.5, 0.2, 0.2, 1)
		end
	end,
	-- Three fezzes in a row: the Defenders panel (LP-B02).
	ui_defenders = function(h, _c)
		for k, x in { 0.22, 0.5, 0.78 } do
			local y = if k == 2 then 0.42 else 0.56
			rectO(h, Palette.fabricRed, x, y, 0.26, 0.3, 0.15)
			rect(h, Palette.woodDark, x + 0.04, y - 0.17, 0.05, 0.1, 1)
		end
	end,
	-- A padlock: a speed the host's passes don't unlock yet (LP-A03).
	ui_lock = function(h, _c)
		rectO(h, Palette.woodDark, 0.5, 0.34, 0.46, 0.46, 1)
		rectO(h, GOLD, 0.5, 0.66, 0.7, 0.48, 0.15)
		rect(h, Palette.woodDark, 0.5, 0.66, 0.1, 0.2, 1)
	end,
	-- A watchtower on its legs with a lit window: the camera view toggle (MH-04).
	ui_view = function(h, _c)
		rectO(h, Palette.woodDark, 0.34, 0.74, 0.08, 0.46, 0.2, 8)
		rectO(h, Palette.woodDark, 0.66, 0.74, 0.08, 0.46, 0.2, -8)
		rectO(h, Palette.wood, 0.5, 0.42, 0.62, 0.34, 0.12)
		rectO(h, Palette.fabricRed, 0.5, 0.18, 0.76, 0.16, 0.3)
		rect(h, GOLD, 0.5, 0.43, 0.22, 0.16, 0.2)
	end,
	qirsh_pouch = function(h, _c)
		rectO(h, Palette.wood, 0.5, 0.58, 0.62, 0.6, 0.4)
		rect(h, Palette.woodDark, 0.5, 0.3, 0.4, 0.08, 1)
		rectO(h, Palette.copper, 0.78, 0.78, 0.26, 0.26, 1)
	end,
}

-- An uploaded painted image for `name` (Config/Icons id > 0), fitted to the holder.
local function image(name: string, holder: Frame, colorHex: string?): boolean
	-- "portrait:<unitId>": that character's painted portrait (Config/Icons.portraits, PV-C05)
	local unitId = string.match(name, "^portrait:(.+)$")
	local portrait = if unitId then IconIds.portraits[unitId] else nil
	local def = if unitId then nil else IconIds.images[name]
	local id = if portrait then portrait.id elseif def then def.id else 0
	if id == 0 then
		return false
	end
	local img = Create("ImageLabel", {
		Name = "Image",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Image = "rbxassetid://" .. tostring(id),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	if not def then
		return true
	end
	if def.tint then
		img.ImageColor3 = Color3.fromHex(def.tint)
	elseif def.recolor and colorHex then
		img.ImageColor3 = Color3.fromHex(colorHex)
	end
	return true
end

-- Draws icon `name` into `holder`: the uploaded image when Config/Icons has an id, else the
-- primitive drawer (tinted by colorHex), else the name as text.
function Icons.draw(name: string, holder: Frame, colorHex: string?)
	if image(name, holder, colorHex) then
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
