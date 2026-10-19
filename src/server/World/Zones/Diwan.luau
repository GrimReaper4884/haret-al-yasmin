--!strict
-- The diwan (LOOK_AND_PLAY_PLAN §4.1, LP-D05): the za'im's house behind the square's south-east block.
-- An ablaq portal in SquareSE's face (z -16..-11; the block is 6 deep there, x 24..30) opens into a
-- paved court (x 30..52, z -26..-4) with a pool and two citrus trees; on its east side the liwan,
-- an open arched hall with cushions round three walls where the za'im holds his sitting. The dispute
-- beat of LP §4.3 plays in front of the liwan (LP-D10). Built into `Zone_diwan` by WorldService when
-- Config/LaneZones marks it built (Zones/Square then makes SquareSE shallow and opens the portal).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Strings = require(Shared.Config.Strings)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)
local KitLayout = require(World.KitLayout)

local M = Kit.M

local Diwan = {}

local WALL_H = 14
local PORTAL = { z0 = -16, z1 = -11 } -- the passage through SquareSE
local LIWAN = { x0 = 46, x1 = 52, z0 = -22, z1 = -8 } -- the open hall on the court's east side
local CUSHION = Color3.fromHex("#7A1E1A")

local function ar(key: string): string
	return Strings.ar[key] or key
end

local function deco(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- Alternating pale and dark voussoirs over an opening along Z at x = `x`, springing at `y`.
local function arch(m: Model, x: number, y: number, z0: number, z1: number, n: number, rise: number, out: number)
	local w = (z1 - z0) / n
	local mid = (z0 + z1) / 2
	for i = 1, n do
		local z = z0 + (i - 0.5) * w
		local lift = (1 - math.abs(z - mid) / ((z1 - z0) / 2)) * rise
		local dark = i % 2 == 0
		deco(Kit.box(m, "Voussoir", x, y, z - w / 2, x + out, y + 1 + lift, z + w / 2, if dark then Palette.basalt else Palette.stoneWarm, if dark then M.Basalt else M.Limestone))
	end
end

local function portal(m: Model)
	local z0, z1 = PORTAL.z0, PORTAL.z1
	Kit.box(m, "PortalFloor", 24, -1, z0, 30, 0, z1, Palette.basalt, M.Basalt)
	Kit.box(m, "PortalOver", 24, 10, z0, 30, 20, z1, Palette.stoneLight, M.Limestone)
	Kit.box(m, "PortalParapet", 24, 20, z0, 30, 21.2, z1, Palette.stoneWarm, M.Limestone)
	-- The square-side frame: a tall ablaq arch, a carved panel over it and stone benches (mastaba)
	arch(m, 23.6, 9, z0 - 0.8, z1 + 0.8, 9, 1.6, 0.4)
	for _, z in { z0 - 0.8, z1 } do
		Kit.box(m, "Jamb", 23.5, 0, z, 24, 9, z + 0.8, Palette.stoneWarm, M.Limestone)
	end
	for _, y in { 2, 4, 6, 8 } do
		deco(Kit.box(m, "JambBand", 23.45, y, z0 - 0.85, 24, y + 0.5, z0 - 0.75, Palette.basalt, M.Basalt))
		deco(Kit.box(m, "JambBand", 23.45, y, z1 + 0.75, 24, y + 0.5, z1 + 0.85, Palette.basalt, M.Basalt))
	end
	deco(Kit.box(m, "Panel", 23.8, 12, z0 - 0.4, 24, 14.6, z1 + 0.4, Palette.stoneWarm, M.Limestone))
	deco(Kit.box(m, "PanelInlay", 23.7, 12.4, z0 + 0.2, 23.8, 14.2, z1 - 0.2, Palette.tile, M.CeramicTiles))
	for _, z in { z0 - 2.6, z1 + 0.6 } do
		Kit.box(m, "Mastaba", 21.8, 0, z, 24, 1.4, z + 2, Palette.stoneLight, M.Limestone)
	end
	-- Both door leaves stand open against the passage walls
	for _, z in { z0 + 0.15, z1 - 0.45 } do
		Kit.box(m, "Leaf", 24.4, 0, z, 26.8, 8.6, z + 0.3, Palette.woodDark, M.WoodPlanks)
		deco(Kit.box(m, "LeafBand", 24.35, 2, z - 0.05, 26.85, 2.25, z + 0.35, Palette.ink, M.Metal))
		deco(Kit.box(m, "LeafBand", 24.35, 6, z - 0.05, 26.85, 6.25, z + 0.35, Palette.ink, M.Metal))
	end
	Props2.sign(m, Kit.faceFrame(Vector3.new(23.6, 15.9, (z0 + z1) / 2), Vector3.new(-1, 0, 0)), 6, ar("sign.diwan"), "Diwan al-Za'im", Palette.woodDark)
end

local function court(m: Model)
	-- Ablaq paving: pale stone with dark bands across the court
	Kit.box(m, "Floor", 30, -1, -26, 52, 0, -4, Palette.stoneLight, M.Pavement)
	for z = -24, -6, 3 do
		deco(Kit.box(m, "FloorBand", 30, 0, z, LIWAN.x0, 0.04, z + 0.6, Palette.basalt, M.Basalt))
	end
	Kit.box(m, "WallS", 30, 0, -28, 54, WALL_H, -26, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallE", 52, 0, -28, 54, WALL_H, -2, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallN", 30, 0, -4, 54, WALL_H, -2, Palette.stoneLight, M.Limestone) -- the mosque court is behind it
	for _, y in { 3, 6, 9 } do
		deco(Kit.box(m, "BandS", 30, y, -26, LIWAN.x0, y + 0.6, -25.9, Palette.basalt, M.Basalt))
		deco(Kit.box(m, "BandN", 30, y, -4.1, LIWAN.x0, y + 0.6, -4, Palette.basalt, M.Basalt))
	end
	KitLayout.place(m, "mashrabiya_bay", CFrame.new(38, 3.2, -4))

	-- The pool with a jet, and two citrus trees
	Kit.box(m, "PoolRim", 35, 0, -18, 41, 1, -12, Palette.stoneWarm, M.Limestone)
	deco(Kit.box(m, "PoolWater", 35.5, 0.6, -17.5, 40.5, 0.9, -12.5, Palette.water, M.Glass))
	Kit.column(m, "Jet", Vector3.new(38, 0.9, -15), 1.4, 0.4, Palette.copper, M.Metal, false)
	Props.tree(m, Vector3.new(33, 0, -22.5), Color3.fromHex("#E8892B"), 0.8)
	Props.tree(m, Vector3.new(33, 0, -7.5), Color3.fromHex("#E8C12B"), 0.8)
	Props.pot(m, Vector3.new(44.6, 0.35, -23.6), "jasmine", 1.2)
	Props.pot(m, Vector3.new(44.6, 0.35, -6.4), "jasmine", 1.2)
	Props.lantern(m, Kit.faceFrame(Vector3.new(38, 9.2, -26), Vector3.new(0, 0, 1)), 18)
end

local function liwan(m: Model)
	local x0, x1, z0, z1 = LIWAN.x0, LIWAN.x1, LIWAN.z0, LIWAN.z1
	-- Side walls and the masses above the arch; the back is the court's east wall
	Kit.box(m, "LiwanSideS", x0, 0, -26, x1, WALL_H, z0, Palette.stoneLight, M.Limestone)
	Kit.box(m, "LiwanSideN", x0, 0, z1, x1, WALL_H, -4, Palette.stoneLight, M.Limestone)
	Kit.box(m, "LiwanOver", x0, 11, z0, x1, WALL_H, z1, Palette.stoneLight, M.Limestone)
	Kit.box(m, "LiwanBack", x1 - 0.4, 0, z0, x1, 11, z1, Color3.fromHex("#3A2A1E"), M.Wood)
	arch(m, x0 - 0.4, 10, z0, z1, 11, 1.4, 0.4)
	deco(Kit.box(m, "LiwanStep", x0 - 0.6, 0, z0, x0 + 0.4, 0.4, z1, Palette.basalt, M.Basalt))
	Kit.box(m, "LiwanFloor", x0, 0, z0, x1, 0.4, z1, Palette.stoneWarm, M.Limestone)
	-- Cushioned benches (dikkeh) on three sides, the za'im's place in the middle of the back
	Kit.box(m, "DiwanBack", x1 - 1.8, 0.4, z0 + 0.4, x1 - 0.4, 1.2, z1 - 0.4, Palette.fabricRed, M.Fabric)
	deco(Kit.box(m, "DiwanBackRest", x1 - 0.8, 1.2, z0 + 0.4, x1 - 0.4, 2.6, z1 - 0.4, CUSHION, M.Fabric))
	for _, z in { z0 + 0.4, z1 - 1.8 } do
		Kit.box(m, "DiwanSide", x0 + 0.6, 0.4, z, x1 - 1.8, 1.2, z + 1.4, Palette.fabricRed, M.Fabric)
	end
	-- The za'im's low table with a coffee pot and cups, a brazier
	Kit.box(m, "LowTable", x1 - 4.2, 0.4, -16.2, x1 - 2.6, 1.2, -13.8, Palette.woodDark, M.Wood)
	Props.copperPot(m, Vector3.new(x1 - 3.4, 1.2, -15.4), 0.7)
	for _, z in { -14.6, -14.1 } do
		Kit.column(m, "Cup", Vector3.new(x1 - 3.1, 1.2, z), 0.3, 0.25, Palette.jasmine, M.SmoothPlastic, false)
	end
	Kit.column(m, "Brazier", Vector3.new(x0 + 1.4, 0.4, -11.4), 0.9, 1.4, Palette.copper, M.Metal, false)
	deco(Kit.disc(m, "Embers", Vector3.new(x0 + 1.4, 1.32, -11.4), 1.1, 0.06, Color3.fromHex("#E2552B"), M.Neon))
	Props.lantern(m, Kit.faceFrame(Vector3.new(x1 - 0.4, 8.8, -15), Vector3.new(-1, 0, 0)), 16)
	-- A rug on the liwan floor
	deco(Kit.box(m, "Rug", x0 + 0.8, 0.4, z0 + 2.2, x1 - 2.2, 0.45, z1 - 2.2, Palette.fabricIndigo, M.Fabric))
	deco(Kit.box(m, "RugField", x0 + 1.2, 0.45, z0 + 2.6, x1 - 2.6, 0.48, z1 - 2.6, Palette.fabricRed, M.Fabric))
end

function Diwan.build(zone: Model)
	portal(zone)
	court(zone)
	liwan(zone)
end

return Diwan
