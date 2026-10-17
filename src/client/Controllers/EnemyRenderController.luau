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
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Enemies = require(Shared.Config.Enemies)
local Units = require(Shared.Config.Units)
local Arenas = require(Shared.Config.Arenas)
local Vfx = require(Shared.Config.Vfx)
local Path = require(Shared.Logic.Path)
local HitFx = require(Shared.Logic.HitFx)
local RigBuilder = require(Shared.Util.RigBuilder)
local BoneAnim = require(Shared.Anim.BoneAnim)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local Fx = require(UI.Fx)
local DamageNumbers = require(UI.DamageNumbers)
local CoinFlight = require(UI.CoinFlight)
local MatchController = require(script.Parent.MatchController)
local MatchCameraController = require(script.Parent.MatchCameraController)
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
	punchAt: number?, -- os.clock() of the last knockback nudge (PV-B02)
}

local folder: Folder
local enemies: { [number]: Enemy } = {}
local byModel: { [Model]: Enemy } = {}
local towerPos: { [number]: Vector3 } = {}
local towerUnit: { [number]: string } = {}
local arenaPath: Path.Path? = nil
local origin: CFrame? = nil
local selectedTower: number? = nil -- PlacementController tells us; its target gets the flash

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
		punchAt = nil,
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

-- Death poof (P2-17): jasmine petals for people, ash for bosses; no blood. Pooled parts, shrunk
-- to this frame's budget (Fx.allow); "reduced" draws two, "off" none.
local function deathPoof(at: Vector3, boss: boolean)
	if not Fx.any() then
		return
	end
	local cfg = Vfx.DEATH
	local wanted = if Fx.full() then cfg.petals else 2
	local n = Fx.allow(wanted)
	local colors = if boss then cfg.ashColors else cfg.petalColors
	local size = if boss then cfg.ashSize else cfg.petalSize
	for i = 1, n do
		local p = Fx.part(if boss then Enum.PartType.Ball else Enum.PartType.Block)
		if not p then
			break
		end
		p.Material = if boss then Enum.Material.SmoothPlastic else Enum.Material.Neon
		p.Color = Color3.fromHex(colors[((i - 1) % #colors) + 1])
		p.Size = Vector3.new(size, size * 0.3, size)
		p.Transparency = 0.1
		local angle = (i / n) * math.pi * 2 + math.random() * 0.8
		local start = at + Vector3.new(math.cos(angle) * 0.6, 1.8, math.sin(angle) * 0.6)
		p.CFrame = CFrame.new(start) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
		local goal = start + Vector3.new(math.cos(angle) * cfg.spread, cfg.rise * (0.6 + math.random() * 0.6), math.sin(angle) * cfg.spread)
		Fx.fade(p, cfg.life, {
			CFrame = CFrame.new(goal) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
			Transparency = 1,
		}, Enum.EasingStyle.Sine)
	end
end

-- A small spark where a strike lands (P2-17). One part; skipped under "reduced".
local function hitSpark(at: Vector3, color: Color3)
	if not Fx.full() then
		return
	end
	local s = Fx.part(Enum.PartType.Ball)
	if not s then
		return
	end
	s.Color = color:Lerp(Color3.new(1, 1, 1), 0.5)
	s.Size = Vector3.one * Vfx.HIT.size
	s.CFrame = CFrame.new(at + Vector3.new(0, 2.5, 0))
	s.Transparency = 0.15
	Fx.fade(s, Vfx.HIT.life, { Size = Vector3.one * Vfx.HIT.grow, Transparency = 1 })
end

-- A thief reached the gate: a red disc flashes on the ground at the path's end (P2-17).
local function gateHit()
	local o, path = origin, arenaPath
	if not Fx.any() or not o or not path then
		return
	end
	local x, z = Path.position(path, path.length)
	local disc = Fx.part(Enum.PartType.Cylinder)
	if not disc then
		return
	end
	local cfg = Vfx.GATE_HIT
	disc.Color = Color3.fromHex(cfg.color)
	disc.Transparency = 0.25
	disc.Size = Vector3.new(0.3, 2, 2)
	disc.CFrame = (o * CFrame.new(x, 0.25, z)) * CFrame.Angles(0, 0, math.rad(90))
	Fx.fade(disc, cfg.life, { Size = Vector3.new(0.3, cfg.radius * 2, cfg.radius * 2), Transparency = 1 })
end

-- Boss telegraph (P2-17): red rings pulse at the spawn end of the path while the boss banner shows,
-- then a shock ring where the boss steps in. Rings are "full" only; the spawn ring also "reduced".
local function bossRing(at: Vector3, radius: number, life: number)
	local ring = Fx.part(Enum.PartType.Cylinder)
	if not ring then
		return
	end
	ring.Color = Color3.fromHex(Vfx.BOSS.color)
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.4, 1.5, 1.5)
	ring.CFrame = CFrame.new(at + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	Fx.fade(ring, life, { Size = Vector3.new(0.4, radius * 2, radius * 2), Transparency = 1 })
end

local function bossTelegraph()
	local o, path = origin, arenaPath
	if not Fx.full() or not o or not path then
		return
	end
	local x, z = Path.position(path, 0)
	local at = (o * CFrame.new(x, 0, z)).Position
	task.spawn(function()
		for i = 1, Vfx.BOSS.pulses do
			if not MatchController.active() then
				return
			end
			bossRing(at, Vfx.BOSS.pulseRadius, Vfx.BOSS.pulseLife)
			if i < Vfx.BOSS.pulses then
				task.wait(Vfx.BOSS.pulseEvery)
			end
		end
	end)
end

-- Set by RigAnimController: plays a figure's `death` clip and returns its length in seconds (0 when
-- the figure has none), so the fade waits for the fall (PV-B03; the clips arrive in PV-A03).
local deathClip: ((Model) -> number)? = nil
function EnemyRenderController.setDeathClip(fn: (Model) -> number)
	deathClip = fn
end

-- A boss falls: a dust ring runs out from the body and the camera shakes briefly ("full" only).
local function bossFall(at: Vector3)
	if not Fx.full() then
		return
	end
	local cfg = Vfx.BOSS_DEATH
	local ring = Fx.part(Enum.PartType.Cylinder)
	if ring then
		ring.Material = Enum.Material.SmoothPlastic
		ring.Color = Color3.fromHex(cfg.dustColor)
		ring.Transparency = 0.35
		ring.Size = Vector3.new(0.6, 2, 2)
		ring.CFrame = CFrame.new(at + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
		Fx.fade(ring, cfg.ringLife, { Size = Vector3.new(0.2, cfg.ringRadius * 2, cfg.ringRadius * 2), Transparency = 1 })
	end
	MatchCameraController.shake(cfg.shake, cfg.amplitude)
end

local function fadeOut(model: Model)
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

-- Defeated: play the death clip if the figure has one (hold its length), then fade.
local function poof(model: Model)
	if not Fx.full() then
		model:Destroy()
		return
	end
	local hold = if deathClip then deathClip(model) else 0
	if hold > 0 then
		-- The model is out of `enemies` already, so nothing moves it while it falls.
		task.delay(hold, function()
			if model.Parent then
				fadeOut(model)
			end
		end)
	else
		fadeOut(model)
	end
end

-- `death` is the server event when the enemy was defeated (it carries cash and the owner).
local function remove(id: number, died: boolean, death: any?)
	local rec = enemies[id]
	if not rec then
		return
	end
	enemies[id] = nil
	byModel[rec.model] = nil
	if died then
		local at = rec.model:GetPivot().Position
		deathPoof(at, rec.boss)
		if rec.boss then
			bossFall(at)
		end
		-- Reward pop: your own kills fling a coin into the cash pill.
		local pill = MatchController.cashPill()
		if death and pill and Fx.any() and death.owner == Players.LocalPlayer.Name and (death.cash or 0) > 0 then
			CoinFlight.fly(at + Vector3.new(0, 3, 0), pill)
		end
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
	if not ability then
		hitSpark(to, color)
	end
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

-- Hit flash (PV-B02): a few pooled white Highlights, lent for HIT_FLASH.life to a boss or the
-- selected tower's target. When all are lent the flash is skipped (the number still shows).
local flashes: { Highlight } = {}
local flashFree: { Highlight } = {}

local function flash(model: Model)
	local cfg = Vfx.HIT_FLASH
	local hl: Highlight
	local reused = table.remove(flashFree)
	if reused then
		hl = reused
	else
		if #flashes >= cfg.max then
			return
		end
		hl = Create("Highlight", {
			Name = "HitFlash",
			FillColor = Color3.fromHex(cfg.color),
			FillTransparency = cfg.fill,
			OutlineTransparency = 1,
			DepthMode = Enum.HighlightDepthMode.Occluded,
			Enabled = false,
			Parent = folder,
		}) :: Highlight
		table.insert(flashes, hl)
	end
	hl.Adornee = model
	hl.Enabled = true
	task.delay(cfg.life, function()
		hl.Enabled = false
		hl.Adornee = nil
		table.insert(flashFree, hl)
	end)
end

-- Per-role impact where a hit lands (PV-B04, Config/Vfx.ROLES). `from` is the striker's position.
local function roleImpact(role: string, at: Vector3, from: Vector3?, radius: number?, thrown: boolean)
	local r = (Vfx.ROLES :: any)[role]
	if not r or r.kind == "none" or not Fx.full() then
		return
	end
	local color = Color3.fromHex(r.color)
	if r.kind == "arc" then
		-- A white blade sweep across the target, perpendicular to the blow, plus the spark.
		local blade = Fx.part()
		if blade then
			local dir = if from then Vector3.new(at.X - from.X, 0, at.Z - from.Z) else Vector3.new(0, 0, 1)
			dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, 1)
			local base = CFrame.lookAt(at + Vector3.new(0, 2.6, 0), at + Vector3.new(0, 2.6, 0) + dir)
			blade.Color = color
			blade.Transparency = 0.15
			blade.Size = Vector3.new(r.length, 0.12, 0.35)
			blade.CFrame = base * CFrame.Angles(0, 0, math.rad(-35))
			Fx.fade(blade, r.life, { CFrame = base * CFrame.Angles(0, 0, math.rad(35)), Transparency = 1 }, Enum.EasingStyle.Quart)
		end
		hitSpark(at, color)
	elseif r.kind == "puff" then
		if thrown then
			return -- the projectile's own landing puff (ThrowFx) already played
		end
		local b = Fx.part(Enum.PartType.Ball)
		if b then
			b.Material = Enum.Material.SmoothPlastic
			b.Color = color
			b.Transparency = 0.3
			b.Size = Vector3.one * r.size * 0.4
			b.CFrame = CFrame.new(at + Vector3.new(0, 2.2, 0))
			Fx.fade(b, r.life, { Size = Vector3.one * r.size, Transparency = 1 })
		end
	elseif r.kind == "ring" then
		local ring = Fx.part(Enum.PartType.Cylinder)
		if ring then
			ring.Material = Enum.Material.SmoothPlastic
			ring.Color = color
			ring.Transparency = 0.3
			ring.Size = Vector3.new(0.2, 1, 1)
			ring.CFrame = CFrame.new(at + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
			Fx.fade(ring, r.life, { Size = Vector3.new(0.1, r.radius * 2, r.radius * 2), Transparency = 1 })
		end
		for i = 1, Fx.allow(r.dust) do
			local d = Fx.part(Enum.PartType.Ball)
			if not d then
				break
			end
			local a = i * 2.1 + math.random()
			d.Material = Enum.Material.SmoothPlastic
			d.Color = Color3.fromHex(Vfx.SWEEP.dustColor)
			d.Transparency = 0.35
			d.Size = Vector3.one * 0.9
			d.CFrame = CFrame.new(at + Vector3.new(math.cos(a), 0.5, math.sin(a)))
			Fx.fade(d, r.life * 1.5, { Size = Vector3.one * 2.2, Transparency = 1, CFrame = CFrame.new(at + Vector3.new(math.cos(a) * 2, 1.8, math.sin(a) * 2)) })
		end
	elseif r.kind == "pulse" then
		local c = from or at
		local ring = Fx.part(Enum.PartType.Cylinder)
		if ring then
			ring.Material = Enum.Material.SmoothPlastic
			ring.Color = color
			ring.Transparency = 0.7
			ring.Size = Vector3.new(0.15, 2, 2)
			ring.CFrame = CFrame.new(c + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
			local rr = radius or 8
			Fx.fade(ring, r.life, { Size = Vector3.new(0.1, rr * 2, rr * 2), Transparency = 1 }, Enum.EasingStyle.Sine)
		end
	elseif r.kind == "sparkle" then
		for i = 1, Fx.allow(r.motes) do
			local m = Fx.part(Enum.PartType.Ball)
			if not m then
				break
			end
			local a = i * 1.6 + math.random()
			local start = at + Vector3.new(math.cos(a) * 0.8, 1.2 + math.random(), math.sin(a) * 0.8)
			m.Color = color
			m.Transparency = 0.1
			m.Size = Vector3.one * 0.35
			m.CFrame = CFrame.new(start)
			Fx.fade(m, r.life, { CFrame = CFrame.new(start + Vector3.new(0, r.rise, 0)), Transparency = 1, Size = Vector3.one * 0.15 }, Enum.EasingStyle.Sine)
		end
	end
end

-- A hit landed on enemy `enemyId` (RigAnimController calls this when the swing or thrown prop
-- arrives): the damage number, the spark, and a flash or a knockback nudge (Logic/HitFx).
function EnemyRenderController.impact(enemyId: number?, damage: number?, ability: boolean, towerId: number?)
	local rec = if enemyId then enemies[enemyId] else nil
	if not rec then
		return
	end
	local plan = HitFx.plan(Fx.level(), rec.boss, towerId ~= nil and towerId == selectedTower)
	local root = rec.model.PrimaryPart
	local at = if root then root.Position else rec.model:GetPivot().Position
	if plan.number and type(damage) == "number" and damage > 0 then
		DamageNumbers.show(at + Vector3.new(0, if rec.boss then 6 else 3.6, 0), damage, ability)
	end
	if plan.flash then
		flash(rec.model)
	elseif plan.punch then
		rec.punchAt = os.clock()
	end
	local unitId = if towerId then towerUnit[towerId] else nil
	local def = if type(unitId) == "string" then (Units :: any)[unitId] else nil
	if def then
		local slot = if ability then "ability" else "attack"
		roleImpact(def.role, (rec.model:GetPivot()).Position, if towerId then towerPos[towerId] else nil, def.levels[1].range, ThrowFx.kindFor(unitId, slot) ~= nil)
	end
end

-- The tower the player has selected (nil = none); its current target gets the white flash.
function EnemyRenderController.setSelectedTower(id: number?)
	selectedTower = id
end

local function onEvents(events: { any })
	if not origin or not arenaPath then
		return
	end
	for _, e in events do
		local t = e.type
		if t == "spawn" then
			spawn(e)
			if e.boss and Fx.any() then
				local p = arenaPath :: Path.Path
				local x, z = Path.position(p, 0)
				bossRing((origin :: CFrame * CFrame.new(x, 0, z)).Position, Vfx.BOSS.spawnRadius, Vfx.BOSS.spawnLife)
			end
		elseif t == "death" then
			remove(e.id, true, e)
		elseif t == "reached" then
			remove(e.id, false)
			gateHit()
			AudioController.sting("gate_hit")
		elseif t == "waveStart" and e.boss then
			bossTelegraph()
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
		local punched = rec.punchAt
		if punched then
			-- Knockback nudge (PV-B02): pushed back along the path, back in place by HIT_PUNCH.life.
			local kb = HitFx.knock(os.clock() - punched, Vfx.HIT_PUNCH.life, Vfx.HIT_PUNCH.knock)
			if kb > 0 then
				x -= ux * kb
				z -= uz * kb
			else
				rec.punchAt = nil
			end
		end
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
	DamageNumbers.start()
	CoinFlight.start()
	if RunService:IsStudio() then
		-- Studio test hook (PV-B04 evidence): draw one role's impact at a point, e.g.
		-- LocalPlayer.HaretFxDemo:Invoke("splash", Vector3.new(...), fromVector3?)
		local demo = Instance.new("BindableFunction")
		demo.Name = "HaretFxDemo"
		demo.OnInvoke = function(role: string, at: Vector3, from: Vector3?)
			roleImpact(role, at, from, 8, false)
			return true
		end
		demo.Parent = Players.LocalPlayer
	end
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
