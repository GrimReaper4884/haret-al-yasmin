--!strict
-- Robux grant rules. Pure. Every grant is keyed by the Roblox PurchaseId and recorded in
-- profile.receipts in the same mutation, so a receipt that Roblox re-sends (it retries until we
-- answer PurchaseGranted) is granted exactly once.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require -- name is dynamic; resolved at runtime
	return dynamicRequire((script :: any).Parent[name])
end

local Wallet = sibling("Wallet")
local Inventory = sibling("Inventory")
local Grants = sibling("Grants")
local PassLogic = sibling("PassLogic")

type Profile = {
	qirsh: number,
	lira: number,
	inventory: { [string]: number },
	receipts: { [string]: number },
	[string]: any,
}
type DevProduct = { kind: string, productId: number?, amount: number?, item: string?, fallbackQirsh: number?, fallbackLira: number?, season: string?, bundle: any?, oneTime: boolean? }

export type GrantResult = "granted" | "already" | "fallback"

-- grantCtx: Grants.Context plus `passTiers` (SeasonPass.tiers)
export type GrantContext = {
	items: { [string]: any },
	units: { [string]: any },
	traits: any,
	rng: () -> number,
	now: number,
	maxQirsh: number,
	maxLira: number,
	maxStones: number,
	passTiers: { any },
}

local MonetizationLogic = {}

-- Bundles are identified by their nameKey (stable across price changes).
local function receiptKey(product: any): string
	return tostring(product.nameKey or product.kind)
end

local function isAmount(v: any): boolean
	return type(v) == "number" and v == v and v > 0 and v ~= math.huge and math.floor(v) == v
end

-- What a "fallback" grant pays (an already-owned item, pass or bundle): currency and amount.
-- Items always fall back to qirsh; passes and bundles prefer lira. The toast uses the same answer.
function MonetizationLogic.fallbackPayout(product: DevProduct): (string, number)
	if product.kind ~= "item" and product.fallbackLira then
		return "lira", product.fallbackLira
	end
	return "qirsh", product.fallbackQirsh or 0
end

local function fallback(profile: Profile, product: DevProduct, ctx: GrantContext)
	local currency, amount = MonetizationLogic.fallbackPayout(product)
	if amount <= 0 then
		return
	end
	if currency == "lira" then
		Grants.apply(profile, { lira = amount }, ctx)
	else
		Wallet.add(profile, amount, ctx.maxQirsh)
	end
end

-- Returns ok, err, result. result "already" means this receipt was granted before.
function MonetizationLogic.grantReceipt(profile: Profile, receiptId: string, product: DevProduct?, ctx: GrantContext): (boolean, string?, GrantResult?)
	if type(receiptId) ~= "string" or receiptId == "" then
		return false, "bad_receipt", nil
	end
	if profile.receipts[receiptId] then
		return true, nil, "already"
	end
	if not product then
		return false, "unknown_product", nil
	end

	local result: GrantResult = "granted"
	local kind = product.kind
	if kind == "qirsh" or kind == "lira" or kind == "stones" then
		if not isAmount(product.amount) then
			return false, "bad_product", nil
		end
		if kind == "qirsh" then
			Wallet.add(profile, product.amount :: number, ctx.maxQirsh)
		elseif kind == "lira" then
			Grants.apply(profile, { lira = product.amount }, ctx)
		else
			Grants.apply(profile, { traitStones = product.amount }, ctx)
		end
	elseif kind == "item" then
		local itemId = product.item
		if type(itemId) ~= "string" or ctx.items[itemId] == nil then
			return false, "bad_product", nil
		end
		if Inventory.has(profile, itemId, 1) then
			-- Bought twice in a race: never take Robux for nothing.
			fallback(profile, product, ctx)
			result = "fallback"
		else
			local ok, err = Inventory.add(profile, itemId, 1, ctx.items)
			if not ok then
				return false, err, nil
			end
		end
	elseif kind == "passPremium" then
		if profile.pass.season ~= product.season or profile.pass.premium then
			fallback(profile, product, ctx)
			result = "fallback"
		else
			profile.pass.premium = true
		end
	elseif kind == "passSkip" then
		if not isAmount(product.amount) then
			return false, "bad_product", nil
		end
		PassLogic.addLevels(profile, product.amount :: number, ctx.passTiers)
	elseif kind == "bundle" then
		if type(product.bundle) ~= "table" then
			return false, "bad_product", nil
		end
		if product.oneTime and profile.bundles[receiptKey(product)] then
			fallback(profile, product, ctx)
			result = "fallback"
		else
			Grants.apply(profile, product.bundle, ctx)
			if product.oneTime then
				profile.bundles[receiptKey(product)] = ctx.now
			end
		end
	else
		return false, "bad_product", nil
	end

	profile.receipts[receiptId] = ctx.now
	return true, nil, result
end

-- Grants pass items not yet owned. Returns ok (true if anything changed), list of granted ids.
function MonetizationLogic.grantPassItems(profile: Profile, passItems: { string }, items: { [string]: any }): (boolean, { string })
	local granted = {}
	for _, itemId in passItems do
		if items[itemId] and not Inventory.has(profile, itemId, 1) then
			if Inventory.add(profile, itemId, 1, items) then
				table.insert(granted, itemId)
			end
		end
	end
	return #granted > 0, granted
end

-- Whether a product turns Robux into something spent on paid random items: lira (summons) or
-- trait stones (trait rerolls), directly, in a bundle, on the premium Diary track, through
-- skipped Diary levels (the free track pays lira), or as a fallback payout. None of these is sold
-- where PolicyService.ArePaidRandomItemsRestricted (docs/research/ROBLOX_IP_AND_POLICY.md §3).
function MonetizationLogic.fundsRandomItems(product: DevProduct): boolean
	local kind = product.kind
	if kind == "lira" or kind == "stones" or kind == "passPremium" or kind == "passSkip" then
		return true
	end
	local bundle = product.bundle
	if kind == "bundle" and type(bundle) == "table" and ((bundle.lira or 0) > 0 or (bundle.traitStones or 0) > 0) then
		return true
	end
	return (MonetizationLogic.fallbackPayout(product)) == "lira"
end

-- The fastest match speed a host may pick (LP-A03): td.PREMIUM_SPEED with the VIP or Fast Mode pass
-- perk or the premium Lane Diary of the running season (`premiumDiary`), else td.FREE_SPEED.
function MonetizationLogic.maxSpeed(perks: { [string]: boolean }?, premiumDiary: boolean, td: any): number
	if premiumDiary or (perks ~= nil and (perks.vip == true or perks.fast == true)) then
		return td.PREMIUM_SPEED
	end
	return td.FREE_SPEED
end

-- The Strings keys that tell a host how to unlock 3x-5x (LP-F05): the caption under the speed sheet and the refusal
-- toast. A restricted player (paid random items) is never pointed at the premium Lane Diary, which funds lira.
function MonetizationLogic.speedUnlockKeys(restricted: boolean?): (string, string)
	if restricted then
		return "match.speed_unlock_restricted", "match.err.fast_pass_restricted"
	end
	return "match.speed_unlock", "match.err.fast_pass"
end

-- Validates a SetSpeed request: "bad_speed" unless it is one of td.SPEEDS (exact membership, so
-- NaN, 2.5, "3" and 99 are refused), "needs_pass" above `maxSpeed`.
function MonetizationLogic.checkSpeed(speed: any, maxSpeed: number, td: any): (boolean, string?)
	if type(speed) ~= "number" or table.find(td.SPEEDS, speed) == nil then
		return false, "bad_speed"
	end
	if speed > maxSpeed then
		return false, "needs_pass"
	end
	return true, nil
end

-- Whether the server may open a Robux prompt for this product for this player right now.
-- restricted = the player's region restricts paid random items (see fundsRandomItems).
function MonetizationLogic.canPrompt(profile: Profile, product: DevProduct?, productId: number?, restricted: boolean?): (boolean, string?)
	if not product then
		return false, "unknown_product"
	end
	if not isAmount(productId) then
		return false, "not_available" -- unpublished (0), NaN, infinite or fractional id
	end
	if product.kind == "item" and product.item and Inventory.has(profile, product.item, 1) then
		return false, "already_owned"
	end
	if restricted and MonetizationLogic.fundsRandomItems(product) then
		return false, "restricted"
	end
	if product.kind == "passPremium" and (profile.pass.premium or profile.pass.season ~= product.season) then
		return false, "already_owned"
	end
	if product.kind == "bundle" and product.oneTime and profile.bundles[receiptKey(product)] then
		return false, "already_owned"
	end
	return true, nil
end

-- Rewarded video ads (Config/Products `ads`). `state` is this session's record for the player:
-- `shown` ads started so far and `lastAt` when the last one finished. One ad per cfg.cooldownSeconds
-- and cfg.perSession per session; the reward product must exist (id > 0) and never fund random items.
export type AdState = { shown: number, lastAt: number? }
export type AdConfig = { enabled: boolean, reward: string, cooldownSeconds: number, perSession: number }

-- `studio` = a Studio playtest, which may play ads before serving is enabled.
function MonetizationLogic.canShowAd(state: AdState?, now: number, cfg: AdConfig, reward: DevProduct?, studio: boolean?): (boolean, string?)
	if not cfg.enabled and not studio then
		return false, "not_available"
	end
	if not reward or not isAmount(reward.productId) or MonetizationLogic.fundsRandomItems(reward) then
		return false, "not_available"
	end
	local shown = if state then state.shown else 0
	if shown >= cfg.perSession then
		return false, "session_cap"
	end
	local last = state and state.lastAt
	if last and now - last < cfg.cooldownSeconds then
		return false, "cooldown"
	end
	return true, nil
end

-- When the next ad may play (a time on the same clock as `lastAt`; 0 = already); nil once the
-- session cap is reached.
function MonetizationLogic.adReadyAt(state: AdState?, cfg: AdConfig): number?
	if state and state.shown >= cfg.perSession then
		return nil
	end
	local last = state and state.lastAt
	return if last then last + cfg.cooldownSeconds else 0
end

return MonetizationLogic
