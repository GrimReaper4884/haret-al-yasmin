--!strict
-- Sitt Wardeh's courtyard house: ablaq-paved courtyard, pool, citrus and climbing jasmine, and a
-- liwan (open arched hall) with cushions, a low table and a birdcage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)

local M = Kit.M

local House = {}

function House.build(map: Instance)
	local m = Kit.model(map, "WardehHouse")
	-- Courtyard walls with an arched entrance at z = -26
	Kit.box(m, "FrontW", -16, 0, -28, -4, 14, -26, Palette.stoneLight, M.Limestone)
	Kit.box(m, "FrontE", 4, 0, -28, 16, 14, -26, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Arch", -4, 10, -28, 4, 14, -26, Palette.stoneLight, M.Limestone)
	for i = 1, 6 do
		local x = -4.5 + (i - 0.5) * 1.5
		Kit.box(m, "Voussoir", x - 0.75, 10, -25.9, x + 0.75, 11.2, -25.6, if i % 2 == 0 then Palette.basalt else Palette.stoneLight, if i % 2 == 0 then M.Basalt else M.Limestone).CastShadow = false
	end
	for _, y in { 3, 6 } do
		Kit.box(m, "BandW", -16, y, -25.9, -4, y + 0.8, -25.7, Palette.basalt, M.Basalt).CastShadow = false
		Kit.box(m, "BandE", 4, y, -25.9, 16, y + 0.8, -25.7, Palette.basalt, M.Basalt).CastShadow = false
	end
	Kit.box(m, "WallW", -16, 0, -58, -14, 14, -28, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallE", 14, 0, -58, 16, 14, -28, Palette.stoneLight, M.Limestone)
	Props.lantern(m, Kit.faceFrame(Vector3.new(0, 9, -26), Vector3.new(0, 0, 1)))

	-- Courtyard paving: alternating pale and dark stripes
	for i = 0, 10 do
		local z0 = -50 + i * 2
		Kit.box(m, "Pave", -14, 0, z0, 14, 0.04, z0 + 2, if i % 2 == 0 then Palette.stoneLight else Color3.fromHex("#8C8079"), M.Limestone).CastShadow = false
	end

	-- South range of rooms with the liwan
	Kit.box(m, "Rooms", -16, 0, -62, 16, 20, -50, Palette.plaster, M.Plaster)
	Kit.box(m, "Parapet", -16, 20, -62, 16, 21.2, -50, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "LiwanBack", -5, 0, -50.4, 5, 11, -50, Color3.fromHex("#3A2A1E"), M.Wood)
	for _, x in { -6, 5 } do
		Kit.box(m, "Pilaster", x, 0, -50.2, x + 1, 11, -49.6, Palette.stoneLight, M.Limestone)
	end
	for i = 1, 8 do
		local x = -6 + (i - 0.5) * 1.5
		local lift = (1 - math.abs(x) / 6) * 0.9
		Kit.box(m, "LiwanVoussoir", x - 0.75, 11 + lift, -50.2, x + 0.75, 12.2 + lift, -49.6, if i % 2 == 0 then Palette.basalt else Palette.stoneLight, if i % 2 == 0 then M.Basalt else M.Limestone).CastShadow = false
	end
	for _, x in { -11, 10.5 } do
		Props.window(m, Kit.faceFrame(Vector3.new(x, 6, -50), Vector3.new(0, 0, 1)), 2.2, 3)
	end
	Props.mashrabiya(m, Kit.faceFrame(Vector3.new(0, 14, -50), Vector3.new(0, 0, 1)), 7, 4.5, 1.6)
	-- Inside the liwan: cushions, low table, copper tray and coffee pot, birdcage
	Kit.box(m, "Diwan", -4.6, 0, -50, 4.6, 1.2, -48.4, Palette.fabricRed, M.Fabric)
	Kit.box(m, "DiwanBack", -4.6, 1.2, -50, 4.6, 2.6, -49.6, Color3.fromHex("#7A1E1A"), M.Fabric)
	Kit.column(m, "TableLeg", Vector3.new(0, 0, -46.6), 1, 0.8, Palette.woodDark, M.Wood)
	Kit.disc(m, "Tray", Vector3.new(0, 1.05, -46.6), 2.4, 0.12, Palette.copper, M.Metal)
	Props.copperPot(m, Vector3.new(0.4, 1.1, -46.6), 0.45)
	Kit.column(m, "CageChain", Vector3.new(3, 8.2, -48.8), 2.6, 0.06, Palette.ink, M.Metal, false)
	local cage = Kit.ball(m, "Birdcage", Vector3.new(3, 7.6, -48.8), 1.3, Palette.copper, M.ForceField, false)
	cage.Transparency = 0.2
	Kit.ball(m, "Bird", Vector3.new(3, 7.5, -48.8), 0.35, Color3.fromHex("#E5C84A"), M.SmoothPlastic, false)

	-- Pool with a small jet, moved clear of Sitt Wardeh's spot at (4, -40)
	Kit.box(m, "PoolRim", -8, 0, -45, -1, 1.2, -37, Palette.basalt, M.Basalt)
	Kit.box(m, "PoolTiles", -7.6, 1.2, -44.6, -1.4, 1.25, -37.4, Palette.tile, M.CeramicTiles).CastShadow = false
	Kit.box(m, "PoolWater", -7.4, 0.6, -44.4, -1.6, 1.15, -37.6, Palette.water, M.Glass).Transparency = 0.25
	Kit.column(m, "Jet", Vector3.new(-4.5, 1.1, -41), 0.9, 0.35, Palette.stoneLight, M.Marble, false)

	-- Citrus and jasmine
	Props.tree(m, Vector3.new(-10, 0, -32), Color3.fromHex("#F0D04A"), 0.85) -- lemon
	Props.tree(m, Vector3.new(10, 0, -31), Color3.fromHex("#E8892B"), 0.85)
	for _, z in { -46, -38, -31 } do
		Kit.box(m, "JasmineW", -14, 3, z - 2.5, -13.7, 11, z + 2.5, Palette.vine, M.Grass).CastShadow = false
		for k = 0, 3 do
			Kit.ball(m, "JasmineFlower", Vector3.new(-13.6, 4.5 + k * 1.8, z - 1.5 + (k % 2) * 2.4), 0.35, Palette.jasmine, M.SmoothPlastic, false)
		end
	end
	Props.pot(m, Vector3.new(12.8, 0, -48), "basil", 1)
	Props.pot(m, Vector3.new(12.8, 0, -44), "geranium", 1)
	Props.pot(m, Vector3.new(-12.8, 0, -28.6), "jasmine", 1)
	Props.cat(m, CFrame.new(-1, 1.2, -36.6) * CFrame.Angles(0, math.rad(200), 0), Color3.fromHex("#E8E1D6"))
end

return House
