--!strict
-- Builds a match arena (Config/Arenas) at a world offset: a cobbled road winding between
-- orchard walls and garden plots toward the lane gate, where the enemies must be stopped.
-- Everything is static primitives; towers and enemies are added by the match services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Arenas = require(Shared.Config.Arenas)
local Path = require(Shared.Logic.Path)
local World = script.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local Arena = {}

local ROAD_WIDTH = 7
local ORANGE = Color3.fromHex("#E8892B")
local POMEGRANATE = Color3.fromHex("#A8322A")

-- Road segments as boxes between consecutive path points, with round joints at corners.
local function road(m: Instance, origin: CFrame, pts: { { number } })
	for i = 1, #pts - 1 do
		local a = Vector3.new(pts[i][1], 0, pts[i][2])
		local b = Vector3.new(pts[i + 1][1], 0, pts[i + 1][2])
		local len = (b - a).Magnitude
		local mid = (a + b) / 2
		local cf = origin * CFrame.lookAt(mid, b) * CFrame.new(0, 0.05, 0)
		Kit.part(m, { name = "Road", size = Vector3.new(ROAD_WIDTH, 0.1, len + ROAD_WIDTH), cf = cf, color = Palette.stoneWarm, material = M.Cobblestone, shadow = false })
		-- kerb stones along both sides
		for _, side in { -1, 1 } do
			Kit.part(m, { name = "Kerb", size = Vector3.new(0.5, 0.35, len - ROAD_WIDTH), cf = cf * CFrame.new(side * (ROAD_WIDTH / 2 + 0.25), 0.15, 0), color = Palette.stoneLight, material = M.Limestone, shadow = false, collide = false })
		end
	end
	-- Start marker: a milestone where the road enters
	local s = origin * CFrame.new(pts[1][1], 0, pts[1][2])
	Kit.part(m, { name = "Milestone", size = Vector3.new(1, 2.4, 1), cf = s * CFrame.new(ROAD_WIDTH / 2 + 1.2, 1.2, 0), color = Palette.stoneLight, material = M.Limestone })
end

-- Orchard plots in the spaces the road doesn't use: low garden walls, trees, a well.
local function gardens(m: Instance, origin: CFrame, def: any, path: Path.Path, rng: Random)
	local b = def.bounds
	local sp = def.playerSpawn
	local step = 14
	local x = b[1] + step / 2
	while x < b[3] do
		local z = b[2] + step / 2
		while z < b[4] do
			local d = Path.distanceTo(path, x, z)
			local nearSpawn = math.abs(x - sp[1]) < 12 and math.abs(z - sp[2]) < 12
			if d > 9 and not nearSpawn then
				local r = rng:NextNumber()
				local pos = (origin * CFrame.new(x + rng:NextNumber(-2, 2), 0, z + rng:NextNumber(-2, 2))).Position
				if r < 0.45 then
					Props.tree(m, pos, if rng:NextNumber() < 0.5 then ORANGE else POMEGRANATE, rng:NextNumber(0.8, 1.1))
				elseif r < 0.6 then
					-- Low garden wall segment
					local horizontal = rng:NextNumber() < 0.5
					Kit.part(m, { name = "GardenWall", size = if horizontal then Vector3.new(9, 1.6, 0.8) else Vector3.new(0.8, 1.6, 9), cf = CFrame.new(pos + Vector3.new(0, 0.8, 0)), color = Palette.stoneLight, material = M.Limestone, collide = false, shadow = false })
				elseif r < 0.7 then
					Props.crate(m, CFrame.new(pos), ORANGE)
				elseif r < 0.76 then
					Props.pot(m, pos, "jasmine", 1.1)
				end
			end
			z += step
		end
		x += step
	end
	-- A well near the middle of the field
	local wx, wz = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
	if Path.distanceTo(path, wx, wz) > 9 then
		local pos = (origin * CFrame.new(wx, 0, wz)).Position
		Kit.column(m, "WellRim", pos, 1.6, 4, Palette.basalt, M.Basalt)
		Kit.disc(m, "WellWater", pos + Vector3.new(0, 1.3, 0), 3.2, 0.2, Palette.water, M.Glass, false)
		for _, dx in { -1.6, 1.6 } do
			Kit.part(m, { name = "WellPost", size = Vector3.new(0.3, 4, 0.3), cf = CFrame.new(pos + Vector3.new(dx, 2, 0)), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
		end
		Kit.part(m, { name = "WellBeam", size = Vector3.new(3.8, 0.3, 0.3), cf = CFrame.new(pos + Vector3.new(0, 4, 0)), color = Palette.woodDark, material = M.Wood, collide = false, shadow = false })
	end
end

-- The quarter's wall and gate at the end of the road, facing the arriving enemies.
local function gate(m: Instance, origin: CFrame, def: any): Model
	local last = def.path[#def.path]
	local prev = def.path[#def.path - 1]
	-- Gate frame: on the ground at the end point; -Z (outward) faces back along the road
	local f = origin * CFrame.lookAt(Vector3.new(last[1], 0, last[2]), Vector3.new(prev[1], 0, prev[2]))
	-- Note Kit.faceFrame convention: LookVector = outward. CFrame.lookAt looks along -Z toward prev, so
	-- the road side is +Z here; flip so -Z faces the road like the other façade props.
	f = f * CFrame.Angles(0, math.rad(180), 0)
	local g = Kit.model(m, "GateWall")
	local W, H = 12, 13
	-- Wall running across, with the gate opening in the middle
	for _, side in { -1, 1 } do
		Kit.part(g, { name = "Wall", size = Vector3.new(34, 20, 4), cf = f * CFrame.new(side * (W / 2 + 17), 10, 2), color = Palette.stoneLight, material = M.Limestone })
		Kit.part(g, { name = "Pillar", size = Vector3.new(3, 19, 5), cf = f * CFrame.new(side * (W / 2 + 1.5), 9.5, 1.5), color = Palette.stoneWarm, material = M.Limestone })
		for _, y in { 3, 6, 9 } do
			Kit.part(g, { name = "Band", size = Vector3.new(3.1, 0.8, 5.1), cf = f * CFrame.new(side * (W / 2 + 1.5), y, 1.5), color = Palette.basalt, material = M.Basalt, shadow = false, collide = false })
		end
	end
	Kit.part(g, { name = "Arch", size = Vector3.new(W + 6, 6, 4), cf = f * CFrame.new(0, H + 3, 2), color = Palette.stoneLight, material = M.Limestone })
	Kit.part(g, { name = "Crown", size = Vector3.new(W + 8, 1.4, 5), cf = f * CFrame.new(0, H + 6.5, 2), color = Palette.stoneWarm, material = M.Limestone, shadow = false })
	for i = 1, 9 do
		local x = -W / 2 + (i - 0.5) * W / 9
		local lift = (1 - math.abs(x) / (W / 2)) * 1.2
		Kit.part(g, { name = "Voussoir", size = Vector3.new(W / 9, 1.4, 0.4), cf = f * CFrame.new(x, H + 0.7 + lift, -0.2), color = if i % 2 == 0 then Palette.basalt else Palette.stoneLight, material = if i % 2 == 0 then M.Basalt else M.Limestone, shadow = false, collide = false })
	end
	Props2.nameplate(g, f * CFrame.new(0, H + 4.2, -0.2), 9, "حارة الياسمين")
	Props.lantern(g, Kit.faceFrame((f * CFrame.new(-W / 2 - 1.5, 10, -0.2)).Position, -f.LookVector), 18)
	Props.lantern(g, Kit.faceFrame((f * CFrame.new(W / 2 + 1.5, 10, -0.2)).Position, -f.LookVector), 18)
	-- Rooftop parapet behind, so the wall reads as the edge of the quarter
	Kit.part(g, { name = "Roofs", size = Vector3.new(80, 14, 30), cf = f * CFrame.new(0, 7, 19), color = Palette.plaster, material = M.Plaster, collide = false, shadow = false })
	Kit.part(g, { name = "Roofs2", size = Vector3.new(40, 24, 20), cf = f * CFrame.new(18, 12, 26), color = Kit.tint(Palette.plaster, Kit.rng(def.seed), 0.08), material = M.Plaster, collide = false, shadow = false })
	-- The gate itself, closed and barred: this is what the enemies attack
	local doors = Props2.gate(g, f * CFrame.new(0, 0, 0), W, H, false)
	doors.Name = "Doors"
	local hp = Instance.new("Part")
	hp.Name = "GateAnchor"
	hp.Size = Vector3.new(1, 1, 1)
	hp.CFrame = f * CFrame.new(0, H + 1, -1)
	hp.Anchored = true
	hp.Transparency = 1
	hp.CanCollide = false
	hp.CanQuery = false
	hp.Parent = g
	g.PrimaryPart = hp
	return g
end

-- Builds the arena at `origin`. Returns the model and the gate model.
function Arena.build(parent: Instance, arenaId: string, origin: CFrame): (Model, Model)
	local def = Arenas[arenaId]
	assert(def, "unknown arena " .. arenaId)
	local m = Kit.model(parent, "Arena_" .. arenaId)
	local rng = Kit.rng(def.seed)
	local b = def.bounds
	-- Ground and an outer orchard wall ring (beyond bounds) so the field has an edge
	Kit.part(m, { name = "Ground", size = Vector3.new(b[3] - b[1] + 40, 1, b[4] - b[2] + 40), cf = origin * CFrame.new((b[1] + b[3]) / 2, -0.5, (b[2] + b[4]) / 2), color = Color3.fromHex("#9F8A5A"), material = M.Ground })
	Kit.part(m, { name = "Field", size = Vector3.new(b[3] - b[1], 0.08, b[4] - b[2]), cf = origin * CFrame.new((b[1] + b[3]) / 2, 0.01, (b[2] + b[4]) / 2), color = Color3.fromHex("#7F9A4A"), material = M.Grass, shadow = false })
	local w = 2.2
	Kit.part(m, { name = "WallN", size = Vector3.new(b[3] - b[1] + 8, 3, 1.2), cf = origin * CFrame.new((b[1] + b[3]) / 2, 1.5, b[4] + w), color = Palette.stoneLight, material = M.Limestone })
	Kit.part(m, { name = "WallS", size = Vector3.new(b[3] - b[1] + 8, 3, 1.2), cf = origin * CFrame.new((b[1] + b[3]) / 2, 1.5, b[2] - w), color = Palette.stoneLight, material = M.Limestone })
	Kit.part(m, { name = "WallW", size = Vector3.new(1.2, 3, b[4] - b[2] + 8), cf = origin * CFrame.new(b[1] - w, 1.5, (b[2] + b[4]) / 2), color = Palette.stoneLight, material = M.Limestone })
	Kit.part(m, { name = "WallE", size = Vector3.new(1.2, 3, b[4] - b[2] + 8), cf = origin * CFrame.new(b[3] + w, 1.5, (b[2] + b[4]) / 2), color = Palette.stoneLight, material = M.Limestone })
	-- Invisible tall fence so players can't leave the field
	for _, s in { { (b[1] + b[3]) / 2, b[4] + w, b[3] - b[1] + 8, 1 }, { (b[1] + b[3]) / 2, b[2] - w, b[3] - b[1] + 8, 1 }, { b[1] - w, (b[2] + b[4]) / 2, 1, b[4] - b[2] + 8 }, { b[3] + w, (b[2] + b[4]) / 2, 1, b[4] - b[2] + 8 } } do
		local fence = Kit.part(m, { name = "Fence", size = Vector3.new(s[3], 40, s[4]), cf = origin * CFrame.new(s[1], 20, s[2]), color = Palette.plaster, material = M.SmoothPlastic, transparency = 1, shadow = false })
		fence.CanQuery = false
	end
	local path = Path.build(def.path)
	road(m, origin, def.path)
	gardens(m, origin, def, path, rng)
	local g = gate(m, origin, def)
	-- Party spawn pad
	local sp = def.playerSpawn
	Kit.part(m, { name = "SpawnPad", size = Vector3.new(10, 0.3, 10), cf = origin * CFrame.new(sp[1], 0.15, sp[2]), color = Palette.stoneLight, material = M.Pavement, shadow = false })
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return m, g
end

return Arena
