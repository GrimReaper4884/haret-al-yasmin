--!strict
-- Ground, the Jasmine Gate and the lane (docs/WORLD_MAP.md). The lane runs along Z from the gate
-- (z ≈ 92) to the fountain square (z = 24). Signature elements of an old Damascus quarter:
-- a covered "sabat" room bridging the lane, latticed bays, a central gutter, stone kerbs,
-- vines and washing lines overhead.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local LaneZones = require(ReplicatedStorage:WaitForChild("Shared").Config.LaneZones)
local LaneZoneLogic = require(ReplicatedStorage:WaitForChild("Shared").Logic.LaneZoneLogic)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)
local Facade = require(World.Facade)

local M = Kit.M

local Lane = {}

local function ground(map: Instance)
	local g = Kit.model(map, "Ground")
	Kit.box(g, "Lane", -8, -1, 24, 8, 0, 96, Palette.stoneWarm, M.Cobblestone)
	-- Central gutter (basalt channel) and stone kerbs along the walls
	Kit.box(g, "Gutter", -0.6, -0.05, 24, 0.6, 0.03, 88, Palette.basalt, M.Slate).CastShadow = false
	for _, run in { { -8, -7.1, 24, 50 }, { -8, -7.1, 70, 86 }, { 7.1, 8, 24, 48 }, { 7.1, 8, 64, 86 } } do
		Kit.box(g, "Kerb", run[1], 0, run[3], run[2], 0.35, run[4], Palette.stoneLight, M.Limestone).CastShadow = false
	end
	Kit.box(g, "BakeryFloor", -22, -1, 50, -8, 0, 70, Palette.stoneLight, M.Limestone)
	Kit.box(g, "TailorFloor", 8, -1, 48, 20, 0, 64, Palette.stoneLight, M.Limestone)
	Kit.box(g, "Square", -24, -1, -26, 24, 0, 24, Palette.stoneLight, M.Pavement)
	Kit.box(g, "HouseFloor", -16, -1, -58, 16, 0, -26, Palette.stoneWarm, M.Limestone)
end

local function gate(map: Instance)
	local m = Kit.model(map, "JasmineGate")
	Kit.box(m, "PillarW", -12, 0, 88, -6, 18, 94, Palette.stoneLight, M.Limestone)
	Kit.box(m, "PillarE", 6, 0, 88, 12, 18, 94, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Arch", -12, 14, 88, 12, 20, 94, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Crown", -13, 20, 87.5, 13, 21.2, 94.5, Palette.stoneWarm, M.Limestone)
	-- Ablaq voussoirs over the opening (inner face) and bands on the pillars
	for i = 1, 9 do
		local x = -6 + (i - 0.5) * 12 / 9
		local lift = (1 - math.abs(x) / 6) * 1.2
		Kit.box(m, "Voussoir", x - 12 / 18, 12.6 + lift, 87.6, x + 12 / 18, 14 + lift, 88, if i % 2 == 0 then Palette.basalt else Palette.stoneLight, if i % 2 == 0 then M.Basalt else M.Limestone).CastShadow = false
	end
	for _, y in { 3, 6, 9 } do
		Kit.box(m, "BandW", -12, y, 87.8, -6, y + 0.8, 88, Palette.basalt, M.Basalt).CastShadow = false
		Kit.box(m, "BandE", 6, y, 87.8, 12, y + 0.8, 88, Palette.basalt, M.Basalt).CastShadow = false
	end
	Kit.box(m, "Keystone", -0.8, 13.6, 87.4, 0.8, 15.6, 87.8, Palette.tile, M.CeramicTiles)
	-- The heavy studded leaves stand open against the lane walls by day; the night bar leans by
	-- the east jamb (Props2.gate; the S1E1 thread clue sits by the west leaf).
	Props2.gate(m, Kit.faceFrame(Vector3.new(0, 0, 91), Vector3.new(0, 0, 1)), 12, 13, true)
	Kit.box(m, "OuterWall", -30, 0, 96, 30, 20, 98, Palette.stoneWarm, M.Limestone)
	Props.lantern(m, Kit.faceFrame(Vector3.new(-9, 11, 88), Vector3.new(0, 0, -1)))
	Props.lantern(m, Kit.faceFrame(Vector3.new(9, 11, 88), Vector3.new(0, 0, -1)))

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

-- Covered room bridging the lane (sabat), with an arch underneath and latticed windows.
local function sabat(m: Instance, z0: number, z1: number)
	local s = Kit.model(m, "Sabat")
	Kit.box(s, "Room", -8, 13.5, z0, 8, 21, z1, Palette.plaster, M.Plaster)
	Kit.box(s, "Parapet", -8, 21, z0, 8, 22.2, z1, Palette.stoneWarm, M.Limestone)
	Kit.box(s, "Beam", -8, 12.8, z0 - 0.2, 8, 13.5, z1 + 0.2, Palette.woodDark, M.Wood)
	-- Stepped arch springers on both sides (read as an arch from the street)
	for _, side in { -1, 1 } do
		local outer = side * 8
		Kit.box(s, "Springer", outer, 9.4, z0, outer - side * 1.6, 12.8, z1, Palette.stoneLight, M.Limestone)
		Kit.box(s, "Springer2", outer - side * 1.6, 11.3, z0, outer - side * 3, 12.8, z1, Palette.stoneLight, M.Limestone)
		Kit.box(s, "SpringerBand", outer, 9.4, z0 - 0.1, outer - side * 1.6, 10, z1 + 0.1, Palette.basalt, M.Basalt).CastShadow = false
	end
	for _, zf in { { z1, 1 }, { z0, -1 } } do
		Props.mashrabiya(s, Kit.faceFrame(Vector3.new(0, 15, zf[1]), Vector3.new(0, 0, zf[2])), 6, 4.5, 1.2)
	end
	Props.lantern(s, Kit.faceFrame(Vector3.new(0, 11.6, z0), Vector3.new(0, 0, -1)), 16)
end


local function lane(map: Instance)
	local m = Kit.model(map, "Lane")
	Facade.build(m, "WestA", -24, 70, -8, 88, 22, "X", 1, { jetty = true, doorAt = 82, lantern = 76 })
	if LaneZoneLogic.built(LaneZones.zones, "hammam") then
		-- The hammam's passage (Zones/Hammam, LP-D04) runs under WestB's south end (z 27..32).
		Facade.build(m, "WestB", -24, 32, -8, 50, 21, "X", 1, { jetty = true, doorAt = 42, lantern = 46 })
		Kit.box(m, "WestBPier", -24, 0, 24, -8, 21, 27, Palette.stoneLight, M.Limestone)
		Kit.box(m, "WestBPierParapet", -24, 21, 24, -8, 22.2, 27, Palette.stoneWarm, M.Limestone)
	else
		Facade.build(m, "WestB", -24, 24, -8, 50, 21, "X", 1, { jetty = true, doorAt = 42, lantern = 46 })
	end
	if LaneZoneLogic.built(LaneZones.zones, "souq") then
		-- The souq's passage (Zones/Souq, LP-D03) runs under the south end of this block (z 64..72).
		Facade.build(m, "EastA", 8, 72, 24, 88, 21, "X", -1, { jetty = true, doorAt = 82, lantern = 76 })
	else
		Facade.build(m, "EastA", 8, 64, 24, 88, 21, "X", -1, { jetty = true, doorAt = 72, lantern = 67 })
	end
	-- EastB (x 8..24, z 24..48) is the barber shop, built in Zones/Extras.
	sabat(m, 28, 34)

	-- Overhead life: vines and washing lines
	Props.trellis(m, -8, 8, 46, 18.5)
	Props.trellis(m, -8, 8, 76, 18.5)
	Props.laundry(m, Vector3.new(-8, 17, 60), Vector3.new(8, 17.5, 58), { Palette.jasmine, Palette.fabricIndigo, Palette.fabricRed })
	Props.laundry(m, Vector3.new(-8, 16.5, 84), Vector3.new(8, 16, 85), { Palette.tile, Palette.jasmine })

	-- Street life
	Props.pot(m, Vector3.new(-6.8, 0.35, 79), "jasmine", 1)
	Props.pot(m, Vector3.new(6.8, 0.35, 70), "geranium", 1)
	Props.pot(m, Vector3.new(6.8, 0.35, 38), "basil", 1)
	Props.crate(m, CFrame.new(-6.4, 0, 46) * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("#E8892B"))
	Props.crate(m, CFrame.new(6.4, 0, 30) * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("#4A2357"))
	-- The bakery cat keeps watch from an empty crate (and turns to look at passers-by, client-side)
	Kit.box(m, "CatCrate", -8, 0, 65.2, -6.4, 1.1, 66.8, Palette.wood, M.WoodPlanks)
	Props.cat(m, CFrame.new(-7.2, 1.1, 66) * CFrame.Angles(0, math.rad(-120), 0), Color3.fromHex("#C98A4B"))
	Props.copperPot(m, Vector3.new(6.9, 0.35, 75), 1.1)
end

function Lane.build(map: Instance)
	ground(map)
	gate(map)
	lane(map)
end

return Lane
