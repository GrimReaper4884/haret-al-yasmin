--!strict
-- Figures for defenders, attackers and UI previews. One builder shared by the server (tower
-- models), the client (enemy models, placement ghost, card previews) and the lobby crowd.
--
-- Two sources, same result shape:
--   1. An imported character (Meshy / Blender → Studio) stored under
--      ReplicatedStorage.CharacterModels, named by Config/CharacterLooks[id].model. It is cloned,
--      scaled to the archetype height and anchored at its root (docs/CHARACTER_PIPELINE.md).
--   2. Otherwise a stylized primitive figure: chunky proportions and a big head so it reads on a
--      phone, with an outfit cut, facial hair and headwear from CharacterLooks + the colours
--      in the unit/enemy `visual`.
--
-- Every figure has an invisible anchored "Root" part (PrimaryPart) whose pivot sits on the
-- ground between the feet, facing -Z, so callers place it with PivotTo(groundCFrame). Primitive
-- figures are jointed: Root → Torso ("Waist"), Torso → Head ("Neck"), Torso → arms ("LeftShoulder"
-- / "RightShoulder") and Root → legs ("LeftHip" / "RightHip") are Motor6Ds whose Transform the
-- client animates (Controllers/RigAnimController); everything else is welded to its bone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Looks = require(script.Parent.Parent.Config.CharacterLooks)

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
local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local CYL_UP = CFrame.Angles(0, 0, math.rad(90))
local IRON = Color3.fromHex("#2B2724")
local WOOD = Color3.fromHex("#6B4423")
local BLADE = Color3.fromHex("#D8DCE0")
local COPPER = Color3.fromHex("#B87333")
local GOLD = Color3.fromHex("#C9A13B")
local INK = Color3.fromHex("#1F1B18")
local EYE_WHITE = Color3.fromHex("#F4EFE6")
local LEATHER = Color3.fromHex("#3A2618")

-- Nominal standing height in studs at scale 1 (feet to the top of the head, without hat).
RigBuilder.HEIGHT = 5.6

type BuildShape = { w: number, h: number, head: number }
local BUILDS: { [string]: BuildShape } = {
	kid = { w = 0.82, h = 0.8, head = 1.12 },
	slim = { w = 0.9, h = 1.0, head = 1.0 },
	normal = { w = 1.0, h = 1.0, head = 1.0 },
	stout = { w = 1.18, h = 0.97, head = 1.02 },
	broad = { w = 1.22, h = 1.03, head = 1.0 },
	giant = { w = 1.32, h = 1.08, head = 1.0 },
}

-- The part being built is welded to `bone` (if set) so it follows the joint it hangs from.
local bone: BasePart? = nil

local function part(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or M.Fabric
	p.Anchored = false
	p.Massless = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	local b = bone
	if b then
		local w = Instance.new("WeldConstraint")
		w.Part0 = b
		w.Part1 = p
		w.Parent = p
	end
	return p
end

-- A Motor6D from part0 to part1 pivoting at the world CFrame `at`.
local function joint(name: string, part0: BasePart, part1: BasePart, at: CFrame)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = part0.CFrame:ToObjectSpace(at)
	m.C1 = part1.CFrame:ToObjectSpace(at)
	m.Parent = part0
end

local function shade(c: Color3, k: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), k)
end

------------------------------------------------------------------------------- headwear
-- `top` is the crown of the head (a CFrame at the top of the sphere), r its radius.
local function hat(model: Model, kind: string, color: Color3, r: number, head: CFrame)
	local top = head * CFrame.new(0, r * 0.78, 0)
	if kind == "tarboosh" then
		-- The fez: a truncated red cylinder with a black tassel falling to the back.
		part(model, "Hat", Vector3.new(r * 1.15, r * 1.25, r * 1.25), top * CFrame.new(0, r * 0.4, 0) * CYL_UP, color, M.Fabric, CYL)
		part(model, "HatTop", Vector3.new(r * 0.05, r * 1.1, r * 1.1), top * CFrame.new(0, r * 0.98, 0) * CYL_UP, shade(color, 0.15), M.Fabric, CYL)
		part(model, "Tassel", Vector3.new(r * 0.14, r * 0.8, r * 0.14), top * CFrame.new(0, r * 0.65, r * 0.55) * CFrame.Angles(math.rad(25), 0, 0), INK)
	elseif kind == "cap" then
		part(model, "Hat", Vector3.new(r * 0.55, r * 1.75, r * 1.75), top * CFrame.new(0, r * 0.05, 0) * CYL_UP, color, M.Fabric, CYL)
	elseif kind == "turban" then
		part(model, "Hat", Vector3.new(r * 0.95, r * 2.15, r * 2.15), top * CFrame.new(0, r * 0.1, 0) * CYL_UP, color, M.Fabric, CYL)
		part(model, "Wrap", Vector3.new(r * 0.3, r * 2.25, r * 2.25), top * CFrame.new(0, -r * 0.15, 0) * CFrame.Angles(math.rad(8), 0, 0) * CYL_UP, shade(color, 0.12), M.Fabric, CYL)
		part(model, "Crown", Vector3.new(r * 0.5, r * 1.3, r * 1.3), top * CFrame.new(0, r * 0.55, 0) * CYL_UP, Color3.fromHex("#A4302A"), M.Fabric, CYL)
	elseif kind == "hatta" then
		-- Head cloth held by a black cord, the tail hanging down the back.
		part(model, "Hat", Vector3.new(r * 2.15, r * 1.0, r * 2.15), top * CFrame.new(0, -r * 0.05, 0), color, M.Fabric)
		part(model, "Agal", Vector3.new(r * 0.22, r * 2.2, r * 2.2), top * CFrame.new(0, r * 0.3, 0) * CYL_UP, INK, M.Fabric, CYL)
		part(model, "Tail", Vector3.new(r * 2.0, r * 2.2, r * 0.15), head * CFrame.new(0, -r * 0.35, r * 1.0), color, M.Fabric)
	elseif kind == "scarf" then
		part(model, "Hat", Vector3.new(r * 2.2, r * 1.15, r * 2.2), top * CFrame.new(0, -r * 0.1, r * 0.05), color, M.Fabric)
		part(model, "Tail", Vector3.new(r * 2.1, r * 2.6, r * 0.16), head * CFrame.new(0, -r * 0.6, r * 1.0), color, M.Fabric)
		part(model, "Frame", Vector3.new(r * 2.25, r * 0.3, r * 0.3), head * CFrame.new(0, r * 0.75, -r * 0.85), shade(color, 0.08), M.Fabric)
	elseif kind == "kepi" then
		part(model, "Hat", Vector3.new(r * 0.85, r * 1.7, r * 1.7), top * CFrame.new(0, r * 0.25, 0) * CYL_UP, color, M.Fabric, CYL)
		part(model, "Band", Vector3.new(r * 0.2, r * 1.78, r * 1.78), top * CFrame.new(0, -r * 0.08, 0) * CYL_UP, GOLD, M.Fabric, CYL)
		part(model, "Peak", Vector3.new(r * 1.4, r * 0.1, r * 0.7), top * CFrame.new(0, -r * 0.18, -r * 0.95) * CFrame.Angles(math.rad(-12), 0, 0), INK, M.SmoothPlastic)
	elseif kind == "helmet" then
		part(model, "Hat", Vector3.new(r * 2.1, r * 2.1, r * 2.1), top * CFrame.new(0, -r * 0.45, 0), color, M.Metal, BALL)
		part(model, "Rim", Vector3.new(r * 0.12, r * 2.6, r * 2.6), top * CFrame.new(0, -r * 0.55, 0) * CYL_UP, shade(color, 0.2), M.Metal, CYL)
	end
end

------------------------------------------------------------------------------- face
local function face(model: Model, r: number, head: CFrame, look: Looks.Look, female: boolean, skin: Color3)
	local hair = Color3.fromHex(look.hair or "#1F1B18")
	local front = -r * 0.9
	-- Eyes: whites with dark pupils, slightly wide-set (stylized, not caricatured).
	for _, side in { -1, 1 } do
		part(model, "EyeWhite", Vector3.new(r * 0.32, r * 0.32, r * 0.16), head * CFrame.new(side * r * 0.36, r * 0.12, front), EYE_WHITE, M.SmoothPlastic, BALL)
		part(model, "Eye", Vector3.new(r * 0.18, r * 0.2, r * 0.12), head * CFrame.new(side * r * 0.36, r * 0.1, front - r * 0.08), INK, M.SmoothPlastic, BALL)
		if not female then
			part(model, "Brow", Vector3.new(r * 0.42, r * 0.11, r * 0.12), head * CFrame.new(side * r * 0.36, r * 0.42, front + r * 0.02) * CFrame.Angles(0, 0, math.rad(side * -8)), hair)
		end
	end
	part(model, "Nose", Vector3.new(r * 0.22, r * 0.3, r * 0.22), head * CFrame.new(0, -r * 0.08, front - r * 0.08), skin:Lerp(Color3.new(0.5, 0.2, 0.1), 0.12), M.SmoothPlastic, BALL)

	local beard = look.beard or "none"
	if beard == "stubble" then
		part(model, "Beard", Vector3.new(r * 1.5, r * 0.6, r * 0.3), head * CFrame.new(0, -r * 0.55, front + r * 0.22), hair:Lerp(Color3.new(1, 1, 1), 0.08), M.Fabric).Transparency = 0.45
	elseif beard == "short" then
		part(model, "Beard", Vector3.new(r * 1.45, r * 0.7, r * 0.45), head * CFrame.new(0, -r * 0.62, front + r * 0.2), hair)
	elseif beard == "full" then
		part(model, "Beard", Vector3.new(r * 1.7, r * 1.0, r * 0.7), head * CFrame.new(0, -r * 0.75, front + r * 0.32), hair)
		for _, side in { -1, 1 } do
			part(model, "Sideburn", Vector3.new(r * 0.3, r * 0.9, r * 0.9), head * CFrame.new(side * r * 0.82, -r * 0.2, -r * 0.1), hair)
		end
	elseif beard == "long" then
		part(model, "Beard", Vector3.new(r * 1.7, r * 1.6, r * 0.7), head * CFrame.new(0, -r * 1.0, front + r * 0.32), hair)
		part(model, "BeardTip", Vector3.new(r * 1.1, r * 0.8, r * 0.55), head * CFrame.new(0, -r * 1.9, front + r * 0.35), hair)
		for _, side in { -1, 1 } do
			part(model, "Sideburn", Vector3.new(r * 0.3, r * 0.9, r * 0.9), head * CFrame.new(side * r * 0.82, -r * 0.2, -r * 0.1), hair)
		end
	end

	local stache = look.moustache or "none"
	if stache == "thin" then
		part(model, "Moustache", Vector3.new(r * 0.8, r * 0.12, r * 0.16), head * CFrame.new(0, -r * 0.33, front - r * 0.04), hair)
	elseif stache == "thick" then
		part(model, "Moustache", Vector3.new(r * 1.0, r * 0.24, r * 0.24), head * CFrame.new(0, -r * 0.33, front - r * 0.04), hair)
	elseif stache == "handlebar" then
		part(model, "Moustache", Vector3.new(r * 0.9, r * 0.22, r * 0.24), head * CFrame.new(0, -r * 0.33, front - r * 0.04), hair)
		for _, side in { -1, 1 } do
			part(model, "MoustacheTip", Vector3.new(r * 0.45, r * 0.14, r * 0.16), head * CFrame.new(side * r * 0.58, -r * 0.22, front + r * 0.02) * CFrame.Angles(0, 0, math.rad(side * 35)), hair)
		end
	end
end

------------------------------------------------------------------------------- props in hand
local function weapon(model: Model, kind: string, s: number, hand: CFrame)
	if kind == "stick" then
		part(model, "Weapon", Vector3.new(0.18 * s, 3.0 * s, 0.18 * s), hand * CFrame.new(0, 0.3 * s, -0.2 * s) * CFrame.Angles(math.rad(-15), 0, 0), WOOD, M.Wood)
	elseif kind == "dagger" then
		-- The curved khanjar, blade up.
		part(model, "Hilt", Vector3.new(0.22 * s, 0.4 * s, 0.22 * s), hand, COPPER, M.Metal)
		part(model, "Guard", Vector3.new(0.5 * s, 0.1 * s, 0.14 * s), hand * CFrame.new(0, 0.24 * s, 0), GOLD, M.Metal)
		part(model, "Weapon", Vector3.new(0.14 * s, 1.0 * s, 0.05 * s), hand * CFrame.new(0, 0.75 * s, 0) * CFrame.Angles(0, 0, math.rad(-10)), BLADE, M.Metal)
	elseif kind == "sword" then
		part(model, "Hilt", Vector3.new(0.18 * s, 0.45 * s, 0.18 * s), hand, INK, M.Wood)
		part(model, "Guard", Vector3.new(0.6 * s, 0.1 * s, 0.14 * s), hand * CFrame.new(0, 0.26 * s, 0), GOLD, M.Metal)
		part(model, "Weapon", Vector3.new(0.16 * s, 2.4 * s, 0.06 * s), hand * CFrame.new(0, 1.45 * s, 0) * CFrame.Angles(0, 0, math.rad(-6)), BLADE, M.Metal)
	elseif kind == "razor" then
		part(model, "Hilt", Vector3.new(0.14 * s, 0.5 * s, 0.1 * s), hand, Color3.fromHex("#EFE6D2"), M.SmoothPlastic)
		part(model, "Weapon", Vector3.new(0.08 * s, 0.6 * s, 0.22 * s), hand * CFrame.new(0, 0.5 * s, -0.08 * s), BLADE, M.Metal)
	elseif kind == "sling" then
		part(model, "Weapon", Vector3.new(0.07 * s, 1.2 * s, 0.07 * s), hand * CFrame.new(0, -0.6 * s, 0), Color3.fromHex("#8C6A3E"), M.Fabric)
		part(model, "Stone", Vector3.new(0.3 * s, 0.3 * s, 0.3 * s), hand * CFrame.new(0, -1.2 * s, 0), Color3.fromHex("#9A9088"), M.Slate, BALL)
	elseif kind == "jug" then
		-- The water carrier's brass-spouted jug.
		part(model, "Weapon", Vector3.new(1.0 * s, 1.2 * s, 1.0 * s), hand * CFrame.new(0, -0.55 * s, -0.2 * s), COPPER, M.Metal, BALL)
		part(model, "Spout", Vector3.new(0.6 * s, 0.16 * s, 0.16 * s), hand * CFrame.new(0, -0.2 * s, -0.8 * s) * CFrame.Angles(0, math.rad(90), math.rad(30)), COPPER, M.Metal, CYL)
	elseif kind == "lantern" then
		part(model, "Handle", Vector3.new(0.08 * s, 0.4 * s, 0.08 * s), hand * CFrame.new(0, -0.3 * s, 0), IRON, M.Metal)
		local g = part(model, "Weapon", Vector3.new(0.55 * s, 0.75 * s, 0.55 * s), hand * CFrame.new(0, -0.85 * s, 0), Color3.fromHex("#F2C46B"), M.Neon)
		part(model, "Cap", Vector3.new(0.7 * s, 0.14 * s, 0.7 * s), hand * CFrame.new(0, -0.45 * s, 0), IRON, M.Metal)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Range = 10
		light.Brightness = 0.8
		light.Parent = g
	elseif kind == "needle" then
		part(model, "Weapon", Vector3.new(0.06 * s, 1.1 * s, 0.06 * s), hand * CFrame.new(0, 0.5 * s, -0.1 * s), BLADE, M.Metal)
		part(model, "Thread", Vector3.new(0.04 * s, 0.9 * s, 0.04 * s), hand * CFrame.new(0.15 * s, 0.4 * s, -0.1 * s) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromHex("#A4302A"), M.Fabric)
	elseif kind == "hammer" then
		part(model, "Weapon", Vector3.new(0.2 * s, 2.2 * s, 0.2 * s), hand * CFrame.new(0, 0.6 * s, 0), WOOD, M.Wood)
		part(model, "HammerHead", Vector3.new(0.7 * s, 0.6 * s, 1.2 * s), hand * CFrame.new(0, 1.7 * s, 0), IRON, M.Metal)
	elseif kind == "tray" then
		part(model, "Weapon", Vector3.new(0.08 * s, 1.5 * s, 1.5 * s), hand * CFrame.new(0, 0.1 * s, -0.5 * s) * CYL_UP, COPPER, M.Metal, CYL)
		for i = -1, 1 do
			part(model, "Cup", Vector3.new(0.32 * s, 0.26 * s, 0.26 * s), hand * CFrame.new(i * 0.4 * s, 0.3 * s, -0.5 * s) * CYL_UP, Color3.fromHex("#FBF8F1"), M.Glass, CYL)
		end
	elseif kind == "bread" then
		part(model, "Weapon", Vector3.new(0.2 * s, 1.0 * s, 1.0 * s), hand * CFrame.new(0, 0.1 * s, -0.4 * s) * CYL_UP, Color3.fromHex("#C98A4B"), M.Sand, CYL)
		part(model, "Peel", Vector3.new(0.14 * s, 2.4 * s, 0.14 * s), hand * CFrame.new(0, -0.6 * s, 0.1 * s), WOOD, M.Wood)
	elseif kind == "rifle" then
		part(model, "Weapon", Vector3.new(0.14 * s, 0.14 * s, 2.6 * s), hand * CFrame.new(0, 0, -0.6 * s), WOOD, M.Wood)
		part(model, "Barrel", Vector3.new(0.09 * s, 0.09 * s, 1.4 * s), hand * CFrame.new(0, 0.07 * s, -1.5 * s), IRON, M.Metal)
	elseif kind == "sack" then
		part(model, "Weapon", Vector3.new(1.1 * s, 1.3 * s, 0.9 * s), hand * CFrame.new(-0.3 * s, 0.6 * s, 0.9 * s), Color3.fromHex("#D9BF94"), M.Fabric, BALL)
	end
end

------------------------------------------------------------------------------- outfits
type Body = { w: number, h: number, torsoW: number, torsoD: number, hipY: number, shoulderY: number, s: number }

local function outfit(model: Model, kind: string, b: Body, robe: Color3, accent: Color3, look: Looks.Look, torso: BasePart, root: BasePart)
	local s, w = b.s, b.w
	local tw, td = b.torsoW, b.torsoD
	local hipY = b.hipY
	local torsoCf = torso.CFrame
	local cloak = Color3.fromHex(look.cloak or "#4A2E18")

	bone = torso
	-- Belt / sash at the waist, everyone wears one.
	if kind == "uniform" then
		part(model, "Belt", Vector3.new(tw * 1.04, 0.32 * s, td * 1.06), torsoCf * CFrame.new(0, -0.8 * s * b.h, 0), LEATHER, M.Leather)
		part(model, "Buckle", Vector3.new(0.4 * s, 0.3 * s, 0.1 * s), torsoCf * CFrame.new(0, -0.8 * s * b.h, -td * 0.54), GOLD, M.Metal)
		part(model, "Strap", Vector3.new(0.22 * s, 2.4 * s * b.h, td * 1.06), torsoCf * CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(38)), LEATHER, M.Leather)
		part(model, "Collar", Vector3.new(tw * 0.7, 0.25 * s, td * 1.04), torsoCf * CFrame.new(0, 0.9 * s * b.h, 0), accent)
		for i = 0, 2 do
			part(model, "Button", Vector3.new(0.14 * s, 0.14 * s, 0.08 * s), torsoCf * CFrame.new(0, (0.45 - i * 0.4) * s * b.h, -td * 0.52), GOLD, M.Metal, BALL)
		end
		for _, side in { -1, 1 } do
			part(model, "Epaulette", Vector3.new(0.6 * s * w, 0.14 * s, 0.7 * s), torsoCf * CFrame.new(side * (tw / 2 - 0.15 * s), 1.0 * s * b.h, 0), accent)
		end
	else
		part(model, "Sash", Vector3.new(tw * 1.05, 0.45 * s, td * 1.07), torsoCf * CFrame.new(0, -0.75 * s * b.h, 0), accent)
	end

	if kind == "vest" or kind == "sherwal" or kind == "apron" then
		-- Open waistcoat (sidriyeh) over the shirt.
		for _, side in { -1, 1 } do
			part(model, "Vest", Vector3.new(tw * 0.32, 1.55 * s * b.h, td * 1.05), torsoCf * CFrame.new(side * tw * 0.3, 0.12 * s * b.h, 0), if kind == "vest" then accent else shade(robe, 0.35))
		end
	end
	if kind == "apron" then
		local apron = Color3.fromHex(look.apron or "#FBF8F1")
		part(model, "Apron", Vector3.new(tw * 0.78, 1.4 * s * b.h, 0.12 * s), torsoCf * CFrame.new(0, -0.2 * s * b.h, -td * 0.55), apron)
		bone = root
		part(model, "ApronSkirt", Vector3.new(tw * 0.8, 1.3 * s * b.h, 0.12 * s), CFrame.new(0, hipY - 0.6 * s * b.h, -td * 0.62), apron)
	end

	bone = root
	if kind == "qumbaz" or kind == "bisht" or kind == "abaya" then
		-- Ankle-length robe as a skirt from the hips; the legs underneath only show the shoes.
		local skirtColor = if kind == "abaya" then cloak else robe
		local len = hipY - 0.35 * s
		part(model, "Skirt", Vector3.new(tw * 1.08, len, td * 1.18), CFrame.new(0, 0.35 * s + len / 2, 0), skirtColor)
		part(model, "Hem", Vector3.new(tw * 1.14, 0.25 * s, td * 1.24), CFrame.new(0, 0.48 * s, 0), shade(skirtColor, 0.18))
		if kind == "qumbaz" then
			-- The qumbaz's crossed front and pin-stripes.
			for i = -1, 1 do
				part(model, "Stripe", Vector3.new(0.08 * s, len, 0.04 * s), CFrame.new(i * tw * 0.28, 0.35 * s + len / 2, -td * 0.6), shade(robe, 0.3))
			end
		end
	end
	if kind == "bisht" or kind == "abaya" then
		-- Open over-cloak: back and two side panels from the shoulders to the ankles, trimmed.
		local top = b.shoulderY + 0.15 * s
		local len = top - 0.3 * s
		local cy = 0.3 * s + len / 2
		part(model, "CloakBack", Vector3.new(tw * 1.22, len, 0.18 * s), CFrame.new(0, cy, td * 0.62), cloak)
		for _, side in { -1, 1 } do
			part(model, "Cloak", Vector3.new(0.2 * s, len, td * 1.2), CFrame.new(side * tw * 0.62, cy, 0), cloak)
			if kind == "bisht" then
				part(model, "Trim", Vector3.new(0.12 * s, len, 0.1 * s), CFrame.new(side * tw * 0.6, cy, -td * 0.6), GOLD, M.Fabric)
			end
		end
	end
	bone = nil
end

------------------------------------------------------------------------------- imported models
local function importedTemplate(look: Looks.Look?): Model?
	if not look or not look.model then
		return nil
	end
	local folder = ReplicatedStorage:FindFirstChild("CharacterModels")
	local m = folder and folder:FindFirstChild(look.model)
	return if m and m:IsA("Model") then m else nil
end

-- Clones an imported character, scales it to the archetype height and gives it the same Root
-- contract as primitive figures. Rig joints and bones are kept for AnimationController playback.
local function buildImported(template: Model, name: string, s: number, look: Looks.Look): Model
	local m = template:Clone()
	m.Name = name
	-- Importer leftovers that only matter in Studio.
	for _, junk in { "InitialPoses", "AnimSaves" } do
		local j = m:FindFirstChild(junk)
		if j then
			j:Destroy()
		end
	end
	if look.modelYaw and look.modelYaw ~= 0 then
		m:PivotTo(m:GetPivot() * CFrame.Angles(0, math.rad(look.modelYaw), 0))
	end
	local cf, size = m:GetBoundingBox()
	if size.Y > 0 then
		m:ScaleTo(m:GetScale() * (RigBuilder.HEIGHT * s) / size.Y)
		cf, size = m:GetBoundingBox()
	end
	local groundY = cf.Position.Y - size.Y / 2
	local hrp = m:FindFirstChild("HumanoidRootPart")
	cf = CFrame.new(cf.Position) -- the bounding box may be rotated; Root stays axis-aligned
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2 * s, RigBuilder.HEIGHT * s, 1 * s)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	-- Face -Z like primitive figures: imported rigs are authored facing -Z (Roblox convention).
	root.CFrame = CFrame.new(cf.Position.X, groundY + size.Y / 2, cf.Position.Z)
	root.PivotOffset = CFrame.new(0, -size.Y / 2, 0)
	root.Parent = m
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			-- A rig with a HumanoidRootPart keeps its joints live; anything else is rigid.
			d.Anchored = false
			if d ~= hrp and not hrp then
				local w = Instance.new("WeldConstraint")
				w.Part0 = root
				w.Part1 = d
				w.Parent = d
			end
		end
	end
	if hrp and hrp:IsA("BasePart") then
		hrp.Transparency = 1
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = hrp
		w.Parent = hrp
	end
	m.PrimaryPart = root
	-- Same starting place as primitive figures: feet at the origin, facing -Z.
	m:PivotTo(CFrame.new())
	m:SetAttribute("Imported", true)
	m:SetAttribute("Rigged", true)
	return m
end

------------------------------------------------------------------------------- build
local function buildCat(m: Model, s: number, robe: Color3, root: BasePart)
	bone = root
	part(m, "Body", Vector3.new(1.0 * s, 1.0 * s, 1.8 * s), CFrame.new(0, 0.75 * s, 0.2 * s), robe, M.Fabric, BALL)
	local head = part(m, "Head", Vector3.new(1.0 * s, 0.95 * s, 0.95 * s), CFrame.new(0, 1.45 * s, -0.75 * s), robe, M.Fabric, BALL)
	for _, side in { -1, 1 } do
		part(m, "Ear", Vector3.new(0.12 * s, 0.38 * s, 0.3 * s), CFrame.new(side * 0.28 * s, 1.95 * s, -0.75 * s) * CFrame.Angles(0, 0, math.rad(side * -15)), robe)
		part(m, "Eye", Vector3.new(0.16 * s, 0.2 * s, 0.1 * s), CFrame.new(side * 0.2 * s, 1.55 * s, -1.2 * s), Color3.fromHex("#7BAF3A"), M.Neon, BALL)
		part(m, "Paw", Vector3.new(0.3 * s, 0.4 * s, 0.3 * s), CFrame.new(side * 0.3 * s, 0.2 * s, -0.4 * s), robe)
		part(m, "Paw", Vector3.new(0.3 * s, 0.4 * s, 0.3 * s), CFrame.new(side * 0.3 * s, 0.2 * s, 0.8 * s), robe)
	end
	part(m, "Tail", Vector3.new(0.18 * s, 0.18 * s, 1.4 * s), CFrame.new(0, 1.3 * s, 1.5 * s) * CFrame.Angles(math.rad(-40), 0, 0), robe)
	head.Name = "Head"
	bone = nil
end

-- Builds a figure for `id` (a unit or enemy id; used to look up CharacterLooks) with its root
-- on the ground at the origin, facing -Z. Returns the model; PrimaryPart is "Root" (invisible).
function RigBuilder.build(parent: Instance?, name: string, v: Visual, id: string?): Model
	local s = v.scale or 1
	local look: Looks.Look = (if id then (Looks :: any)[id] else nil) or {}
	local template = importedTemplate(look)
	if template then
		local m = buildImported(template, name, s, look)
		m:SetAttribute("LookId", id)
		m.Parent = parent
		return m
	end

	local m = Instance.new("Model")
	m.Name = name
	local robe = Color3.fromHex(v.robe)
	local accent = Color3.fromHex(v.accent)
	local skin = Color3.fromHex(v.skin)

	bone = nil
	local root = part(m, "Root", Vector3.new(2 * s, RigBuilder.HEIGHT * s, 1 * s), CFrame.new(0, RigBuilder.HEIGHT / 2 * s, 0), robe)
	root.Transparency = 1
	root.Anchored = true
	root.PivotOffset = CFrame.new(0, -RigBuilder.HEIGHT / 2 * s, 0)
	m.PrimaryPart = root

	if v.weapon == "cat" then
		buildCat(m, s, robe, root)
		m.Parent = parent
		return m
	end

	local shape = BUILDS[look.build or "normal"] or BUILDS.normal
	local kind = look.outfit or "qumbaz"
	local female = kind == "abaya"
	local w, h = shape.w, shape.h
	local legH = 1.45 * s * h
	local footH = 0.35 * s
	local hipY = footH + legH - 0.1 * s
	local torsoH = 1.85 * s * h
	local torsoW = 2.0 * s * w
	local torsoD = 1.15 * s * math.sqrt(w)
	local shoulderY = hipY + torsoH - 0.2 * s
	local r = 0.98 * s * shape.head -- head radius: big heads read better on phones
	local b: Body = { w = w, h = h, torsoW = torsoW, torsoD = torsoD, hipY = hipY, shoulderY = shoulderY, s = s }

	local bulky = kind == "sherwal" or kind == "vest" or kind == "apron"
	local legColor = if kind == "uniform" then robe elseif bulky then shade(robe, 0.45) else robe
	local shoe = if kind == "uniform" then INK else Color3.fromHex("#4A2E18")

	-- Torso
	local torso = part(m, "Torso", Vector3.new(torsoW, torsoH, torsoD), CFrame.new(0, hipY + torsoH / 2, 0), if female then Color3.fromHex(look.cloak or "#2F3E6B") else robe)
	joint("Waist", root, torso, CFrame.new(0, hipY, 0))
	if look.build == "stout" then
		bone = torso
		part(m, "Belly", Vector3.new(torsoW * 0.8, torsoH * 0.6, torsoD * 0.6), CFrame.new(0, hipY + torsoH * 0.35, -torsoD * 0.32), robe, M.Fabric, BALL)
		bone = nil
	end

	-- Legs + shoes (Root → leg Motor6Ds so enemies can walk)
	for _, side in { -1, 1 } do
		local lx = side * torsoW * 0.24
		local legW = (if bulky then 0.95 else 0.78) * s * w
		local leg = part(m, if side < 0 then "LeftLeg" else "RightLeg", Vector3.new(legW, legH, legW), CFrame.new(lx, footH + legH / 2 - 0.05 * s, 0), legColor)
		joint(if side < 0 then "LeftHip" else "RightHip", root, leg, CFrame.new(lx, hipY, 0))
		bone = leg
		part(m, "Shoe", Vector3.new(0.8 * s * w, footH, 1.15 * s), CFrame.new(lx, footH / 2, -0.15 * s), shoe, M.Leather)
		if kind == "uniform" then
			part(m, "Boot", Vector3.new(legW * 1.08, legH * 0.45, legW * 1.08), CFrame.new(lx, footH + legH * 0.2, 0), INK, M.Leather)
		elseif bulky then
			part(m, "Cuff", Vector3.new(legW * 0.85, 0.25 * s, legW * 0.85), CFrame.new(lx, footH + 0.08 * s, 0), shade(legColor, 0.25))
		end
		bone = nil
	end

	-- Arms: sleeve + hand, hanging from the shoulder joint
	for _, side in { -1, 1 } do
		local ax = side * (torsoW / 2 + 0.36 * s * w)
		local armH = 1.7 * s * h
		local shoulder = CFrame.new(ax, shoulderY, 0)
		local sleeveColor = if female then Color3.fromHex(look.cloak or "#2F3E6B") else robe
		local arm = part(m, if side < 0 then "LeftArm" else "RightArm", Vector3.new(0.72 * s * w, armH, 0.72 * s * w), shoulder * CFrame.new(0, -armH / 2 + 0.2 * s, 0), sleeveColor)
		joint(if side < 0 then "LeftShoulder" else "RightShoulder", torso, arm, shoulder)
		bone = arm
		part(m, "Hand", Vector3.new(0.62 * s, 0.62 * s, 0.62 * s), shoulder * CFrame.new(0, -armH + 0.05 * s, 0), skin, M.SmoothPlastic, BALL)
		part(m, "Shoulder", Vector3.new(0.85 * s * w, 0.85 * s * w, 0.85 * s * w), shoulder * CFrame.new(0, -0.1 * s, 0), sleeveColor, M.Fabric, BALL)
		if side > 0 then
			weapon(m, v.weapon, s, shoulder * CFrame.new(0, -armH + 0.05 * s, 0))
		end
		bone = nil
	end

	-- Head
	local neckY = shoulderY + 0.15 * s
	local headCf = CFrame.new(0, neckY + r * 0.82, 0)
	local head = part(m, "Head", Vector3.new(r * 2, r * 2, r * 2), headCf, skin, M.SmoothPlastic, BALL)
	joint("Neck", torso, head, CFrame.new(0, neckY, 0))
	bone = head
	for _, side in { -1, 1 } do
		part(m, "Ear", Vector3.new(r * 0.25, r * 0.5, r * 0.4), headCf * CFrame.new(side * r * 0.95, 0, 0.05 * s), skin, M.SmoothPlastic, BALL)
	end
	face(m, r, headCf, look, female, skin)
	hat(m, v.hat, Color3.fromHex(v.hatColor), r, headCf)
	bone = nil

	outfit(m, kind, b, robe, accent, look, torso, root)

	m:SetAttribute("Rigged", true)
	m.Parent = parent
	return m
end

-- Like build, but builds each id once and returns clones of that template afterwards. Building a
-- figure is dozens of parts and joints (an imported one also rescales meshes); cloning a finished
-- one is much cheaper. Use for anything spawned repeatedly (enemies, cards, towers).
local templates: { [string]: Model } = {}
function RigBuilder.cached(parent: Instance?, name: string, v: Visual, id: string): Model
	local key = id .. "@" .. tostring(v.scale or 1)
	local tpl = templates[key]
	if not tpl then
		tpl = RigBuilder.build(nil, "Template", v, id)
		templates[key] = tpl
	end
	local m = (tpl :: Model):Clone()
	m.Name = name
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
