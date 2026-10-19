--!strict
-- The hammam (LOOK_AND_PLAY_PLAN §4.1, LP-D04): behind the square's north-west block. A low vaulted
-- passage under the south end of WestB (x -24..-8, z 27..32, beneath the sabat) leads west from the
-- lane into an open court (x -60..-24, z 26..38). The bath-house front faces the court from the south:
-- banded stone, a curtained arch, a dome with bottle-glass oculi and a steaming roof vent (LobbyLife
-- `hammamSteam`). Towels dry on a line and on the bench, copper bowls and clogs wait by the door, a
-- small basin trickles. Abu Basim keeps the door. Built into `Zone_hammam` by WorldService when
-- Config/LaneZones marks it built (Zones/Lane then shortens WestB to make room for the passage).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Strings = require(Shared.Config.Strings)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local Hammam = {}

local H = 16 -- the bath-house front
local WALL_H = 14 -- the court's walls
local FRONT = 26 -- z of the bath-house front (faces +Z, into the court)
local DOOR_X = -51 -- centre of the entrance arch
local HALF = 2.5 -- half the entrance width
local OCULUS = Color3.fromHex("#CFE8C8")

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

local function passage(m: Model)
	Kit.box(m, "PassageFloor", -24, -1, 27, -8, 0, 32, Palette.stoneWarm, M.Pavement)
	-- WestB's upper floors run over the passage; the sabat's springers frame its mouth from the lane
	Kit.box(m, "PassageOver", -24, 9, 27, -8, 21, 32, Palette.plaster, M.Plaster)
	Kit.box(m, "PassageParapet", -24, 21, 27, -8, 22.2, 32, Palette.stoneWarm, M.Limestone)
	for _, x in { -21, -17, -13 } do
		deco(Kit.box(m, "Beam", x - 0.3, 8.5, 27, x + 0.3, 9, 32, Palette.woodDark, M.Wood))
	end
	for i = 1, 5 do
		local z = 27 + (i - 0.5)
		local dark = i % 2 == 0
		deco(Kit.box(m, "Voussoir", -8.1, 8.2, z - 0.5, -7.7, 9.2, z + 0.5, if dark then Palette.basalt else Palette.stoneWarm, if dark then M.Basalt else M.Limestone))
	end
end

local function court(m: Model)
	Kit.box(m, "Floor", -62, -1, 24, -24, 0, 40, Palette.stoneLight, M.Pavement)
	deco(Kit.box(m, "Inlay", -24, 0, 28.9, DOOR_X + 0.6, 0.04, 30.1, Palette.basalt, M.Basalt)) -- from the passage…
	deco(Kit.box(m, "Inlay", DOOR_X - 0.6, 0, FRONT, DOOR_X + 0.6, 0.04, 30.1, Palette.basalt, M.Basalt)) -- …to the door
	Kit.box(m, "WallN", -62, 0, 38, -24, WALL_H, 40, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallW", -62, 0, 26, -60, WALL_H, 38, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallSE", -40, 0, 24, -24, WALL_H, 26, Palette.stoneLight, M.Limestone) -- behind SquareNW
	for _, y in { 4, 8 } do
		deco(Kit.box(m, "BandN", -60, y, 37.9, -24, y + 0.6, 38, Palette.basalt, M.Basalt))
	end

	-- A small basin trickling by the east wall
	Kit.column(m, "Basin", Vector3.new(-28.5, 0, 35), 1.1, 3.2, Palette.stoneWarm, M.Limestone, true)
	deco(Kit.disc(m, "Water", Vector3.new(-28.5, 1.06, 35), 2.6, 0.08, Palette.water, M.Glass))
	Kit.column(m, "Spout", Vector3.new(-28.5, 1.1, 35), 1.4, 0.35, Palette.copper, M.Metal, false)

	-- The bench against the north wall, with folded towels on it
	Props.bench(m, CFrame.new(-42, 0, 36.6))
	for i, c in { Palette.jasmine, Palette.tile, Palette.fabricRed } do
		deco(Kit.box(m, "Towel", -44.1 + i * 1.1, 1.8, 36.1, -43.3 + i * 1.1, 2.15, 37.1, c, M.Fabric))
	end
	-- Towels drying on a line along the west wall
	Props.laundry(m, Vector3.new(-58.6, 7.4, 27.6), Vector3.new(-58.4, 7.8, 37), { Palette.jasmine, Palette.tile, Palette.jasmine, Palette.fabricRed })
	Props.pot(m, Vector3.new(DOOR_X - 4.2, 0.35, FRONT + 0.9), "jasmine", 1)
	Props.pot(m, Vector3.new(DOOR_X + 4.2, 0.35, FRONT + 0.9), "jasmine", 1)
	Props.lantern(m, Kit.faceFrame(Vector3.new(-36, 8.6, 38), Vector3.new(0, 0, -1)), 16)
end

local function bathHouse(m: Model)
	-- Masses around the entrance (a 3-deep recess behind the arch)
	Kit.box(m, "Back", -62, 0, 2, -40, H, FRONT - 3, Palette.stoneLight, M.Limestone)
	Kit.box(m, "PierW", -62, 0, FRONT - 3, DOOR_X - HALF, H, FRONT, Palette.stoneLight, M.Limestone)
	Kit.box(m, "PierE", DOOR_X + HALF, 0, FRONT - 3, -40, H, FRONT, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Lintel", DOOR_X - HALF, 9, FRONT - 3, DOOR_X + HALF, H, FRONT, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Parapet", -62, H, 2, -40, H + 1, FRONT, Palette.stoneWarm, M.Limestone)
	-- Ablaq courses across the front
	for _, y in { 2.5, 5, 7.5, 12.5 } do
		deco(Kit.box(m, "Band", -60, y, FRONT, DOOR_X - HALF, y + 0.7, FRONT + 0.1, Palette.basalt, M.Basalt))
		deco(Kit.box(m, "Band", DOOR_X + HALF, y, FRONT, -40, y + 0.7, FRONT + 0.1, Palette.basalt, M.Basalt))
	end
	deco(Kit.box(m, "Band", DOOR_X - HALF, 12.5, FRONT, DOOR_X + HALF, 13.2, FRONT + 0.1, Palette.basalt, M.Basalt))
	-- Pointed arch of alternating voussoirs
	local n = 9
	local w = (2 * HALF + 1.2) / n
	for i = 1, n do
		local x = DOOR_X - HALF - 0.6 + (i - 0.5) * w
		local lift = (1 - math.abs(x - DOOR_X) / (HALF + 0.6)) * 1.6
		local dark = i % 2 == 0
		deco(Kit.box(m, "Voussoir", x - w / 2, 9, FRONT, x + w / 2, 10 + lift, FRONT + 0.4, if dark then Palette.basalt else Palette.stoneWarm, if dark then M.Basalt else M.Limestone))
	end
	-- The entrance curtain (three hangings) and the dim vestibule behind it
	deco(Kit.box(m, "Vestibule", DOOR_X - HALF, 0, FRONT - 3, DOOR_X + HALF, 9, FRONT - 2.9, Color3.fromHex("#3A2A1E"), M.Wood))
	for i, c in { Palette.fabricRed, Palette.jasmine, Palette.fabricRed } do
		local x0 = DOOR_X - HALF + (i - 1) * (2 * HALF / 3)
		deco(Kit.box(m, "Curtain", x0 + 0.05, 0.6, FRONT - 0.7, x0 + 2 * HALF / 3 - 0.05, 9, FRONT - 0.6, c, M.Fabric))
	end
	deco(Kit.box(m, "CurtainRod", DOOR_X - HALF, 8.9, FRONT - 0.75, DOOR_X + HALF, 9.1, FRONT - 0.55, Palette.copper, M.Metal))
	Props2.sign(m, Kit.faceFrame(Vector3.new(DOOR_X, 14.4, FRONT), Vector3.new(0, 0, 1)), 7, ar("sign.hammam"), "Hammam al-Hara", Palette.tile)
	Props.lantern(m, Kit.faceFrame(Vector3.new(DOOR_X + HALF + 1.6, 8.4, FRONT), Vector3.new(0, 0, 1)), 16)
	-- Clogs and a stack of copper bowls by the door
	for i = 0, 2 do
		for side = 0, 1 do
			local x = DOOR_X - HALF - 1.7 + side * 0.5
			deco(Kit.box(m, "Clog", x, 0, FRONT + 0.6 + i * 0.9, x + 0.35, 0.35, FRONT + 1.3 + i * 0.9, Palette.wood, M.Wood))
		end
	end
	Props.copperPot(m, Vector3.new(DOOR_X + HALF + 0.9, 0, FRONT + 1.2), 0.9)
	Props.copperPot(m, Vector3.new(DOOR_X + HALF + 0.9, 0.8, FRONT + 1.2), 0.7)

	-- The dome with its bottle-glass oculi, and the roof vent that steams
	local c = Vector3.new(DOOR_X, 15, 13)
	Kit.ball(m, "Dome", c, 12, Palette.stoneLight, M.Limestone, false)
	Kit.column(m, "Finial", c + Vector3.new(0, 5.8, 0), 1.6, 0.5, Palette.copper, M.Metal, false)
	for k = 0, 7 do
		local phi = k * math.pi / 4
		local e = math.rad(if k % 2 == 0 then 38 else 58)
		local p = c + Vector3.new(math.cos(e) * math.cos(phi), math.sin(e), math.cos(e) * math.sin(phi)) * 5.9
		deco(Kit.ball(m, "Oculus", p, 0.8, OCULUS, M.Glass))
	end
	Kit.column(m, "Vent", Vector3.new(-58, H, 6), 3.2, 1.4, Palette.stoneWarm, M.Limestone, false)
	Kit.column(m, "VentCap", Vector3.new(-58, H + 3.2, 6), 0.3, 2, Palette.basalt, M.Basalt, false)
end

function Hammam.build(zone: Model)
	passage(zone)
	court(zone)
	bathHouse(zone)
end

return Hammam
