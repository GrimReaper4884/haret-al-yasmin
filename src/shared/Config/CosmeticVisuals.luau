--!strict
-- How cosmetics and NPC headwear look, built from primitives (no uploaded assets).
-- Each part is positioned relative to the character's head top.

export type VisualPart = {
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	offset: CFrame,
}

local Palette = require(script.Parent.Palette)

local CYL_UP = CFrame.Angles(0, 0, math.rad(90)) -- cylinders are X-aligned; stand them up

local visuals: { [string]: { VisualPart } } = {
	tarboosh_red = {
		{
			name = "Felt",
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(0.75, 1.05, 1.05),
			color = Palette.fabricRed,
			material = Enum.Material.Fabric,
			offset = CFrame.new(0, 0.3, 0) * CYL_UP,
		},
		{
			name = "Tassel",
			shape = Enum.PartType.Block,
			size = Vector3.new(0.12, 0.55, 0.12),
			color = Palette.ink,
			material = Enum.Material.Fabric,
			offset = CFrame.new(0.2, 0.55, 0.42) * CFrame.Angles(math.rad(-20), 0, 0),
		},
	},
	-- NPC-only headwear
	cap = {
		{
			name = "Cap",
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(0.4, 1.2, 1.2),
			color = Palette.jasmine,
			material = Enum.Material.Fabric,
			offset = CFrame.new(0, 0.12, 0) * CYL_UP,
		},
	},
	scarf = {
		{
			name = "ScarfTop",
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(0.3, 1.3, 1.3),
			color = Palette.jasmine,
			material = Enum.Material.Fabric,
			offset = CFrame.new(0, 0.08, 0.05) * CYL_UP,
		},
		{
			name = "ScarfBack",
			shape = Enum.PartType.Block,
			size = Vector3.new(1.3, 1.5, 0.7),
			color = Palette.jasmine,
			material = Enum.Material.Fabric,
			offset = CFrame.new(0, -0.65, 0.4),
		},
	},
}

-- NPC tailor wears the same tarboosh as the shop item.
visuals.tarboosh = visuals.tarboosh_red

return visuals
