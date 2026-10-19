--!strict
-- The mosque court (LOOK_AND_PLAY_PLAN §4.1, LP-D05), exterior only: an arch in SquareNE's face just
-- north of the Event arch (z 16..21; the block is 6 deep there, x 24..30) opens into the courtyard
-- (x 30..48, z -2..24): the ablution fountain with its stools, a fig tree, a bench, and the mosque's
-- closed wooden door under a canopy in the east wall. The minaret stands in the north-east corner
-- (moved here from the skyline). The sheikh sits by the door once his model ships (LP-D08). Built
-- into `Zone_mosque_court` by WorldService when Config/LaneZones marks it built.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local MosqueCourt = {}

local WALL_H = 14
local GATE = { z0 = 16, z1 = 21 } -- the passage through SquareNE
local EAST = 48 -- the mosque wall (its inner face)
local FIG = Color3.fromHex("#5B2A55")

local function deco(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

local function gate(m: Model)
	local z0, z1 = GATE.z0, GATE.z1
	Kit.box(m, "GateFloor", 24, -1, z0, 30, 0, z1, Palette.stoneWarm, M.Pavement)
	Kit.box(m, "GateOver", 24, 9, z0, 30, 21, z1, Palette.stoneLight, M.Limestone)
	Kit.box(m, "GateParapet", 24, 21, z0, 30, 22.2, z1, Palette.stoneWarm, M.Limestone)
	local n = 7
	local w = (z1 - z0 + 1.2) / n
	for i = 1, n do
		local z = z0 - 0.6 + (i - 0.5) * w
		local lift = (1 - math.abs(z - (z0 + z1) / 2) / ((z1 - z0) / 2 + 0.6)) * 1.2
		local dark = i % 2 == 0
		deco(Kit.box(m, "Voussoir", 23.6, 8.2, z - w / 2, 24, 9.2 + lift, z + w / 2, if dark then Palette.basalt else Palette.stoneWarm, if dark then M.Basalt else M.Limestone))
	end
end

local function court(m: Model)
	Kit.box(m, "Floor", 30, -1, -2, EAST, 0, 24, Palette.stoneLight, M.Pavement)
	Kit.box(m, "WallN", 24, 0, 24, EAST + 2, WALL_H, 26, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallE", EAST, 0, -2, EAST + 2, WALL_H, 24, Palette.stoneLight, M.Limestone)
	for _, y in { 4, 8 } do
		deco(Kit.box(m, "BandN", 30, y, 23.9, 42, y + 0.6, 24, Palette.basalt, M.Basalt))
	end

	-- The ablution fountain: a round basin, a central pillar with taps, stools around it
	local c = Vector3.new(38, 0, 9)
	Kit.column(m, "Basin", c, 0.9, 6, Palette.stoneWarm, M.Limestone, true)
	deco(Kit.disc(m, "Water", c + Vector3.new(0, 0.86, 0), 5.2, 0.06, Palette.water, M.Glass))
	Kit.column(m, "Pillar", c, 2.8, 1.2, Palette.stoneLight, M.Limestone, true)
	Kit.column(m, "PillarCap", c + Vector3.new(0, 2.8, 0), 0.3, 1.6, Palette.basalt, M.Basalt, false)
	for k = 0, 7 do
		local a = k * math.pi / 4
		deco(Kit.part(m, { name = "Tap", size = Vector3.new(0.6, 0.18, 0.18), cf = CFrame.new(c + Vector3.new(math.cos(a) * 0.8, 2.1, math.sin(a) * 0.8)) * CFrame.Angles(0, -a, 0), color = Palette.copper, material = M.Metal }))
	end
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		Props2.stool(m, c + Vector3.new(math.cos(a) * 4.2, 0, math.sin(a) * 4.2))
	end

	Props.tree(m, Vector3.new(33.5, 0, 1.8), FIG, 1)
	Props.bench(m, CFrame.new(40, 0, -0.4))
	Props.pot(m, Vector3.new(31, 0.35, 22.6), "jasmine", 1.1)
	Props.lantern(m, Kit.faceFrame(Vector3.new(30, 8.4, 14.6), Vector3.new(1, 0, 0)), 16)
end

local function mosqueFront(m: Model)
	local f = Kit.faceFrame(Vector3.new(EAST, 0, 9), Vector3.new(-1, 0, 0))
	Props.door(m, f, 4.4, 8, Palette.woodDark)
	-- The canopy over the door on two brackets
	deco(Kit.box(m, "Canopy", EAST - 1.6, 10, 5.4, EAST, 10.4, 12.6, Palette.wood, M.WoodPlanks))
	for _, z in { 5.8, 12.2 } do
		deco(Kit.box(m, "Bracket", EAST - 1.2, 9, z - 0.2, EAST, 10, z + 0.2, Palette.woodDark, M.Wood))
	end
	deco(Kit.box(m, "Inscription", EAST - 0.1, 11.2, 1, EAST, 12.2, 17, Palette.tile, M.CeramicTiles))
	for _, z in { 2.8, 15.2 } do
		Props.window(m, Kit.faceFrame(Vector3.new(EAST, 6.4, z), Vector3.new(-1, 0, 0)), 1.8, 3)
	end
	for _, y in { 3, 6 } do
		deco(Kit.box(m, "Band", EAST - 0.1, y, -2, EAST, y + 0.6, 1, Palette.basalt, M.Basalt))
		deco(Kit.box(m, "Band", EAST - 0.1, y, 17, EAST, y + 0.6, 18, Palette.basalt, M.Basalt))
	end
	Props.lantern(m, Kit.faceFrame(Vector3.new(EAST - 1.6, 9.4, 9), Vector3.new(-1, 0, 0)), 16)
end

-- The minaret in the north-east corner (it used to stand in the skyline at -48, -92)
local function minaret(m: Model)
	local base = Vector3.new(45, 0, 21)
	Kit.box(m, "MinaretBase", 42, 0, 18, EAST, WALL_H + 2, 24, Palette.stoneLight, M.Limestone)
	deco(Kit.box(m, "MinaretBaseBand", 41.9, 10, 18, 42, 10.6, 24, Palette.basalt, M.Basalt))
	local top = WALL_H + 2
	Kit.column(m, "MinaretShaft", base + Vector3.new(0, top, 0), 18, 4.6, Palette.stoneLight, M.Limestone, false)
	for _, y in { top + 5, top + 11 } do
		Kit.column(m, "MinaretBand", base + Vector3.new(0, y, 0), 0.9, 4.9, Palette.basalt, M.Basalt, false)
	end
	Kit.column(m, "Balcony", base + Vector3.new(0, top + 15, 0), 1, 6.6, Palette.stoneWarm, M.Limestone, false)
	Kit.column(m, "UpperShaft", base + Vector3.new(0, top + 18, 0), 5, 3.2, Palette.stoneLight, M.Limestone, false)
	Kit.ball(m, "Cap", base + Vector3.new(0, top + 23.6, 0), 3.6, Color3.fromHex("#5E7D3A"), M.Slate, false)
	Kit.column(m, "Spire", base + Vector3.new(0, top + 25, 0), 2.6, 0.4, Palette.copper, M.Metal, false)
end

function MosqueCourt.build(zone: Model)
	gate(zone)
	court(zone)
	mosqueFront(zone)
	minaret(zone)
end

return MosqueCourt
