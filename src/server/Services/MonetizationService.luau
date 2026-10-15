--!strict
-- Robux purchases (docs/MONETIZATION.md).
--  * Prompts are opened by the SERVER after validation (product live, item not already owned).
--  * ProcessReceipt grants through MonetizationLogic (idempotent by PurchaseId), saves, and only
--    then answers PurchaseGranted. Any failure answers NotProcessedYet so Roblox retries later.
--  * Game passes grant their cosmetics while owned (checked on join and on purchase).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxAnalytics = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Items = require(Shared.Config.Items)
local Products = require(Shared.Config.Products)
local Economy = require(Shared.Config.Economy)
local MonetizationLogic = require(Shared.Logic.MonetizationLogic)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local AvatarService = require(script.Parent.AvatarService)

local MonetizationService = {}

local byProductId: { [number]: string } = {}
local byPassId: { [number]: string } = {}

local function logIap(player: Player, key: string, product: any)
	pcall(function()
		local profile = DataService.getProfile(player)
		if product.kind == "qirsh" and profile then
			RobloxAnalytics:LogEconomyEvent(
				player,
				Enum.AnalyticsEconomyFlowType.Source,
				"Qirsh",
				product.amount,
				profile.qirsh,
				Enum.AnalyticsEconomyTransactionType.IAP.Name,
				key
			)
		else
			RobloxAnalytics:LogCustomEvent(player, "IAP_" .. key, 1)
		end
	end)
end

local function processReceipt(info: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player or not DataService.getProfile(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- granted when they next join
	end
	local key = byProductId[info.ProductId]
	local product = if key then (Products.devProducts :: any)[key] else nil
	if not product then
		warn("[Monetization] receipt for unknown product " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err, result = DataService.mutate(player, function(profile)
		return MonetizationLogic.grantReceipt(profile, tostring(info.PurchaseId), product, Items :: any, Economy.MAX_QIRSH, os.time())
	end)
	if not ok then
		warn("[Monetization] grant failed: " .. tostring(err))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Persist before acknowledging. If the save fails the receipt is already recorded in the live
	-- profile, so the retry finds it ("already") and nothing is granted twice.
	if not DataService.saveNow(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if result ~= "already" then
		if product.kind == "item" then
			PlayerStateService.notify(player, "notify.purchased", { itemKey = (Items :: any)[product.item].nameKey })
		else
			PlayerStateService.notify(player, "notify.qirsh_added", { n = product.amount })
		end
		logIap(player, key :: string, product)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function grantPasses(player: Player, onlyPassId: number?)
	for key, pass in Products.gamePasses :: any do
		if pass.gamePassId > 0 and (onlyPassId == nil or onlyPassId == pass.gamePassId) then
			local okOwn, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.gamePassId)
			end)
			if okOwn and owns then
				local changed = DataService.mutate(player, function(profile)
					return MonetizationLogic.grantPassItems(profile, pass.items, Items :: any)
				end)
				if changed then
					PlayerStateService.notify(player, "notify.pass_unlocked", { passKey = pass.nameKey })
					AvatarService.refresh(player)
				end
			elseif not okOwn then
				warn("[Monetization] pass check failed for " .. key)
			end
		end
	end
end

function MonetizationService.start()
	for key, p in Products.devProducts :: any do
		if p.productId > 0 then
			byProductId[p.productId] = key
		end
	end
	for key, p in Products.gamePasses :: any do
		if p.gamePassId > 0 then
			byPassId[p.gamePassId] = key
		end
	end

	MarketplaceService.ProcessReceipt = processReceipt

	RemoteGuard.event(Net.Events.RequestProduct, RemoteGuard.STRICT, function(player: Player, key: any)
		if not Validate.isIdentifier(key) then
			return
		end
		local product = (Products.devProducts :: any)[key]
		local profile = DataService.getProfile(player)
		if not profile then
			return
		end
		local ok, err = MonetizationLogic.canPrompt(profile, product, product and product.productId)
		if not ok then
			if err == "already_owned" then
				PlayerStateService.notify(player, "notify.already_owned")
			elseif err == "not_available" then
				PlayerStateService.notify(player, "notify.coming_soon")
			end
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.productId)
	end)

	RemoteGuard.event(Net.Events.RequestPass, RemoteGuard.STRICT, function(player: Player, key: any)
		if not Validate.isIdentifier(key) then
			return
		end
		local pass = (Products.gamePasses :: any)[key]
		if not pass or pass.gamePassId <= 0 then
			PlayerStateService.notify(player, "notify.coming_soon")
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		if purchased and byPassId[passId] then
			grantPasses(player, passId)
		end
	end)

	DataService.ProfileLoaded:Connect(function(player: Player)
		task.spawn(grantPasses, player, nil)
	end)
end

return MonetizationService
