--!strict
-- Spawns clue spots (Config/Clues) as small primitive props with an "Inspect" ProximityPrompt.
-- Prompts exist for everyone; the client hides them unless the player can use them, and the
-- server re-validates range and quest state on every trigger.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Clues = require(Shared.Config.Clues)
local Economy = require(Shared.Config.Economy)
local Palette = require(Shared.Config.Palette)
local QuestService = require(script.Parent.QuestService)

local ClueService = {}

ClueService.TAG = "Clue"

local function piece(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Shape = shape or Enum.PartType.Block
	p.Parent = parent
	return p
end

local CYL_FLAT = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis → Y (flat disc)

local looks: { [string]: (Model, Vector3) -> () } = {
	slipper = function(m, pos)
		-- Two soft prints in a patch of spilled cumin.
		piece(m, Vector3.new(0.06, 3.2, 3.2), CFrame.new(pos) * CYL_FLAT, Color3.fromHex("#B5832F"), Enum.Material.Sand, Enum.PartType.Cylinder)
		piece(m, Vector3.new(0.4, 0.08, 1.1), CFrame.new(pos + Vector3.new(-0.35, 0.04, 0.2)), Palette.ink, Enum.Material.Fabric)
		piece(m, Vector3.new(0.4, 0.08, 1.1), CFrame.new(pos + Vector3.new(0.35, 0.04, -0.6)), Palette.ink, Enum.Material.Fabric)
	end,
	thread = function(m, pos)
		piece(m, Vector3.new(0.15, 0.15, 0.15), CFrame.new(pos), Palette.basalt, Enum.Material.Metal)
		piece(m, Vector3.new(0.06, 1.4, 0.06), CFrame.new(pos + Vector3.new(0.05, -0.7, 0)) * CFrame.Angles(0, 0, math.rad(8)), Palette.fabricIndigo, Enum.Material.Fabric)
	end,
	token = function(m, pos)
		piece(m, Vector3.new(0.08, 0.6, 0.6), CFrame.new(pos + Vector3.new(0, 0.04, 0)) * CYL_FLAT, Palette.copper, Enum.Material.Metal, Enum.PartType.Cylinder)
	end,
}

local function spawnClue(folder: Instance, clueId: string, def: any)
	local pos = Vector3.new(def.position[1], def.position[2], def.position[3])
	local m = Instance.new("Model")
	m.Name = clueId
	local build = looks[def.look]
	if build then
		build(m, pos)
	end
	-- Invisible anchor for the prompt (and for the client's highlight).
	local anchor = piece(m, Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(0, 0.5, 0)), Palette.copper, Enum.Material.SmoothPlastic)
	anchor.Name = "Anchor"
	anchor.Transparency = 1
	m.PrimaryPart = anchor

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InspectPrompt"
	prompt.ActionText = "Inspect"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player: Player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root or (root.Position - pos).Magnitude > Economy.INTERACT_RANGE then
			return
		end
		local ok = QuestService.collectClue(player, clueId)
		if ok then
			Net.event(Net.Events.ClueShow):FireClient(player, clueId)
		end
	end)

	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m:SetAttribute("ClueId", clueId)
	CollectionService:AddTag(m, ClueService.TAG)
	m.Parent = folder
end

function ClueService.start()
	local folder = Instance.new("Folder")
	folder.Name = "Clues"
	folder.Parent = Workspace
	for clueId: string, def in Clues :: any do
		spawnClue(folder, clueId, def)
	end
end

return ClueService
