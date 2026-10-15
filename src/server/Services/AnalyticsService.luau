--!strict
-- Thin, failure-proof wrapper over Roblox AnalyticsService (docs/GAME_DESIGN.md §10).

local RobloxAnalytics = game:GetService("AnalyticsService")

local Analytics = {}

local CURRENCY = "Qirsh"

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

function Analytics.source(player: Player, amount: number, balance: number, sku: string)
	safe("source", function()
		RobloxAnalytics:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			CURRENCY,
			amount,
			balance,
			Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
			sku
		)
	end)
end

function Analytics.sink(player: Player, amount: number, balance: number, sku: string)
	safe("sink", function()
		RobloxAnalytics:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Sink,
			CURRENCY,
			amount,
			balance,
			Enum.AnalyticsEconomyTransactionType.Shop.Name,
			sku
		)
	end)
end

function Analytics.custom(player: Player, name: string, value: number?)
	safe("custom", function()
		RobloxAnalytics:LogCustomEvent(player, name, value or 1)
	end)
end

return Analytics
