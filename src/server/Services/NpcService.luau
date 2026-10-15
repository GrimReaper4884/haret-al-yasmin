--!strict
-- Spawns NPC rigs from Config/Npcs with a ProximityPrompt each, and answers range checks.
-- Prompt text is localized on the client (NpcLabelController).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Npcs = require(Shared.Config.Npcs)
local Economy = require(Shared.Config.Economy)
local Signal = require(Shared.Util.Signal)
local AvatarService = require(script.Parent.AvatarService)

local NpcService = {}

NpcService.TAG = "Npc"
NpcService.Triggered = Signal.new() -- (player, npcId)

local rigs: { [string]: Model } = {}

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

local function spawnNpc(folder: Instance, npcId: string, def: any)
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
	m:SetAttribute("NpcId", npcId)
	CollectionService:AddTag(m, NpcService.TAG)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TalkPrompt"
	prompt.ActionText = "Talk"
	prompt.ObjectText = npcId
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Economy.INTERACT_RANGE - 2
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = root
	prompt.Triggered:Connect(function(player: Player)
		NpcService.Triggered:Fire(player, npcId)
	end)

	m.Parent = folder
	if def.headwear then
		AvatarService.attach(m, def.headwear, "head")
	end
	rigs[npcId] = m
end

function NpcService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Npcs"
	folder.Parent = Workspace
	for npcId: string, def in Npcs :: any do
		task.spawn(spawnNpc, folder, npcId, def)
	end
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
