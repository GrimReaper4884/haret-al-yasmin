--!strict
-- Robux products. IDs are 0 until the owner creates each product in the Creator Dashboard and
-- approves its price (docs/MONETIZATION.md, RELEASE_CHECKLIST §D). A product with id 0 is shown as
-- "coming soon" and can never be prompted. `robux` is the PLANNED price, for docs/UI only; the
-- real price always comes from MarketplaceService.

export type DevProduct = {
	productId: number,
	kind: "qirsh" | "item",
	amount: number?, -- qirsh packs
	item: string?, -- item products
	fallbackQirsh: number?, -- paid instead if the item is somehow already owned (race)
	robux: number, -- planned price
	nameKey: string,
}

export type GamePass = {
	gamePassId: number,
	items: { string }, -- cosmetics granted while the pass is owned
	robux: number,
	nameKey: string,
	descKey: string,
}

local devProducts: { [string]: DevProduct } = {
	qirsh_pouch = { productId = 0, kind = "qirsh", amount = 100, robux = 25, nameKey = "product.qirsh_pouch" },
	qirsh_purse = { productId = 0, kind = "qirsh", amount = 450, robux = 99, nameKey = "product.qirsh_purse" },
	qirsh_chest = { productId = 0, kind = "qirsh", amount = 1000, robux = 199, nameKey = "product.qirsh_chest" },
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
	-- Qirsh packs shown in the store panel, in order.
	storeOrder = { "qirsh_pouch", "qirsh_purse", "qirsh_chest" },
}
