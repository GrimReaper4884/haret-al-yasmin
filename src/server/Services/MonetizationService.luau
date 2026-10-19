--!strict
-- Robux purchases (docs/MONETIZATION.md).
--  * Prompts are opened by the SERVER after validation (product live, not already owned, region
--    policy for lira).
--  * ProcessReceipt grants through MonetizationLogic (idempotent by PurchaseId), saves, and only
--    then answers PurchaseGranted. Any failure answers NotProcessedYet so Roblox retries later.
--  * Game passes grant their cosmetics and perk flags (vip / fast / slot): checked on join, and
--    applied straight away for the session when PromptGamePassPurchaseFinished reports a purchase.
--  * Rewarded video ads (AdService): the client asks, the server checks the cooldown and plays one;
--    Roblox pays the reward product (Config/Products `ads`) through ProcessReceipt like a purchase.
--  * PolicyService: players whose region restricts paid random items cannot buy anything that
--    funds them: lira, trait stones, the starter pack, premium Diary, Diary skips
--    (MonetizationLogic.fundsRandomItems).

local AdService = game:GetService("AdService")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxAnalytics = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

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
local ads: { [Player]: MonetizationLogic.AdState } = {}
local ownedPasses: { [Player]: { [string]: boolean } } = {} -- pass keys owned this session (the store shows "Owned")
local adPlaying: { [Player]: boolean } = {}

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

	if info.ProductPurchaseChannel == Enum.ProductPurchaseChannel.AdReward then
		pcall(function()
			RobloxAnalytics:LogCustomEvent(player, "ad_reward", 1)
		end)
	end
	-- The ledger key is the PurchaseId, so a replayed receipt ("already") never writes a second line.
	local ok, err, result = DataService.mutate(player, function(profile)
		return MonetizationLogic.grantReceipt(profile, tostring(info.PurchaseId), product, grantCtx())
	end, { src = "receipt:" .. (key :: string), key = "receipt:" .. tostring(info.PurchaseId) })
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
			local currency, amount = MonetizationLogic.fallbackPayout(product)
			PlayerStateService.notify(player, if currency == "lira" then "notify.lira_added" else "notify.qirsh_added", { n = amount })
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

-- Sets the pass's perk flag for this session and grants its cosmetics (once).
local function applyPass(player: Player, pass: any, key: string)
	local passes = ownedPasses[player] or {}
	ownedPasses[player] = passes
	passes[key] = true
	local owned = perks[player] or {}
	perks[player] = owned
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
end

local function perksChanged(player: Player)
	MonetizationService.PerksChanged:Fire(player)
	PlayerStateService.schedule(player)
end

-- Join-time ownership check. Flags are never revoked mid-session (a pass bought this session may
-- not show in UserOwnsGamePassAsync yet).
local function grantOwnedPasses(player: Player)
	perks[player] = perks[player] or {}
	for key, pass in Products.gamePasses :: any do
		if pass.gamePassId > 0 then
			local okOwn, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.gamePassId)
			end)
			if okOwn and owns then
				applyPass(player, pass, key)
			elseif not okOwn then
				warn("[Monetization] pass check failed for " .. key)
			end
		end
	end
	perksChanged(player)
end

-- Perk flags for other services: vip / fast / slot.
function MonetizationService.hasPerk(player: Player, perk: string): boolean
	local p = perks[player]
	return p ~= nil and p[perk] == true
end

-- The fastest match speed this player may set as host (LP-A03): VIP, the Fast Mode pass or the
-- premium Lane Diary of the running season unlock TD.PREMIUM_SPEED.
function MonetizationService.maxSpeed(player: Player): number
	local profile = DataService.getProfile(player)
	local premium = profile ~= nil and profile.pass.premium == true and profile.pass.season == SeasonPass.season
	return MonetizationLogic.maxSpeed(perks[player], premium, TD)
end

-- Studio test hook (DebugService "perk"): sets a perk flag for this session only, never the
-- profile or a purchase. A no-op outside Studio.
function MonetizationService.debugPerk(player: Player, perk: string, on: boolean): boolean
	if not game:GetService("RunService"):IsStudio() then
		return false
	end
	local p = perks[player] or {}
	perks[player] = p
	if on then
		p[perk] = true
	else
		p[perk] = nil
	end
	perksChanged(player)
	return true
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

-- Studio harness only (DebugService): play this session as a player whose region restricts paid random items, or
-- read the real policy again ("clear"). Exercises the restricted UI path without the Player Emulator (LP-F05).
function MonetizationService.debugRestricted(player: Player, on: boolean?)
	if not game:GetService("RunService"):IsStudio() then
		return
	end
	if on == nil then
		loadPolicy(player) -- yields: a later call must not be overwritten by this read
		return
	end
	restricted[player] = on
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
		s.ownedPasses = table.clone(ownedPasses[player] or {})
		-- When the store's ad row can play again (os.time; 0 = now, nil = this session's cap reached).
		s.adReadyAt = MonetizationLogic.adReadyAt(ads[player], Products.ads)
	end)

	RemoteGuard.event(Net.Events.RequestRewardedAd, RemoteGuard.STRICT, function(player: Player)
		if adPlaying[player] or not DataService.getProfile(player) then
			return
		end
		local now = os.time()
		local reward = (Products.devProducts :: any)[Products.ads.reward]
		local ok, err = MonetizationLogic.canShowAd(ads[player], now, Products.ads, reward, RunService:IsStudio())
		if not ok then
			if err == "cooldown" then
				local wait = (MonetizationLogic.adReadyAt(ads[player], Products.ads) or now) - now
				PlayerStateService.notify(player, "notify.ad_cooldown", { n = math.max(1, math.ceil(wait / 60)) })
			else
				PlayerStateService.notify(player, "notify.ad_unavailable")
			end
			return
		end
		adPlaying[player] = true
		local state: MonetizationLogic.AdState = ads[player] or { shown = 0, lastAt = nil }
		state.shown += 1
		ads[player] = state
		local okShow, result = pcall(function()
			local adReward = AdService:CreateAdRewardFromDevProductId(reward.productId)
			return AdService:ShowRewardedVideoAdAsync(player, adReward)
		end)
		adPlaying[player] = nil
		if not player.Parent then
			return
		end
		if okShow and result == Enum.ShowAdResult.ShowCompleted then
			state.lastAt = os.time() -- the reward itself arrives through ProcessReceipt
		else
			state.shown -= 1 -- nothing was watched: the attempt doesn't count
			warn("[Monetization] rewarded ad not shown: " .. tostring(result))
			PlayerStateService.notify(player, "notify.ad_unavailable")
		end
		PlayerStateService.schedule(player)
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
		-- Trust the purchase for this session: UserOwnsGamePassAsync is cached and can lag a fresh
		-- purchase (and never reflects a Studio test purchase). The next join re-checks ownership.
		local key = byPassId[passId]
		if purchased and key and player.Parent then
			applyPass(player, (Products.gamePasses :: any)[key], key)
			perksChanged(player)
		end
	end)

	DataService.ProfileLoaded:Connect(function(player: Player)
		task.spawn(grantOwnedPasses, player)
		task.spawn(loadPolicy, player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		perks[player] = nil
		restricted[player] = nil
		ads[player] = nil
		adPlaying[player] = nil
		ownedPasses[player] = nil
	end)
end

return MonetizationService
