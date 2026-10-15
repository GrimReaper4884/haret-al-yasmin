--!strict
-- Draws the attackers: the server simulates and sends spawn/death events plus a 10 Hz stream of
-- path distances; this controller builds a rig per enemy, moves it smoothly along the arena path
-- between updates, shows a health bar, and plays hit/ability effects and defeat poofs.

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
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local MatchController = require(script.Parent.MatchController)
local AudioController = require(script.Parent.AudioController)

local EnemyRenderController = {}

type Enemy = { model: Model, enemyId: string, dist: number, target: number, speed: number, hp: number, bar: Frame?, bob: number, boss: boolean, bornAt: number, missing: number }

local folder: Folder
local enemies: { [number]: Enemy } = {}
local towerPos: { [number]: Vector3 } = {}
local arenaPath: Path.Path? = nil
local origin: CFrame? = nil
local effects = 0

local function clear()
	for _, e in enemies do
		e.model:Destroy()
	end
	enemies = {}
	towerPos = {}
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
	local model = RigBuilder.build(folder, "Enemy_" .. e.id, def.visual)
	local rec: Enemy = { model = model, enemyId = e.enemyId, dist = 0, target = 0, speed = def.speed, hp = 1, bar = nil, bob = math.random() * 6, boss = def.boss == true, bornAt = os.clock(), missing = 0 }
	rec.bar = healthBar(model, rec.boss)
	enemies[e.id] = rec
	local x, z, ux, uz = Path.position(arenaPath :: Path.Path, 0)
	model:PivotTo(origin * CFrame.lookAt(Vector3.new(x, 0, z), Vector3.new(x + ux, 0, z + uz)))
end

local function poof(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			TweenService:Create(d, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1, Size = d.Size * 0.3 }):Play()
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
	if died then
		poof(rec.model)
	else
		rec.model:Destroy()
	end
end

-- A short neon streak from the defender to the target, coloured by rarity; abilities glow gold.
local function strike(from: Vector3, to: Vector3, color: Color3, ability: boolean)
	if effects > 40 then
		return
	end
	effects += 1
	local mid = (from + to) / 2 + Vector3.new(0, 2.5, 0)
	local len = (to - from).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = if ability then Theme.lira else color
	p.Size = Vector3.new(if ability then 0.5 else 0.18, if ability then 0.5 else 0.18, len)
	p.CFrame = CFrame.lookAt(mid, to + Vector3.new(0, 2.5, 0))
	p.Transparency = 0.1
	p.Parent = folder
	local t = TweenService:Create(p, TweenInfo.new(if ability then 0.35 else 0.15), { Transparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		p:Destroy()
		effects -= 1
	end)
	if ability then
		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Ball
		flash.Anchored = true
		flash.CanCollide = false
		flash.CanQuery = false
		flash.CastShadow = false
		flash.Material = Enum.Material.Neon
		flash.Color = Theme.lira
		flash.Size = Vector3.new(2, 2, 2)
		flash.CFrame = CFrame.new(to + Vector3.new(0, 3, 0))
		flash.Parent = folder
		local ft = TweenService:Create(flash, TweenInfo.new(0.4), { Size = Vector3.new(9, 9, 9), Transparency = 1 })
		ft:Play()
		ft.Completed:Connect(function()
			flash:Destroy()
		end)
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
		elseif t == "towerSold" then
			towerPos[e.id] = nil
		elseif t == "attack" then
			local from = towerPos[e.tower]
			if from then
				local to = (origin * CFrame.new(e.x, 0, e.z)).Position
				local model = Workspace:FindFirstChild("Arenas")
				local unitId = nil
				if model then
					for _, arena in model:GetChildren() do
						local towers = arena:FindFirstChild("Towers")
						local tm = towers and towers:FindFirstChild("Tower_" .. e.tower)
						if tm then
							unitId = tm:GetAttribute("UnitId")
						end
					end
				end
				local def = if type(unitId) == "string" then (Units :: any)[unitId] else nil
				strike(from, to, if def then Theme.rarityColor(def.rarity) else Theme.colors.quest, e.ability == true)
				if e.ability then
					AudioController.sting("shabriyeh")
				end
			end
		end
	end
end

local function onPositions(packed: { number })
	if type(packed) ~= "table" then
		return
	end
	local seen = {}
	for i = 1, #packed - 2, 3 do
		local id, dist, hp = packed[i], packed[i + 1], packed[i + 2]
		local rec = enemies[id]
		if rec then
			rec.target = dist
			rec.hp = hp / 100
			seen[id] = true
			if rec.bar then
				rec.bar.Size = UDim2.fromScale(rec.hp, 1)
			end
		end
	end
	-- Anything the server stops reporting is gone (a missed event). The unreliable stream can
	-- overtake a fresh spawn event, so only give up after several packets and a short grace.
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
	for _, rec in enemies do
		-- Move toward the last reported distance, a little faster than the enemy so we catch up.
		local maxStep = rec.speed * speedMul * 1.35 * dt
		local delta = rec.target - rec.dist
		if delta > 0 then
			rec.dist += math.min(delta, maxStep)
		elseif delta < -2 then
			rec.dist = rec.target
		end
		rec.bob += dt * 10 * speedMul
		local x, z, ux, uz = Path.position(p, rec.dist)
		local bob = math.abs(math.sin(rec.bob)) * 0.25
		rec.model:PivotTo(o * CFrame.lookAt(Vector3.new(x, bob, z), Vector3.new(x + ux, bob, z + uz)))
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
