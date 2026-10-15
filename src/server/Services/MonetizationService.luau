--!strict
-- Robux purchases (docs/MONETIZATION.md).
--  * Prompts are opened by the SERVER after validation (product live, not already owned, region
--    policy for lira).
--  * ProcessReceipt grants through MonetizationLogic (idempotent by PurchaseId), saves, and only
--    then answers PurchaseGranted. Any failure answers NotProcessedYet so Roblox retries later.
--  * Game passes grant their cosmetics and perk flags (vip / fast / slot) while owned.
--  * PolicyService: players whose region restricts paid random items cannot buy lira.

local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxAnalytics = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Items = require(Shared.Config.Items)
local Units = require(Shared.Config.Units)
local Traits = require(Shared.Config.Traits)
local SeasonPass = require(Shared.Config.SeasonPass)
local Products = require(Shared.Config.Products)
local Economy = require(Shared.Config.Economy)
local TD = require(Shared.Config.TD)
local MonetizationLogic = require(Shared.Logic.MonetizationLogic)
local Validate = require(Shared.Logic.Validate)
local Signal = require(Shared.Util.Signal)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local AvatarService = require(script.Parent.AvatarService)

local MonetizationService = {}

MonetizationService.PerksChanged = Signal.new() -- (player)

local byProductId: { [number]: string } = {}
local byPassId: { [number]: string } = {}
local perks: { [Player]: { [string]: boolean } } = {}
local restricted: { [Player]: boolean } = {}

local function grantCtx(): MonetizationLogic.GrantContext
	return {
		items = Items :: any,
		units = Units :: any,
		traits = Traits,
		rng = function()
			return math.random()
		end,
		now = os.time(),
		maxQirsh = Economy.MAX_QIRSH,
		maxLira = TD.MAX_LIRA,
		maxStones = TD.MAX_TRAIT_STONES,
		passTiers = SeasonPass.tiers,
	}
end

local function logIap(player: Player, key: string, product: any)
	pcall(function()
		local profile = DataService.getProfile(player)
		if (product.kind == "qirsh" or product.kind == "lira") and profile then
			RobloxAnalytics:LogEconomyEvent(
				player,
				Enum.AnalyticsEconomyFlowType.Source,
				if product.kind == "qirsh" then "Qirsh" else "Lira",
				product.amount,
				if product.kind == "qirsh" then profile.qirsh else profile.lira,
				Enum.AnalyticsEconomyTransactionType.IAP.Name,
				key
			)
		else
			RobloxAnalytics:LogCustomEvent(player, "IAP_" .. key, 1)
		end
	end)
end

local function notifyGrant(player: Player, product: any)
	local k = product.kind
	if k == "item" then
		PlayerStateService.notify(player, "notify.purchased", { itemKey = (Items :: any)[product.item].nameKey })
	elseif k == "qirsh" then
		PlayerStateService.notify(player, "notify.qirsh_added", { n = product.amount })
	elseif k == "lira" then
		PlayerStateService.notify(player, "notify.lira_added", { n = product.amount })
	elseif k == "stones" then
		PlayerStateService.notify(player, "notify.stones_added", { n = product.amount })
	elseif k == "passPremium" then
		PlayerStateService.notify(player, "notify.premium_unlocked")
	elseif k == "passSkip" then
		PlayerStateService.notify(player, "notify.levels_added")
	elseif k == "bundle" then
		PlayerStateService.notify(player, "notify.bundle_granted")
	end
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
		return MonetizationLogic.grantReceipt(profile, tostring(info.PurchaseId), product, grantCtx())
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
		if result == "fallback" then
			PlayerStateService.notify(player, "notify.lira_added", { n = product.fallbackLira or product.fallbackQirsh or 0 })
		else
			notifyGrant(player, product)
		end
		logIap(player, key :: string, product)
		if product.kind == "bundle" or product.kind == "item" then
			AvatarService.refresh(player)
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function grantPasses(player: Player, onlyPassId: number?)
	local owned = perks[player] or {}
	perks[player] = owned
	for key, pass in Products.gamePasses :: any do
		if pass.gamePassId > 0 and (onlyPassId == nil or onlyPassId == pass.gamePassId) then
			local okOwn, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.gamePassId)
			end)
			if okOwn and owns then
				if pass.perk then
					owned[pass.perk] = true
				end
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
	MonetizationService.PerksChanged:Fire(player)
	PlayerStateService.schedule(player)
end

-- Perk flags for other services: vip / fast / slot.
function MonetizationService.hasPerk(player: Player, perk: string): boolean
	local p = perks[player]
	return p ~= nil and p[perk] == true
end

function MonetizationService.perks(player: Player): { [string]: boolean }
	return table.clone(perks[player] or {})
end

function MonetizationService.isRestricted(player: Player): boolean
	return restricted[player] == true
end

local function loadPolicy(player: Player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	-- If the policy can't be read, be safe: treat as restricted (no lira sales).
	restricted[player] = (not ok) or (info and info.ArePaidRandomItemsRestricted == true)
	PlayerStateService.schedule(player)
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
	PlayerStateService.addExtra(function(player: Player, s: { [string]: any })
		s.perks = table.clone(perks[player] or {})
		s.restricted = restricted[player] == true
	end)

	RemoteGuard.event(Net.Events.RequestProduct, RemoteGuard.STRICT, function(player: Player, key: any)
		if not Validate.isIdentifier(key) then
			return
		end
		local product = (Products.devProducts :: any)[key]
		local profile = DataService.getProfile(player)
		if not profile then
			return
		end
		local ok, err = MonetizationLogic.canPrompt(profile, product, product and product.productId, restricted[player])
		if not ok then
			if err == "already_owned" then
				PlayerStateService.notify(player, "notify.already_owned")
			elseif err == "not_available" then
				PlayerStateService.notify(player, "notify.coming_soon")
			elseif err == "restricted" then
				PlayerStateService.notify(player, "notify.restricted")
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
		task.spawn(loadPolicy, player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		perks[player] = nil
		restricted[player] = nil
	end)
end

return MonetizationService
