--!strict
-- Robux products. IDs are the TEST experience's (Haret Al-Yasmin (TEST), created 2026-10-19 at the
-- owner-approved prices, managed pricing off; docs/MONETIZATION.md, RELEASE_CHECKLIST §B2). The
-- production experience will need its own. A product with id 0 is shown as
-- "coming soon" and can never be prompted. `robux` is the PLANNED price, for docs/UI only; the
-- real price always comes from MarketplaceService.
--
-- Kinds: qirsh / lira / stones (currency), item (cosmetic), passPremium (this season's premium
-- track), passSkip (10 pass levels), bundle (one-time starter pack).

export type DevProduct = {
	productId: number,
	kind: "qirsh" | "lira" | "stones" | "item" | "passPremium" | "passSkip" | "bundle",
	amount: number?, -- currency packs / levels
	item: string?, -- item products
	fallbackQirsh: number?, -- paid instead if the item is somehow already owned (race)
	fallbackLira: number?, -- paid instead of a pass/bundle that is already owned
	season: string?, -- passPremium
	bundle: { lira: number?, qirsh: number?, unit: string?, item: string?, traitStones: number? }?,
	robux: number, -- planned price
	nameKey: string,
	descKey: string?,
	oneTime: boolean?, -- bundles: recorded in profile.bundles
}

export type GamePass = {
	gamePassId: number,
	items: { string }, -- cosmetics granted while the pass is owned
	robux: number,
	nameKey: string,
	descKey: string,
	perk: ("vip" | "fast" | "slot")?, -- gameplay perk flag read by the services
}

local devProducts: { [string]: DevProduct } = {
	-- Qirsh (cosmetics currency)
	qirsh_pouch = { productId = 3720107655, kind = "qirsh", amount = 100, robux = 25, nameKey = "product.qirsh_pouch" },
	qirsh_purse = { productId = 3720107876, kind = "qirsh", amount = 450, robux = 99, nameKey = "product.qirsh_purse" },
	qirsh_chest = { productId = 3720107991, kind = "qirsh", amount = 1000, robux = 199, nameKey = "product.qirsh_chest" },
	-- Lira (summons currency). Hidden for players whose region restricts paid random items.
	lira_100 = { productId = 3720108028, kind = "lira", amount = 100, robux = 49, nameKey = "product.lira_100" },
	lira_300 = { productId = 3720108152, kind = "lira", amount = 320, robux = 129, nameKey = "product.lira_300" },
	lira_650 = { productId = 3720108172, kind = "lira", amount = 700, robux = 249, nameKey = "product.lira_650" },
	lira_1500 = { productId = 3720108206, kind = "lira", amount = 1650, robux = 499, nameKey = "product.lira_1500" },
	lira_4000 = { productId = 3720108234, kind = "lira", amount = 4500, robux = 1199, nameKey = "product.lira_4000" },
	-- Trait stones
	stones_3 = { productId = 3720108345, kind = "stones", amount = 3, robux = 99, nameKey = "product.stones_3" },
	stones_10 = { productId = 3720108374, kind = "stones", amount = 10, robux = 279, nameKey = "product.stones_10" },
	-- Season pass
	pass_premium_s1 = { productId = 3720108408, kind = "passPremium", season = "s1", fallbackLira = 800, robux = 799, nameKey = "product.pass_premium", descKey = "product.pass_premium.desc" },
	pass_skip_10 = { productId = 3720108439, kind = "passSkip", amount = 10, robux = 999, nameKey = "product.pass_skip" },
	-- Starter pack (once per player)
	starter_pack = {
		productId = 3720108571,
		kind = "bundle",
		oneTime = true,
		bundle = { lira = 300, unit = "qabaday", item = "tarboosh_red" },
		fallbackLira = 300,
		robux = 199,
		nameKey = "product.starter_pack",
		descKey = "product.starter_pack.desc",
	},
	-- The rewarded video ad's reward (`ads` below): granted through ProcessReceipt like any purchase, its
	-- receipt on the AdReward channel. Roblox requires the reward to be a product also sold for Robux, never a
	-- random item: qirsh only buys cosmetics, so it is not one (MonetizationLogic.fundsRandomItems).
	ad_qirsh_25 = { productId = 3720108682, kind = "qirsh", amount = 25, robux = 7, nameKey = "product.ad_qirsh_25" },
	-- Cosmetics
	item_tarboosh_gold = {
		productId = 3720108604,
		kind = "item",
		item = "tarboosh_gold",
		fallbackQirsh = 300,
		robux = 79,
		nameKey = "item.tarboosh_gold.name",
	},
	item_qumbaz_wedding = {
		productId = 3720108644,
		kind = "item",
		item = "qumbaz_wedding",
		fallbackQirsh = 500,
		robux = 129,
		nameKey = "item.qumbaz_wedding.name",
	},
}

local gamePasses: { [string]: GamePass } = {
	vip = {
		gamePassId = 2041676362,
		items = { "shawl_embroidered" },
		robux = 299,
		nameKey = "pass.vip.name",
		descKey = "pass.vip.desc",
		perk = "vip",
	},
	fast_mode = {
		gamePassId = 2038120926,
		items = {},
		robux = 799,
		nameKey = "pass.fast_mode.name",
		descKey = "pass.fast_mode.desc",
		perk = "fast",
	},
	extra_slot = {
		gamePassId = 2036332883,
		items = {},
		robux = 149,
		nameKey = "pass.extra_slot.name",
		descKey = "pass.extra_slot.desc",
		perk = "slot",
	},
	lane_patron = {
		gamePassId = 2040154471,
		items = { "tarboosh_gold", "shawl_embroidered" },
		robux = 249,
		nameKey = "pass.lane_patron.name",
		descKey = "pass.lane_patron.desc",
	},
}

return {
	devProducts = devProducts,
	gamePasses = gamePasses,
	-- Store tabs, in order
	liraOrder = { "lira_100", "lira_300", "lira_650", "lira_1500", "lira_4000" },
	storeOrder = { "qirsh_pouch", "qirsh_purse", "qirsh_chest" },
	extrasOrder = { "starter_pack", "stones_3", "stones_10", "pass_skip_10" },
	passOrder = { "vip", "fast_mode", "extra_slot", "lane_patron" },
	-- Rewarded video ads (AdService): the store's ad row plays one and Roblox pays `reward` through
	-- ProcessReceipt. The server allows one ad per `cooldownSeconds` and at most `perSession` a session.
	-- `enabled` stays false until the owner turns Rewarded Video serving on in Creator Hub (Monetization →
	-- Ads): until then Roblox refuses every ad ("not enabled for this universe") although
	-- GetAdAvailabilityNowAsync still answers IsAvailable. Studio ignores it so the flow stays testable.
	ads = { enabled = false, reward = "ad_qirsh_25", cooldownSeconds = 600, perSession = 6 },
}
