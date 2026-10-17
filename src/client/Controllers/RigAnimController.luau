--!strict
-- Brings the figures to life on the client. Primitive figures (Util/RigBuilder) are jointed with
-- Motor6Ds; this writes their Transform every frame: an idle sway for placed defenders, a walk
-- cycle for attackers, and an attack swing (per role) that turns the defender toward its target.
-- Imported characters with baked signature clips (Anim/Clips, tools/anim) are posed bone by bone
-- through Anim/BoneAnim: each character's own idle, attack and ultimate, a walk matched to the
-- enemy's real speed, a flinch when hit, and the thrown prop (ThrowFx) leaving the hand on the
-- clip's impact frame. Imported characters without baked clips fall back to published Animator
-- clips (CharacterLooks[id].anims or an "Anims" folder) (docs/CHARACTER_PIPELINE.md).
--
-- Only models within ANIM_RADIUS of the camera are animated; nothing here touches the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Units = require(Shared.Config.Units)
local Looks = require(Shared.Config.CharacterLooks)
local BoneAnim = require(Shared.Anim.BoneAnim)
local MatchController = require(script.Parent.MatchController)
local EnemyRenderController = require(script.Parent.EnemyRenderController)
local ThrowFx = require(script.Parent.ThrowFx)

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
	bone: BoneAnim.Player?, -- baked signature clips (preferred over tracks)
	retryAt: number?, -- imported figure whose bones / Animator hadn't arrived yet: try again then
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

-- Binds baked clips when this character has them. The importer's AnimationController is removed
-- (locally) so a stray Animator can never fight the bone writes.
local function bindBones(rec: Rec, isTower: boolean): boolean
	local model = rec.model
	local lookId = model:GetAttribute("LookId")
	if not model:GetAttribute("Imported") or type(lookId) ~= "string" or not BoneAnim.has(lookId) then
		return false
	end
	local p = BoneAnim.new(model, lookId)
	if not p then
		return false
	end
	for _, d in model:GetDescendants() do
		if d:IsA("AnimationController") then
			d:Destroy()
		end
	end
	BoneAnim.loop(p, if isTower then "idle" else "walk")
	rec.bone = p
	return true
end

local function playLoop(rec: Rec, isTower: boolean)
	local tracks = rec.tracks
	if tracks then
		local loop = if isTower then tracks.Idle else (tracks.Walk or tracks.Idle)
		if loop then
			loop:Play()
		end
	end
end

local function track(model: Model, isTower: boolean): Rec
	local existing = recs[model]
	if existing then
		-- With streaming, parts of an imported figure can arrive after its root; until its clips
		-- load it shows the raw T-pose, so keep trying instead of giving up on the first look.
		if existing.retryAt and os.clock() >= existing.retryAt then
			if bindBones(existing, isTower) then
				existing.retryAt = nil
			else
				existing.tracks = loadTracks(model)
				existing.retryAt = if existing.tracks then nil else os.clock() + 1
				playLoop(existing, isTower)
			end
		end
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
		tracks = nil,
	}
	if not bindBones(rec, isTower) then
		local lookId = model:GetAttribute("LookId")
		if model:GetAttribute("Imported") and type(lookId) == "string" and BoneAnim.has(lookId) then
			rec.retryAt = os.clock() + 0.5 -- bones not streamed in yet
		else
			rec.tracks = loadTracks(model)
			if not rec.tracks and model:GetAttribute("Imported") then
				rec.retryAt = os.clock() + 1
			end
		end
	end
	recs[model] = rec
	model.Destroying:Connect(function()
		recs[model] = nil
	end)
	playLoop(rec, isTower)
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

local function animateTower(rec: Rec, now: number, dt: number, smooth: boolean)
	local j = rec.joints
	local t = now + rec.phase
	-- Turn toward the last target, then drift back to facing the road.
	if now - rec.attackAt > 2.5 then
		rec.targetYaw = 0
	end
	rec.yaw += (rec.targetYaw - rec.yaw) * math.min(1, dt * 10)
	local bone = rec.bone
	if bone then
		bone.yaw = rec.yaw
		BoneAnim.step(bone, dt, smooth)
		return
	end
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

local function animateEnemy(rec: Rec, now: number, dt: number, speedMul: number, smooth: boolean)
	local bone = rec.bone
	if bone then
		-- Match the stride to how fast the figure really moves (slows, stuns, wave speed-ups).
		local v = EnemyRenderController.speedOf(rec.model)
		local authored = BoneAnim.walkSpeed(bone)
		local rate = if authored > 0.01 then math.clamp(v / authored, 0.15, 2.5) else speedMul
		BoneAnim.loop(bone, "walk", rate)
		BoneAnim.step(bone, dt, smooth)
		return
	end
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

local function enemyModel(id: number?): Model?
	local folder = Workspace:FindFirstChild("EnemyRender")
	local m = if folder and id then folder:FindFirstChild("Enemy_" .. id) else nil
	return if m and m:IsA("Model") then m else nil
end

-- A short flinch layered over the enemy's walk.
local function flinch(enemyId: number?)
	local m = enemyModel(enemyId)
	local rec = if m then recs[m] else nil
	local bone = if rec then rec.bone else nil
	if bone and not BoneAnim.busy(bone) then
		BoneAnim.play(bone, "hit", 1.4, 0.6)
	end
end

-- Where a thrown prop leaves: the right hand of an imported figure, else above the root.
local function handPosition(model: Model): Vector3
	local hand = model:FindFirstChild("RightHand", true)
	if hand and hand:IsA("Bone") then
		return hand.TransformedWorldCFrame.Position
	end
	local root = model.PrimaryPart
	return if root then root.Position + Vector3.new(0, 3, 0) else model:GetPivot().Position
end

-- Plays the attack (or ultimate) on a tower, turns it toward the world point `at`, and throws the
-- character's prop from the hand when the swing lands (the target flinches when it arrives).
function RigAnimController.attack(towerId: number, at: Vector3?, ability: boolean?, targetId: number?, damage: number?)
	-- The hit lands on the target with the flinch: number, spark, flash (EnemyRenderController.impact).
	local function landed()
		flinch(targetId)
		EnemyRenderController.impact(targetId, damage, ability == true, towerId)
	end
	local model = findTower(towerId)
	if not model then
		landed()
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
	local slot = if ability then "ability" else "attack"
	local unitId = model:GetAttribute("UnitId")
	local kind = ThrowFx.kindFor(if type(unitId) == "string" then unitId else nil, slot)
	local delay = 0
	local bone = rec.bone
	if bone then
		delay = BoneAnim.play(bone, slot, 1.15) or BoneAnim.play(bone, "attack", 1.15) or 0
	else
		local tracks = rec.tracks
		if tracks and tracks.Attack then
			tracks.Attack:Play(0.05)
		end
	end
	if kind and at then
		local target = at + Vector3.new(0, 2.2, 0)
		task.delay(delay, function()
			if model.Parent then
				if rec.bone then
					BoneAnim.thrown(rec.bone, slot, 0.7)
				end
				ThrowFx.throw(kind, handPosition(model), target, function()
					landed()
					if ability then
						EnemyRenderController.ultimateAt(towerId, target)
					end
				end)
			end
		end)
	else
		task.delay(delay, landed)
	end
end

-- Animates a figure outside the arena folders (the placement ghost) with its idle.
local extras: { [Model]: boolean } = {}
function RigAnimController.adopt(model: Model)
	extras[model] = true
	model.Destroying:Connect(function()
		extras[model] = nil
	end)
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
					animateTower(track(m, true), now, if far then dt * 3 else dt, not far)
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
					animateEnemy(track(m, false), now, if far then dt * 3 else dt, speedMul, not far)
				end
			end
		end
	end
	for m in extras do
		if m.Parent and m.PrimaryPart then
			animateTower(track(m, true), now, dt, true)
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
				RigAnimController.attack(e.tower, at, e.ability == true, if type(e.target) == "number" then e.target else nil, if type(e.damage) == "number" then e.damage else nil)
			end
		end
	end)
	RunService.RenderStepped:Connect(step)
	ThrowFx.start()
end

return RigAnimController
