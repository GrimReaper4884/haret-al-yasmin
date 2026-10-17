--!strict
-- Meta progression remotes: summons, loadout and traits, season pass claims, codes and the daily
-- reward. Every handler validates input, reads the live profile and writes through
-- DataService.mutate with the pure Logic modules.

local Players = game:GetService("Players")
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
local EventLogic = require(Shared.Logic.EventLogic)
local Events = require(Shared.Config.Events)
local DailyLogic = require(Shared.Logic.DailyLogic)
local Validate = require(Shared.Logic.Validate)
local DataService = require(script.Parent.DataService)
local MatchService = require(script.Parent.MatchService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RemoteGuard = require(script.Parent.RemoteGuard)
local MonetizationService = require(script.Parent.MonetizationService)
local Analytics = require(script.Parent.AnalyticsService)
local FunnelService = require(script.Parent.FunnelService)

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

-- The reward context for Logic/Grants (also used by AfkService).
MetaService.grantCtx = grantCtx

-- A fresh seed and a generator driven by it, for rolls that the audit ledger must be able to replay.
local function seededRng(): (number, () -> number)
	local seed = math.random(0, 2 ^ 31 - 1)
	local random = Random.new(seed)
	return seed, function()
		return random:NextNumber()
	end
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
	-- Every roll of this summon comes from one seeded generator; the seed goes into the ledger
	-- entry so the pull can be replayed from the audit trail.
	local seed, rng = seededRng()
	local ctx = summonCtx()
	ctx.rng = rng
	local ok, err, results = DataService.mutate(player, function(p)
		return SummonLogic.summon(p, n, cost, ctx)
	end, { src = "summon_x" .. n, seed = seed })
	if not ok then
		return { ok = false, err = err }
	end
	FunnelService.reach(player, "summon")
	Analytics.custom(player, "Summon_x" .. n)
	local announce = {}
	for _, r in results :: { any } do
		if r.rarity == "mythic" or r.rarity == "legendary" then
			Analytics.custom(player, "Summon_" .. r.rarity .. "_" .. r.unitId)
		end
		if (r.rarity == "mythic" or r.rarity == "secret") and #announce < 2 then
			table.insert(announce, r)
		end
	end
	-- A server-wide line for Mythic and better, after the summoner's own reveal has played.
	if #announce > 0 then
		task.delay(3, function()
			for _, r in announce do
				local def = (Units :: any)[r.unitId]
				for _, other in Players:GetPlayers() do
					if other ~= player then
						PlayerStateService.notify(other, "notify.global_pull", { name = player.DisplayName, rarityKey = "rarity." .. r.rarity, unitKey = def.nameKey })
					end
				end
			end
		end)
	end
	return { ok = true, results = results, cost = cost }
end

local function setLoadout(player: Player, list: any): { [string]: any }
	if type(list) ~= "table" or #list > 8 then
		return { ok = false, err = "bad_request" }
	end
	-- The loadout is fixed for the length of a match (docs/TOWER_DEFENSE.md: 6 slots, 7 with the
	-- pass). PlaceTower reads it live, so swapping it mid-match would place every owned unit and
	-- make the Extra Slot pass worthless. The result screen (match.ended) is open again.
	local match = MatchService.matchOf(player)
	if match and not match.ended then
		return { ok = false, err = "in_match" }
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
	local seed, rng = seededRng()
	local ok, err, trait = DataService.mutate(player, function(p)
		return UnitLogic.rerollTrait(p, unitId, TD.TRAIT_REROLL_COST, Traits.traits, Traits.order, rng)
	end, { src = "reroll:" .. unitId, seed = seed })
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
	end, { src = "pass:" .. track })
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
	if CodesLogic.isMatchCash(code, Codes :: any) then
		local inMatch = MatchService.matchOf(player) ~= nil
		local ok, err, amount = CodesLogic.redeemMatchCash(code, Codes :: any, { userId = player.UserId, now = os.time(), inMatch = inMatch })
		if not ok or not amount or not MatchService.addCash(player, amount) then
			return { ok = false, err = err or "match_only" }
		end
		Analytics.custom(player, "Code_" .. (CodesLogic.normalize(code) or "?"))
		return { ok = true, granted = { cash = amount } }
	end
	local clean = CodesLogic.normalize(code) or "?"
	local ok, err, granted = DataService.mutate(player, function(p)
		local c = grantCtx()
		c.userId = player.UserId
		return CodesLogic.redeem(p, code, Codes :: any, c)
	end, { src = "code:" .. clean, key = "code:" .. clean })
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "Code_" .. (CodesLogic.normalize(code) or "?"))
	return { ok = true, granted = granted }
end

local function claimDaily(player: Player): { [string]: any }
	local ok, err, granted, day = DataService.mutate(player, function(p)
		return DailyLogic.claim(p, os.time(), Daily :: any, grantCtx())
	end, { src = "daily" })
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "DailyClaim", day)
	PlayerStateService.notify(player, "notify.daily_claimed")
	return { ok = true, granted = granted, day = day }
end

-- Buys one entry from a running event's shop with that event's currency (Logic/EventLogic).
local function eventBuy(player: Player, eventId: any, key: any): { [string]: any }
	if not Validate.isIdentifier(eventId) or not Validate.isShortString(key, 40) then
		return { ok = false, err = "bad_request" }
	end
	local ok, err, granted = DataService.mutate(player, function(p)
		return EventLogic.buy(p, Events :: any, eventId, key, os.time(), grantCtx())
	end, { src = "event:" .. eventId })
	if not ok then
		return { ok = false, err = err }
	end
	Analytics.custom(player, "EventBuy_" .. eventId .. "_" .. key)
	return { ok = true, granted = granted }
end

function MetaService.start()
	RemoteGuard.func(Net.Functions.Summon, RemoteGuard.STRICT, summon)
	RemoteGuard.func(Net.Functions.SetLoadout, RemoteGuard.DEFAULT, setLoadout)
	RemoteGuard.func(Net.Functions.RerollTrait, RemoteGuard.STRICT, rerollTrait)
	RemoteGuard.func(Net.Functions.ClaimPass, RemoteGuard.DEFAULT, claimPass)
	RemoteGuard.func(Net.Functions.RedeemCode, RemoteGuard.STRICT, redeemCode)
	RemoteGuard.func(Net.Functions.ClaimDaily, RemoteGuard.STRICT, claimDaily)
	RemoteGuard.func(Net.Functions.EventBuy, RemoteGuard.STRICT, eventBuy)

	-- Loadout slots can grow with a pass bought mid-session; the client reads them from the snapshot.
	PlayerStateService.addExtra(function(player: Player, s: { [string]: any })
		s.loadoutSlots = MetaService.loadoutSlots(player)
	end)
end

return MetaService
