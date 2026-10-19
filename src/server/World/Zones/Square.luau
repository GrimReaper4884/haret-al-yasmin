--!strict
-- The fountain square (al-bahra): octagonal tiled basin, citrus trees, benches, pigeons, and the
-- façades that close the square.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local LaneZones = require(ReplicatedStorage:WaitForChild("Shared").Config.LaneZones)
local LaneZoneLogic = require(ReplicatedStorage:WaitForChild("Shared").Logic.LaneZoneLogic)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Facade = require(World.Facade)

local M = Kit.M

local Square = {}

local ORANGE = Color3.fromHex("#E8892B")
local POMEGRANATE = Color3.fromHex("#A8322A")

local function fountain(parent: Instance)
	local f = Kit.model(parent, "Fountain")
	local R = 8
	local seg = 2 * R * math.tan(math.rad(22.5))
	for k = 0, 7 do
		local cf = CFrame.Angles(0, math.rad(k * 45), 0) * CFrame.new(0, 0, -(R - 0.6))
		Kit.part(f, { name = "Wall", size = Vector3.new(seg + 0.1, 2.2, 1.2), cf = CFrame.new(0, 1.1, 0) * cf, color = Palette.basalt, material = M.Basalt })
		Kit.part(f, { name = "Tiles", size = Vector3.new(seg + 0.1, 0.3, 1.3), cf = CFrame.new(0, 2.35, 0) * cf, color = if k % 2 == 0 then Palette.tile else Palette.jasmine, material = M.CeramicTiles, shadow = false })
	end
	Kit.disc(f, "BasinFloor", Vector3.new(0, 0.1, 0), 2 * R - 1, 0.2, Palette.tile, M.CeramicTiles, false)
	local water = Kit.disc(f, "Water", Vector3.new(0, 1.6, 0), 2 * R - 1.4, 0.2, Palette.water, M.Glass, false)
	water.Transparency = 0.3
	-- Central column, bowl and spout
	Kit.column(f, "Column", Vector3.new(0, 0, 0), 5.5, 1.6, Palette.stoneLight, M.Marble)
	Kit.disc(f, "Bowl", Vector3.new(0, 5.6, 0), 5, 0.8, Palette.stoneLight, M.Marble)
	Kit.disc(f, "BowlWater", Vector3.new(0, 6.05, 0), 4.4, 0.1, Palette.water, M.Glass, false).Transparency = 0.25
	Kit.ball(f, "Spout", Vector3.new(0, 6.9, 0), 1.1, Palette.tile, M.CeramicTiles)
	-- Four thin streams falling from the bowl into the basin
	for k = 0, 3 do
		local a = math.rad(k * 90 + 45)
		local top = Vector3.new(math.cos(a) * 2.4, 5.7, math.sin(a) * 2.4)
		local bottom = Vector3.new(math.cos(a) * 3.4, 1.7, math.sin(a) * 3.4)
		local stream = Kit.part(f, { name = "Stream", size = Vector3.new(0.18, 0.18, (top - bottom).Magnitude), cf = CFrame.lookAt((top + bottom) / 2, bottom), color = Color3.fromHex("#BFE3EE"), material = M.Glass, collide = false, transparency = 0.35, shadow = false })
		stream.Name = "Stream"
	end
end

function Square.build(map: Instance)
	local m = Kit.model(map, "FountainSquare")

	-- Inlaid paving rings around the fountain
	Kit.disc(m, "Inlay", Vector3.new(0, 0.02, 0), 30, 0.1, Palette.basalt, M.Slate, false)
	Kit.disc(m, "InlayInner", Vector3.new(0, 0.03, 0), 27, 0.12, Palette.stoneLight, M.Pavement, false)

	-- Surrounding façades
	Facade.build(m, "SquareNW", -40, 0, -24, 24, 20, "X", 1, { lantern = 2 })
	if LaneZoneLogic.built(LaneZones.zones, "mosque_court") then
		-- 6 deep, with the mosque court's arch at z 16..21 (Zones/MosqueCourt, LP-D05)
		Facade.build(m, "SquareNE", 24, 0, 30, 16, 21, "X", -1, { jetty = true, lantern = 2 })
		Kit.box(m, "SquareNEPier", 24, 0, 21, 30, 21, 24, Palette.stoneLight, M.Limestone)
		Kit.box(m, "SquareNEPierParapet", 24, 21, 21, 30, 22.2, 24, Palette.stoneWarm, M.Limestone)
	else
		Facade.build(m, "SquareNE", 24, 0, 40, 24, 21, "X", -1, { jetty = true, lantern = 2 })
	end
	-- SquareSW (x -40..-24, z -26..0) is the coffee house, built in Zones/Extras.
	if LaneZoneLogic.built(LaneZones.zones, "diwan") then
		-- 6 deep, with the diwan's portal at z -16..-11 (Zones/Diwan, LP-D05)
		Facade.build(m, "SquareSE", 24, -11, 30, 0, 20, "X", -1, { door = false })
		Facade.build(m, "SquareSEs", 24, -26, 30, -16, 20, "X", -1, { door = false })
	else
		Facade.build(m, "SquareSE", 24, -26, 40, 0, 20, "X", -1, { door = false })
	end
	Facade.build(m, "SouthW", -40, -42, -16, -26, 20, "Z", 1, { doorAt = -26 })
	Facade.build(m, "SouthE", 16, -42, 40, -26, 22, "Z", 1, { doorAt = 26, jetty = true })
	Kit.box(m, "CornerNW", -24, 0, 24, -8, 20, 26, Palette.stoneLight, M.Limestone)
	Kit.box(m, "CornerNE", 8, 0, 24, 24, 20, 26, Palette.stoneLight, M.Limestone)

	fountain(m)

	Props.bench(m, CFrame.new(-14, 0, 8) * CFrame.Angles(0, math.rad(90), 0))
	Props.bench(m, CFrame.new(14, 0, 8) * CFrame.Angles(0, math.rad(90), 0))
	Props.bench(m, CFrame.new(-14, 0, -12) * CFrame.Angles(0, math.rad(90), 0))
	Props.bench(m, CFrame.new(14, 0, -12) * CFrame.Angles(0, math.rad(90), 0))
	Props.tree(m, Vector3.new(-15, 0, 21), ORANGE, 0.9) -- clear of Hajj Rashid's shopfront
	Props.tree(m, Vector3.new(19, 0, 18), ORANGE)
	Props.tree(m, Vector3.new(-19, 0, -20), POMEGRANATE)
	Props.tree(m, Vector3.new(19, 0, -20), ORANGE)

	-- Copper jugs by the basin (the water seller's spot) and pigeons on the paving
	Props.copperPot(m, Vector3.new(9.2, 0, 3), 1.2)
	Props.copperPot(m, Vector3.new(9.6, 0, 4.6), 0.9)
	for i = 1, 6 do
		local a = i * 1.05
		Props.pigeon(m, Vector3.new(math.cos(a) * 11.5, 0.02, math.sin(a) * 11.5 - 2), a * 2)
	end
	Props.pot(m, Vector3.new(-22.5, 0, 22.5), "geranium", 1.2)
	Props.pot(m, Vector3.new(22.5, 0, 22.5), "jasmine", 1.2)
	Props.pot(m, Vector3.new(-22.5, 0, -24.5), "basil", 1.2)
	Props.cat(m, CFrame.new(13.2, 1.8, -12) * CFrame.Angles(0, math.rad(90), 0), Color3.fromHex("#3A3430"))
end

return Square
