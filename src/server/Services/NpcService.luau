--!strict
-- Spawns NPC rigs from Config/Npcs with a ProximityPrompt each, and answers range checks.
-- Prompt text is localized on the client (NpcLabelController).
--
-- An NPC with a `look` wears that unit's or enemy's figure (Util/RigBuilder: the imported Meshy
-- model, LP-D02); the client plays its idle (RigAnimController). Walkers follow their route on the
-- shared clock (Logic/LobbyLife.route): the server moves them a few times a second so the prompt
-- range is right, every client draws the same walk smoothly. NPCs of a zone that is not built yet
-- (Config/LaneZones) wait for it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Npcs = require(Shared.Config.Npcs)
local Economy = require(Shared.Config.Economy)
local LaneZones = require(Shared.Config.LaneZones)
local LifeCfg = require(Shared.Config.LobbyLife)
local LobbyLife = require(Shared.Logic.LobbyLife)
local Signal = require(Shared.Util.Signal)
local RigBuilder = require(Shared.Util.RigBuilder)
local AvatarService = require(script.Parent.AvatarService)

local NpcService = {}

NpcService.TAG = "Npc"
NpcService.Triggered = Signal.new() -- (player, npcId)

local rigs: { [string]: Model } = {}
local walkers: { [Model]: any } = {} -- model -> its NpcDef
local folder: Folder? = nil

local function describe(def: any): HumanoidDescription
	local d = Instance.new("HumanoidDescription")
	local skin = Color3.fromHex(def.skin)
	local robe = Color3.fromHex(def.robe)
	local accent = Color3.fromHex(def.accent)
	d.HeadColor = skin
	d.LeftArmColor = robe
	d.RightArmColor = robe
	d.TorsoColor = accent
	d.LeftLegColor = robe
	d.RightLegColor = robe
	return d
end

local function fallbackRig(): Model
	-- Used only if avatar creation fails (e.g. offline Studio): a simple anchored figure.
	local m = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 5, 1)
	root.Transparency = 0
	root.Parent = m
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.CFrame = root.CFrame * CFrame.new(0, 3.2, 0)
	head.Parent = m
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = head
	Instance.new("Humanoid").Parent = m
	m.PrimaryPart = root
	return m
end

local function addPrompt(npcId: string, part: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = npcId
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Economy.INTERACT_RANGE - 2
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = part
	prompt.Triggered:Connect(function(player: Player)
		NpcService.Triggered:Fire(player, npcId)
	end)
end

-- Where a figure's ground pivot goes: a seated one rests its hip bone `sit.lift` above the seat at
-- `position` (each rig's own hip height, read at rest: toon figures have short legs).
local function placeFigure(m: Model, def: any)
	local pos = def.position
	local y = pos[2]
	if def.pose == "seated" then
		local sit = LifeCfg.npcs.sit
		local hips = m:FindFirstChild("Hips", true)
		local hipH = if hips and hips:IsA("Bone") then hips.WorldPosition.Y - m:GetPivot().Position.Y else (m.PrimaryPart :: BasePart).Size.Y * sit.drop
		y -= hipH - sit.lift
	end
	m:PivotTo(CFrame.new(pos[1], y, pos[3]) * CFrame.Angles(0, math.rad(def.yaw), 0))
end

-- The unit / enemy figure for an NPC with a look (LP-D02). Its Root is the anchored PrimaryPart.
local function spawnFigure(parent: Instance, npcId: string, def: any)
	local m = RigBuilder.build(nil, npcId, {
		robe = def.robe,
		accent = def.accent,
		skin = def.skin,
		hat = def.headwear or "none",
		hatColor = def.accent,
		weapon = "none",
	}, def.look)
	local root = m.PrimaryPart :: BasePart
	root.CanCollide = def.pose ~= "walk" -- players bump into a standing or seated neighbour, walkers pass through
	placeFigure(m, def)
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute("NpcId", npcId)
	m:SetAttribute("NpcPose", def.pose or "stand")
	CollectionService:AddTag(m, NpcService.TAG)
	if def.talk ~= false then
		addPrompt(npcId, root)
	end
	m.Parent = parent
	rigs[npcId] = m
	if def.pose == "walk" and def.route then
		walkers[m] = def
	end
end

local function spawnNpc(parent: Instance, npcId: string, def: any)
	if def.look then
		spawnFigure(parent, npcId, def)
		return
	end
	local ok, rig = pcall(function()
		return Players:CreateHumanoidModelFromDescription(describe(def), Enum.HumanoidRigType.R15)
	end)
	local m: Model = if ok and rig then rig else fallbackRig()
	m.Name = npcId
	local humanoid = m:FindFirstChildOfClass("Humanoid")
	local root = m:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		warn("[NpcService] rig missing parts for " .. npcId)
		return
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	root.Anchored = true

	local pos = def.position
	local hipToGround = humanoid.HipHeight + root.Size.Y / 2
	m:PivotTo(CFrame.new(pos[1], pos[2] + hipToGround, pos[3]) * CFrame.Angles(0, math.rad(def.yaw), 0))
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute("NpcId", npcId)
	CollectionService:AddTag(m, NpcService.TAG)

	if def.talk ~= false then
		addPrompt(npcId, root)
	end

	m.Parent = parent
	if def.headwear then
		AvatarService.attach(m, def.headwear, "head")
	end
	rigs[npcId] = m
end

-- Zones that are built (Config/LaneZones): an NPC of any other zone waits for it.
local function builtZones(): { [string]: boolean }
	local out = {}
	for _, z in LaneZones.zones do
		out[z.id] = z.built
	end
	return out
end

local function moveWalkers()
	local step = 1 / LifeCfg.npcs.serverHz
	local acc = 0
	local cfg = LifeCfg.npcs
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < step then
			return
		end
		acc = 0
		local now = Workspace:GetServerTimeNow()
		for m, def in walkers do
			if not m.Parent then
				walkers[m] = nil
				continue
			end
			local x, z, yaw = LobbyLife.route(def.route, cfg.walkSpeed, cfg.pause, now + (def.phase or 0))
			m:PivotTo(CFrame.new(x, def.position[2], z) * CFrame.Angles(0, yaw, 0))
		end
	end)
end

function NpcService.start()
	local f = Instance.new("Folder")
	f.Name = "Npcs"
	f.Parent = Workspace
	folder = f
	local built = builtZones()
	for npcId: string, def in Npcs :: any do
		if not def.zone or built[def.zone] then
			task.spawn(spawnNpc, f, npcId, def)
		end
	end
	moveWalkers()
end

-- Studio harness (DebugService "npcs"): spawns the NPCs still waiting for their zone, at their
-- provisional spots, so every figure can be looked at before its zone ships. Returns how many.
function NpcService.spawnWaiting(): number
	local f = folder
	if not f or not RunService:IsStudio() then
		return 0
	end
	local n = 0
	for npcId: string, def in Npcs :: any do
		if not rigs[npcId] then
			spawnNpc(f, npcId, def)
			n += 1
		end
	end
	return n
end

-- True if the player's character is within interaction range of the NPC.
function NpcService.inRange(player: Player, npcId: string): boolean
	local rig = rigs[npcId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local npcRoot = rig and rig.PrimaryPart
	if not root or not npcRoot then
		return false
	end
	return (root.Position - npcRoot.Position).Magnitude <= Economy.INTERACT_RANGE
end

return NpcService
