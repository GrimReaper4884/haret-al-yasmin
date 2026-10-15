--!strict
-- Builds the vertical-slice map from primitives (docs/WORLD_MAP.md). If Workspace already has a
-- "Map" model (e.g. a Studio-authored replacement), building is skipped.
-- Layout: lane along Z, gate at +Z, fountain square at the origin, Sitt Wardeh's house at -Z.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)

local WorldService = {}

local M = Enum.Material
local CYL_UP = CFrame.Angles(0, 0, math.rad(90))

type PartProps = {
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	name: string?,
	collide: boolean?,
	transparency: number?,
}

local function part(parent: Instance, p: PartProps): Part
	local x = Instance.new("Part")
	x.Anchored = true
	x.Size = p.size
	x.CFrame = p.cf
	x.Color = p.color
	x.Material = p.material or M.Limestone
	x.Shape = p.shape or Enum.PartType.Block
	x.Name = p.name or "Part"
	x.CanCollide = if p.collide == nil then true else p.collide
	x.Transparency = p.transparency or 0
	x.TopSurface = Enum.SurfaceType.Smooth
	x.BottomSurface = Enum.SurfaceType.Smooth
	x.CastShadow = x.Size.Magnitude > 4
	x.Parent = parent
	return x
end

-- Axis-aligned box from min/max corners.
local function box(parent: Instance, name: string, x0: number, y0: number, z0: number, x1: number, y1: number, z1: number, color: Color3, material: Enum.Material?): Part
	return part(parent, {
		name = name,
		size = Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)),
		cf = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
		color = color,
		material = material,
	})
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- A solid two-storey building block with ablaq bands, a parapet, a door and windows on the
-- face pointing toward `faceDir` (+1/-1 along `axis`).
local function building(parent: Instance, name: string, x0: number, z0: number, x1: number, z1: number, height: number, axis: "X" | "Z", faceDir: number, opts: { door: boolean?, jetty: boolean? }?)
	local m = model(parent, name)
	local o: { door: boolean?, jetty: boolean? } = opts or {}
	box(m, "Ground", x0, 0, z0, x1, 12, z1, Palette.stoneLight, M.Limestone)
	box(m, "Upper", x0, 12, z0, x1, height, z1, Palette.plaster, M.Plaster)

	local face = if axis == "X" then (if faceDir > 0 then math.max(x0, x1) else math.min(x0, x1)) else (if faceDir > 0 then math.max(z0, z1) else math.min(z0, z1))
	local lo = if axis == "X" then math.min(z0, z1) else math.min(x0, x1)
	local hi = if axis == "X" then math.max(z0, z1) else math.max(x0, x1)
	local mid = (lo + hi) / 2
	local width = hi - lo

	local function facePart(nm: string, along0: number, along1: number, y0: number, y1: number, depth: number, color: Color3, mat: Enum.Material)
		local d0, d1 = face, face + faceDir * depth
		if axis == "X" then
			return box(m, nm, d0, y0, along0, d1, y1, along1, color, mat)
		end
		return box(m, nm, along0, y0, d0, along1, y1, d1, color, mat)
	end

	-- Ablaq bands (alternating basalt courses) on the ground floor
	for i, y in { 3, 6, 9 } do
		facePart("Ablaq" .. i, lo, hi, y, y + 1, 0.2, Palette.basalt, M.Basalt)
	end
	-- Plinth and parapet
	facePart("Plinth", lo, hi, 0, 1, 0.4, Palette.basalt, M.Basalt)
	box(m, "Parapet", x0, height, z0, x1, height + 1.5, z1, Palette.stoneWarm, M.Limestone)

	if o.door ~= false then
		facePart("Door", mid - 3, mid + 3, 0, 9, 0.3, Palette.wood, M.WoodPlanks)
		facePart("Lintel", mid - 4, mid + 4, 9, 10, 0.5, Palette.basalt, M.Basalt)
	end
	-- Upper-floor windows with mashrabiya screens
	local count = math.max(1, math.floor(width / 10))
	for i = 1, count do
		local c = lo + (i - 0.5) * width / count
		facePart("Window" .. i, c - 1.5, c + 1.5, 14.5, 18.5, 0.3, Palette.woodDark, M.Wood)
	end
	-- Jutting wooden bay over the alley
	if o.jetty then
		facePart("Jetty", mid - 5, mid + 5, 12.5, 19, 2, Palette.wood, M.WoodPlanks)
		facePart("JettyScreen", mid - 4, mid + 4, 13.5, 18, 2.2, Palette.woodDark, M.Wood)
	end
	return m
end

local function lantern(parent: Instance, pos: Vector3)
	local m = model(parent, "Lantern")
	part(m, { name = "Arm", size = Vector3.new(0.3, 0.3, 1.6), cf = CFrame.new(pos + Vector3.new(0, 0.8, 0)), color = Palette.ink, material = M.Metal, collide = false })
	local glass = part(m, { name = "Glass", size = Vector3.new(0.9, 1.3, 0.9), cf = CFrame.new(pos), color = Palette.copper, material = M.Glass, collide = false, transparency = 0.2 })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 196, 120)
	light.Range = 14
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = glass
end

local function tree(parent: Instance, pos: Vector3, blossom: Color3?)
	local m = model(parent, "Tree")
	part(m, { name = "Trunk", size = Vector3.new(6, 1.2, 1.2), cf = CFrame.new(pos + Vector3.new(0, 3, 0)) * CYL_UP, color = Palette.wood, material = M.Wood, shape = Enum.PartType.Cylinder })
	part(m, { name = "Canopy", size = Vector3.new(7, 7, 7), cf = CFrame.new(pos + Vector3.new(0, 7.5, 0)), color = Palette.vine, material = M.Grass, shape = Enum.PartType.Ball, collide = false })
	if blossom then
		for i = 1, 5 do
			local a = i * math.pi * 2 / 5
			part(m, { name = "Blossom", size = Vector3.new(1, 1, 1), cf = CFrame.new(pos + Vector3.new(math.cos(a) * 3, 8 + (i % 2), math.sin(a) * 3)), color = blossom, material = M.SmoothPlastic, shape = Enum.PartType.Ball, collide = false })
		end
	end
end

local function bench(parent: Instance, cf: CFrame)
	local m = model(parent, "Bench")
	part(m, { name = "Seat", size = Vector3.new(6, 0.6, 2), cf = cf * CFrame.new(0, 1.6, 0), color = Palette.wood, material = M.WoodPlanks })
	part(m, { name = "Base", size = Vector3.new(5.4, 1.3, 1.6), cf = cf * CFrame.new(0, 0.65, 0), color = Palette.basalt, material = M.Basalt })
end

local function buildGround(map: Instance)
	local g = model(map, "Ground")
	-- Lane floor and gate approach
	box(g, "Lane", -8, -1, 24, 8, 0, 96, Palette.stoneWarm, M.Cobblestone)
	-- Shop floors
	box(g, "BakeryFloor", -22, -1, 50, -8, 0, 70, Palette.stoneLight, M.Limestone)
	box(g, "TailorFloor", 8, -1, 48, 20, 0, 64, Palette.stoneLight, M.Limestone)
	-- Square paving and connector to the house
	box(g, "Square", -24, -1, -26, 24, 0, 24, Palette.stoneLight, M.Pavement)
	box(g, "HouseFloor", -16, -1, -58, 16, 0, -26, Palette.stoneWarm, M.Limestone)
	-- Decorative inlay ring around the fountain
	part(g, { name = "Inlay", size = Vector3.new(0.1, 30, 30), cf = CFrame.new(0, 0.02, 0) * CYL_UP, color = Palette.basalt, material = M.Slate, shape = Enum.PartType.Cylinder, collide = false })
	part(g, { name = "InlayInner", size = Vector3.new(0.12, 27, 27), cf = CFrame.new(0, 0.03, 0) * CYL_UP, color = Palette.stoneLight, material = M.Pavement, shape = Enum.PartType.Cylinder, collide = false })
end

local function buildGate(map: Instance)
	local m = model(map, "JasmineGate")
	box(m, "PillarW", -12, 0, 88, -6, 18, 94, Palette.stoneLight, M.Limestone)
	box(m, "PillarE", 6, 0, 88, 12, 18, 94, Palette.stoneLight, M.Limestone)
	box(m, "Arch", -12, 14, 88, 12, 20, 94, Palette.stoneLight, M.Limestone)
	for i, y in { 15, 17, 19 } do
		box(m, "ArchBand" .. i, -12, y, 87.8, 12, y + 0.8, 94.2, Palette.basalt, M.Basalt)
	end
	box(m, "Keystone", -1, 13, 87.6, 1, 15.5, 88, Palette.tile, M.CeramicTiles)
	-- Closed outer doors stand open against the pillars
	box(m, "DoorW", -6, 0, 86, -5.4, 13, 92, Palette.wood, M.WoodPlanks)
	box(m, "DoorE", 5.4, 0, 86, 6, 13, 92, Palette.wood, M.WoodPlanks)
	-- Back wall beyond the gate (map edge)
	box(m, "OuterWall", -30, 0, 96, 30, 20, 98, Palette.stoneWarm, M.Limestone)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "GateSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.4, 6)
	spawn.CFrame = CFrame.new(0, 0.2, 80) -- default look vector is -Z: into the lane
	spawn.Color = Palette.stoneWarm
	spawn.Material = M.Cobblestone
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = m
end

local function buildLane(map: Instance)
	local m = model(map, "Lane")
	-- West side (x < -8)
	building(m, "WestA", -24, 70, -8, 88, 22, "X", 1, { jetty = true })
	building(m, "WestB", -24, 24, -8, 50, 21, "X", 1, { jetty = true })
	-- East side (x > 8)
	building(m, "EastA", 8, 64, 24, 88, 21, "X", -1, { jetty = true })
	building(m, "EastB", 8, 24, 24, 48, 22, "X", -1)
	-- Lanterns along the lane
	lantern(m, Vector3.new(-7.2, 11, 78))
	lantern(m, Vector3.new(7.2, 11, 40))
	-- Vines over the lane
	for i, z in { 32, 44, 76 } do
		box(m, "VineBeam" .. i, -8, 19, z - 0.4, 8, 19.6, z + 0.4, Palette.wood, M.Wood)
		box(m, "Vine" .. i, -7, 18.4, z - 1.5, 7, 19, z + 1.5, Palette.vine, M.Grass).CanCollide = false
	end
end

local function buildBakery(map: Instance)
	local m = model(map, "Bakery")
	box(m, "Back", -24, 0, 50, -16, 22, 70, Palette.stoneLight, M.Limestone)
	box(m, "WallN", -16, 0, 69, -8, 22, 70, Palette.stoneLight, M.Limestone)
	box(m, "WallS", -16, 0, 50, -8, 22, 51, Palette.stoneLight, M.Limestone)
	box(m, "Roof", -16, 12, 50, -8, 22, 70, Palette.plaster, M.Plaster)
	box(m, "Parapet", -24, 22, 50, -8, 23.5, 70, Palette.stoneWarm, M.Limestone)
	-- Counter facing the lane
	box(m, "Counter", -9.5, 0, 53, -8, 3.4, 67, Palette.woodDark, M.Wood)
	box(m, "CounterTop", -9.8, 3.4, 52.8, -7.6, 3.8, 67.2, Palette.stoneWarm, M.Marble)
	-- Bread on the counter
	for i = 0, 4 do
		part(m, { name = "Kaak", size = Vector3.new(0.35, 1.4, 1.4), cf = CFrame.new(-8.8, 4, 55 + i * 2.6) * CYL_UP, color = Palette.copper, material = M.Sand, shape = Enum.PartType.Cylinder, collide = false })
	end
	-- Domed oven with glow
	local oven = part(m, { name = "Oven", size = Vector3.new(9, 9, 9), cf = CFrame.new(-17, 2, 60), color = Palette.stoneWarm, material = M.Brick, shape = Enum.PartType.Ball })
	box(m, "OvenMouth", -12.8, 1.2, 58.5, -12.4, 3.6, 61.5, Color3.fromRGB(255, 120, 40), M.Neon)
	local fire = Instance.new("PointLight")
	fire.Color = Color3.fromRGB(255, 140, 60)
	fire.Range = 12
	fire.Brightness = 1.5
	fire.Parent = oven
	-- Awning
	local awning = part(m, { name = "Awning", size = Vector3.new(5, 0.3, 20), cf = CFrame.new(-6, 11, 60) * CFrame.Angles(0, 0, math.rad(-18)), color = Palette.fabricIndigo, material = M.Fabric })
	awning.CastShadow = true
end

local function buildTailor(map: Instance)
	local m = model(map, "Tailor")
	box(m, "Back", 16, 0, 48, 24, 21, 64, Palette.stoneLight, M.Limestone)
	box(m, "Roof", 8, 12, 48, 16, 21, 64, Palette.plaster, M.Plaster)
	box(m, "WallN", 8, 0, 63, 16, 12, 64, Palette.stoneLight, M.Limestone)
	box(m, "WallS", 8, 0, 48, 16, 12, 49, Palette.stoneLight, M.Limestone)
	box(m, "Table", 13, 0, 51, 15.5, 3, 61, Palette.wood, M.WoodPlanks)
	-- Bolts of cloth
	local colors = { Palette.fabricRed, Palette.fabricIndigo, Palette.jasmine, Palette.tile, Palette.copper }
	for i, c in colors do
		part(m, { name = "Bolt", size = Vector3.new(2.4, 0.9, 0.9), cf = CFrame.new(14.2, 3.45, 51.5 + i * 1.6) * CFrame.Angles(0, math.rad(90), 0), color = c, material = M.Fabric, shape = Enum.PartType.Cylinder, collide = false })
	end
	-- Mannequin showing the tarboosh
	part(m, { name = "Stand", size = Vector3.new(4, 0.4, 0.4), cf = CFrame.new(10, 2, 62) * CYL_UP, color = Palette.woodDark, material = M.Wood, shape = Enum.PartType.Cylinder })
	part(m, { name = "Form", size = Vector3.new(1.8, 2.2, 1.2), cf = CFrame.new(10, 5, 62), color = Palette.plaster, material = M.Fabric })
	part(m, { name = "Head", size = Vector3.new(1.1, 1.1, 1.1), cf = CFrame.new(10, 6.7, 62), color = Palette.stoneWarm, material = M.Wood, shape = Enum.PartType.Ball })
	part(m, { name = "Tarboosh", size = Vector3.new(0.8, 1, 1), cf = CFrame.new(10, 7.5, 62) * CYL_UP, color = Palette.fabricRed, material = M.Fabric, shape = Enum.PartType.Cylinder })
	part(m, { name = "Awning", size = Vector3.new(5, 0.3, 16), cf = CFrame.new(6, 11, 56) * CFrame.Angles(0, 0, math.rad(18)), color = Palette.fabricRed, material = M.Fabric })
end

local function buildSquare(map: Instance)
	local m = model(map, "FountainSquare")
	-- Surrounding façades
	building(m, "SquareNW", -40, 0, -24, 24, 20, "X", 1)
	building(m, "SquareNE", 24, 0, 40, 24, 20, "X", -1)
	building(m, "SquareSW", -40, -26, -24, 0, 21, "X", 1, { door = false })
	building(m, "SquareSE", 24, -26, 40, 0, 21, "X", -1, { door = false })
	building(m, "SouthW", -40, -42, -16, -26, 20, "Z", 1)
	building(m, "SouthE", 16, -42, 40, -26, 20, "Z", 1)
	box(m, "CornerNW", -24, 0, 24, -8, 20, 26, Palette.stoneLight, M.Limestone)
	box(m, "CornerNE", 8, 0, 24, 24, 20, 26, Palette.stoneLight, M.Limestone)

	-- Fountain
	local f = model(m, "Fountain")
	part(f, { name = "Rim", size = Vector3.new(2.2, 16, 16), cf = CFrame.new(0, 1.1, 0) * CYL_UP, color = Palette.basalt, material = M.Basalt, shape = Enum.PartType.Cylinder })
	part(f, { name = "Tiles", size = Vector3.new(0.4, 16.4, 16.4), cf = CFrame.new(0, 1.6, 0) * CYL_UP, color = Palette.tile, material = M.CeramicTiles, shape = Enum.PartType.Cylinder, collide = false })
	part(f, { name = "Water", size = Vector3.new(0.3, 14.6, 14.6), cf = CFrame.new(0, 2.05, 0) * CYL_UP, color = Palette.water, material = M.Glass, shape = Enum.PartType.Cylinder, collide = false, transparency = 0.25 })
	part(f, { name = "Column", size = Vector3.new(5, 1.6, 1.6), cf = CFrame.new(0, 4, 0) * CYL_UP, color = Palette.stoneLight, material = M.Marble, shape = Enum.PartType.Cylinder })
	part(f, { name = "Bowl", size = Vector3.new(0.8, 5, 5), cf = CFrame.new(0, 6.6, 0) * CYL_UP, color = Palette.stoneLight, material = M.Marble, shape = Enum.PartType.Cylinder })
	part(f, { name = "Spout", size = Vector3.new(1.2, 1.2, 1.2), cf = CFrame.new(0, 7.4, 0), color = Palette.tile, material = M.CeramicTiles, shape = Enum.PartType.Ball })

	bench(m, CFrame.new(-14, 0, 8) * CFrame.Angles(0, math.rad(90), 0))
	bench(m, CFrame.new(14, 0, 8) * CFrame.Angles(0, math.rad(90), 0))
	bench(m, CFrame.new(-14, 0, -12) * CFrame.Angles(0, math.rad(90), 0))
	bench(m, CFrame.new(14, 0, -12) * CFrame.Angles(0, math.rad(90), 0))
	tree(m, Vector3.new(-19, 0, 18), Palette.copper)
	tree(m, Vector3.new(19, 0, 18), Palette.copper)
	tree(m, Vector3.new(-19, 0, -20), nil)
	tree(m, Vector3.new(19, 0, -20), nil)
	lantern(m, Vector3.new(-23.2, 11, 0))
	lantern(m, Vector3.new(23.2, 11, 0))
end

local function buildHouse(map: Instance)
	local m = model(map, "WardehHouse")
	-- Courtyard walls with an arched entrance at z = -26
	box(m, "FrontW", -16, 0, -28, -4, 14, -26, Palette.stoneLight, M.Limestone)
	box(m, "FrontE", 4, 0, -28, 16, 14, -26, Palette.stoneLight, M.Limestone)
	box(m, "Arch", -4, 10, -28, 4, 14, -26, Palette.stoneLight, M.Limestone)
	box(m, "ArchBand", -5, 10, -25.8, 5, 11, -25.6, Palette.basalt, M.Basalt)
	box(m, "WallW", -16, 0, -58, -14, 14, -28, Palette.stoneLight, M.Limestone)
	box(m, "WallE", 14, 0, -58, 16, 14, -28, Palette.stoneLight, M.Limestone)
	-- South range of rooms with a liwan (open arched hall) facing the courtyard
	box(m, "Rooms", -16, 0, -62, 16, 20, -50, Palette.plaster, M.Plaster)
	box(m, "LiwanBack", -5, 0, -50.4, 5, 11, -50, Palette.woodDark, M.Wood)
	box(m, "LiwanArch", -6, 11, -50.2, 6, 12, -49.8, Palette.basalt, M.Basalt)
	for i, x in { -12, 9 } do
		box(m, "Window" .. i, x, 13, -50.2, x + 3, 17, -49.8, Palette.woodDark, M.Wood)
	end
	box(m, "Parapet", -16, 20, -62, 16, 21.5, -50, Palette.stoneWarm, M.Limestone)
	-- Courtyard pool and jasmine
	box(m, "PoolRim", -4, 0, -45, 4, 1.2, -37, Palette.basalt, M.Basalt)
	box(m, "PoolWater", -3.4, 0.6, -44.4, 3.4, 1.1, -37.6, Palette.water, M.Glass).Transparency = 0.25
	tree(m, Vector3.new(-9, 0, -44), Palette.jasmine)
	tree(m, Vector3.new(9, 0, -33), Palette.jasmine)
	-- Floor cushions (diwan) in the liwan
	box(m, "Diwan", -4.5, 0, -50, 4.5, 1.4, -48, Palette.fabricRed, M.Fabric)
	lantern(m, Vector3.new(0, 9, -27))
end

local function buildBounds(map: Instance)
	local m = model(map, "Bounds")
	local function wall(x0: number, z0: number, x1: number, z1: number)
		local w = box(m, "Bound", x0, 0, z0, x1, 40, z1, Palette.plaster, M.SmoothPlastic)
		w.Transparency = 1
		w.CanQuery = false
		w.CastShadow = false
	end
	-- Buildings already enclose the play space; these close the small gaps beside the gate,
	-- where the lane floor is wider than the buildings.
	wall(-9, 88, -8, 96)
	wall(8, 88, 9, 96)
end

function WorldService.build()
	if Workspace:FindFirstChild("Map") then
		return
	end
	local map = Instance.new("Model")
	map.Name = "Map"
	buildGround(map)
	buildGate(map)
	buildLane(map)
	buildBakery(map)
	buildTailor(map)
	buildSquare(map)
	buildHouse(map)
	buildBounds(map)
	map.Parent = Workspace

	-- Remove the template's baseplate and spawn so players only spawn at the gate.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	for _, child in Workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
end

return WorldService
