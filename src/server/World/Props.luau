--!strict
-- Reusable props for the lane, built from primitives (docs/ART_BIBLE.md, docs/research §1–3).
-- Façade props take a frame from Kit.faceFrame: local x runs along the wall, y is up, and
-- NEGATIVE local z points out of the wall (toward the street).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local Kit = require(script.Parent.Kit)

local M = Kit.M
local part, model = Kit.part, Kit.model

local Props = {}

local IRON = Color3.fromHex("#2B2724")
local TERRACOTTA = Color3.fromHex("#B5643C")

-- Arched wooden door with a stone frame, ablaq voussoirs, iron bands, knocker and threshold.
function Props.door(parent: Instance, f: CFrame, w: number, h: number, color: Color3?): Model
	local m = model(parent, "Door")
	local wood = color or Palette.wood
	-- Jambs
	for _, side in { -1, 1 } do
		part(m, { name = "Jamb", size = Vector3.new(0.7, h + 0.6, 0.6), cf = f * CFrame.new(side * (w / 2 + 0.35), (h + 0.6) / 2, -0.3), color = Palette.stoneLight, material = M.Limestone })
	end
	-- Ablaq voussoirs (alternating pale and dark stones) over the opening
	local n = 5
	local span = w + 1.4
	for i = 1, n do
		local x = -span / 2 + (i - 0.5) * span / n
		local lift = (1 - math.abs(x) / (span / 2)) * 0.5 -- slight arch profile
		part(m, {
			name = "Voussoir",
			size = Vector3.new(span / n, 1.1, 0.7),
			cf = f * CFrame.new(x, h + 0.55 + lift, -0.35),
			color = if i % 2 == 0 then Palette.basalt else Palette.stoneLight,
			material = if i % 2 == 0 then M.Basalt else M.Limestone,
			shadow = false,
		})
	end
	-- Leaves
	part(m, { name = "Leaf", size = Vector3.new(w, h, 0.3), cf = f * CFrame.new(0, h / 2, -0.15), color = wood, material = M.WoodPlanks })
	part(m, { name = "Seam", size = Vector3.new(0.1, h, 0.34), cf = f * CFrame.new(0, h / 2, -0.17), color = Palette.woodDark, material = M.Wood, shadow = false })
	for _, y in { h * 0.25, h * 0.7 } do
		part(m, { name = "Band", size = Vector3.new(w, 0.18, 0.36), cf = f * CFrame.new(0, y, -0.18), color = IRON, material = M.Metal, shadow = false })
	end
	-- Knocker ring
	part(m, {
		name = "Knocker",
		size = Vector3.new(0.1, 0.55, 0.55),
		cf = f * CFrame.new(w * 0.22, h * 0.55, -0.4) * CFrame.Angles(0, math.rad(90), 0),
		color = Palette.copper,
		material = M.Metal,
		shape = Enum.PartType.Cylinder,
		collide = false,
		shadow = false,
	})
	-- Threshold step
	part(m, { name = "Step", size = Vector3.new(w + 1.4, 0.3, 1), cf = f * CFrame.new(0, 0.15, -0.5), color = Palette.basalt, material = M.Basalt })
	return m
end

-- Small window with a stone sill and iron grille.
function Props.window(parent: Instance, f: CFrame, w: number, h: number): Model
	local m = model(parent, "Window")
	part(m, { name = "Opening", size = Vector3.new(w, h, 0.2), cf = f * CFrame.new(0, 0, -0.1), color = Palette.ink, material = M.SmoothPlastic, shadow = false })
	part(m, { name = "Sill", size = Vector3.new(w + 0.6, 0.3, 0.6), cf = f * CFrame.new(0, -h / 2 - 0.15, -0.3), color = Palette.stoneWarm, material = M.Limestone, shadow = false })
	for i = 1, 3 do
		local x = -w / 2 + i * w / 4
		part(m, { name = "Bar", size = Vector3.new(0.1, h, 0.1), cf = f * CFrame.new(x, 0, -0.25), color = IRON, material = M.Metal, collide = false, shadow = false })
	end
	part(m, { name = "Rail", size = Vector3.new(w, 0.1, 0.1), cf = f * CFrame.new(0, 0, -0.25), color = IRON, material = M.Metal, collide = false, shadow = false })
	return m
end

-- Projecting wooden bay with a lattice screen (mashrabiya), resting on corbels.
function Props.mashrabiya(parent: Instance, f: CFrame, w: number, h: number, depth: number): Model
	local m = model(parent, "Mashrabiya")
	part(m, { name = "Bay", size = Vector3.new(w, h, depth), cf = f * CFrame.new(0, h / 2, -depth / 2), color = Palette.woodDark, material = M.Wood })
	part(m, { name = "Cap", size = Vector3.new(w + 0.5, 0.35, depth + 0.5), cf = f * CFrame.new(0, h + 0.17, -depth / 2), color = Palette.wood, material = M.WoodPlanks, shadow = false })
	part(m, { name = "Sill", size = Vector3.new(w + 0.3, 0.3, depth + 0.3), cf = f * CFrame.new(0, -0.15, -depth / 2), color = Palette.wood, material = M.WoodPlanks, shadow = false })
	-- Lattice on the front face
	local cols = math.max(3, math.floor(w / 0.9))
	local rows = math.max(3, math.floor(h / 0.9))
	for i = 1, cols - 1 do
		part(m, { name = "LatticeV", size = Vector3.new(0.12, h - 0.4, 0.12), cf = f * CFrame.new(-w / 2 + i * w / cols, h / 2, -depth - 0.04), color = Palette.wood, material = M.Wood, collide = false, shadow = false })
	end
	for j = 1, rows - 1 do
		part(m, { name = "LatticeH", size = Vector3.new(w - 0.4, 0.12, 0.12), cf = f * CFrame.new(0, j * h / rows, -depth - 0.04), color = Palette.wood, material = M.Wood, collide = false, shadow = false })
	end
	-- Corbels (beam ends) under the bay
	for _, x in { -w / 2 + 0.5, 0, w / 2 - 0.5 } do
		part(m, { name = "Corbel", size = Vector3.new(0.5, 0.7, depth), cf = f * CFrame.new(x, -0.65, -depth / 2), color = Palette.woodDark, material = M.Wood, shadow = false })
	end
	return m
end

-- Hanging lantern on a wall bracket, with a soft light.
function Props.lantern(parent: Instance, f: CFrame, range: number?): Model
	local m = model(parent, "Lantern")
	part(m, { name = "Bracket", size = Vector3.new(0.18, 0.18, 1.4), cf = f * CFrame.new(0, 0.9, -0.7), color = IRON, material = M.Metal, collide = false, shadow = false })
	part(m, { name = "Cap", size = Vector3.new(0.9, 0.25, 0.9), cf = f * CFrame.new(0, 0.6, -1.3), color = IRON, material = M.Metal, collide = false, shadow = false })
	local glass = part(m, { name = "Glass", size = Vector3.new(0.75, 1.0, 0.75), cf = f * CFrame.new(0, 0, -1.3), color = Color3.fromHex("#F2C46B"), material = M.Glass, collide = false, transparency = 0.15, shadow = false })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 196, 120)
	light.Range = range or 14
	light.Brightness = 1.1
	light.Shadows = false
	light.Parent = glass
	-- PV-E04: the Meshy lantern takes the glass and cap's place under the bracket
	m:SetAttribute("SwapProp", "hanging_lantern")
	m:SetAttribute("SwapCFrame", f * CFrame.new(0, -0.6, -1.3))
	m:SetAttribute("SwapReplace", "Cap,Glass")
	return m
end

-- Terracotta pot with a plant (basil / jasmine / geranium).
function Props.pot(parent: Instance, pos: Vector3, kind: "basil" | "jasmine" | "geranium", scale: number?): Model
	local s = scale or 1
	local m = model(parent, "Pot")
	Kit.column(m, "Pot", pos, 0.9 * s, 0.9 * s, TERRACOTTA, M.Slate, false)
	Kit.ball(m, "Leaves", pos + Vector3.new(0, 1.25 * s, 0), 1.2 * s, Palette.vine, M.Grass, false)
	local flower = if kind == "jasmine" then Palette.jasmine elseif kind == "geranium" then Palette.fabricRed else nil
	if kind == "jasmine" then
		m:SetAttribute("SwapProp", "jasmine_pot") -- PV-E04
		m:SetAttribute("SwapCFrame", CFrame.new(pos))
		m:SetAttribute("SwapScale", s)
	end
	if flower then
		for i = 1, 3 do
			local a = i * 2.1
			Kit.ball(m, "Flower", pos + Vector3.new(math.cos(a) * 0.4 * s, 1.6 * s, math.sin(a) * 0.4 * s), 0.3 * s, flower, M.SmoothPlastic, false)
		end
	end
	return m
end

-- Clothes line between two points with hanging cloths.
function Props.laundry(parent: Instance, a: Vector3, b: Vector3, colors: { Color3 }): Model
	local m = model(parent, "Laundry")
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the client sways it (LobbyLifeController)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	part(m, { name = "Rope", size = Vector3.new(0.06, 0.06, len), cf = CFrame.lookAt(mid, b), color = Palette.stoneWarm, material = M.Fabric, collide = false, shadow = false })
	for i, c in colors do
		local t = i / (#colors + 1)
		local p = a:Lerp(b, t)
		part(m, { name = "Cloth", size = Vector3.new(1.4, 1.8, 0.05), cf = CFrame.lookAt(p, p + (b - a):Cross(Vector3.yAxis)) * CFrame.new(0, -0.9, 0), color = c, material = M.Fabric, collide = false, shadow = false })
	end
	return m
end

-- Citrus or flowering tree with a full canopy.
function Props.tree(parent: Instance, pos: Vector3, fruit: Color3?, scale: number?): Model
	local s = scale or 1
	local m = model(parent, "Tree")
	Kit.column(m, "Trunk", pos, 5 * s, 1 * s, Palette.wood, M.Wood)
	Kit.ball(m, "Canopy", pos + Vector3.new(0, 6.6 * s, 0), 6.2 * s, Palette.vine, M.Grass, false)
	Kit.ball(m, "Canopy2", pos + Vector3.new(1.4 * s, 5.8 * s, 0.8 * s), 4.2 * s, Color3.fromHex("#4E6B30"), M.Grass, false)
	Kit.ball(m, "Canopy3", pos + Vector3.new(-1.3 * s, 6 * s, -0.9 * s), 4.4 * s, Color3.fromHex("#6A8A40"), M.Grass, false)
	if fruit then
		for i = 1, 7 do
			local a = i * 0.9
			local r = 2.9 * s
			Kit.ball(m, "Fruit", pos + Vector3.new(math.cos(a) * r, (5.4 + (i % 3) * 0.8) * s, math.sin(a) * r), 0.55 * s, fruit, M.SmoothPlastic, false)
		end
	end
	return m
end

-- Stone bench with a wooden seat (`cf` at ground, bench along local X).
function Props.bench(parent: Instance, cf: CFrame): Model
	local m = model(parent, "Bench")
	part(m, { name = "Seat", size = Vector3.new(6, 0.5, 2), cf = cf * CFrame.new(0, 1.55, 0), color = Palette.wood, material = M.WoodPlanks })
	part(m, { name = "Base", size = Vector3.new(5.4, 1.3, 1.6), cf = cf * CFrame.new(0, 0.65, 0), color = Palette.basalt, material = M.Basalt })
	part(m, { name = "Cushion", size = Vector3.new(2.2, 0.3, 1.6), cf = cf * CFrame.new(-1.4, 1.95, 0), color = Palette.fabricRed, material = M.Fabric, collide = false, shadow = false })
	return m
end

-- A sitting cat (`cf` at ground, facing local -Z).
function Props.cat(parent: Instance, cf: CFrame, color: Color3): Model
	local m = model(parent, "Cat")
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the client turns it (LobbyLifeController)
	part(m, { name = "Body", size = Vector3.new(0.7, 0.8, 1.2), cf = cf * CFrame.new(0, 0.4, 0.15), color = color, material = M.Fabric, collide = false })
	Kit.ball(m, "Head", (cf * CFrame.new(0, 1.05, -0.35)).Position, 0.62, color, M.Fabric, false)
	for _, x in { -0.18, 0.18 } do
		Kit.wedge(m, "Ear", Vector3.new(0.08, 0.25, 0.2), cf * CFrame.new(x, 1.42, -0.35), color, M.Fabric).CanCollide = false
	end
	part(m, { name = "Tail", size = Vector3.new(0.14, 0.14, 1.0), cf = cf * CFrame.new(0.3, 0.12, 0.7) * CFrame.Angles(0, math.rad(35), 0), color = color, material = M.Fabric, collide = false, shadow = false })
	return m
end

-- Wooden crate of produce (oranges, aubergines, pomegranates…).
function Props.crate(parent: Instance, cf: CFrame, produce: Color3): Model
	local m = model(parent, "Crate")
	m:SetAttribute("SwapProp", "market_bundle") -- PV-E04
	m:SetAttribute("SwapCFrame", cf)
	part(m, { name = "Crate", size = Vector3.new(2, 1, 1.4), cf = cf * CFrame.new(0, 0.5, 0), color = Palette.wood, material = M.WoodPlanks })
	for i = 0, 5 do
		local x = -0.65 + (i % 3) * 0.65
		local z = if i < 3 then -0.3 else 0.3
		Kit.ball(m, "Produce", (cf * CFrame.new(x, 1.1, z)).Position, 0.55, produce, M.SmoothPlastic, false)
	end
	return m
end

-- Copper water jug / cooking pot.
function Props.copperPot(parent: Instance, pos: Vector3, size: number): Model
	local m = model(parent, "CopperPot")
	Kit.ball(m, "Body", pos + Vector3.new(0, size * 0.45, 0), size, Palette.copper, M.Metal, false)
	Kit.column(m, "Neck", pos + Vector3.new(0, size * 0.85, 0), size * 0.35, size * 0.35, Palette.copper, M.Metal, false)
	return m
end

-- Pigeon on the ground.
function Props.pigeon(parent: Instance, pos: Vector3, yaw: number): Model
	local m = model(parent, "Pigeon")
	local cf = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	part(m, { name = "Body", size = Vector3.new(0.35, 0.35, 0.6), cf = cf * CFrame.new(0, 0.2, 0), color = Color3.fromHex("#8A8F98"), material = M.Fabric, collide = false, shadow = false })
	Kit.ball(m, "Head", (cf * CFrame.new(0, 0.42, -0.3)).Position, 0.22, Color3.fromHex("#6E7480"), M.Fabric, false)
	return m
end

-- Grapevine trellis spanning the lane between two heights (x0..x1 at z).
function Props.trellis(parent: Instance, x0: number, x1: number, z: number, y: number): Model
	local m = model(parent, "Trellis")
	Kit.box(m, "Beam", x0, y, z - 0.25, x1, y + 0.45, z + 0.25, Palette.wood, M.Wood).CastShadow = false
	local leaves = Kit.box(m, "Vine", x0 + 0.5, y - 0.6, z - 1.6, x1 - 0.5, y, z + 1.6, Palette.vine, M.Grass)
	leaves.CanCollide = false
	leaves.CanQuery = false
	for i = 1, 4 do
		local x = x0 + (x1 - x0) * i / 5
		Kit.ball(m, "Grapes", Vector3.new(x, y - 1.1, z + (if i % 2 == 0 then 0.6 else -0.6)), 0.6, Color3.fromHex("#5B2A55"), M.SmoothPlastic, false)
	end
	return m
end

return Props
