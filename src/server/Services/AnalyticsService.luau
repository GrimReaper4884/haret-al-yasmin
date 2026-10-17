--!strict
-- Thin, failure-proof wrapper over Roblox AnalyticsService (docs/GAME_DESIGN.md §10).

local RobloxAnalytics = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ledger = require(ReplicatedStorage:WaitForChild("Shared").Logic.Ledger)

local Analytics = {}

local function safe(label: string, fn: () -> ())
	local ok, err = pcall(fn :: () -> any)
	if not ok then
		warn("[Analytics] " .. label .. " failed: " .. tostring(err))
	end
end

-- Onboarding funnel: 1 spawned, 2 talked to giver, 3 accepted, 4 delivered, 5 purchased.
export type FunnelStep = { step: number, name: string }

Analytics.Funnel = {
	Spawned = { step = 1, name = "Spawned" } :: FunnelStep,
	TalkedToGiver = { step = 2, name = "TalkedToGiver" } :: FunnelStep,
	AcceptedQuest = { step = 3, name = "AcceptedQuest" } :: FunnelStep,
	DeliveredQuest = { step = 4, name = "DeliveredQuest" } :: FunnelStep,
	FirstPurchase = { step = 5, name = "FirstPurchase" } :: FunnelStep,
}

function Analytics.funnel(player: Player, step: FunnelStep)
	safe("funnel", function()
		RobloxAnalytics:LogOnboardingFunnelStepEvent(player, step.step, step.name)
	end)
end

-- Ledger entries → one economy event per currency moved. The transaction type follows the
-- source prefix: receipts are IAP, shop / summon / reroll are Shop, daily is TimedReward, the
-- rest Gameplay. `profile` supplies the balance after the mutation.
local LEDGER_CURRENCY = { lira = "Lira", qirsh = "Qirsh", stones = "TraitStones" }
local BALANCE_FIELD = { lira = "lira", qirsh = "qirsh", stones = "traitStones" }

local function transactionType(src: string): string
	if string.sub(src, 1, 8) == "receipt:" then
		return Enum.AnalyticsEconomyTransactionType.IAP.Name
	elseif string.sub(src, 1, 6) == "summon" or string.sub(src, 1, 6) == "reroll" or src == "shop" or string.sub(src, 1, 6) == "event:" then
		return Enum.AnalyticsEconomyTransactionType.Shop.Name
	elseif src == "daily" then
		return Enum.AnalyticsEconomyTransactionType.TimedReward.Name
	end
	return Enum.AnalyticsEconomyTransactionType.Gameplay.Name
end

function Analytics.ledger(player: Player, entry: Ledger.Entry, profile: any)
	for field, currency in LEDGER_CURRENCY do
		local delta = (entry :: any)[field]
		if type(delta) == "number" and delta ~= 0 then
			safe("ledger", function()
				RobloxAnalytics:LogEconomyEvent(
					player,
					if delta > 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink,
					currency,
					math.abs(delta),
					profile[BALANCE_FIELD[field]],
					transactionType(entry.src),
					string.sub(entry.src, 1, 50)
				)
			end)
		end
	end
end

function Analytics.custom(player: Player, name: string, value: number?)
	safe("custom", function()
		RobloxAnalytics:LogCustomEvent(player, name, value or 1)
	end)
end

return Analytics
