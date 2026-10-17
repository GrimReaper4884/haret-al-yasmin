--!strict
-- Robux products. IDs are 0 until the owner creates each product in the Creator Dashboard and
-- approves its price (docs/MONETIZATION.md, RELEASE_CHECKLIST §D). A product with id 0 is shown as
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
	qirsh_pouch = { productId = 0, kind = "qirsh", amount = 100, robux = 25, nameKey = "product.qirsh_pouch" },
	qirsh_purse = { productId = 0, kind = "qirsh", amount = 450, robux = 99, nameKey = "product.qirsh_purse" },
	qirsh_chest = { productId = 0, kind = "qirsh", amount = 1000, robux = 199, nameKey = "product.qirsh_chest" },
	-- Lira (summons currency). Hidden for players whose region restricts paid random items.
	lira_100 = { productId = 0, kind = "lira", amount = 100, robux = 49, nameKey = "product.lira_100" },
	lira_300 = { productId = 0, kind = "lira", amount = 320, robux = 129, nameKey = "product.lira_300" },
	lira_650 = { productId = 0, kind = "lira", amount = 700, robux = 249, nameKey = "product.lira_650" },
	lira_1500 = { productId = 0, kind = "lira", amount = 1650, robux = 499, nameKey = "product.lira_1500" },
	lira_4000 = { productId = 0, kind = "lira", amount = 4500, robux = 1199, nameKey = "product.lira_4000" },
	-- Trait stones
	stones_3 = { productId = 0, kind = "stones", amount = 3, robux = 99, nameKey = "product.stones_3" },
	stones_10 = { productId = 0, kind = "stones", amount = 10, robux = 279, nameKey = "product.stones_10" },
	-- Season pass
	pass_premium_s1 = { productId = 0, kind = "passPremium", season = "s1", fallbackLira = 800, robux = 799, nameKey = "product.pass_premium", descKey = "product.pass_premium.desc" },
	pass_skip_10 = { productId = 0, kind = "passSkip", amount = 10, robux = 999, nameKey = "product.pass_skip" },
	-- Starter pack (once per player)
	starter_pack = {
		productId = 0,
		kind = "bundle",
		oneTime = true,
		bundle = { lira = 300, unit = "qabaday", item = "tarboosh_red" },
		fallbackLira = 300,
		robux = 199,
		nameKey = "product.starter_pack",
		descKey = "product.starter_pack.desc",
	},
	-- Cosmetics
	item_tarboosh_gold = {
		productId = 0,
		kind = "item",
		item = "tarboosh_gold",
		fallbackQirsh = 300,
		robux = 79,
		nameKey = "item.tarboosh_gold.name",
	},
	item_qumbaz_wedding = {
		productId = 0,
		kind = "item",
		item = "qumbaz_wedding",
		fallbackQirsh = 500,
		robux = 129,
		nameKey = "item.qumbaz_wedding.name",
	},
}

local gamePasses: { [string]: GamePass } = {
	vip = {
		gamePassId = 0,
		items = { "shawl_embroidered" },
		robux = 299,
		nameKey = "pass.vip.name",
		descKey = "pass.vip.desc",
		perk = "vip",
	},
	fast_mode = {
		gamePassId = 0,
		items = {},
		robux = 799,
		nameKey = "pass.fast_mode.name",
		descKey = "pass.fast_mode.desc",
		perk = "fast",
	},
	extra_slot = {
		gamePassId = 0,
		items = {},
		robux = 149,
		nameKey = "pass.extra_slot.name",
		descKey = "pass.extra_slot.desc",
		perk = "slot",
	},
	lane_patron = {
		gamePassId = 0,
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
}
