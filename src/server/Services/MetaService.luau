--!strict
-- Meta progression remotes: summons, loadout and traits, season pass claims, codes and the daily
-- reward. Every handler validates input, reads the live profile and writes through
-- DataService.mutate with the pure Logic modules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local TD = require(Shared.Config.TD)
local Units = require(Shared.Config.Units)
local Banners = require(Shared.Config.Banners)
local Traits = require(Shared.Config.Traits)
local SeasonPass = require(Shared.Config.SeasonPass)
local Codes = require(Shared.Config.Codes)
local Daily = require(Shared.Config.Daily)
local Items = require(Shared.Config.Items)
local Economy = require(Shared.Config.Economy)
local SummonLogic = require(Shared.Logic.SummonLogic)
local UnitLogic = require(Shared.Logic.UnitLogic)
local PassLogic = require(Shared.Logic.PassLogic)
local CodesLogic = require(Shared.Logic.CodesLogic)
local DailyLogic = require(Shared.Logic.DailyLogic)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MonetizationService = require(script.Parent.MonetizationService)
local Analytics = require(script.Parent.AnalyticsService)

local MetaService = {}

local function grantCtx(): any
	return {
		maxQirsh = Economy.MAX_QIRSH,
		maxLira = TD.MAX_LIRA,
		maxStones = TD.MAX_TRAIT_STONES,
		items = Items :: any,
		units = Units :: any,
		traits = Traits,
		rng = function()
			return math.random()
		end,
		now = os.time(),
	}
end

local function summonCtx(): SummonLogic.Context
	return {
		units = Units :: any,
		banners = Banners :: any,
		odds = TD.ODDS,
		rarityOrder = TD.RARITY_ORDER,
		pityLegendary = TD.PITY_LEGENDARY,
		pityMythic = TD.PITY_MYTHIC,
		featuredShare = TD.FEATURED_SHARE,
		rotation = TD.BANNER_ROTATION,
		traits = Traits,
		rng = function()
			return math.random()
		end,
		now = os.time(),
	}
end

function MetaService.loadoutSlots(player: Player): number
	return TD.LOADOUT_SLOTS + (if MonetizationService.hasPerk(player, "slot") then 1 else 0)
end

local function summon(player: Player, n: any): { [string]: any }
	if n ~= 1 and n ~= 10 then
		return { ok = false, err = "bad_request" }
	end
	local profile = DataService.getProfile(player)
	if not profile then
		return { ok = false, err = "not_loaded" }
	end
	local cost = SummonLogic.cost(n, TD.SUMMON_COST, TD.SUMMON_TEN_COST, TD.VIP_SUMMON_DISCOUNT, MonetizationService.hasPerk(player, "vip"))
	local ok, err, results = DataService.mutate(player, function(p)
		return SummonLogic.summon(p, n, cost, summonCtx())
	end)
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.sink(player, cost, profile.lira, "summon_x" .. n)
	Analytics.custom(player, "Summon_x" .. n)
	for _, r in results :: { any } do
		if r.rarity == "mythic" or r.rarity == "legendary" then
			Analytics.custom(player, "Summon_" .. r.rarity .. "_" .. r.unitId)
		end
	end
	return { ok = true, results = results, cost = cost }
end

local function setLoadout(player: Player, list: any): { [string]: any }
	if type(list) ~= "table" or #list > 8 then
		return { ok = false, err = "bad_request" }
	end
	local slots = MetaService.loadoutSlots(player)
	local ok, err = DataService.mutate(player, function(p)
		return UnitLogic.setLoadout(p, list, slots, Units :: any)
	end)
	if not ok then
		return { ok = false, err = err }
	end
	return { ok = true }
end

local function rerollTrait(player: Player, unitId: any): { [string]: any }
	if not Validate.isIdentifier(unitId) or not (Units :: any)[unitId] then
		return { ok = false, err = "bad_request" }
	end
	local ok, err, trait = DataService.mutate(player, function(p)
		return UnitLogic.rerollTrait(p, unitId, TD.TRAIT_REROLL_COST, Traits.traits, Traits.order, function()
			return math.random()
		end)
	end)
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "TraitReroll")
	PlayerStateService.notify(player, "notify.trait_rolled", { traitKey = Traits.traits[trait :: string].nameKey })
	return { ok = true, trait = trait }
end

local function claimPass(player: Player, tier: any, track: any): { [string]: any }
	if not Validate.isPositiveInteger(tier) or (track ~= "free" and track ~= "premium") then
		return { ok = false, err = "bad_request" }
	end
	local ok, err, granted = DataService.mutate(player, function(p)
		return PassLogic.claim(p, tier, track, SeasonPass.tiers, grantCtx())
	end)
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "PassClaim_" .. track, tier)
	return { ok = true, granted = granted }
end

local function redeemCode(player: Player, code: any): { [string]: any }
	if not Validate.isShortString(code, 40) then
		return { ok = false, err = "bad_code" }
	end
	local ok, err, granted = DataService.mutate(player, function(p)
		return CodesLogic.redeem(p, code, Codes :: any, grantCtx())
	end)
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "Code_" .. (CodesLogic.normalize(code) or "?"))
	return { ok = true, granted = granted }
end

local function claimDaily(player: Player): { [string]: any }
	local ok, err, granted, day = DataService.mutate(player, function(p)
		return DailyLogic.claim(p, os.time(), Daily :: any, grantCtx())
	end)
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "DailyClaim", day)
	PlayerStateService.notify(player, "notify.daily_claimed")
	return { ok = true, granted = granted, day = day }
end

function MetaService.start()
	RemoteGuard.func(Net.Functions.Summon, RemoteGuard.STRICT, summon)
	RemoteGuard.func(Net.Functions.SetLoadout, RemoteGuard.DEFAULT, setLoadout)
	RemoteGuard.func(Net.Functions.RerollTrait, RemoteGuard.STRICT, rerollTrait)
	RemoteGuard.func(Net.Functions.ClaimPass, RemoteGuard.DEFAULT, claimPass)
	RemoteGuard.func(Net.Functions.RedeemCode, RemoteGuard.STRICT, redeemCode)
	RemoteGuard.func(Net.Functions.ClaimDaily, RemoteGuard.STRICT, claimDaily)

	-- Loadout slots can grow with a pass bought mid-session; the client reads them from the snapshot.
	PlayerStateService.addExtra(function(player: Player, s: { [string]: any })
		s.loadoutSlots = MetaService.loadoutSlots(player)
	end)
end

return MetaService
