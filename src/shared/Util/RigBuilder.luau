--!strict
-- Blocky figures for defenders, attackers and previews, built from primitives (no uploads, cheap
-- on mobile). One builder shared by the server (tower models), the client (enemy models, UI
-- previews) and the lobby crowd. Parts are anchored and relative to a root at ground level
-- facing -Z; callers move the model with PivotTo.

local RigBuilder = {}

export type Visual = {
	robe: string,
	accent: string,
	skin: string,
	hat: string,
	hatColor: string,
	weapon: string,
	scale: number?,
}

local M = Enum.Material
local CYL_UP = CFrame.Angles(0, 0, math.rad(90))
local IRON = Color3.fromHex("#2B2724")
local WOOD = Color3.fromHex("#6B4423")
local BLADE = Color3.fromHex("#D8DCE0")
local COPPER = Color3.fromHex("#B87333")

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or M.Fabric
	p.Shape = shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function hat(model: Model, kind: string, color: Color3, s: number, head: CFrame)
	local top = head * CFrame.new(0, 0.55 * s, 0)
	if kind == "tarboosh" then
		part(model, "Hat", Vector3.new(0.7 * s, 1 * s, 1 * s), top * CFrame.new(0, 0.3 * s, 0) * CYL_UP, color, M.Fabric, Enum.PartType.Cylinder)
		part(model, "Tassel", Vector3.new(0.1 * s, 0.5 * s, 0.1 * s), top * CFrame.new(0.2 * s, 0.4 * s, 0.4 * s) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromHex("#1F1B18"))
	elseif kind == "cap" then
		part(model, "Hat", Vector3.new(0.35 * s, 1.05 * s, 1.05 * s), top * CFrame.new(0, 0.1 * s, 0) * CYL_UP, color, M.Fabric, Enum.PartType.Cylinder)
	elseif kind == "turban" then
		part(model, "Hat", Vector3.new(0.6 * s, 1.3 * s, 1.3 * s), top * CFrame.new(0, 0.2 * s, 0) * CYL_UP, color, M.Fabric, Enum.PartType.Cylinder)
	elseif kind == "hatta" then
		part(model, "Hat", Vector3.new(1.25 * s, 0.5 * s, 1.25 * s), top * CFrame.new(0, 0.1 * s, 0), color, M.Fabric)
		part(model, "Agal", Vector3.new(0.12 * s, 1.3 * s, 1.3 * s), top * CFrame.new(0, 0.25 * s, 0) * CYL_UP, Color3.fromHex("#1F1B18"), M.Fabric, Enum.PartType.Cylinder)
		part(model, "Tail", Vector3.new(1.1 * s, 1.2 * s, 0.1 * s), head * CFrame.new(0, -0.1 * s, 0.6 * s), color, M.Fabric)
	elseif kind == "scarf" then
		part(model, "Hat", Vector3.new(1.25 * s, 0.6 * s, 1.25 * s), top * CFrame.new(0, 0.15 * s, 0), color, M.Fabric)
		part(model, "Tail", Vector3.new(1.1 * s, 1.4 * s, 0.1 * s), head * CFrame.new(0, -0.2 * s, 0.6 * s), color, M.Fabric)
	elseif kind == "kepi" then
		part(model, "Hat", Vector3.new(0.45 * s, 1 * s, 1 * s), top * CFrame.new(0, 0.15 * s, 0) * CYL_UP, color, M.Fabric, Enum.PartType.Cylinder)
		part(model, "Peak", Vector3.new(0.9 * s, 0.08 * s, 0.5 * s), top * CFrame.new(0, -0.05 * s, -0.6 * s), IRON, M.SmoothPlastic)
	elseif kind == "helmet" then
		part(model, "Hat", Vector3.new(1.2 * s, 1.2 * s, 1.2 * s), top * CFrame.new(0, 0, 0), color, M.Metal, Enum.PartType.Ball)
	end
end

local function weapon(model: Model, kind: string, s: number, hand: CFrame)
	if kind == "stick" then
		part(model, "Weapon", Vector3.new(0.15 * s, 2.6 * s, 0.15 * s), hand * CFrame.new(0, -0.2 * s, 0) * CFrame.Angles(math.rad(25), 0, 0), WOOD, M.Wood)
	elseif kind == "dagger" then
		part(model, "Weapon", Vector3.new(0.12 * s, 0.9 * s, 0.05 * s), hand * CFrame.new(0, -0.5 * s, -0.1 * s) * CFrame.Angles(math.rad(110), 0, 0), BLADE, M.Metal)
		part(model, "Hilt", Vector3.new(0.18 * s, 0.35 * s, 0.18 * s), hand * CFrame.new(0, 0, 0), COPPER, M.Metal)
	elseif kind == "sword" then
		part(model, "Weapon", Vector3.new(0.14 * s, 2.2 * s, 0.06 * s), hand * CFrame.new(0, 0.6 * s, -0.3 * s) * CFrame.Angles(math.rad(70), 0, 0), BLADE, M.Metal)
		part(model, "Shield", Vector3.new(0.12 * s, 1.5 * s, 1.5 * s), hand * CFrame.new(-1.3 * s, 0.2 * s, -0.4 * s) * CFrame.Angles(0, 0, math.rad(90)), COPPER, M.Metal, Enum.PartType.Cylinder)
	elseif kind == "razor" then
		part(model, "Weapon", Vector3.new(0.08 * s, 0.7 * s, 0.05 * s), hand * CFrame.new(0, -0.3 * s, -0.15 * s) * CFrame.Angles(math.rad(100), 0, 0), BLADE, M.Metal)
	elseif kind == "sling" then
		part(model, "Weapon", Vector3.new(0.06 * s, 1.1 * s, 0.06 * s), hand * CFrame.new(0, -0.5 * s, 0), Color3.fromHex("#8C6A3E"), M.Fabric)
	elseif kind == "jug" then
		part(model, "Weapon", Vector3.new(0.9 * s, 1.1 * s, 0.9 * s), hand * CFrame.new(0, -0.7 * s, 0), Color3.fromHex("#8C6A3E"), M.Fabric, Enum.PartType.Ball)
	elseif kind == "lantern" then
		local g = part(model, "Weapon", Vector3.new(0.5 * s, 0.7 * s, 0.5 * s), hand * CFrame.new(0, -0.8 * s, 0), Color3.fromHex("#F2C46B"), M.Neon)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Range = 10
		light.Brightness = 0.8
		light.Parent = g
	elseif kind == "needle" then
		part(model, "Weapon", Vector3.new(0.05 * s, 1.0 * s, 0.05 * s), hand * CFrame.new(0, -0.3 * s, -0.2 * s) * CFrame.Angles(math.rad(90), 0, 0), BLADE, M.Metal)
	elseif kind == "hammer" then
		part(model, "Weapon", Vector3.new(0.18 * s, 2.0 * s, 0.18 * s), hand * CFrame.new(0, 0.3 * s, 0), WOOD, M.Wood)
		part(model, "Head", Vector3.new(0.6 * s, 0.5 * s, 1.0 * s), hand * CFrame.new(0, 1.3 * s, 0), IRON, M.Metal)
	elseif kind == "tray" then
		part(model, "Weapon", Vector3.new(0.08 * s, 1.3 * s, 1.3 * s), hand * CFrame.new(0, -0.3 * s, -0.5 * s) * CYL_UP, COPPER, M.Metal, Enum.PartType.Cylinder)
		part(model, "Cup", Vector3.new(0.3 * s, 0.35 * s, 0.3 * s), hand * CFrame.new(0.2 * s, -0.1 * s, -0.5 * s) * CYL_UP, Color3.fromHex("#FBF8F1"), M.Glass, Enum.PartType.Cylinder)
	elseif kind == "bread" then
		part(model, "Weapon", Vector3.new(0.25 * s, 0.9 * s, 0.9 * s), hand * CFrame.new(0, -0.4 * s, 0) * CYL_UP, Color3.fromHex("#C98A4B"), M.Sand, Enum.PartType.Cylinder)
	elseif kind == "rifle" then
		part(model, "Weapon", Vector3.new(0.12 * s, 0.12 * s, 2.6 * s), hand * CFrame.new(0, -0.2 * s, -0.8 * s), WOOD, M.Wood)
		part(model, "Barrel", Vector3.new(0.08 * s, 0.08 * s, 1.4 * s), hand * CFrame.new(0, -0.14 * s, -1.6 * s), IRON, M.Metal)
	elseif kind == "sack" then
		part(model, "Weapon", Vector3.new(1.0 * s, 1.2 * s, 0.8 * s), hand * CFrame.new(-0.2 * s, -0.4 * s, 0.9 * s), Color3.fromHex("#D9BF94"), M.Fabric, Enum.PartType.Ball)
	end
end

-- Builds a figure with its root at `parent`. Returns the model; PrimaryPart is "Root" (invisible).
function RigBuilder.build(parent: Instance?, name: string, v: Visual): Model
	local s = v.scale or 1
	local m = Instance.new("Model")
	m.Name = name
	local robe = Color3.fromHex(v.robe)
	local accent = Color3.fromHex(v.accent)
	local skin = Color3.fromHex(v.skin)
	local root = part(m, "Root", Vector3.new(2 * s, 5.6 * s, 1 * s), CFrame.new(0, 2.8 * s, 0), robe)
	root.Transparency = 1
	m.PrimaryPart = root
	local origin = CFrame.new(0, 0, 0)
	if v.weapon == "cat" then
		-- A cat is not a person: body, head, ears, tail.
		part(m, "Body", Vector3.new(0.9 * s, 0.9 * s, 1.6 * s), origin * CFrame.new(0, 0.5 * s, 0.2 * s), robe)
		part(m, "Head", Vector3.new(0.8 * s, 0.8 * s, 0.8 * s), origin * CFrame.new(0, 1.2 * s, -0.5 * s), robe, M.Fabric, Enum.PartType.Ball)
		part(m, "EarL", Vector3.new(0.2 * s, 0.3 * s, 0.1 * s), origin * CFrame.new(-0.25 * s, 1.7 * s, -0.5 * s), robe)
		part(m, "EarR", Vector3.new(0.2 * s, 0.3 * s, 0.1 * s), origin * CFrame.new(0.25 * s, 1.7 * s, -0.5 * s), robe)
		part(m, "Tail", Vector3.new(0.15 * s, 0.15 * s, 1.2 * s), origin * CFrame.new(0.3 * s, 0.9 * s, 1.3 * s) * CFrame.Angles(math.rad(-30), 0, 0), robe)
		m.Parent = parent
		return m
	end
	-- Legs (sherwal) and feet
	for _, side in { -1, 1 } do
		part(m, "Leg", Vector3.new(0.85 * s, 2.0 * s, 0.9 * s), origin * CFrame.new(side * 0.5 * s, 1.0 * s, 0), robe)
		part(m, "Foot", Vector3.new(0.9 * s, 0.3 * s, 1.1 * s), origin * CFrame.new(side * 0.5 * s, 0.15 * s, -0.1 * s), Color3.fromHex("#4A2E18"), M.Fabric)
	end
	-- Torso: robe, waistcoat/sash accent
	part(m, "Torso", Vector3.new(2.0 * s, 2.1 * s, 1.0 * s), origin * CFrame.new(0, 3.05 * s, 0), robe)
	part(m, "Sash", Vector3.new(2.06 * s, 0.5 * s, 1.06 * s), origin * CFrame.new(0, 2.25 * s, 0), accent)
	part(m, "Vest", Vector3.new(1.3 * s, 1.5 * s, 1.08 * s), origin * CFrame.new(0, 3.3 * s, 0), accent)
	-- Arms
	for _, side in { -1, 1 } do
		part(m, "Arm", Vector3.new(0.7 * s, 2.0 * s, 0.7 * s), origin * CFrame.new(side * 1.35 * s, 3.1 * s, 0), robe)
		part(m, "Hand", Vector3.new(0.6 * s, 0.5 * s, 0.6 * s), origin * CFrame.new(side * 1.35 * s, 1.9 * s, 0), skin, M.SmoothPlastic)
	end
	-- Head and face
	local headCf = origin * CFrame.new(0, 4.75 * s, 0)
	part(m, "Head", Vector3.new(1.2 * s, 1.2 * s, 1.2 * s), headCf, skin, M.SmoothPlastic, Enum.PartType.Ball)
	part(m, "Moustache", Vector3.new(0.6 * s, 0.12 * s, 0.1 * s), headCf * CFrame.new(0, -0.15 * s, -0.58 * s), Color3.fromHex("#1F1B18"))
	hat(m, v.hat, Color3.fromHex(v.hatColor), s, headCf)
	weapon(m, v.weapon, s, origin * CFrame.new(1.35 * s, 1.9 * s, 0))
	m.Parent = parent
	return m
end

-- Tints every visible part (used for the placement ghost and hit flashes).
function RigBuilder.setTransparency(model: Model, t: number)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			d.Transparency = t
		end
	end
end

return RigBuilder
