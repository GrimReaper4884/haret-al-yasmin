--!strict
-- Server-side dialogue sessions. Dialogue starts from the server-side ProximityPrompt event;
-- the client only sends the index of a choice within the node the server says it is on.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Dialogue = require(Shared.Config.Dialogue)
local Quests = require(Shared.Config.Quests)
local DialogueLogic = require(Shared.Logic.DialogueLogic)
local DataService = require(script.Parent.DataService)
local NpcService = require(script.Parent.NpcService)
local QuestService = require(script.Parent.QuestService)
local ShopService = require(script.Parent.ShopService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local Analytics = require(script.Parent.AnalyticsService)

local DialogueService = {}

type Session = { npcId: string, nodeId: string }
local sessions: { [Player]: Session } = {}

local showEvent: RemoteEvent
local hideEvent: RemoteEvent

local function show(player: Player, npcId: string, nodeId: string)
	local tree = (Dialogue :: any)[npcId]
	local node = tree and tree.nodes[nodeId]
	if not node then
		warn("[DialogueService] missing node " .. npcId .. "/" .. nodeId)
		sessions[player] = nil
		hideEvent:FireClient(player)
		return
	end
	sessions[player] = { npcId = npcId, nodeId = nodeId }
	local choices = {}
	for i, c in node.choices do
		choices[i] = c.textKey
	end
	showEvent:FireClient(player, { npcId = npcId, nodeId = nodeId, textKey = node.textKey, choices = choices })
end

local function close(player: Player)
	sessions[player] = nil
	hideEvent:FireClient(player)
end

function DialogueService.open(player: Player, npcId: string)
	local profile = DataService.getProfile(player)
	local tree = (Dialogue :: any)[npcId]
	if not profile or not tree then
		return
	end
	ShopService.close(player)
	local nodeId = DialogueLogic.entryNode(tree, profile)
	if not nodeId then
		return
	end
	for _, q in Quests :: any do
		if q.giver == npcId then
			Analytics.funnel(player, Analytics.Funnel.TalkedToGiver)
			break
		end
	end
	show(player, npcId, nodeId)
end

local function choose(player: Player, index: any)
	local session = sessions[player]
	if not session then
		return
	end
	local tree = (Dialogue :: any)[session.npcId]
	local choice = DialogueLogic.choice(tree, session.nodeId, index)
	if not choice then
		return -- stale or forged index: ignore
	end
	if not NpcService.inRange(player, session.npcId) then
		PlayerStateService.notify(player, "notify.too_far")
		close(player)
		return
	end

	local action = choice.action
	if action then
		if action.type == "acceptQuest" or action.type == "deliverQuest" then
			local ok
			if action.type == "acceptQuest" then
				ok = QuestService.accept(player, action.quest :: string, session.npcId)
			else
				ok = QuestService.deliver(player, action.quest :: string, session.npcId)
			end
			if not ok then
				PlayerStateService.notify(player, "notify.error")
				close(player)
				return
			end
		elseif action.type == "openShop" then
			local npcId = session.npcId
			close(player)
			ShopService.open(player, action.shop :: string, npcId)
			return
		elseif action.type == "close" then
			close(player)
			return
		end
	end

	if choice.next then
		show(player, session.npcId, choice.next)
	else
		close(player)
	end
end

function DialogueService.start()
	showEvent = Net.event(Net.Events.DialogueShow)
	hideEvent = Net.event(Net.Events.DialogueHide)
	NpcService.Triggered:Connect(DialogueService.open)
	RemoteGuard.event(Net.Events.DialogueChoose, RemoteGuard.DEFAULT, choose)
	RemoteGuard.event(Net.Events.DialogueClose, RemoteGuard.DEFAULT, function(player: Player)
		sessions[player] = nil
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return DialogueService
