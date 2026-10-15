--!strict
-- Puts equipped cosmetics on characters and NPC rigs (built by Shared/Util/CosmeticBuilder).
-- Callers are responsible for ownership checks; this service only renders profile.equipped.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CosmeticBuilder = require(ReplicatedStorage:WaitForChild("Shared").Util.CosmeticBuilder)
local DataService = require(script.Parent.DataService)

local AvatarService = {}

local FOLDER_PREFIX = "Cosmetic_"

-- Builds the visual `visualId` on `character`. Returns the created model, or nil.
function AvatarService.attach(character: Model, visualId: string, slot: string): Model?
	return CosmeticBuilder.build(character, visualId, FOLDER_PREFIX .. slot, true)
end

local function clear(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("Model") and string.sub(child.Name, 1, #FOLDER_PREFIX) == FOLDER_PREFIX then
			child:Destroy()
		end
	end
end

-- Hats and hair from the player's own avatar would cover period headwear: hide them while a head
-- cosmetic is worn, restore them when it is taken off.
local HIDDEN_ATTR = "HaretHidden"
local function setHeadAccessoriesHidden(character: Model, hidden: boolean)
	for _, acc in character:GetChildren() do
		if acc:IsA("Accessory") then
			local t = acc.AccessoryType
			if t == Enum.AccessoryType.Hat or t == Enum.AccessoryType.Hair then
				local handle = acc:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then
					if hidden and not handle:GetAttribute(HIDDEN_ATTR) then
						handle:SetAttribute(HIDDEN_ATTR, handle.Transparency)
						handle.Transparency = 1
					elseif not hidden and handle:GetAttribute(HIDDEN_ATTR) ~= nil then
						handle.Transparency = handle:GetAttribute(HIDDEN_ATTR) :: number
						handle:SetAttribute(HIDDEN_ATTR, nil)
					end
				end
			end
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
	setHeadAccessoriesHidden(character, profile.equipped.head ~= nil)
end

local function onCharacter(player: Player, character: Model)
	-- Wait until the rig is assembled so body parts are in their final positions.
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
