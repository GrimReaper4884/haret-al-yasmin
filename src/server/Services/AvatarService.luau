--!strict
-- Attaches primitive-built cosmetics (Config/CosmeticVisuals) to characters and NPC rigs.
-- Callers are responsible for ownership checks; this service only renders profile.equipped.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CosmeticVisuals = require(Shared.Config.CosmeticVisuals)
local DataService = require(script.Parent.DataService)

local AvatarService = {}

local FOLDER_PREFIX = "Cosmetic_"

-- Builds the visual `visualId` on `character`'s head. Returns the created model, or nil.
function AvatarService.attach(character: Model, visualId: string, slot: string): Model?
	local spec = CosmeticVisuals[visualId]
	local head = character:FindFirstChild("Head")
	if not spec or not head or not head:IsA("BasePart") then
		return nil
	end
	local holder = Instance.new("Model")
	holder.Name = FOLDER_PREFIX .. slot
	local top = head.CFrame * CFrame.new(0, head.Size.Y / 2, 0)
	for _, p in spec do
		local x = Instance.new("Part")
		x.Name = p.name
		x.Shape = p.shape
		x.Size = p.size
		x.Color = p.color
		x.Material = p.material
		x.CFrame = top * p.offset
		x.Anchored = false
		x.Massless = true
		x.CanCollide = false
		x.CanQuery = false
		x.CanTouch = false
		x.CastShadow = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = x
		weld.Parent = x
		x.Parent = holder
	end
	holder.Parent = character
	return holder
end

local function clear(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("Model") and string.sub(child.Name, 1, #FOLDER_PREFIX) == FOLDER_PREFIX then
			child:Destroy()
		end
	end
end

function AvatarService.refresh(player: Player)
	local character = player.Character
	local profile = DataService.getProfile(player)
	if not character or not profile then
		return
	end
	clear(character)
	for slot, itemId in profile.equipped do
		AvatarService.attach(character, itemId, slot)
	end
end

local function onCharacter(player: Player, character: Model)
	-- Wait until the rig is assembled so the head is in its final position.
	character:WaitForChild("Head", 10)
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end
	if player.Character == character then
		AvatarService.refresh(player)
	end
end

function AvatarService.start()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	DataService.ProfileLoaded:Connect(function(player: Player)
		AvatarService.refresh(player)
	end)
end

return AvatarService
