--!strict
-- Shared-world comfort: players pass through each other so a crowded lane, a doorway or an NPC's
-- counter can never be blocked by other players (or griefers). Players still collide with the world.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PlayerCollisionService = {}

local GROUP = "Players"

local function setGroup(part: Instance)
	if part:IsA("BasePart") then
		part.CollisionGroup = GROUP
	end
end

local function onCharacter(character: Model)
	for _, d in character:GetDescendants() do
		setGroup(d)
	end
	character.DescendantAdded:Connect(setGroup)
end

function PlayerCollisionService.start()
	PhysicsService:RegisterCollisionGroup(GROUP)
	PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
	local function hook(player: Player)
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			onCharacter(player.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
end

return PlayerCollisionService
