--!strict
-- The rooftops over the lane (LOOK_AND_PLAY_PLAN §4.1, LP-D07): set dressing only, nothing collides.
-- WestB's roof is Fawza's (she sits on its edge over the lane: Config/Npcs `fawza_roof`): a mat,
-- a washing line between two poles, a basket of washing, a water jar and pots. EastA's roof waits
-- for Feryal (her model is LP-D08): a washing line, a low stool, pots and a rolled mattress.
-- Fawza's calls and broom waves are the client's (RooftopController, Config/LobbyLife `rooftop`).
-- Built into `Zone_rooftop_view` by WorldService when Config/LaneZones marks it built.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local World = script.Parent.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local Rooftops = {}

local ROOF = 22.2 -- top of the lane blocks' parapet slab (Facade height 21 + 1.2)
local TERRACOTTA = Color3.fromHex("#B5643C")
local WICKER = Color3.fromHex("#B8925A")

-- Everything up here is out of reach and must never block a camera or a player.
local function ghostAll(m: Instance)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

local function line(m: Model, a: Vector3, b: Vector3, colors: { Color3 })
	for _, p in { a, b } do
		Kit.column(m, "Pole", Vector3.new(p.X, ROOF, p.Z), p.Y - ROOF + 0.3, 0.25, Palette.woodDark, M.Wood, false)
	end
	Props.laundry(m, a, b, colors)
end

local function fawzasRoof(m: Model)
	-- Her mat at the roof's lane edge (she sits at -8.6, 22.3, 44)
	Kit.box(m, "Mat", -11.2, ROOF, 42.4, -8.2, ROOF + 0.08, 45.6, Palette.fabricRed, M.Fabric)
	Kit.box(m, "MatStripe", -11.2, ROOF + 0.08, 43.6, -8.2, ROOF + 0.1, 44.4, Palette.jasmine, M.Fabric)
	line(m, Vector3.new(-20, ROOF + 4.2, 36), Vector3.new(-14, ROOF + 4.4, 48), { Palette.jasmine, Palette.fabricIndigo, Palette.jasmine, Palette.tile })
	Kit.column(m, "Basket", Vector3.new(-12.6, ROOF, 39.6), 1.1, 1.8, WICKER, M.Fabric, false)
	Kit.box(m, "BasketWash", -13.2, ROOF + 1.1, 39, -12, ROOF + 1.5, 40.2, Palette.jasmine, M.Fabric)
	Kit.column(m, "Jar", Vector3.new(-10, ROOF, 47.6), 1.5, 1.1, TERRACOTTA, M.Slate, false)
	Props.pot(m, Vector3.new(-9, ROOF, 36.5), "geranium", 0.9)
	Props.pot(m, Vector3.new(-9, ROOF, 49), "basil", 0.9)
end

local function feryalsRoof(m: Model)
	line(m, Vector3.new(14, ROOF + 4.2, 74), Vector3.new(20, ROOF + 4.4, 86), { Palette.fabricRed, Palette.jasmine, Color3.fromHex("#C9A13B") })
	Props2.stool(m, Vector3.new(10.6, ROOF, 80))
	Kit.part(m, { name = "Mattress", size = Vector3.new(2.6, 0.9, 0.9), cf = CFrame.new(18, ROOF + 0.45, 76.4), color = Palette.fabricIndigo, material = M.Fabric, shape = Enum.PartType.Cylinder, collide = false })
	Props.pot(m, Vector3.new(9, ROOF, 74), "jasmine", 0.9)
	Props.pot(m, Vector3.new(9, ROOF, 86.5), "geranium", 0.9)
end

function Rooftops.build(zone: Model)
	fawzasRoof(zone)
	feryalsRoof(zone)
	ghostAll(zone)
end

return Rooftops
