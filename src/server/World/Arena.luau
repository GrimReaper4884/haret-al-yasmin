--!strict
-- Builds a match arena (Config/Arenas) at a world offset: a cobbled road winding between
-- orchard walls and garden plots toward the lane gate, where the enemies must be stopped.
-- Everything is static primitives; towers and enemies are added by the match services.
-- PV-E03: each arena has a theme (Config/ArenaThemes: the orchard, or the Rival Lane's paved
-- street with house fronts all round), crates and sacks along the kerb, lanterns on wires across
-- the road, jasmine on the home wall and a night dust haze over the road (AmbienceController turns
-- it on at Effects full). Placement spots come from Logic/ArenaDressing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Palette = require(Shared.Config.Palette)
local Arenas = require(Shared.Config.Arenas)
local ArenaThemes = require(Shared.Config.ArenaThemes)
local Vfx = require(Shared.Config.Vfx)
local Path = require(Shared.Logic.Path)
local ArenaDressing = require(Shared.Logic.ArenaDressing)
local World = script.Parent
local Kit = require(World.Kit)
local Props = require(World.Props)
local Props2 = require(World.Props2)

local M = Kit.M

local Arena = {}

local ROAD_WIDTH = 7
local ORANGE = Color3.fromHex("#E8892B")
local POMEGRANATE = Color3.fromHex("#A8322A")

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

local function mat(name: string): Enum.Material
	return (Enum.Material :: any)[name] or M.SmoothPlastic
end

-- Kerb props and other dressing never block players.
local function decorative(model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
		end
	end
end

-- Road segments as boxes between consecutive path points, with round joints at corners.
local function road(m: Instance, origin: CFrame, pts: { { number } }, th: any)
	for i = 1, #pts - 1 do
		local a = Vector3.new(pts[i][1], 0, pts[i][2])
		local b = Vector3.new(pts[i + 1][1], 0, pts[i + 1][2])
		local len = (b - a).Magnitude
		local mid = (a + b) / 2
		local cf = origin * CFrame.lookAt(mid, b) * CFrame.new(0, 0.05, 0)
		Kit.part(m, { name = "Road", size = Vector3.new(ROAD_WIDTH, 0.1, len + ROAD_WIDTH), cf = cf, color = hex(th.road), material = M.Cobblestone, shadow = false })
		-- kerb stones along both sides
		for _, side in { -1, 1 } do
			Kit.part(m, { name = "Kerb", size = Vector3.new(0.5, 0.35, len - ROAD_WIDTH), cf = cf * CFrame.new(side * (ROAD_WIDTH / 2 + 0.25), 0.15, 0), color = hex(th.kerb), material = M.Limestone, shadow = false, collide = false })
		end
	end
	-- Start marker: a milestone where the road enters
	local s = origin * CFrame.new(pts[1][1], 0, pts[1][2])
	Kit.part(m, { name = "Milestone", size = Vector3.new(1, 2.4, 1), cf = s * CFrame.new(ROAD_WIDTH / 2 + 1.2, 1.2, 0), color = Palette.stoneLight, material = M.Limestone })
end

-- Orchard plots in the spaces the road doesn't use: low garden walls, trees, a well.
local function gardens(m: Instance, origin: CFrame, def: any, path: Path.Path, rng: Random, th: any)
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
				if not th.trees then
					-- The Rival Lane's paving: pots, low basalt walls, crates and copper jugs
					if r < 0.22 then
						Props.pot(m, pos, if rng:NextNumber() < 0.5 then "basil" else "geranium", 1.1)
					elseif r < 0.36 then
						local horizontal = rng:NextNumber() < 0.5
						Kit.part(m, { name = "LowWall", size = if horizontal then Vector3.new(8, 1.2, 0.8) else Vector3.new(0.8, 1.2, 8), cf = CFrame.new(pos + Vector3.new(0, 0.6, 0)), color = Palette.basalt, material = M.Basalt, collide = false, shadow = false })
					elseif r < 0.46 then
						Props.crate(m, CFrame.new(pos), hex(th.produce[1 + rng:NextInteger(0, #th.produce - 1)]))
					elseif r < 0.52 then
						Props.copperPot(m, pos, 1.2)
					end
				elseif r < 0.45 then
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
-- Climbing jasmine on the home wall either side of the gate. The wall slabs span local z 0..4 of
-- `f`; `toward` (+1 / -1) is the local Z side the road is on, so the vines sit on that face.
local function jasmine(g: Instance, f: CFrame, halfW: number, toward: number)
	local j = ArenaThemes.jasmine
	local leaf, white = hex(j.leaf), hex(j.flower)
	for _, side in { -1, 1 } do
		for k, off in j.offsets do
			local x = side * (halfW + off)
			local v = Kit.model(g, "Jasmine")
			local face = 2 + toward * 2
			Kit.part(v, { name = "Leaves", size = Vector3.new(j.width, j.height, 0.3), cf = f * CFrame.new(x, j.height / 2, face + toward * 0.15), color = leaf, material = M.Grass, collide = false, shadow = false })
			Kit.part(v, { name = "Crown", size = Vector3.new(j.width + 1.4, 1.3, 0.5), cf = f * CFrame.new(x, j.height, face + toward * 0.25), color = leaf, material = M.Grass, collide = false, shadow = false })
			for n = 1, j.flowers do
				local fx = ((n * 0.618 + k * 0.29) % 1 - 0.5) * (j.width + 0.6)
				local fy = j.height * (0.2 + 0.8 * n / j.flowers)
				Kit.ball(v, "Flower", (f * CFrame.new(x + fx, fy, face + toward * 0.4)).Position, 0.45, white, M.SmoothPlastic, false)
			end
		end
	end
end

local function gate(m: Instance, origin: CFrame, def: any, th: any): Model
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
		Kit.part(g, { name = "Wall", size = Vector3.new(34, 20, 4), cf = f * CFrame.new(side * (W / 2 + 17), 10, 2), color = hex(th.wall), material = M.Limestone })
		Kit.part(g, { name = "Pillar", size = Vector3.new(3, 19, 5), cf = f * CFrame.new(side * (W / 2 + 1.5), 9.5, 1.5), color = hex(th.gateStone), material = M.Limestone })
		for _, y in { 3, 6, 9 } do
			Kit.part(g, { name = "Band", size = Vector3.new(3.1, 0.8, 5.1), cf = f * CFrame.new(side * (W / 2 + 1.5), y, 1.5), color = Palette.basalt, material = M.Basalt, shadow = false, collide = false })
		end
	end
	Kit.part(g, { name = "Arch", size = Vector3.new(W + 6, 6, 4), cf = f * CFrame.new(0, H + 3, 2), color = hex(th.wall), material = M.Limestone })
	Kit.part(g, { name = "Crown", size = Vector3.new(W + 8, 1.4, 5), cf = f * CFrame.new(0, H + 6.5, 2), color = hex(th.gateStone), material = M.Limestone, shadow = false })
	for i = 1, 9 do
		local x = -W / 2 + (i - 0.5) * W / 9
		local lift = (1 - math.abs(x) / (W / 2)) * 1.2
		Kit.part(g, { name = "Voussoir", size = Vector3.new(W / 9, 1.4, 0.4), cf = f * CFrame.new(x, H + 0.7 + lift, -0.2), color = if i % 2 == 0 then Palette.basalt else Palette.stoneLight, material = if i % 2 == 0 then M.Basalt else M.Limestone, shadow = false, collide = false })
	end
	Props2.nameplate(g, f * CFrame.new(0, H + 4.2, -0.2), 9, "حارة الياسمين")
	local roadSide = f:PointToObjectSpace((origin * CFrame.new(prev[1], 0, prev[2])).Position).Z
	jasmine(g, f, W / 2 + 3, if roadSide >= 0 then 1 else -1)
	Props.lantern(g, Kit.faceFrame((f * CFrame.new(-W / 2 - 1.5, 10, -0.2)).Position, -f.LookVector), 18)
	Props.lantern(g, Kit.faceFrame((f * CFrame.new(W / 2 + 1.5, 10, -0.2)).Position, -f.LookVector), 18)
	-- Rooftops of the quarter behind the gate (f's -Z, away from the road), starting past the field's
	-- edge wall. They used to sit at +Z, on top of the last stretch of road, and swallowed the
	-- orchard's bread oven (player report "a building on top of the track and a furnace inside the wall").
	local b = def.bounds
	local ux, uz = last[1] - prev[1], last[2] - prev[2]
	local edge = if math.abs(ux) > math.abs(uz)
		then (if ux > 0 then b[3] - last[1] else last[1] - b[1])
		else (if uz > 0 then b[4] - last[2] else last[2] - b[2])
	local back = edge + 4 -- past the boundary wall (bounds + 2.2) with a little air
	Kit.part(g, { name = "Roofs", size = Vector3.new(80, 14, 30), cf = f * CFrame.new(0, 7, -(back + 15)), color = Palette.plaster, material = M.Plaster, collide = false, shadow = false })
	Kit.part(g, { name = "Roofs2", size = Vector3.new(40, 24, 20), cf = f * CFrame.new(18, 12, -(back + 18)), color = Kit.tint(Palette.plaster, Kit.rng(def.seed), 0.08), material = M.Plaster, collide = false, shadow = false })
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

-- Crates, sacks and copper jugs along the kerb (Logic/ArenaDressing.kerbSpots).
local function kerbProps(m: Instance, origin: CFrame, def: any, th: any)
	local k = Kit.model(m, "KerbProps")
	local sack = hex(ArenaThemes.kerb.sack)
	for i, s in ArenaDressing.kerbSpots(def.path, ArenaThemes.kerb, def.playerSpawn) do
		local cf = origin * CFrame.new(s.x, 0, s.z) * CFrame.Angles(0, s.yaw, 0)
		local kind = i % 3
		if kind == 1 then
			Props.crate(k, cf, hex(th.produce[1 + (i % #th.produce)]))
		elseif kind == 2 then
			for n = 0, 1 do
				local p = (cf * CFrame.new(0, 0, (n - 0.5) * 1.3)).Position
				Kit.column(k, "Sack", p, 1.3 - n * 0.2, 1.1, sack, M.Fabric, false)
				Kit.ball(k, "SackTie", p + Vector3.new(0, 1.35 - n * 0.2, 0), 0.5, sack, M.Fabric, false)
			end
		else
			Props.copperPot(k, cf.Position, 1.1)
		end
	end
	decorative(k)
end

-- Lanterns hanging on wires across the road (Config/Arenas `wires`).
local function wires(m: Instance, origin: CFrame, def: any)
	local w = ArenaThemes.wires
	for _, spot in def.wires or {} do
		local ax, az, bx, bz, mx, mz = ArenaDressing.wire(def.path, spot.seg, spot.t, w.inset)
		local g = Kit.model(m, "WireLantern")
		local a = (origin * CFrame.new(ax, 0, az)).Position
		local b = (origin * CFrame.new(bx, 0, bz)).Position
		Kit.column(g, "Post", a, w.height + 0.6, 0.45, Palette.woodDark, M.Wood, false)
		Kit.column(g, "Post", b, w.height + 0.6, 0.45, Palette.woodDark, M.Wood, false)
		local top = Vector3.new(0, w.height, 0)
		Kit.part(g, { name = "Wire", size = Vector3.new(0.08, 0.08, (b - a).Magnitude), cf = CFrame.lookAt((a + b) / 2 + top, b + top), color = Palette.woodDark, material = M.Fabric, collide = false, shadow = false })
		local mid = (origin * CFrame.new(mx, w.height, mz)).Position
		local chain = w.drop - 0.5
		Kit.part(g, { name = "Chain", size = Vector3.new(0.08, chain, 0.08), cf = CFrame.new(mid - Vector3.new(0, chain / 2, 0)), color = Palette.woodDark, material = M.Metal, collide = false, shadow = false })
		Kit.part(g, { name = "Cap", size = Vector3.new(0.9, 0.25, 0.9), cf = CFrame.new(mid - Vector3.new(0, chain, 0)), color = Palette.woodDark, material = M.Metal, collide = false, shadow = false })
		local glass = Kit.part(g, { name = "Glass", size = Vector3.new(0.75, 1, 0.75), cf = CFrame.new(mid - Vector3.new(0, w.drop, 0)), color = Color3.fromHex("#F2C46B"), material = M.Glass, collide = false, transparency = 0.15, shadow = false })
		local light = Instance.new("PointLight")
		light.Color = hex(w.color)
		light.Range = w.range
		light.Brightness = w.brightness
		light.Shadows = false
		light.Parent = glass
		g:SetAttribute("SwapProp", "hanging_lantern") -- PV-E04: the Meshy lantern hangs from the chain
		g:SetAttribute("SwapCFrame", CFrame.new(mid - Vector3.new(0, w.drop + 0.6, 0)))
		g:SetAttribute("SwapReplace", "Cap,Glass")
		decorative(g)
	end
end

-- The Rival Lane's house fronts outside the field wall (Logic/ArenaDressing.houseSpots).
local function houses(m: Instance, origin: CFrame, def: any, th: any, rng: Random)
	local h = ArenaThemes.houses
	local g = Kit.model(m, "Houses")
	local out = 2.2 + 1.2 + h.depth / 2
	for i, s in ArenaDressing.houseSpots(def.bounds, def.path, h.every, out, h.clearStart, h.clearEnd) do
		local height = h.minH + rng:NextNumber() * (h.maxH - h.minH)
		local cf = origin * CFrame.new(s.x, 0, s.z) * CFrame.Angles(0, s.yaw, 0)
		local plaster = hex(h.plaster[1 + rng:NextInteger(0, #h.plaster - 1)])
		Kit.part(g, { name = "House", size = Vector3.new(h.every - 1.2, height, h.depth), cf = cf * CFrame.new(0, height / 2, 0), color = plaster, material = M.Plaster, shadow = false })
		Kit.part(g, { name = "Windows", size = Vector3.new(h.every * 0.55, 1.6, 0.1), cf = cf * CFrame.new(0, height * 0.62, -h.depth / 2 - 0.05), color = hex(h.window), material = M.SmoothPlastic, collide = false, shadow = false })
		Kit.part(g, { name = "Cornice", size = Vector3.new(h.every - 0.8, 0.6, h.depth + 0.4), cf = cf * CFrame.new(0, height + 0.3, 0), color = hex(th.wallBand or th.wall), material = M.Basalt, collide = false, shadow = false })
		if i % h.lanternEvery == 0 then
			Props.lantern(g, Kit.faceFrame((cf * CFrame.new(0, 7, -h.depth / 2)).Position, cf.LookVector))
		end
	end
end

-- A low dust haze drifting over each stretch of road; built disabled, AmbienceController enables it
-- at Effects full near the camera (matches are at night).
local function haze(m: Instance, origin: CFrame, pts: { { number } })
	local tex = (Vfx.TEXTURES :: any).smoke
	if not tex or tex.id == 0 then
		return
	end
	local hz = ArenaThemes.haze
	local g = Kit.model(m, "RoadHaze")
	for i = 1, #pts - 1 do
		local a = Vector3.new(pts[i][1], 0, pts[i][2])
		local b = Vector3.new(pts[i + 1][1], 0, pts[i + 1][2])
		local len = (b - a).Magnitude
		local p = Kit.part(g, { name = "Haze", size = Vector3.new(ROAD_WIDTH, 0.4, len), cf = origin * CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, hz.y, 0), color = Palette.plaster, material = M.SmoothPlastic, transparency = 1, collide = false, shadow = false })
		p.CanQuery = false
		p.CanTouch = false
		local e = Instance.new("ParticleEmitter")
		e.Name = "Haze"
		e.Texture = "rbxassetid://" .. tostring(tex.id)
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.Rate = hz.rate * len
		e.Lifetime = NumberRange.new(hz.lifetime * 0.8, hz.lifetime)
		e.Speed = NumberRange.new(0, hz.speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new(hz.size * 0.6, hz.size)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, hz.transparency),
			NumberSequenceKeypoint.new(0.7, hz.transparency),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-6, 6)
		e.Color = ColorSequence.new(hex(hz.color))
		e.LightInfluence = 1
		e.Enabled = false
		e:SetAttribute("AmbientHaze", true)
		e.Parent = p
	end
end

-- Builds the arena at `origin`. Returns the model and the gate model.
function Arena.build(parent: Instance, arenaId: string, origin: CFrame): (Model, Model)
	local def = Arenas[arenaId]
	assert(def, "unknown arena " .. arenaId)
	local m = Kit.model(parent, "Arena_" .. arenaId)
	local rng = Kit.rng(def.seed)
	local th = ArenaThemes.themes[def.theme] or ArenaThemes.themes.orchard
	local b = def.bounds
	-- Ground and an outer orchard wall ring (beyond bounds) so the field has an edge
	Kit.part(m, { name = "Ground", size = Vector3.new(b[3] - b[1] + 40, 1, b[4] - b[2] + 40), cf = origin * CFrame.new((b[1] + b[3]) / 2, -0.5, (b[2] + b[4]) / 2), color = hex(th.ground), material = mat(th.groundMaterial) })
	Kit.part(m, { name = "Field", size = Vector3.new(b[3] - b[1], 0.08, b[4] - b[2]), cf = origin * CFrame.new((b[1] + b[3]) / 2, 0.01, (b[2] + b[4]) / 2), color = hex(th.field), material = mat(th.fieldMaterial), shadow = false })
	local w = 2.2
	Kit.part(m, { name = "WallN", size = Vector3.new(b[3] - b[1] + 8, 3, 1.2), cf = origin * CFrame.new((b[1] + b[3]) / 2, 1.5, b[4] + w), color = hex(th.wall), material = M.Limestone })
	Kit.part(m, { name = "WallS", size = Vector3.new(b[3] - b[1] + 8, 3, 1.2), cf = origin * CFrame.new((b[1] + b[3]) / 2, 1.5, b[2] - w), color = hex(th.wall), material = M.Limestone })
	Kit.part(m, { name = "WallW", size = Vector3.new(1.2, 3, b[4] - b[2] + 8), cf = origin * CFrame.new(b[1] - w, 1.5, (b[2] + b[4]) / 2), color = hex(th.wall), material = M.Limestone })
	Kit.part(m, { name = "WallE", size = Vector3.new(1.2, 3, b[4] - b[2] + 8), cf = origin * CFrame.new(b[3] + w, 1.5, (b[2] + b[4]) / 2), color = hex(th.wall), material = M.Limestone })
	if th.wallBand then
		-- A basalt band along the top of the outer wall
		for _, s in { { (b[1] + b[3]) / 2, b[4] + w, b[3] - b[1] + 8.1, 1.3 }, { (b[1] + b[3]) / 2, b[2] - w, b[3] - b[1] + 8.1, 1.3 }, { b[1] - w, (b[2] + b[4]) / 2, 1.3, b[4] - b[2] + 8.1 }, { b[3] + w, (b[2] + b[4]) / 2, 1.3, b[4] - b[2] + 8.1 } } do
			Kit.part(m, { name = "WallBand", size = Vector3.new(s[3], 0.5, s[4]), cf = origin * CFrame.new(s[1], 3.1, s[2]), color = hex(th.wallBand), material = M.Basalt, collide = false, shadow = false })
		end
	end
	-- Invisible tall fence so players can't leave the field
	for _, s in { { (b[1] + b[3]) / 2, b[4] + w, b[3] - b[1] + 8, 1 }, { (b[1] + b[3]) / 2, b[2] - w, b[3] - b[1] + 8, 1 }, { b[1] - w, (b[2] + b[4]) / 2, 1, b[4] - b[2] + 8 }, { b[3] + w, (b[2] + b[4]) / 2, 1, b[4] - b[2] + 8 } } do
		local fence = Kit.part(m, { name = "Fence", size = Vector3.new(s[3], 40, s[4]), cf = origin * CFrame.new(s[1], 20, s[2]), color = Palette.plaster, material = M.SmoothPlastic, transparency = 1, shadow = false })
		fence.CanQuery = false
	end
	local path = Path.build(def.path)
	road(m, origin, def.path, th)
	if th.gardens ~= false then
		gardens(m, origin, def, path, rng, th)
	end
	local g = gate(m, origin, def, th)
	kerbProps(m, origin, def, th)
	wires(m, origin, def)
	if th.houses then
		houses(m, origin, def, th, rng)
	end
	haze(m, origin, def.path)
	-- Party spawn pad
	local sp = def.playerSpawn
	Kit.part(m, { name = "SpawnPad", size = Vector3.new(10, 0.3, 10), cf = origin * CFrame.new(sp[1], 0.15, sp[2]), color = Palette.stoneLight, material = M.Pavement, shadow = false })
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return m, g
end

return Arena
