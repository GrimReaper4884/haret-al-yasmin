--!strict
-- Brings the figures to life on the client. Primitive figures (Util/RigBuilder) are jointed with
-- Motor6Ds; this writes their Transform every frame: an idle sway for placed defenders, a walk
-- cycle for attackers, and an attack swing (per role) that turns the defender toward its target.
-- Imported characters that carry an Animator and an "Anims" folder (Animation objects named
-- Idle / Walk / Attack) play those clips instead (docs/CHARACTER_PIPELINE.md).
--
-- Only models within ANIM_RADIUS of the camera are animated; nothing here touches the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Units = require(Shared.Config.Units)
local Looks = require(Shared.Config.CharacterLooks)
local MatchController = require(script.Parent.MatchController)

local RigAnimController = {}

local ANIM_RADIUS = 220
local ATTACK_TIME = 0.38

type Joints = { waist: Motor6D?, neck: Motor6D?, ls: Motor6D?, rs: Motor6D?, lh: Motor6D?, rh: Motor6D? }
type Rec = {
	model: Model,
	joints: Joints,
	phase: number,
	role: string,
	attackAt: number, -- os.clock() of the last swing, 0 = none
	yaw: number, -- current waist yaw (radians)
	targetYaw: number,
	tracks: { [string]: AnimationTrack }?,
}

local recs: { [Model]: Rec } = {}

local function findJoints(model: Model): Joints
	local j: Joints = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			if d.Name == "Waist" then
				j.waist = d
			elseif d.Name == "Neck" then
				j.neck = d
			elseif d.Name == "LeftShoulder" then
				j.ls = d
			elseif d.Name == "RightShoulder" then
				j.rs = d
			elseif d.Name == "LeftHip" then
				j.lh = d
			elseif d.Name == "RightHip" then
				j.rh = d
			end
		end
	end
	return j
end

-- Loads Idle / Walk / Attack clips for an imported character: ids from CharacterLooks[id].anims,
-- or Animation objects in an "Anims" folder inside the model.
local function loadTracks(model: Model): { [string]: AnimationTrack }?
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		return nil
	end
	local list: { Animation } = {}
	local lookId = model:GetAttribute("LookId")
	local look = if type(lookId) == "string" then (Looks :: any)[lookId] else nil
	if look and look.anims then
		for key, assetId in look.anims do
			local a = Instance.new("Animation")
			a.Name = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2) -- idle → Idle
			a.AnimationId = "rbxassetid://" .. tostring(assetId)
			table.insert(list, a)
		end
	end
	local folder = model:FindFirstChild("Anims")
	if folder then
		for _, a in folder:GetChildren() do
			if a:IsA("Animation") then
				table.insert(list, a)
			end
		end
	end
	if #list == 0 then
		return nil
	end
	local tracks = {}
	for _, a in list do
		local ok, track = pcall(function()
			return (animator :: Animator):LoadAnimation(a)
		end)
		if ok and track then
			tracks[a.Name] = track
			track.Looped = a.Name ~= "Attack"
			track.Priority = if a.Name == "Attack" then Enum.AnimationPriority.Action else Enum.AnimationPriority.Idle
		end
	end
	return tracks
end

local function track(model: Model, isTower: boolean): Rec
	local existing = recs[model]
	if existing then
		return existing
	end
	local unitId = model:GetAttribute("UnitId")
	local def = if type(unitId) == "string" then (Units :: any)[unitId] else nil
	local rec: Rec = {
		model = model,
		joints = findJoints(model),
		phase = math.random() * 10,
		role = if def then def.role else "melee",
		attackAt = 0,
		yaw = 0,
		targetYaw = 0,
		tracks = loadTracks(model),
	}
	recs[model] = rec
	model.Destroying:Connect(function()
		recs[model] = nil
	end)
	local tracks = rec.tracks
	if tracks then
		local loop = if isTower then tracks.Idle else (tracks.Walk or tracks.Idle)
		if loop then
			loop:Play()
		end
	end
	return rec
end

local function setT(m: Motor6D?, cf: CFrame)
	if m then
		m.Transform = cf
	end
end

-- 0 → 1 → 0 envelope with a fast wind-up and a snappy strike.
local function swing(k: number): (number, number)
	-- returns (windUp 0..1, strike 0..1)
	if k < 0.4 then
		return k / 0.4, 0
	elseif k < 0.6 then
		return 1, (k - 0.4) / 0.2
	else
		return 1 - (k - 0.6) / 0.4, 1 - (k - 0.6) / 0.4
	end
end

local function animateTower(rec: Rec, now: number, dt: number)
	local j = rec.joints
	local t = now + rec.phase
	-- Turn toward the last target, then drift back to facing the road.
	if now - rec.attackAt > 2.5 then
		rec.targetYaw = 0
	end
	rec.yaw += (rec.targetYaw - rec.yaw) * math.min(1, dt * 10)
	local breathe = math.sin(t * 1.6) * 0.025
	local sway = math.sin(t * 0.7) * 0.05
	local k = if rec.attackAt > 0 then (now - rec.attackAt) / ATTACK_TIME else 2
	local lean, rArm, lArm = 0, 0, 0
	if k < 1 then
		local up, hit = swing(k)
		local role = rec.role
		if role == "melee" then
			rArm = up * 2.6 - hit * 1.9
			lean = -hit * 0.25
		elseif role == "ranged" then
			rArm = up * 2.1 - hit * 1.0
			lean = up * 0.08 - hit * 0.15
		elseif role == "splash" then
			rArm = up * 2.8 - hit * 2.4
			lArm = rArm
			lean = -hit * 0.3
		else -- support / farm / healer: a raised, open hand
			rArm = up * 2.4
			lArm = up * 0.5
		end
	end
	setT(j.waist, CFrame.Angles(breathe + lean, rec.yaw + sway, 0))
	setT(j.neck, CFrame.Angles(math.sin(t * 0.9) * 0.05, math.sin(t * 0.45) * 0.15, 0))
	setT(j.rs, CFrame.Angles(rArm + math.sin(t * 1.6) * 0.04, 0, 0))
	setT(j.ls, CFrame.Angles(lArm - math.sin(t * 1.6) * 0.04, 0, 0))
	setT(j.lh, CFrame.identity)
	setT(j.rh, CFrame.identity)
end

local function animateEnemy(rec: Rec, now: number, speedMul: number)
	local j = rec.joints
	local t = (now + rec.phase) * 7 * speedMul
	local stride = math.sin(t) * 0.55
	setT(j.lh, CFrame.Angles(stride, 0, 0))
	setT(j.rh, CFrame.Angles(-stride, 0, 0))
	setT(j.ls, CFrame.Angles(-stride * 0.7, 0, 0))
	setT(j.rs, CFrame.Angles(stride * 0.7 + 0.25, 0, 0))
	setT(j.waist, CFrame.Angles(-0.08, math.sin(t) * 0.08, 0))
	setT(j.neck, CFrame.Angles(0.05, -math.sin(t) * 0.06, 0))
end

local function towerFolders(): { Instance }
	local out = {}
	local arenas = Workspace:FindFirstChild("Arenas")
	if arenas then
		for _, arena in arenas:GetChildren() do
			local towers = arena:FindFirstChild("Towers")
			if towers then
				table.insert(out, towers)
			end
		end
	end
	return out
end

local function findTower(towerId: number): Model?
	for _, folder in towerFolders() do
		local m = folder:FindFirstChild("Tower_" .. towerId)
		if m and m:IsA("Model") then
			return m
		end
	end
	return nil
end

-- Plays the attack swing on a tower and turns it toward the world point `at`.
function RigAnimController.attack(towerId: number, at: Vector3?)
	local model = findTower(towerId)
	if not model then
		return
	end
	local rec = track(model, true)
	rec.attackAt = os.clock()
	local root = model.PrimaryPart
	if at and root then
		local l = root.CFrame:PointToObjectSpace(at)
		-- Figures face -Z; yaw is positive toward -X when looking down -Z.
		rec.targetYaw = math.clamp(math.atan2(-l.X, -l.Z), -1.2, 1.2)
	end
	local tracks = rec.tracks
	if tracks and tracks.Attack then
		tracks.Attack:Play(0.05)
	end
end

-- Level of detail: figures off screen are skipped, distant ones update every third frame
-- (a stride a few frames coarse is invisible past ~70 studs), the rest every frame.
local NEAR = 70
local frame = 0

local function visible(camera: Camera, pos: Vector3, camPos: Vector3): (boolean, boolean)
	local d = (pos - camPos).Magnitude
	if d > ANIM_RADIUS then
		return false, false
	end
	local _, onScreen = camera:WorldToViewportPoint(pos)
	if not onScreen then
		return false, false
	end
	return true, d > NEAR
end

local function step(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	frame += 1
	local camPos = camera.CFrame.Position
	local now = os.clock()
	local s = MatchController.state()
	local speedMul = if s and s.speed then s.speed else 1

	local i = 0
	for _, folder in towerFolders() do
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m.PrimaryPart and m:GetAttribute("Rigged") then
				i += 1
				local show, far = visible(camera, m.PrimaryPart.Position, camPos)
				if show and (not far or (frame + i) % 3 == 0) then
					animateTower(track(m, true), now, if far then dt * 3 else dt)
				end
			end
		end
	end
	local enemies = Workspace:FindFirstChild("EnemyRender")
	if enemies then
		for _, m in enemies:GetChildren() do
			if m:IsA("Model") and m.PrimaryPart and m:GetAttribute("Rigged") then
				i += 1
				local show, far = visible(camera, m.PrimaryPart.Position, camPos)
				if show and (not far or (frame + i) % 3 == 0) then
					animateEnemy(track(m, false), now, speedMul)
				end
			end
		end
	end
end

function RigAnimController.start()
	MatchController.Events:Connect(function(events: { any })
		local info = MatchController.info()
		if not info then
			return
		end
		local origin = CFrame.new(info.origin)
		for _, e in events do
			if e.type == "attack" and type(e.tower) == "number" then
				local at = if type(e.x) == "number" and type(e.z) == "number" then (origin * CFrame.new(e.x, 0, e.z)).Position else nil
				RigAnimController.attack(e.tower, at)
			end
		end
	end)
	RunService.RenderStepped:Connect(step)
end

return RigAnimController
