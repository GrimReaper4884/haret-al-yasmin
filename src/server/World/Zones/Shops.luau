--!strict
-- Shops on the lane and the square: Abu Nadim's bakery, Khalil's tailoring and Hajj Rashid's
-- spice shop. NPC positions live in Config/Npcs; these props are built around them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local World = script.Parent.Parent
local Kit = require(World.Kit)

local M = Kit.M
local CYL_UP = Kit.CYL_UP

local Shops = {}

local KAAK = Color3.fromHex("#C98A4B")
local FLOUR = Color3.fromHex("#EFE6D2")

local function bakery(map: Instance)
	local m = Kit.model(map, "Bakery")
	Kit.box(m, "Back", -24, 0, 50, -16, 22, 70, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallN", -16, 0, 69, -8, 22, 70, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallS", -16, 0, 50, -8, 22, 51, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Roof", -16, 12, 50, -8, 22, 70, Palette.plaster, M.Plaster)
	Kit.box(m, "Parapet", -24, 22, 50, -8, 23.5, 70, Palette.stoneWarm, M.Limestone)
	Kit.box(m, "Lintel", -8.6, 11, 50, -7.8, 12.2, 70, Palette.woodDark, M.Wood)
	for _, y in { 3, 5.5, 8 } do
		Kit.box(m, "AblaqN", -8.15, y, 69, -7.95, y + 0.8, 70, Palette.basalt, M.Basalt).CastShadow = false
		Kit.box(m, "AblaqS", -8.15, y, 50, -7.95, y + 0.8, 51, Palette.basalt, M.Basalt).CastShadow = false
	end

	-- Counter with stacks of ka'ak
	Kit.box(m, "Counter", -9.5, 0, 53, -8, 3.4, 67, Palette.woodDark, M.Wood)
	Kit.box(m, "CounterTop", -9.8, 3.4, 52.8, -7.6, 3.8, 67.2, Palette.stoneWarm, M.Marble)
	for i = 0, 5 do
		for j = 0, 1 do
			Kit.disc(m, "Kaak", Vector3.new(-8.8, 3.95 + j * 0.3, 54.5 + i * 2.2), 1.4, 0.28, KAAK, M.Sand, false)
		end
	end
	-- Bread racks on the back wall
	for _, y in { 4, 6.5, 9 } do
		Kit.box(m, "Shelf", -15.8, y, 51.2, -14.6, y + 0.25, 55.2, Palette.wood, M.WoodPlanks).CastShadow = false
		for k = 0, 3 do
			Kit.disc(m, "Loaf", Vector3.new(-15.2, y + 0.4, 51.8 + k * 1.1), 1, 0.3, KAAK, M.Sand, false)
		end
	end
	-- Domed oven with a glowing mouth, firewood and flour sacks
	local oven = Kit.ball(m, "Oven", Vector3.new(-17, 2, 60), 9, Color3.fromHex("#C9A27A"), M.Brick)
	Kit.box(m, "OvenMouth", -12.8, 1.2, 58.5, -12.4, 3.6, 61.5, Color3.fromRGB(255, 120, 40), M.Neon)
	local fire = Instance.new("PointLight")
	fire.Color = Color3.fromRGB(255, 140, 60)
	fire.Range = 12
	fire.Brightness = 1.5
	fire.Parent = oven
	for i = 0, 4 do
		Kit.part(m, { name = "Log", size = Vector3.new(2.4, 0.45, 0.45), cf = CFrame.new(-14, 0.25 + (i % 2) * 0.4, 66 + i * 0.45) * CFrame.Angles(0, math.rad(90), 0), color = Palette.woodDark, material = M.Wood, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
	end
	for i = 0, 1 do
		Kit.column(m, "FlourSack", Vector3.new(-14.5, 0, 52 + i * 1.6), 1.5, 1.3, FLOUR, M.Fabric)
	end
	-- Long wooden peel leaning on the wall
	Kit.part(m, { name = "Peel", size = Vector3.new(0.25, 7, 0.25), cf = CFrame.new(-15.6, 3.4, 68.2) * CFrame.Angles(0, 0, math.rad(-12)), color = Palette.wood, material = M.Wood, collide = false, shadow = false })
	Kit.part(m, { name = "PeelHead", size = Vector3.new(0.12, 1.2, 1.1), cf = CFrame.new(-15.2, 0.6, 68.2), color = Palette.wood, material = M.WoodPlanks, collide = false, shadow = false })
	-- Awning over the counter
	Kit.part(m, { name = "Awning", size = Vector3.new(5, 0.3, 20), cf = CFrame.new(-6, 11, 60) * CFrame.Angles(0, 0, math.rad(-18)), color = Palette.fabricIndigo, material = M.Fabric })
	Kit.part(m, { name = "AwningStripe", size = Vector3.new(5.02, 0.32, 1), cf = CFrame.new(-6, 11, 55) * CFrame.Angles(0, 0, math.rad(-18)), color = Palette.jasmine, material = M.Fabric, collide = false, shadow = false })
	Kit.part(m, { name = "AwningStripe", size = Vector3.new(5.02, 0.32, 1), cf = CFrame.new(-6, 11, 65) * CFrame.Angles(0, 0, math.rad(-18)), color = Palette.jasmine, material = M.Fabric, collide = false, shadow = false })
end

local function tailor(map: Instance)
	local m = Kit.model(map, "Tailor")
	Kit.box(m, "Back", 16, 0, 48, 24, 21, 64, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Roof", 8, 12, 48, 16, 21, 64, Palette.plaster, M.Plaster)
	Kit.box(m, "WallN", 8, 0, 63, 16, 12, 64, Palette.stoneLight, M.Limestone)
	Kit.box(m, "WallS", 8, 0, 48, 16, 12, 49, Palette.stoneLight, M.Limestone)
	Kit.box(m, "Lintel", 7.8, 11, 48, 8.6, 12.2, 64, Palette.woodDark, M.Wood)
	Kit.box(m, "Table", 13, 0, 51, 15.5, 3, 61, Palette.wood, M.WoodPlanks)
	-- Bolts of cloth on the table
	local colors = { Palette.fabricRed, Palette.fabricIndigo, Palette.jasmine, Palette.tile, Palette.copper }
	for i, c in colors do
		Kit.part(m, { name = "Bolt", size = Vector3.new(2.4, 0.9, 0.9), cf = CFrame.new(14.2, 3.45, 51.5 + i * 1.6) * CFrame.Angles(0, math.rad(90), 0), color = c, material = M.Fabric, shape = Enum.PartType.Cylinder, collide = false, shadow = false })
	end
	-- Lengths of cloth hanging from a rod on the back wall
	Kit.box(m, "Rod", 15.6, 10, 49.5, 15.8, 10.2, 62.5, Palette.woodDark, M.Wood).CastShadow = false
	for i, c in { Palette.fabricIndigo, Palette.fabricRed, Color3.fromHex("#C9A13B"), Palette.vine, Palette.jasmine, Color3.fromHex("#1F1B18") } do
		local z = 50 + i * 1.8
		Kit.part(m, { name = "Hanging", size = Vector3.new(0.08, 5.5, 1.5), cf = CFrame.new(15.5, 7.2, z), color = c, material = M.Fabric, collide = false, shadow = false })
	end
	-- Tarboosh press: copper moulds on a bench
	Kit.box(m, "PressBench", 13.5, 0, 61.5, 15.5, 2.4, 63, Palette.woodDark, M.Wood)
	for i = 0, 2 do
		Kit.column(m, "Mould", Vector3.new(13.9 + i * 0.6, 2.4, 62.2), 0.9, 0.55, Palette.copper, M.Metal, false)
	end
	-- Dummy displaying a tarboosh and waistcoat
	Kit.column(m, "Stand", Vector3.new(10, 0, 62), 3.5, 0.4, Palette.woodDark, M.Wood)
	Kit.box(m, "Form", 9.1, 3.5, 61.4, 10.9, 5.9, 62.6, Palette.plaster, M.Fabric)
	Kit.box(m, "Vest", 9.05, 3.9, 61.35, 10.95, 5.85, 62.0, Color3.fromHex("#1F1B18"), M.Fabric)
	Kit.ball(m, "Head", Vector3.new(10, 6.6, 62), 1.1, Palette.stoneWarm, M.Wood)
	Kit.column(m, "Tarboosh", Vector3.new(10, 7.05, 62), 0.8, 0.95, Palette.fabricRed, M.Fabric)
	Kit.part(m, { name = "Awning", size = Vector3.new(5, 0.3, 16), cf = CFrame.new(6, 11, 56) * CFrame.Angles(0, 0, math.rad(18)), color = Palette.fabricRed, material = M.Fabric })
	Kit.part(m, { name = "AwningStripe", size = Vector3.new(5.02, 0.32, 1), cf = CFrame.new(6, 11, 56) * CFrame.Angles(0, 0, math.rad(18)), color = Palette.jasmine, material = M.Fabric, collide = false, shadow = false })
end

local function spiceShop(map: Instance)
	local m = Kit.model(map, "SpiceShop")
	Kit.part(m, { name = "Awning", size = Vector3.new(5, 0.3, 18), cf = CFrame.new(-22, 10.5, 13) * CFrame.Angles(0, 0, math.rad(16)), color = Palette.vine, material = M.Fabric })
	-- Open sacks heaped with spice (cumin, sumac, turmeric, za'atar, chilli)
	local spices = { "#B5832F", "#8E2B2B", "#D9A421", "#6F7D3A", "#B7361F" }
	for i, hex in spices do
		local z = 16.5 + i * 1.5
		Kit.column(m, "Sack", Vector3.new(-23, 0, z), 1.4, 1.3, Palette.stoneWarm, M.Fabric)
		Kit.ball(m, "Heap", Vector3.new(-23, 1.35, z), 1.1, Color3.fromHex(hex), M.Sand, false)
	end
	-- Shelf of glass jars
	Kit.box(m, "Shelf", -23.9, 4.5, 2, -23.3, 4.75, 7, Palette.wood, M.WoodPlanks).CastShadow = false
	for k = 0, 4 do
		Kit.part(m, { name = "Jar", size = Vector3.new(0.7, 0.6, 0.6), cf = CFrame.new(-23.6, 5.1, 2.6 + k * 1) * CYL_UP, color = Color3.fromHex(spices[k + 1]), material = M.Glass, shape = Enum.PartType.Cylinder, collide = false, transparency = 0.2, shadow = false })
	end
	-- The chest the necklace was taken from (copper bands)
	Kit.box(m, "Chest", -23.8, 0, 6.6, -22.2, 1.6, 8.6, Palette.woodDark, M.Wood)
	Kit.box(m, "ChestBand", -23.85, 0.6, 6.55, -22.15, 0.85, 8.65, Palette.copper, M.Metal)
	Kit.box(m, "ChestLid", -23.9, 1.6, 6.5, -22.1, 1.8, 8.7, Palette.wood, M.WoodPlanks)
	-- Brass scale on a low table
	Kit.box(m, "Table", -23.6, 0, 11, -22.2, 2.4, 13, Palette.wood, M.WoodPlanks)
	Kit.column(m, "ScalePost", Vector3.new(-22.9, 2.4, 12), 1.2, 0.12, Palette.copper, M.Metal, false)
	Kit.box(m, "ScaleArm", -22.95, 3.55, 11.2, -22.85, 3.65, 12.8, Palette.copper, M.Metal).CanCollide = false
	for _, z in { 11.3, 12.7 } do
		Kit.disc(m, "ScalePan", Vector3.new(-22.9, 3.0, z), 0.7, 0.08, Palette.copper, M.Metal, false)
	end
end

function Shops.build(map: Instance)
	bakery(map)
	tailor(map)
	spiceShop(map)
end

return Shops
