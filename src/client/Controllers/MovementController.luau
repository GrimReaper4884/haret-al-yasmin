--!strict
-- Player movement rules. The lane's façades are stacks of thin ledges (plinth, ablaq bands, sills,
-- cornice) that the Humanoid treats as ladder rungs, so players climbed onto the roofs and fell out
-- of the map. Nothing in the game is meant to be climbed: climbing is off. The state must be set on
-- the client, which owns its character's physics. WorldService also brings back anyone who still
-- ends up on a roof or below the ground.

local Players = game:GetService("Players")

local MovementController = {}

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end
end

function MovementController.start()
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return MovementController
