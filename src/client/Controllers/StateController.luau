--!strict
-- Holds the latest server snapshot of this player's state. Display only: nothing here is trusted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)

export type Snapshot = {
	qirsh: number,
	inventory: { [string]: number },
	equipped: { [string]: string },
	quests: { [string]: { state: string, completions: number } },
	language: string?,
	persistent: boolean,
}

local StateController = {}

StateController.Changed = Signal.new()

local current: Snapshot? = nil

function StateController.get(): Snapshot?
	return current
end

function StateController.questState(questId: string): string
	local s = current
	local rec = s and s.quests[questId]
	return if rec then rec.state else "none"
end

function StateController.start()
	Net.event(Net.Events.StateSync).OnClientEvent:Connect(function(snapshot: Snapshot)
		current = snapshot
		StateController.Changed:Fire(snapshot)
	end)
end

return StateController
