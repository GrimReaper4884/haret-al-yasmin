--!strict
-- Thin, failure-proof wrapper over Roblox AnalyticsService (docs/GAME_DESIGN.md §10).

local RobloxAnalytics = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ledger = require(Shared.Logic.Ledger)
local FunnelLogic = require(Shared.Logic.FunnelLogic)

local Analytics = {}

local function safe(label: string, fn: () -> ())
	local ok, err = pcall(fn :: () -> any)
	if not ok then
		warn("[Analytics] " .. label .. " failed: " .. tostring(err))
	end
end

-- Onboarding funnel (Logic/FunnelLogic.ORDER): 1 join, 2 prompt, 3 summon, 4 portal, 5 wave1,
-- 6 wave5, 7 clear. FunnelService stamps each step once per player and calls this.
export type FunnelStep = FunnelLogic.Step

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
