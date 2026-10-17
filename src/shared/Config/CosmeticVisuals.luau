--!strict
-- Period wardrobe built from primitives (no uploaded assets). Generic 1920s–30s Levantine dress
-- (docs/research/DAMASCUS_LANE_LIFE.md §6); not modelled on any TV character.
--
-- Each part attaches to a body part:
--   attach = "HeadTop"  → offset is in studs from the top of the head (hats).
--   attach = <R15 part> → size = part.Size * fit + pad; offset position is a FRACTION of the part's
--                          size (so clothes follow body proportions); rotation from `rot` (degrees).
-- R6 rigs are mapped to the nearest part (see AvatarService.R6_MAP).

export type VisualPart = {
	name: string,
	attach: string?, -- default "HeadTop"
	shape: Enum.PartType,
	color: Color3,
	material: Enum.Material,
	-- HeadTop parts:
	size: Vector3?,
	offset: CFrame?,
	-- Body parts:
	fit: Vector3?,
	pad: Vector3?,
	at: Vector3?, -- fractional offset
	rot: Vector3?, -- degrees
}

local Palette = require(script.Parent.Palette)

local M = Enum.Material
local P = Enum.PartType
local CYL_UP = CFrame.Angles(0, 0, math.rad(90)) -- cylinders are X-aligned; stand them up

local BLACK = Color3.fromHex("#1F1B18")
local GOLD = Color3.fromHex("#C9A13B")
local CREAM = Color3.fromHex("#EFE6D2")

local function tarboosh(color: Color3, tassel: Color3): { VisualPart }
	return {
		{
			name = "Felt",
			shape = P.Cylinder,
			size = Vector3.new(0.75, 1.05, 1.05),
			color = color,
			material = M.Fabric,
			offset = CFrame.new(0, 0.3, 0) * CYL_UP,
		},
		{
			name = "Tassel",
			shape = P.Block,
			size = Vector3.new(0.12, 0.55, 0.12),
			color = tassel,
			material = M.Fabric,
			offset = CFrame.new(0.2, 0.55, 0.42) * CFrame.Angles(math.rad(-20), 0, 0),
		},
	}
end

-- Baggy trousers gathered below the knee.
local function sherwal(color: Color3): { VisualPart }
	local parts: { VisualPart } = {}
	for _, side in { "Left", "Right" } do
		table.insert(parts, {
			name = side .. "Thigh",
			attach = side .. "UpperLeg",
			shape = P.Block,
			fit = Vector3.new(1.45, 1.08, 1.45),
			color = color,
			material = M.Fabric,
		})
		table.insert(parts, {
			name = side .. "Shin",
			attach = side .. "LowerLeg",
			shape = P.Block,
			fit = Vector3.new(1.3, 0.75, 1.3),
			at = Vector3.new(0, 0.12, 0),
			color = color,
			material = M.Fabric,
		})
	end
	-- Low-slung seat that gives the sherwal its shape
	table.insert(parts, {
		name = "Seat",
		attach = "LowerTorso",
		shape = P.Block,
		fit = Vector3.new(1.12, 1.6, 1.25),
		at = Vector3.new(0, -0.6, 0),
		color = color,
		material = M.Fabric,
	})
	return parts
end

local visuals: { [string]: { VisualPart } } = {
	-- Head ------------------------------------------------------------------------------------
	tarboosh_red = tarboosh(Palette.fabricRed, Palette.ink),
	tarboosh_black = tarboosh(BLACK, Palette.fabricRed),
	tarboosh_gold = (function()
		local t = tarboosh(Color3.fromHex("#7A1E1A"), GOLD)
		table.insert(t, {
			name = "Band",
			shape = P.Cylinder,
			size = Vector3.new(0.14, 1.08, 1.08),
			color = GOLD,
			material = M.Metal,
			offset = CFrame.new(0, 0.02, 0) * CYL_UP,
		})
		return t
	end)(),
	taqiyah_white = {
		{
			name = "Cap",
			shape = P.Cylinder,
			size = Vector3.new(0.4, 1.2, 1.2),
			color = Palette.jasmine,
			material = M.Fabric,
			offset = CFrame.new(0, 0.12, 0) * CYL_UP,
		},
	},
	hatta_agal = {
		{
			name = "Hatta",
			shape = P.Block,
			size = Vector3.new(1.45, 0.45, 1.45),
			color = CREAM,
			material = M.Fabric,
			offset = CFrame.new(0, 0.05, 0.05),
		},
		{
			name = "Drape",
			shape = P.Block,
			size = Vector3.new(1.5, 1.7, 0.8),
			color = CREAM,
			material = M.Fabric,
			offset = CFrame.new(0, -0.75, 0.45),
		},
		{
			name = "Agal",
			shape = P.Cylinder,
			size = Vector3.new(0.18, 1.35, 1.35),
			color = BLACK,
			material = M.Fabric,
			offset = CFrame.new(0, 0.3, 0.05) * CYL_UP,
		},
	},

	-- Torso -----------------------------------------------------------------------------------
	sidriyye_black = {
		{
			name = "Waistcoat",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.06, 0.98, 1.12),
			at = Vector3.new(0, -0.02, 0),
			color = BLACK,
			material = M.Fabric,
		},
		{
			name = "Trim",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(0.12, 0.9, 1.14),
			color = GOLD,
			material = M.Fabric,
		},
	},
	qumbaz_striped = {
		{
			name = "Robe",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.08, 1.02, 1.14),
			color = Color3.fromHex("#8C6A3F"),
			material = M.Fabric,
		},
		{
			name = "Skirt",
			attach = "LowerTorso",
			shape = P.Block,
			fit = Vector3.new(1.18, 9.5, 1.3),
			at = Vector3.new(0, -4.3, 0),
			color = Color3.fromHex("#8C6A3F"),
			material = M.Fabric,
		},
		{
			name = "StripeL",
			attach = "LowerTorso",
			shape = P.Block,
			fit = Vector3.new(0.08, 9.5, 1.32),
			at = Vector3.new(-0.25, -4.3, 0),
			color = CREAM,
			material = M.Fabric,
		},
		{
			name = "StripeR",
			attach = "LowerTorso",
			shape = P.Block,
			fit = Vector3.new(0.08, 9.5, 1.32),
			at = Vector3.new(0.25, -4.3, 0),
			color = CREAM,
			material = M.Fabric,
		},
	},
	qumbaz_wedding = {
		{
			name = "Robe",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.08, 1.02, 1.14),
			color = CREAM,
			material = M.Fabric,
		},
		{
			name = "Skirt",
			attach = "LowerTorso",
			shape = P.Block,
			fit = Vector3.new(1.18, 9.5, 1.3),
			at = Vector3.new(0, -4.3, 0),
			color = CREAM,
			material = M.Fabric,
		},
		{
			name = "Embroidery",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(0.3, 0.95, 1.16),
			color = GOLD,
			material = M.Fabric,
		},
	},

	-- Legs ------------------------------------------------------------------------------------
	sherwal_black = sherwal(BLACK),
	sherwal_indigo = sherwal(Palette.fabricIndigo),

	-- Waist -----------------------------------------------------------------------------------
	zunnar_sash = {
		{
			name = "Sash",
			attach = "LowerTorso",
			shape = P.Block,
			fit = Vector3.new(1.12, 1.4, 1.18),
			at = Vector3.new(0, 0.3, 0),
			color = Palette.fabricRed,
			material = M.Fabric,
		},
		{
			name = "SashEnd",
			attach = "LowerTorso",
			shape = P.Block,
			fit = Vector3.new(0.18, 2.4, 0.15),
			at = Vector3.new(0.38, -0.9, -0.55),
			color = Palette.fabricRed,
			material = M.Fabric,
		},
	},

	-- Back ------------------------------------------------------------------------------------
	abaya_brown = {
		{
			name = "Cloak",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.3, 2.9, 0.12),
			at = Vector3.new(0, -0.85, 0.62),
			color = Color3.fromHex("#5A4030"),
			material = M.Fabric,
		},
		{
			name = "Shoulders",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.32, 0.25, 1.2),
			at = Vector3.new(0, 0.42, 0.05),
			color = Color3.fromHex("#5A4030"),
			material = M.Fabric,
		},
	},
	shawl_embroidered = {
		{
			name = "Shawl",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.25, 1.1, 0.12),
			at = Vector3.new(0, -0.1, 0.6),
			color = Palette.tile,
			material = M.Fabric,
		},
		{
			name = "Border",
			attach = "UpperTorso",
			shape = P.Block,
			fit = Vector3.new(1.27, 0.12, 0.14),
			at = Vector3.new(0, -0.6, 0.6),
			color = GOLD,
			material = M.Fabric,
		},
	},
}

-- NPC-only headwear
visuals.cap = visuals.taqiyah_white
visuals.tarboosh = visuals.tarboosh_red
visuals.scarf = {
	{
		name = "ScarfTop",
		shape = P.Cylinder,
		size = Vector3.new(0.3, 1.3, 1.3),
		color = Palette.jasmine,
		material = M.Fabric,
		offset = CFrame.new(0, 0.08, 0.05) * CYL_UP,
	},
	{
		name = "ScarfBack",
		shape = P.Block,
		size = Vector3.new(1.3, 1.5, 0.7),
		color = Palette.jasmine,
		material = M.Fabric,
		offset = CFrame.new(0, -0.65, 0.4),
	},
}

return visuals
