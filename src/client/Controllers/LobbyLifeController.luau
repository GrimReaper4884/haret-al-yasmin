--!strict
-- Lobby life (POLISH_PLAN PV-E02), all on this client: washing that sways on its lines, jasmine
-- climbing six walls, a flock of birds over the square, spray and ripples in the fountain, steam
-- from Abu Hatem's samovar, Abu Baseer's oven flaring and puffing flour when you walk past, and
-- cats that turn to look at the nearest player. Numbers in Config/LobbyLife, math in
-- Logic/LobbyLife. Gated by the Lane life setting (off: nothing, lite: no particles; LP-D09) and by
-- distance: farther than `radius` from the camera, a piece holds still or switches off. The
-- server builds and simulates nothing for it.
--
-- The world streams (StreamingEnabled), so washing, cats and the oven are tracked as they stream
-- in and dropped as they stream out, like AmbienceController's lanterns.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cfg = require(Shared.Config.LobbyLife)
local LaneZones = require(Shared.Config.LaneZones)
local LaneZoneLogic = require(Shared.Logic.LaneZoneLogic)
local LobbyLife = require(Shared.Logic.LobbyLife)
local Vfx = require(Shared.Config.Vfx)
local Fx = require(script.Parent.Parent.UI.Fx)

local LobbyLifeController = {}

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local folder: Folder
local cloths: { [BasePart]: { base: CFrame, seed: number, moved: boolean } } = {}
local cats: { [Model]: boolean } = {}
local ovenLight: PointLight? = nil
local birds: { BasePart } = {}
local ripples: { BasePart } = {}
local vines: { { model: Model, at: Vector3 } } = {}
local spray: ParticleEmitter? = nil
local steams: { { e: ParticleEmitter, at: { number } } } = {} -- the samovar, and the hammam vent once built (LP-D04)
local lastPuff = -math.huge
local flaring = false

local function newPart(
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	return p
end

---------------------------------------------------------------- tracking streamed world pieces

local function track(d: Instance)
	if
		d:IsA("BasePart")
		and d.Name == "Cloth"
		and d.Parent
		and d.Parent.Name == "Laundry"
		and not cloths[d]
	then
		cloths[d] = { base = d.CFrame, seed = math.random() * 10, moved = false }
	elseif d:IsA("Model") and d.Name == "Cat" then
		cats[d] = true
	elseif d:IsA("PointLight") and d.Parent and d.Parent.Name == "Oven" then
		ovenLight = d
	end
end

local function untrack(d: Instance)
	if d:IsA("BasePart") then
		cloths[d] = nil
	elseif d:IsA("Model") then
		cats[d] = nil
	elseif d == ovenLight then
		ovenLight = nil
	end
end

---------------------------------------------------------------- client-built pieces

local function emitter(kind: string, at: Vector3, rate: number, color: Color3?): ParticleEmitter?
	local tex = (Vfx.TEXTURES :: any)[kind]
	if not tex or tex.id == 0 then
		return nil
	end
	local anchor =
		newPart("Emitter_" .. kind, Vector3.one * 0.2, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	anchor.Transparency = 1
	anchor.Position = at
	anchor.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Name = kind
	e.Texture = "rbxassetid://" .. tostring(tex.id)
	e.Rate = rate
	e.Enabled = false
	e.Lifetime = NumberRange.new(tex.life * 0.8, tex.life)
	e.LightEmission = tex.light
	if color then
		e.Color = ColorSequence.new(color)
	end
	e.Parent = anchor
	return e
end

local function buildFountain()
	local f = Cfg.fountain
	local e = emitter("shard", v3(f.spout), f.rate, Color3.fromHex(f.color))
	if e then
		-- Drops thrown up and out of the spout that fall back into the bowl
		e.Speed = NumberRange.new(3, 5)
		e.SpreadAngle = Vector2.new(35, 35)
		e.EmissionDirection = Enum.NormalId.Top
		e.Acceleration = Vector3.new(0, -16, 0)
		e.Lifetime = NumberRange.new(0.7, 0.9)
		e.Size = NumberSequence.new(0.35, 0.15)
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.8, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.LightEmission = 0.3
	end
	spray = e
	local r = f.ripples
	for k = 1, r.count do
		local ring = newPart(
			"Ripple",
			Vector3.new(0.05, r.from, r.from),
			Color3.fromHex(r.color),
			Enum.Material.Glass,
			Enum.PartType.Cylinder
		)
		ring.Transparency = 1
		local a = math.rad((k - 1) * 360 / r.count + 45) -- under each of the four streams
		ring.CFrame = CFrame.new(f.at[1] + math.cos(a) * r.ring, r.y, f.at[2] + math.sin(a) * r.ring)
			* CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = folder
		table.insert(ripples, ring)
	end
end

local function buildSteam(s: { at: { number }, rate: number })
	local e = emitter("steam", v3(s.at), s.rate)
	if e then
		e.Speed = NumberRange.new(0.8, 1.4)
		e.SpreadAngle = Vector2.new(12, 12)
		e.EmissionDirection = Enum.NormalId.Top
		e.Acceleration = Vector3.new(0.2, 0.6, 0)
		e.Size =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.8) })
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.6, 0.75),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-20, 20)
		table.insert(steams, { e = e, at = s.at })
	end
end

local function buildBirds()
	local b = Cfg.birds
	for _ = 1, b.count do
		local p = newPart("Bird", v3(b.size), Color3.fromHex(b.color), Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.Parent = folder
		table.insert(birds, p)
	end
end

-- One climbing jasmine: a leafy panel flush on the wall, two darker side tendrils and white
-- flower clusters, from the ground up to `height`.
local function buildVine(hitPos: Vector3, normal: Vector3, height: number, idx: number): Model
	local v = Cfg.vines
	local m = Instance.new("Model")
	m.Name = "Jasmine"
	local base = Vector3.new(hitPos.X, 0, hitPos.Z) + normal * 0.18
	local face = CFrame.lookAt(base, base + normal) -- -Z points out of the wall
	local leaf, dark, white = Color3.fromHex(v.leaf), Color3.fromHex(v.leafDark), Color3.fromHex(v.flower)
	local panel = newPart("Leaves", Vector3.new(v.width, height, 0.3), leaf, Enum.Material.Grass)
	panel.CFrame = face * CFrame.new(0, height / 2, 0)
	panel.Parent = m
	for _, side in { -1, 1 } do
		local tendril = newPart("Tendril", Vector3.new(0.5, height * 0.7, 0.32), dark, Enum.Material.Grass)
		tendril.CFrame = face
			* CFrame.new(side * (v.width / 2 + 0.4), height * 0.45, 0)
			* CFrame.Angles(0, 0, math.rad(side * -8))
		tendril.Parent = m
	end
	local crown =
		newPart("Crown", Vector3.new(v.width + 1.6, 1.4, 0.5), leaf, Enum.Material.Grass, Enum.PartType.Block)
	crown.CFrame = face * CFrame.new(0, height, 0)
	crown.Parent = m
	for k = 1, v.flowers do
		local fx = ((k * 0.618 + idx * 0.37) % 1 - 0.5) * (v.width + 0.8)
		local fy = height * (0.25 + 0.75 * (k / v.flowers))
		local flower =
			newPart("Flower", Vector3.one * 0.42, white, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		flower.CFrame = face * CFrame.new(fx, fy, -0.25)
		flower.Parent = m
	end
	return m
end

-- Casts for each vine's wall; a wall that hasn't streamed in yet is tried again a few times.
local function buildVines(map: Instance)
	local v = Cfg.vines
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	local pending: { [number]: boolean } = {}
	for i in v.spots do
		pending[i] = true
	end
	for _ = 1, 6 do
		for i in pending do
			local spot = v.spots[i]
			local from = v3(spot.from)
			local dir = Vector3.new(spot.dir[1], 0, spot.dir[2]).Unit * v.reach
			local hit = Workspace:Raycast(from, dir, params)
			if hit and math.abs(hit.Normal.Y) < 0.2 then
				local m = buildVine(hit.Position, hit.Normal, spot.height, i)
				table.insert(vines, { model = m, at = hit.Position })
				pending[i] = nil
			end
		end
		if next(pending) == nil then
			return
		end
		task.wait(5)
	end
end

---------------------------------------------------------------- per-frame

local function hideAll()
	for _, p in birds do
		p.Transparency = 1
	end
	for _, p in ripples do
		p.Transparency = 1
	end
end

local function turnCats(dt: number, cam: Vector3)
	local maxStep = math.rad(Cfg.cat.turnSpeed) * dt
	for cat in cats do
		local body = cat:FindFirstChild("Body")
		local head = cat:FindFirstChild("Head")
		if body and head and body:IsA("BasePart") and head:IsA("BasePart") then
			local c = body.Position
			if LobbyLife.near(c.X - cam.X, c.Y - cam.Y, c.Z - cam.Z, Cfg.radius) then
				local best: Vector3? = nil
				local bestD = Cfg.cat.reach
				for _, plr in Players:GetPlayers() do
					local char = plr.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if root and root:IsA("BasePart") then
						local d = (root.Position - c).Magnitude
						if d < bestD then
							best, bestD = root.Position, d
						end
					end
				end
				if best then
					local h = head.Position
					local current = LobbyLife.yawToward(c.X, c.Z, h.X, h.Z)
					local target = LobbyLife.yawToward(c.X, c.Z, best.X, best.Z)
					local step = LobbyLife.turnStep(current, target, maxStep)
					if math.abs(step) > 1e-4 then
						local pivot = CFrame.new(c.X, 0, c.Z)
						cat:PivotTo(pivot * CFrame.Angles(0, step, 0) * pivot:Inverse() * cat:GetPivot())
					end
				end
			end
		end
	end
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	local cam = if camera then camera.CFrame.Position else Vector3.zero
	local tier = LobbyLife.tier(Fx.laneLife())
	local now = os.clock()
	local R = Cfg.radius
	local parts: { BasePart } = {}
	local cfs: { CFrame } = {}

	-- Washing
	local l = Cfg.laundry
	for cloth, st in cloths do
		local p = st.base.Position
		if tier.motion and LobbyLife.near(p.X - cam.X, p.Y - cam.Y, p.Z - cam.Z, R) then
			local a = math.rad(LobbyLife.sway(now, st.seed, l.amp, l.hz))
			local hinge = cloth.Size.Y / 2
			table.insert(parts, cloth)
			table.insert(
				cfs,
				st.base * CFrame.new(0, hinge, 0) * CFrame.Angles(a, 0, 0) * CFrame.new(0, -hinge, 0)
			)
			st.moved = true
		elseif st.moved then
			table.insert(parts, cloth)
			table.insert(cfs, st.base)
			st.moved = false
		end
	end

	-- Birds
	local b = Cfg.birds
	local flockNear = tier.motion
		and LobbyLife.near(b.center[1] - cam.X, b.height - cam.Y, b.center[2] - cam.Z, R + b.radius)
	for i, p in birds do
		if flockNear then
			local x, y, z, yaw, roll = LobbyLife.bird(i, now, b)
			p.Transparency = 0
			table.insert(parts, p)
			table.insert(cfs, CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, roll))
		else
			p.Transparency = 1
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	-- Fountain and samovar
	local f = Cfg.fountain
	local fountainNear = LobbyLife.near(f.at[1] - cam.X, f.spout[2] - cam.Y, f.at[2] - cam.Z, R)
	local r = f.ripples
	for k, ring in ripples do
		if tier.motion and fountainNear then
			local ph = LobbyLife.ripple(now, k, r.count, r.period)
			local d = r.from + (r.to - r.from) * ph
			ring.Size = Vector3.new(0.05, d, d)
			ring.Transparency = r.transparency + (1 - r.transparency) * ph
		else
			ring.Transparency = 1
		end
	end
	if spray then
		spray.Enabled = tier.particles and fountainNear
	end
	for _, st in steams do
		local s = st.at
		st.e.Enabled = tier.particles and LobbyLife.near(s[1] - cam.X, s[2] - cam.Y, s[3] - cam.Z, R)
	end

	-- The oven: the local player walking past
	local o = Cfg.oven
	local light = ovenLight
	local me = Players.LocalPlayer.Character
	local root = me and me:FindFirstChild("HumanoidRootPart")
	if light and tier.motion and root and root:IsA("BasePart") then
		local dist = (root.Position - v3(o.mouth)).Magnitude
		if LobbyLife.ovenPuff(dist, now, lastPuff, o.trigger, o.cooldown) then
			lastPuff = now
			Fx.emit("dust", v3(o.puff), o.dust, Color3.fromHex(o.dustColor))
		end
	end
	if light then
		local mul = LobbyLife.flare(now - lastPuff, o.boost, o.flare)
		if mul > 1 then
			light:SetAttribute("Boost", mul)
			flaring = true
		elseif flaring then
			light:SetAttribute("Boost", nil)
			flaring = false
		end
	end

	if tier.motion then
		turnCats(dt, cam)
	end
end

local staticAcc = 0
local function updateStatic(dt: number)
	staticAcc += dt
	if staticAcc < 1 / Cfg.staticHz then
		return
	end
	staticAcc = 0
	local camera = Workspace.CurrentCamera
	local cam = if camera then camera.CFrame.Position else Vector3.zero
	local show = LobbyLife.tier(Fx.laneLife()).static
	for _, v in vines do
		local near = show and LobbyLife.near(v.at.X - cam.X, v.at.Y - cam.Y, v.at.Z - cam.Z, Cfg.radius)
		local want = if near then folder else nil
		if v.model.Parent ~= want then
			v.model.Parent = want
		end
	end
end

-- Counts for the debug overlay / play-test probes.
function LobbyLifeController.stats(): { [string]: number }
	local n = 0
	for _ in cloths do
		n += 1
	end
	local c = 0
	for _ in cats do
		c += 1
	end
	local shown = 0
	for _, v in vines do
		if v.model.Parent then
			shown += 1
		end
	end
	return { cloths = n, cats = c, birds = #birds, ripples = #ripples, vines = #vines, vinesShown = shown }
end

function LobbyLifeController.start()
	folder = Instance.new("Folder")
	folder.Name = "LobbyLife"
	folder.Parent = Workspace
	buildFountain()
	buildSteam(Cfg.steam)
	if LaneZoneLogic.built(LaneZones.zones, "hammam") then
		buildSteam(Cfg.hammamSteam)
	end
	buildBirds()
	for _, d in Workspace:GetDescendants() do
		track(d)
	end
	Workspace.DescendantAdded:Connect(track)
	Workspace.DescendantRemoving:Connect(untrack)
	task.spawn(function()
		local map = Workspace:WaitForChild("Map", 60)
		if map then
			-- Let the lane around the vines stream in before casting at its walls
			task.wait(3)
			buildVines(map)
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		updateStatic(dt)
		acc += dt
		if acc < 1 / Cfg.hz then
			return
		end
		local step = acc
		acc = 0
		update(step)
	end)
	hideAll()
end

return LobbyLifeController
