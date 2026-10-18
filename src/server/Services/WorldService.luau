--!strict
-- Builds the lane from primitives (docs/WORLD_MAP.md) using the modules in Server/World:
-- Kit (helpers), Props (doors, lattice bays, lanterns, trees…), Facade (buildings) and one module
-- per zone. If Workspace already has a "Map" model (a Studio-authored replacement), building is
-- skipped. Logs the part count so the mobile budget (docs/ART_BIBLE.md §9) stays visible.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
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
local PropDressing = require(World.PropDressing)

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

-- Lobby safety net (players reported climbing the façades and falling out of the map). Anyone in
-- the lobby area who is on the roofs or has dropped below the ground goes back to the gate spawn.
-- Arenas sit far out at x >= 3000, so they are never checked here.
local LOBBY_HALF_EXTENT = 400
local ROOF_Y = 17 -- root height; the highest walkable lobby floor is the ground (awnings ~10-12)
local FLOOR_Y = -12
local function watchBounds()
	while true do
		task.wait(0.5)
		local map = Workspace:FindFirstChild("Map")
		local spawn = map and map:FindFirstChild("GateSpawn", true) :: BasePart?
		if spawn then
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					local p = root.Position
					local inLobby = math.abs(p.X) < LOBBY_HALF_EXTENT and math.abs(p.Z) < LOBBY_HALF_EXTENT
					if inLobby and (p.Y > ROOF_Y or p.Y < FLOOR_Y) then
						root.AssemblyLinearVelocity = Vector3.zero
						character:PivotTo(spawn.CFrame * CFrame.new(0, 3.5, 0))
					end
				end
			end
		end
	end
end

function WorldService.build()
	Atmosphere.apply()
	task.spawn(watchBounds)
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
	PropDressing.dressLobby(map)
	PropDressing.swap(map)
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
