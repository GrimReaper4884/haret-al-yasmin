--!strict
-- Builds the lane from primitives (docs/WORLD_MAP.md) using the modules in Server/World:
-- Kit (helpers), Props (doors, lattice bays, lanterns, trees…), Facade (buildings) and one module
-- per zone. If Workspace already has a "Map" model (a Studio-authored replacement), building is
-- skipped. Logs the part count so the mobile budget (docs/ART_BIBLE.md §9) stays visible.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage:WaitForChild("Shared").Config.Palette)
local World = script.Parent.Parent:WaitForChild("World")
local Kit = require(World.Kit)
local Atmosphere = require(World.Atmosphere)
local Zones = World:WaitForChild("Zones")
local Lane = require(Zones.Lane)
local Shops = require(Zones.Shops)
local Square = require(Zones.Square)
local House = require(Zones.House)
local Skyline = require(Zones.Skyline)
local Extras = require(Zones.Extras)

local WorldService = {}

WorldService.PART_BUDGET = 6000

local function bounds(map: Instance)
	local m = Kit.model(map, "Bounds")
	-- Buildings enclose the play space; these close the gaps beside the gate, where the lane floor
	-- is wider than the buildings.
	for _, w in { { -9, 88, -8, 96 }, { 8, 88, 9, 96 } } do
		local p = Kit.box(m, "Bound", w[1], 0, w[2], w[3], 40, w[4], Palette.plaster, Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.CanQuery = false
		p.CastShadow = false
	end
end

function WorldService.build()
	Atmosphere.apply()
	if Workspace:FindFirstChild("Map") then
		return
	end
	local map = Instance.new("Model")
	map.Name = "Map"
	Lane.build(map)
	Shops.build(map)
	Square.build(map)
	House.build(map)
	Skyline.build(map)
	Extras.build(map)
	bounds(map)
	map.Parent = Workspace

	-- Remove the template's baseplate and spawn so players only spawn at the gate.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	for _, child in Workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	local parts = 0
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	local msg = string.format("[World] built %d parts (budget %d)", parts, WorldService.PART_BUDGET)
	if parts > WorldService.PART_BUDGET then
		warn(msg)
	else
		print(msg)
	end
end

return WorldService
