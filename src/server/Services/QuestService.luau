--!strict
-- Server-side quest transitions. Only reachable through DialogueService, which has already
-- verified the player is talking to (and standing near) the NPC passed in here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local Items = require(Shared.Config.Items)
local Economy = require(Shared.Config.Economy)
local Clues = require(Shared.Config.Clues)
local QuestLogic = require(Shared.Logic.QuestLogic)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local Analytics = require(script.Parent.AnalyticsService)

local QuestService = {}

function QuestService.accept(player: Player, questId: string, npcId: string): (boolean, string?)
	local def = (Quests :: any)[questId]
	if not def or def.giver ~= npcId then
		return false, "wrong_npc"
	end
	local ok, err = DataService.mutate(player, function(profile)
		return QuestLogic.accept(profile, questId, Quests :: any, Items :: any, os.time())
	end)
	if ok then
		PlayerStateService.notify(player, "notify.quest_accepted", { titleKey = def.titleKey })
		if def.item then -- investigations grant no item
			PlayerStateService.notify(player, "notify.item_received", { itemKey = (Items :: any)[def.item].nameKey })
		end
		Analytics.funnel(player, Analytics.Funnel.AcceptedQuest)
	end
	return ok, err
end

-- Called by ClueService after its own range check. The clue → quest mapping comes from config.
function QuestService.collectClue(player: Player, clueId: string): (boolean, string?)
	local clue = (Clues :: any)[clueId]
	if not clue then
		return false, "unknown_clue"
	end
	local def = (Quests :: any)[clue.quest]
	local ok, err, found = DataService.mutate(player, function(profile)
		return QuestLogic.collectClue(profile, clue.quest, clueId, Quests :: any)
	end)
	if ok then
		PlayerStateService.notify(player, "notify.clue_found", {
			clueKey = clue.nameKey,
			n = found,
			total = #def.clues,
		})
		Analytics.custom(player, "ClueFound_" .. clueId)
	end
	return ok, err
end

function QuestService.deliver(player: Player, questId: string, npcId: string): (boolean, string?)
	local def = (Quests :: any)[questId]
	if not def or def.target ~= npcId then
		return false, "wrong_npc"
	end
	local ok, err, paid = DataService.mutate(player, function(profile)
		return QuestLogic.deliver(profile, questId, Quests :: any, Economy.MAX_QIRSH, os.time())
	end)
	if ok then
		local profile = DataService.getProfile(player)
		PlayerStateService.notify(player, "notify.quest_completed", { n = paid })
		Analytics.funnel(player, Analytics.Funnel.DeliveredQuest)
		Analytics.source(player, paid, if profile then profile.qirsh else 0, "quest_" .. questId)
	end
	return ok, err
end

return QuestService
