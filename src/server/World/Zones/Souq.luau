--!strict
-- The souq (LOOK_AND_PLAY_PLAN §4.1, LP-D03): a covered market off the lane's east side. A vaulted
-- passage under the south end of the EastA block (x 8..24, z 64..72) opens into corridor A (east,
-- to x 60), which turns into corridor B (south, to the khan door at z 42). Shops are niches in
-- the outer walls: the potter (with the cat on a jar), the clog-maker, Abu Marzouk's greens with
-- his cart, Abu Brahim's cloth shop (bolts on the awning, the money chest) and a coppersmith. The
-- roof is slatted so daylight falls in bars; two real lights, the rest are glowing lamps on chains.
-- Built into `Zone_souq` by WorldService when Config/LaneZones marks it built. Bounds x 24..64,
-- z 40..76 (the passage sits under the lane's own block).

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

local Souq = {}

local WALL_H = 14 -- outer walls and the shop block; the roof slats sit at 13..14
local LINTEL_Y = 9 -- top of every shop opening
local TERRACOTTA = Color3.fromHex("#B5643C")
local CLAY = Color3.fromHex("#C98A5B")

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

-- A sloped cloth awning over a shop opening. `f` = Kit.faceFrame at the wall face, lintel height;
-- the awning reaches `depth` out from the wall, `w` wide.
local function awning(m: Model, f: CFrame, w: number, depth: number, color: Color3, stripe: Color3): CFrame
	local cf = f * CFrame.new(0, 0, -depth / 2) * CFrame.Angles(math.rad(-18), 0, 0)
	deco(Kit.part(m, { name = "Awning", size = Vector3.new(w, 0.25, depth), cf = cf, color = color, material = M.Fabric }))
	deco(Kit.part(m, { name = "AwningStripe", size = Vector3.new(w + 0.02, 0.27, 0.5), cf = cf * CFrame.new(0, 0, -depth / 2 + 0.6), color = stripe, material = M.Fabric }))
	return cf
end

-- A lamp hanging on a chain from the roof (emissive glass, no light: the zone keeps two lights).
local function lamp(m: Model, x: number, z: number)
	deco(Kit.part(m, { name = "Chain", size = Vector3.new(0.08, 2.4, 0.08), cf = CFrame.new(x, 11.8, z), color = Palette.ink, material = M.Metal }))
	deco(Kit.part(m, { name = "LampCap", size = Vector3.new(0.8, 0.25, 0.8), cf = CFrame.new(x, 10.5, z), color = Palette.copper, material = M.Metal }))
	deco(Kit.part(m, { name = "LampGlass", size = Vector3.new(0.7, 0.9, 0.7), cf = CFrame.new(x, 9.9, z), color = Color3.fromHex("#F2C46B"), material = M.Neon, transparency = 0.15 }))
end

-- Closed wooden shutters on the shop block's face (`f` at the ground, outward normal).
local function shutters(m: Model, f: CFrame, w: number)
	Kit.part(m, { name = "Shutter", size = Vector3.new(w, 7, 0.3), cf = f * CFrame.new(0, 3.5, -0.15), color = Palette.wood, material = M.WoodPlanks })
	for i = 1, 3 do
		deco(Kit.part(m, { name = "Slat", size = Vector3.new(w, 0.15, 0.36), cf = f * CFrame.new(0, i * 1.8, -0.2), color = Palette.woodDark, material = M.Wood }))
	end
	deco(Kit.part(m, { name = "Hasp", size = Vector3.new(0.2, 0.6, 0.4), cf = f * CFrame.new(0, 3.2, -0.3), color = Palette.ink, material = M.Metal }))
end

------------------------------------------------------------------------------- shell

local function passage(m: Model)
	-- Vaulted way under EastA: the block bridges it (its upper floor runs over the passage).
	Kit.box(m, "PassageFloor", 8, -1, 64, 24, 0, 72, Palette.stoneWarm, M.Cobblestone)
	Kit.box(m, "PassageOver", 8, 11, 64, 24, 21, 72, Palette.plaster, M.Plaster)
	Kit.box(m, "PassageParapet", 8, 21, 64, 24, 22.2, 72, Palette.stoneWarm, M.Limestone)
	for _, x in { 11, 15, 19, 23 } do
		deco(Kit.box(m, "Beam", x - 0.3, 10.5, 64, x + 0.3, 11, 72, Palette.woodDark, M.Wood))
	end
	-- Ablaq voussoirs over the lane-side opening
	for i = 1, 6 do
		local z = 64 + (i - 0.5) * 8 / 6
		local lift = (1 - math.abs(z - 68) / 4) * 0.5
		local dark = i % 2 == 0
		deco(Kit.box(m, "Voussoir", 7.6, 10 + lift, z - 4 / 6, 8.1, 11.2 + lift, z + 4 / 6, if dark then Palette.basalt else Palette.stoneLight, if dark then M.Basalt else M.Limestone))
	end
	Props2.sign(m, Kit.faceFrame(Vector3.new(7.5, 13.2, 68), Vector3.new(-1, 0, 0)), 7, ar("sign.souq"), "Souq al-Hara", Palette.copper)
end

local function shell(m: Model)
	Kit.box(m, "Floor", 24, -1, 42, 63, 0, 75, Palette.stoneWarm, M.Cobblestone)
	-- A basalt runner down the middle of both corridors
	deco(Kit.box(m, "Runner", 24, 0, 67.6, 56.4, 0.04, 68.4, Palette.basalt, M.Basalt))
	deco(Kit.box(m, "Runner", 55.6, 0, 42, 56.4, 0.04, 67.6, Palette.basalt, M.Basalt))

	-- Outer walls
	Kit.box(m, "WallN", 24, 0, 75, 64, WALL_H, 76, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallE", 63, 0, 40, 64, WALL_H, 75, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallS", 24, 0, 40, 63, WALL_H, 42, Palette.stoneLight, M.Limestone)
	-- North wall piers between the shop niches (the niches are 3 deep, z 72..75)
	for _, x in { { 24, 27 }, { 33, 37 }, { 43, 46 }, { 52, 63 } } do
		Kit.box(m, "PierN", x[1], 0, 72, x[2], WALL_H, 75, Palette.stoneLight, M.Limestone)
	end
	for _, x in { { 27, 33 }, { 37, 43 }, { 46, 52 } } do
		Kit.box(m, "LintelN", x[1], LINTEL_Y, 72, x[2], WALL_H, 75, Palette.stoneLight, M.Limestone)
		deco(Kit.box(m, "LintelBand", x[1], LINTEL_Y, 71.9, x[2], LINTEL_Y + 0.6, 72, Palette.basalt, M.Basalt))
	end
	-- East wall piers (niches x 60..63)
	for _, z in { { 42, 46 }, { 52, 56 }, { 62, 72 } } do
		Kit.box(m, "PierE", 60, 0, z[1], 63, WALL_H, z[2], Palette.stoneLight, M.Limestone)
	end
	for _, z in { { 46, 52 }, { 56, 62 } } do
		Kit.box(m, "LintelE", 60, LINTEL_Y, z[1], 63, WALL_H, z[2], Palette.stoneLight, M.Limestone)
		deco(Kit.box(m, "LintelBand", 59.9, LINTEL_Y, z[1], 60, LINTEL_Y + 0.6, z[2], Palette.basalt, M.Basalt))
	end

	-- The shop block between the corridors, its two faces shuttered
	Kit.box(m, "Block", 24, 0, 42, 52, WALL_H, 64, Kit.tint(Palette.stoneLight, Kit.rng("souq"), 0.04), M.Limestone)
	for _, y in { 4, 9 } do
		deco(Kit.box(m, "BandN", 24, y, 64, 52, y + 0.7, 64.1, Palette.basalt, M.Basalt))
		deco(Kit.box(m, "BandE", 52, y, 42, 52.1, y + 0.7, 64, Palette.basalt, M.Basalt))
	end
	shutters(m, Kit.faceFrame(Vector3.new(30, 0, 64), Vector3.new(0, 0, 1)), 5)
	shutters(m, Kit.faceFrame(Vector3.new(40, 0, 64), Vector3.new(0, 0, 1)), 5)
	shutters(m, Kit.faceFrame(Vector3.new(52, 0, 45.2), Vector3.new(1, 0, 0)), 4.4)
	KitLayout.place(m, "mashrabiya_bay", CFrame.new(47.5, 0.6, 64) * CFrame.Angles(0, math.rad(180), 0))
	-- Two rugs for sale on the block's east face
	for i, c in { Palette.fabricRed, Palette.fabricIndigo } do
		local z = 54 + (i - 1) * 4.5
		deco(Kit.box(m, "RugBorder", 52, 2, z, 52.15, 8, z + 3.4, Palette.jasmine, M.Fabric))
		deco(Kit.box(m, "Rug", 52.15, 2.4, z + 0.4, 52.2, 7.6, z + 3, c, M.Fabric))
	end

	-- The khan door closing corridor B
	Props.door(m, Kit.faceFrame(Vector3.new(56, 0, 42), Vector3.new(0, 0, 1)), 4, 7, Palette.woodDark)

	-- Slatted roof: daylight falls through the 1-stud gaps between the slats
	for x = 24, 56, 4 do
		Kit.box(m, "Roof", x, 13, 64, x + 3, 14, 72, Palette.plaster, M.Plaster)
		deco(Kit.box(m, "Rib", x + 3.1, 12.4, 64, x + 3.9, 13, 72, Palette.woodDark, M.Wood))
	end
	for z = 42, 60, 4 do
		Kit.box(m, "Roof", 52, 13, z, 60, 14, z + 3, Palette.plaster, M.Plaster)
		deco(Kit.box(m, "Rib", 52, 12.4, z + 3.1, 60, 13, z + 3.9, Palette.woodDark, M.Wood))
	end

	-- Light: two lanterns that shine (the zone's two PointLights), five that glow
	Props.lantern(m, Kit.faceFrame(Vector3.new(35, 9.6, 64), Vector3.new(0, 0, 1)), 18)
	Props.lantern(m, Kit.faceFrame(Vector3.new(52, 9.6, 52), Vector3.new(1, 0, 0)), 18)
	for _, p in { { 29, 68 }, { 45, 68 }, { 56, 69 }, { 56, 58 }, { 56, 47 } } do
		lamp(m, p[1], p[2])
	end
	KitLayout.place(m, "lantern_wall", CFrame.new(25.5, 0, 72))
end

------------------------------------------------------------------------------- shops

-- The potter (niche x 27..33): shelves of jugs, big jars out front, the cat asleep on one.
local function potter(m: Model)
	Kit.box(m, "Counter", 27.4, 0, 72.2, 32.6, 1.2, 73, Palette.wood, M.WoodPlanks)
	for _, y in { 3.4, 6.2 } do
		deco(Kit.box(m, "Shelf", 27.3, y, 74.1, 32.7, y + 0.2, 75, Palette.wood, M.WoodPlanks))
		for i = 0, 3 do
			local x = 28.1 + i * 1.3
			local tall = 0.8 + (i % 2) * 0.35
			Kit.column(m, "Jug", Vector3.new(x, y + 0.2, 74.55), tall, 0.7, if i % 2 == 0 then TERRACOTTA else CLAY, M.Slate, false)
		end
	end
	for _, x in { 29.4, 31.2 } do
		Kit.column(m, "Pot", Vector3.new(x, 1.2, 72.6), 0.7, 0.9, CLAY, M.Slate, false)
	end
	Kit.column(m, "BigJar", Vector3.new(28.2, 0, 71), 2.2, 1.6, TERRACOTTA, M.Slate, true)
	Kit.ball(m, "BigJarShoulder", Vector3.new(28.2, 2.1, 71), 1.5, TERRACOTTA, M.Slate, false)
	Props.cat(m, CFrame.new(28.2, 2.6, 71), Color3.fromHex("#D8A35D"))
	KitLayout.place(m, "oil_jar_cluster", CFrame.new(31.8, 0, 70.6))
	awning(m, Kit.faceFrame(Vector3.new(30, LINTEL_Y, 72), Vector3.new(0, 0, -1)), 6.4, 2.6, Palette.fabricRed, Palette.jasmine)
end

-- The clog-maker (niche x 37..43): his bench and stool, pairs of wooden clogs on two shelves.
local function clogMaker(m: Model)
	Kit.box(m, "Bench", 38, 0, 73.4, 41.4, 1.6, 74.8, Palette.woodDark, M.Wood)
	Props2.stool(m, Vector3.new(39.6, 0, 72.6))
	deco(Kit.box(m, "Shavings", 38.4, 0, 72.4, 41, 0.08, 73.4, Color3.fromHex("#D9B98A"), M.Sand))
	for row, y in { 4, 6.4 } do
		deco(Kit.box(m, "Shelf", 37.3, y, 74.1, 42.7, y + 0.2, 75, Palette.wood, M.WoodPlanks))
		for i = 0, 3 do
			local x = 37.9 + i * 1.35
			for side = 0, 1 do
				deco(Kit.box(m, "Clog", x + side * 0.5, y + 0.2, 74.2, x + side * 0.5 + 0.4, y + 0.55, 75, if (i + row) % 2 == 0 then Palette.wood else Palette.woodDark, M.Wood))
			end
		end
	end
	KitLayout.place(m, "sack_pile", CFrame.new(41.6, 0, 73.6) * CFrame.Angles(0, math.rad(180), 0), 0.6)
	awning(m, Kit.faceFrame(Vector3.new(40, LINTEL_Y, 72), Vector3.new(0, 0, -1)), 6.4, 2.6, Palette.fabricIndigo, Palette.jasmine)
end

-- Abu Marzouk's greens (niche x 46..52) and his cart in front of the pier beside it.
local function grocer(m: Model)
	Props.crate(m, CFrame.new(47.6, 0, 73), Color3.fromHex("#E8892B"))
	Props.crate(m, CFrame.new(50.4, 0, 73), Color3.fromHex("#4A2357"))
	Props.crate(m, CFrame.new(49, 1, 73), Color3.fromHex("#B7361F"))
	-- Strings of garlic and onions from the lintel
	for i, x in { 47, 51 } do
		deco(Kit.part(m, { name = "String", size = Vector3.new(0.06, 3, 0.06), cf = CFrame.new(x, 7.4, 72.4), color = Palette.wood, material = M.Fabric }))
		for k = 0, 2 do
			Kit.ball(m, "Bulb", Vector3.new(x, 6.2 + k * 1, 72.4), 0.55, if i == 1 then Color3.fromHex("#EFE6D2") else Color3.fromHex("#B5652E"), M.SmoothPlastic, false)
		end
	end
	awning(m, Kit.faceFrame(Vector3.new(49, LINTEL_Y, 72), Vector3.new(0, 0, -1)), 6.4, 2.6, Palette.vine, Palette.jasmine)
	Props2.sign(m, Kit.faceFrame(Vector3.new(49, 11.2, 72), Vector3.new(0, 0, -1)), 5, ar("sign.grocer"), "Abu Marzouk", Palette.vine)

	-- The cart: a bed on two wheels, handles towards the passage, heaped with produce
	Kit.box(m, "CartBed", 43.4, 1.4, 69.6, 47.4, 1.9, 71.6, Palette.wood, M.WoodPlanks)
	for _, z in { 69.5, 71.7 } do
		deco(Kit.box(m, "CartSide", 43.4, 1.9, z - 0.1, 47.4, 2.4, z + 0.1, Palette.woodDark, M.Wood))
		Kit.part(m, { name = "Wheel", size = Vector3.new(0.3, 2.2, 2.2), cf = CFrame.new(45.8, 1.1, z + (if z < 70 then -0.3 else 0.3)) * CFrame.Angles(0, math.rad(90), 0), color = Palette.woodDark, material = M.Wood, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
		deco(Kit.part(m, { name = "Handle", size = Vector3.new(2.4, 0.2, 0.2), cf = CFrame.new(42.3, 1.6, z) * CFrame.Angles(0, 0, math.rad(-10)), color = Palette.woodDark, material = M.Wood }))
	end
	Kit.column(m, "Prop", Vector3.new(43.6, 0, 70.6), 1.4, 0.25, Palette.woodDark, M.Wood, false)
	for i, c in { "#E8892B", "#5B2A55", "#7BAF3A", "#E8892B", "#B7361F" } do
		Kit.ball(m, "Heap", Vector3.new(43.9 + i * 0.6, 2.2, 70.2 + (i % 2) * 0.8), 0.9, Color3.fromHex(c), M.SmoothPlastic, false)
	end
end

-- Abu Brahim's cloth shop (niche z 46..52 on the east wall): bolts on shelves and on the awning, the
-- money chest under the counter. Abu Brahim stands before the counter (Config/Npcs `cloth_merchant`, LP-E03).
local function clothShop(m: Model)
	local colors = { Palette.fabricRed, Palette.fabricIndigo, Palette.jasmine, Palette.tile, Color3.fromHex("#C9A13B"), Palette.vine }
	Kit.box(m, "Counter", 60.1, 0, 46.6, 61, 2.6, 51.4, Palette.wood, M.WoodPlanks)
	for r, y in { 3, 5.2, 7.4 } do
		deco(Kit.box(m, "Shelf", 61.9, y, 46.3, 63, y + 0.2, 51.7, Palette.wood, M.WoodPlanks))
		for i = 0, 3 do
			local z = 47.1 + i * 1.3
			Kit.part(m, { name = "Bolt", size = Vector3.new(1.0, 0.75, 0.75), cf = CFrame.new(62.45, y + 0.58, z), color = colors[(r + i) % #colors + 1], material = M.Fabric, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
		end
	end
	-- The chest: dark wood with copper bands
	Kit.box(m, "Chest", 61.1, 0, 50, 62.7, 1.4, 51.6, Palette.woodDark, M.Wood)
	for _, z in { 50.4, 51.2 } do
		deco(Kit.box(m, "ChestBand", 61.05, 0, z - 0.08, 62.75, 1.45, z + 0.08, Palette.copper, M.Metal))
	end
	local cf = awning(m, Kit.faceFrame(Vector3.new(60, LINTEL_Y, 49), Vector3.new(-1, 0, 0)), 6.4, 2.6, Palette.fabricIndigo, Color3.fromHex("#C9A13B"))
	for i = 1, 3 do
		Kit.part(m, { name = "AwningBolt", size = Vector3.new(4.8, 0.6, 0.6), cf = cf * CFrame.new(0, 0.42, -1.4 + i * 0.75), color = colors[i], material = M.Fabric, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
	end
	Props2.sign(m, Kit.faceFrame(Vector3.new(60, 11.2, 49), Vector3.new(-1, 0, 0)), 5, ar("sign.cloth"), "Abu Brahim", Palette.fabricIndigo)
	-- Lengths of cloth hanging from the roof rib in front of the shop
	for i, c in { Palette.fabricRed, Palette.jasmine, Palette.tile } do
		deco(Kit.box(m, "Hanging", 58.6, 7.2, 46.4 + i * 1.4, 58.7, 12.4, 47.6 + i * 1.4, c, M.Fabric))
	end
end

-- The coppersmith (niche z 56..62): pots on a rod, a bench with an anvil and a tray.
local function coppersmith(m: Model)
	deco(Kit.box(m, "Rod", 62.3, 7.6, 56.4, 62.5, 7.8, 61.6, Palette.ink, M.Metal))
	for _, z in { 57.2, 58.8, 60.4 } do
		Props.copperPot(m, Vector3.new(62.4, 6.6, z), 0.9)
	end
	Kit.box(m, "Workbench", 60.4, 0, 57.4, 61.8, 2, 60.6, Palette.woodDark, M.Wood)
	Kit.box(m, "Anvil", 60.7, 2, 58.4, 61.5, 2.6, 59.4, Palette.basalt, M.Basalt)
	Kit.disc(m, "Tray", Vector3.new(61.1, 2.05, 60), 1.1, 0.08, Palette.copper, M.Metal, false)
	Props.copperPot(m, Vector3.new(62.2, 0, 56.9), 1.5)
	Props.copperPot(m, Vector3.new(62.3, 0, 61.2), 1.2)
	awning(m, Kit.faceFrame(Vector3.new(60, LINTEL_Y, 59), Vector3.new(-1, 0, 0)), 6.4, 2.6, Palette.tile, Palette.jasmine)
end

function Souq.build(zone: Model)
	passage(zone)
	shell(zone)
	potter(zone)
	clogMaker(zone)
	grocer(zone)
	clothShop(zone)
	coppersmith(zone)
	KitLayout.place(zone, "bench_dikkeh", CFrame.new(52.9, 0, 51) * CFrame.Angles(0, math.rad(-90), 0))
end

return Souq
