--!strict
-- Holds the latest server snapshot of this player's state. Display only: nothing here is trusted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Signal = require(Shared.Util.Signal)
local Quests = require(Shared.Config.Quests)
local QuestLogic = require(Shared.Logic.QuestLogic)

export type Snapshot = {
	qirsh: number,
	inventory: { [string]: number },
	equipped: { [string]: string },
	quests: { [string]: { state: string, completions: number, progress: { [string]: boolean }? } },
	language: string?,
	persistent: boolean,
}

local StateController = {}

StateController.Changed = Signal.new()

local current: Snapshot? = nil

function StateController.get(): Snapshot?
	return current
end

-- "none" | "active" | "ready" | "completed" (same rules as the server, from the snapshot).
function StateController.questState(questId: string): string
	local s = current
	if not s then
		return "none"
	end
	return QuestLogic.state(s :: any, questId, Quests :: any)
end

function StateController.clueFound(questId: string, clueId: string): boolean
	local s = current
	local rec = s and s.quests[questId]
	return rec ~= nil and rec.progress ~= nil and rec.progress[clueId] == true
end

function StateController.start()
	Net.event(Net.Events.StateSync).OnClientEvent:Connect(function(snapshot: Snapshot)
		current = snapshot
		StateController.Changed:Fire(snapshot)
	end)
end

return StateController
