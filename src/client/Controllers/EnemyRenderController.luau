--!strict
-- Draws the attackers: the server simulates and sends spawn/death events plus a 10 Hz stream of
-- path distances; this controller builds a rig per enemy, moves it smoothly along the arena path
-- between updates, shows a health bar, and plays hit/ability effects and defeat poofs.
--
-- Movement is predicted: each enemy runs at the speed measured from its last updates and is pulled
-- gently toward the reported distance, instead of sprinting to each 10 Hz update and waiting
-- (which read as stop-go "lag").

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Enemies = require(Shared.Config.Enemies)
local Units = require(Shared.Config.Units)
local Arenas = require(Shared.Config.Arenas)
local Path = require(Shared.Logic.Path)
local RigBuilder = require(Shared.Util.RigBuilder)
local BoneAnim = require(Shared.Anim.BoneAnim)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local MatchController = require(script.Parent.MatchController)
local AudioController = require(script.Parent.AudioController)
local ThrowFx = require(script.Parent.ThrowFx)

local EnemyRenderController = {}

type Enemy = {
	model: Model,
	enemyId: string,
	dist: number, -- drawn distance along the path
	target: number, -- predicted server distance (advanced by vel between updates)
	vel: number, -- measured speed along the path (studs / s)
	lastAt: number?, -- os.clock() of the last position update
	lastDist: number,
	speed: number,
	hp: number,
	bar: Frame?,
	bob: number,
	boss: boolean,
	bornAt: number,
	missing: number,
	walks: boolean, -- baked walk clip: no synthetic bob
}

local folder: Folder
local enemies: { [number]: Enemy } = {}
local byModel: { [Model]: Enemy } = {}
local towerPos: { [number]: Vector3 } = {}
local towerUnit: { [number]: string } = {}
local arenaPath: Path.Path? = nil
local origin: CFrame? = nil

local function clear()
	for _, e in enemies do
		e.model:Destroy()
	end
	enemies = {}
	byModel = {}
	towerPos = {}
	towerUnit = {}
end

local function healthBar(model: Model, boss: boolean): Frame
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	local gui = Create("BillboardGui", {
		Adornee = head,
		Size = UDim2.fromOffset(if boss then 90 else 44, if boss then 10 else 6),
		StudsOffset = Vector3.new(0, if boss then 3.4 else 1.6, 0),
		MaxDistance = 140,
		AlwaysOnTop = false,
		LightInfluence = 0,
		Parent = model,
	})
	local back = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = gui })
	local fill = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = if boss then Theme.colors.danger else Theme.colors.quest, BorderSizePixel = 0, Parent = back })
	return fill
end

local function spawn(e: any)
	local def = (Enemies :: any)[e.enemyId]
	if not def or not origin or enemies[e.id] then
		return
	end
	local model = RigBuilder.cached(folder, "Enemy_" .. e.id, def.visual, e.enemyId)
	local rec: Enemy = {
		model = model,
		enemyId = e.enemyId,
		dist = 0,
		target = 0,
		vel = def.speed,
		lastAt = nil,
		lastDist = 0,
		speed = def.speed,
		hp = 1,
		bar = nil,
		bob = math.random() * 6,
		boss = def.boss == true,
		bornAt = os.clock(),
		missing = 0,
		walks = model:GetAttribute("Imported") == true and BoneAnim.has(e.enemyId),
	}
	rec.bar = healthBar(model, rec.boss)
	if def.stealth then
		-- Stealth enemies are drawn see-through: only defenders that "see hidden thieves" can hit them
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "Root" then
				d.Transparency = math.max(d.Transparency, 0.55)
			end
		end
	end
	enemies[e.id] = rec
	byModel[model] = rec
	local x, z, ux, uz = Path.position(arenaPath :: Path.Path, 0)
	model:PivotTo(origin * CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(x + ux, 0, z + uz)))
end

local function poof(model: Model)
	if not Fx.full() then
		model:Destroy()
		return
	end
	-- Shrinking a skinned mesh doesn't move its bones, so imported figures would stretch; fade only
	local skinned = model:FindFirstChildWhichIsA("Bone", true) ~= nil
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			local goal = if skinned then { Transparency = 1 } else { Transparency = 1, Size = d.Size * 0.3 }
			TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), goal):Play()
		end
	end
	task.delay(0.4, function()
		model:Destroy()
	end)
end

local function remove(id: number, died: boolean)
	local rec = enemies[id]
	if not rec then
		return
	end
	enemies[id] = nil
	byModel[rec.model] = nil
	if died then
		poof(rec.model)
	else
		rec.model:Destroy()
	end
end

-- A short neon streak from the defender to the target, coloured by rarity; abilities glow gold.
-- Parts come from the shared Fx pool; the Effects setting trims what is drawn.
local function strike(from: Vector3, to: Vector3, color: Color3, ability: boolean)
	local level = Fx.level()
	if level == "off" and not ability then
		return
	end
	local p = Fx.part()
	if not p then
		return
	end
	local mid = (from + to) / 2 + Vector3.new(0, 2.5, 0)
	local len = (to - from).Magnitude
	p.Color = if ability then Theme.lira else color
	p.Size = Vector3.new(if ability then 0.5 else 0.18, if ability then 0.5 else 0.18, len)
	p.CFrame = CFrame.lookAt(mid, to + Vector3.new(0, 2.5, 0))
	p.Transparency = 0.1
	Fx.fade(p, if ability then 0.35 else 0.15, { Transparency = 1 }, Enum.EasingStyle.Linear)
	if ability and level ~= "off" then
		local flash = Fx.part(Enum.PartType.Ball)
		if flash then
			flash.Color = Theme.lira
			flash.Size = Vector3.new(2, 2, 2)
			flash.CFrame = CFrame.new(to + Vector3.new(0, 3, 0))
			Fx.fade(flash, 0.4, { Size = Vector3.new(9, 9, 9), Transparency = 1 })
		end
	end
end

-- Ultimate strikes in the world, per kind (pooled parts; Effects "full" only):
-- shabriyeh = two crossing blade flashes over the target; sweep = a ground ring that runs out
-- from the defender to its radius, with a dust disc under it.
local function ultimateStrike(kind: string, from: Vector3, to: Vector3, radius: number, color: Color3)
	if not Fx.full() then
		return
	end
	if kind == "shabriyeh" then
		for _, angle in { 35, -35 } do
			local blade = Fx.part()
			if blade then
				blade.Color = Color3.new(1, 1, 1):Lerp(color, 0.3)
				blade.Size = Vector3.new(0.25, 0.25, 1)
				blade.CFrame = CFrame.new(to + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(angle), math.rad(angle))
				Fx.fade(blade, 0.35, { Size = Vector3.new(0.12, 0.12, 9), Transparency = 1 }, Enum.EasingStyle.Quart)
			end
		end
	elseif kind == "sweep" then
		local ring = Fx.part(Enum.PartType.Cylinder)
		if ring then
			ring.Color = color
			ring.Transparency = 0.2
			ring.Size = Vector3.new(0.3, 2, 2)
			ring.CFrame = CFrame.new(from + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
			Fx.fade(ring, 0.5, { Size = Vector3.new(0.3, radius * 2, radius * 2), Transparency = 1 })
		end
		local dust = Fx.part(Enum.PartType.Cylinder)
		if dust then
			dust.Material = Enum.Material.SmoothPlastic
			dust.Color = Color3.fromHex("#C9B48F")
			dust.Transparency = 0.4
			dust.Size = Vector3.new(1.2, 3, 3)
			dust.CFrame = CFrame.new(from + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
			Fx.fade(dust, 0.8, { Size = Vector3.new(0.2, radius * 1.6, radius * 1.6), Transparency = 1 })
		end
	end
end

local function onEvents(events: { any })
	if not origin or not arenaPath then
		return
	end
	for _, e in events do
		local t = e.type
		if t == "spawn" then
			spawn(e)
		elseif t == "death" then
			remove(e.id, true)
		elseif t == "reached" then
			remove(e.id, false)
			AudioController.sting("gate_hit")
		elseif t == "towerPlaced" then
			towerPos[e.id] = (origin * CFrame.new(e.x, 0, e.z)).Position
			towerUnit[e.id] = e.unitId
		elseif t == "towerSold" then
			towerPos[e.id] = nil
			towerUnit[e.id] = nil
		elseif t == "attack" then
			local from = towerPos[e.tower]
			if from then
				local to = (origin * CFrame.new(e.x, 0, e.z)).Position
				local unitId = towerUnit[e.tower]
				local def = if type(unitId) == "string" then (Units :: any)[unitId] else nil
				local color = if def then Theme.rarityColor(def.rarity) else Theme.colors.quest
				-- A thrown prop (ThrowFx, launched by RigAnimController) replaces the streak, and
				-- an ultimate's flash then waits for it to land (EnemyRenderController.ultimateAt).
				local thrown = ThrowFx.kindFor(unitId, if e.ability then "ability" else "attack") ~= nil
				if not thrown then
					strike(from, to, color, e.ability == true)
				end
				if e.ability then
					AudioController.sting("shabriyeh")
					local ab = def and def.ability
					if ab and not thrown then
						ultimateStrike(ab.kind, from, to, ab.radius or 9, color)
					end
				end
			end
		end
	end
end

-- A round of positions arrives as several packets sharing one send number (MatchService
-- caps packet size). The round's enemies are collected and checked once the next round starts.
local roundSeq = -1
local roundSeen: { [number]: boolean } = {}

-- Anything the server stops reporting is gone (a missed event). The unreliable stream can
-- overtake a fresh spawn event, so only give up after several rounds and a short grace.
local function sweep(seen: { [number]: boolean })
	local now = os.clock()
	for id, rec in enemies do
		if seen[id] then
			rec.missing = 0
		elseif now - rec.bornAt > 0.6 then
			rec.missing += 1
			if rec.missing >= 4 then
				remove(id, false)
			end
		end
	end
end

local function onPositions(packed: { number })
	if type(packed) ~= "table" or type(packed[1]) ~= "number" then
		return
	end
	local seq = packed[1]
	if seq < roundSeq and roundSeq - seq < 1000 then
		return -- a late packet from an older round
	end
	if seq ~= roundSeq then
		if roundSeq >= 0 then
			sweep(roundSeen)
		end
		roundSeq = seq
		roundSeen = {}
	end
	for i = 2, #packed - 2, 3 do
		local id, dist, hp = packed[i], packed[i + 1], packed[i + 2]
		local rec = enemies[id]
		if rec then
			local now = os.clock()
			local last = rec.lastAt
			if last and now - last > 0.03 then
				local v = math.max(0, (dist - rec.lastDist) / (now - last))
				rec.vel = rec.vel * 0.6 + v * 0.4
			end
			if not last or now - last > 0.03 then
				rec.lastAt = now
				rec.lastDist = dist
			end
			rec.target = dist
			rec.hp = hp / 100
			roundSeen[id] = true
			if rec.bar then
				rec.bar.Size = UDim2.fromScale(rec.hp, 1)
			end
		end
	end
end

local function step(dt: number)
	local o = origin
	local p = arenaPath
	if not o or not p then
		return
	end
	local speedMul = 1
	local s = MatchController.state()
	if s and s.speed then
		speedMul = s.speed
	end
	-- Only the anchored Root moves; every other part hangs off it on joints. One BulkMoveTo for the
	-- whole wave instead of a PivotTo (which writes every part) per enemy per frame.
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	for _, rec in enemies do
		-- Predict: the server distance keeps moving at the measured speed between updates; draw at
		-- that speed plus a gentle pull toward the prediction (never backwards, snap if far off).
		if rec.lastAt and os.clock() - rec.lastAt < 0.4 then
			rec.target += rec.vel * dt
		end
		local delta = rec.target - rec.dist
		if math.abs(delta) > 8 then
			rec.dist = rec.target
		else
			rec.dist += math.max(0, rec.vel * dt + delta * math.min(1, dt * 4))
		end
		rec.bob += dt * 10 * speedMul
		local x, z, ux, uz = Path.position(p, rec.dist)
		local bob = if rec.walks then 0 else math.abs(math.sin(rec.bob)) * 0.25
		local root = rec.model.PrimaryPart
		if root then
			table.insert(parts, root)
			table.insert(cframes, o * CFrame.lookAt(Vector3.new(x, bob, z), Vector3.new(x + ux, bob, z + uz)) * root.PivotOffset:Inverse())
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- How fast an enemy figure is moving along the path right now (studs / s), for walk-cycle speed.
function EnemyRenderController.speedOf(model: Model): number
	local rec = byModel[model]
	return if rec then rec.vel else 0
end

-- The ultimate's world strike for a tower's ability, at `to` (called when a thrown shibriyeh lands).
function EnemyRenderController.ultimateAt(towerId: number, to: Vector3)
	local from = towerPos[towerId]
	local unitId = towerUnit[towerId]
	local def = if type(unitId) == "string" then (Units :: any)[unitId] else nil
	local ab = def and def.ability
	if from and ab then
		ultimateStrike(ab.kind, from, to - Vector3.new(0, 2.2, 0), ab.radius or 9, Theme.rarityColor(def.rarity))
	end
end

function EnemyRenderController.start()
	folder = Instance.new("Folder")
	folder.Name = "EnemyRender"
	folder.Parent = Workspace
	MatchController.Started:Connect(function(info: MatchController.Info)
		clear()
		arenaPath = Path.build(Arenas[info.arenaId].path)
		origin = CFrame.new(info.origin)
	end)
	MatchController.Ended:Connect(function()
		task.delay(1, clear)
	end)
	MatchController.Events:Connect(onEvents)
	Net.unreliable(Net.Events.EnemyPositions).OnClientEvent:Connect(onPositions)
	RunService.RenderStepped:Connect(step)
end

return EnemyRenderController
