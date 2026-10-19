--!strict
-- The road to the orchards outside the gate (LOOK_AND_PLAY_PLAN §4.1, LP-D06). The gate's outer wall
-- opens (Zones/Lane) onto a packed-earth road (x -6..6) that runs north to a vista wall where the
-- rival lane's gate stands (the kit's gate_rival). East of the road, olive and apricot orchards behind
-- low walls, with a well; west of it, the post's yard (Zones/Post), then a strip where a donkey cart
-- of pickles waits by the wall and an old olive hides a rifle in its hollow (a tease). Built into
-- `Zone_orchard_road` by WorldService when Config/LaneZones marks it built, together with the post.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local KitLayout = require(World.KitLayout)

local M = Kit.M

local OrchardRoad = {}

local WALL_H = 16
local EARTH = Color3.fromHex("#CDB892")
local GRASS = Color3.fromHex("#8A9A4E")
local APRICOT = Color3.fromHex("#F2A33A")
local PICKLE = Color3.fromHex("#7BAF3A")

local function deco(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

local function shell(m: Model)
	-- Ground: orchard grass either side of a packed-earth road with a cobbled crown
	Kit.box(m, "Ground", -16, -1, 98, 42, 0, 152, GRASS, M.Grass)
	Kit.box(m, "Road", -6, -0.98, 96, 6, 0.02, 152, EARTH, M.Ground)
	deco(Kit.box(m, "RoadCrown", -1.5, 0.02, 98, 1.5, 0.06, 150, Palette.stoneWarm, M.Cobblestone))
	-- Enclosure: the gate's outer wall is the south side east of x 30 too; the vista wall closes the north
	Kit.box(m, "WallS", 30, 0, 96, 44, WALL_H, 98, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "WallE", 42, 0, 96, 44, WALL_H, 154, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "WallW", -16, 0, 124, -14, WALL_H, 152, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "VistaWall", -16, 0, 152, 44, WALL_H + 4, 154, Palette.stoneLight, M.Limestone)
	-- The rival lane's gate on the vista wall, at the road's end
	KitLayout.place(m, "gate_rival", CFrame.new(0, 0, 151.4))
	Props.lantern(m, Kit.faceFrame(Vector3.new(9, 9.6, 152), Vector3.new(0, 0, -1)), 18)
end

local function orchards(m: Model)
	-- Low orchard walls along the east side of the road, with a gap at the well's path
	for _, z in { 101, 109.4, 131.8, 140.2 } do
		KitLayout.place(m, "orchard_wall_low", CFrame.new(7.4, 0, z) * CFrame.Angles(0, math.rad(90), 0))
	end
	for _, x in { 12, 20.4, 28.8, 37.2 } do
		KitLayout.place(m, "orchard_wall_low", CFrame.new(x, 0, 120.4))
	end
	-- Olive trees (kit) and apricots (primitive) in two plots
	local olives = {
		{ kind = "olive_tree_a", x = 14, z = 106 },
		{ kind = "olive_tree_b", x = 26, z = 104 },
		{ kind = "olive_tree_c", x = 36, z = 112 },
		{ kind = "olive_tree_a", x = 16, z = 140 },
		{ kind = "olive_tree_c", x = 30, z = 144 },
	}
	for i, o in olives do
		KitLayout.place(m, o.kind, CFrame.new(o.x, 0, o.z) * CFrame.Angles(0, math.rad(i * 67), 0))
	end
	for _, p in { { 24, 130 }, { 36, 132 }, { 22, 114 } } do
		Props.tree(m, Vector3.new(p[1], 0, p[2]), APRICOT, 0.9)
	end
	KitLayout.place(m, "well", CFrame.new(13, 0, 127))
	KitLayout.place(m, "harvest_net", CFrame.new(30, 0.02, 141))
	Props.lantern(m, Kit.faceFrame(Vector3.new(42, 8.4, 127), Vector3.new(-1, 0, 0)), 16)
end

local function westStrip(m: Model)
	-- The donkey cart of pickles by the wall: a bed on two wheels, jars and a crate of green pickles
	local x, z = -11, 134
	Kit.box(m, "CartBed", x - 1.4, 1.5, z - 2.4, x + 1.4, 2, z + 2.4, Palette.wood, M.WoodPlanks)
	for _, dx in { -1.6, 1.6 } do
		Kit.part(m, { name = "Wheel", size = Vector3.new(0.3, 2.4, 2.4), cf = CFrame.new(x + dx, 1.2, z), color = Palette.woodDark, material = M.Wood, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
	end
	for _, dx in { -0.9, 0.9 } do
		deco(Kit.part(m, { name = "Shaft", size = Vector3.new(0.2, 0.2, 3.4), cf = CFrame.new(x + dx, 1.6, z - 3.9) * CFrame.Angles(math.rad(-8), 0, 0), color = Palette.woodDark, material = M.Wood }))
	end
	for i = 0, 3 do
		Kit.column(m, "PickleJar", Vector3.new(x - 0.6 + (i % 2) * 1.2, 2, z - 1.4 + math.floor(i / 2) * 1.4), 1.2, 0.9, Color3.fromHex("#B9D4C2"), M.Glass, false)
		Kit.ball(m, "Pickles", Vector3.new(x - 0.6 + (i % 2) * 1.2, 2.5, z - 1.4 + math.floor(i / 2) * 1.4), 0.6, PICKLE, M.SmoothPlastic, false)
	end
	Props.crate(m, CFrame.new(x, 2, z + 1.4) * CFrame.Angles(0, math.rad(90), 0), PICKLE)
	KitLayout.place(m, "oil_jar_cluster", CFrame.new(-12.4, 0, 129.5) * CFrame.Angles(0, math.rad(90), 0))

	-- The old olive by the vista wall, with a rifle leaning in its hollow
	KitLayout.place(m, "olive_tree_b", CFrame.new(-11, 0, 145) * CFrame.Angles(0, math.rad(200), 0))
	deco(Kit.box(m, "Hollow", -10.3, 1, 144.2, -9.9, 3.4, 145.4, Palette.ink, M.SmoothPlastic))
	deco(Kit.part(m, { name = "RifleStock", size = Vector3.new(0.25, 1.4, 0.4), cf = CFrame.new(-9.7, 1.1, 144.8) * CFrame.Angles(0, 0, math.rad(-12)), color = Palette.woodDark, material = M.Wood }))
	deco(Kit.part(m, { name = "RifleBarrel", size = Vector3.new(0.14, 2.4, 0.14), cf = CFrame.new(-9.95, 2.9, 144.8) * CFrame.Angles(0, 0, math.rad(-12)), color = Palette.ink, material = M.Metal }))
end

function OrchardRoad.build(zone: Model)
	shell(zone)
	orchards(zone)
	westStrip(zone)
end

return OrchardRoad
