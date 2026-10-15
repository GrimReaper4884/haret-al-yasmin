--!strict
-- Item catalogue. Pure data (no Roblox datatypes) so Lune tests can load it.
-- Visuals for cosmetics live in CosmeticVisuals.luau; icons in client UI/Icons.luau.
--
-- Pricing: `price` = qirsh (earned in play). `product` = key in Config/Products for Robux-only items.
-- Cosmetics never change gameplay (docs/MONETIZATION.md: no pay-to-win).

export type Slot = "head" | "torso" | "legs" | "waist" | "back"

export type ItemDef = {
	kind: "quest" | "cosmetic",
	nameKey: string,
	descKey: string,
	stackMax: number,
	price: number?, -- qirsh
	product: string?, -- Robux developer product key (Config/Products)
	slot: Slot?, -- cosmetics only
	icon: string, -- UI/Icons drawer name
	iconColor: string?, -- hex
}

local Items: { [string]: ItemDef } = {
	basket_kaak = {
		kind = "quest",
		nameKey = "item.basket_kaak.name",
		descKey = "item.basket_kaak.desc",
		stackMax = 1,
		icon = "basket",
	},

	-- Head
	tarboosh_red = {
		kind = "cosmetic",
		nameKey = "item.tarboosh_red.name",
		descKey = "item.tarboosh_red.desc",
		stackMax = 1,
		price = 40,
		slot = "head",
		icon = "tarboosh",
		iconColor = "#A4302A",
	},
	tarboosh_black = {
		kind = "cosmetic",
		nameKey = "item.tarboosh_black.name",
		descKey = "item.tarboosh_black.desc",
		stackMax = 1,
		price = 60,
		slot = "head",
		icon = "tarboosh",
		iconColor = "#1F1B18",
	},
	taqiyah_white = {
		kind = "cosmetic",
		nameKey = "item.taqiyah_white.name",
		descKey = "item.taqiyah_white.desc",
		stackMax = 1,
		price = 20,
		slot = "head",
		icon = "cap",
		iconColor = "#FBF8F1",
	},
	hatta_agal = {
		kind = "cosmetic",
		nameKey = "item.hatta_agal.name",
		descKey = "item.hatta_agal.desc",
		stackMax = 1,
		price = 70,
		slot = "head",
		icon = "hatta",
		iconColor = "#EFE6D2",
	},
	tarboosh_gold = {
		kind = "cosmetic",
		nameKey = "item.tarboosh_gold.name",
		descKey = "item.tarboosh_gold.desc",
		stackMax = 1,
		product = "item_tarboosh_gold",
		slot = "head",
		icon = "tarboosh",
		iconColor = "#C9A13B",
	},

	-- Torso
	sidriyye_black = {
		kind = "cosmetic",
		nameKey = "item.sidriyye_black.name",
		descKey = "item.sidriyye_black.desc",
		stackMax = 1,
		price = 90,
		slot = "torso",
		icon = "vest",
		iconColor = "#1F1B18",
	},
	qumbaz_striped = {
		kind = "cosmetic",
		nameKey = "item.qumbaz_striped.name",
		descKey = "item.qumbaz_striped.desc",
		stackMax = 1,
		price = 150,
		slot = "torso",
		icon = "robe",
		iconColor = "#8C6A3F",
	},
	qumbaz_wedding = {
		kind = "cosmetic",
		nameKey = "item.qumbaz_wedding.name",
		descKey = "item.qumbaz_wedding.desc",
		stackMax = 1,
		product = "item_qumbaz_wedding",
		slot = "torso",
		icon = "robe",
		iconColor = "#EFE6D2",
	},

	-- Legs
	sherwal_black = {
		kind = "cosmetic",
		nameKey = "item.sherwal_black.name",
		descKey = "item.sherwal_black.desc",
		stackMax = 1,
		price = 80,
		slot = "legs",
		icon = "trousers",
		iconColor = "#1F1B18",
	},
	sherwal_indigo = {
		kind = "cosmetic",
		nameKey = "item.sherwal_indigo.name",
		descKey = "item.sherwal_indigo.desc",
		stackMax = 1,
		price = 80,
		slot = "legs",
		icon = "trousers",
		iconColor = "#2F3E6B",
	},

	-- Waist
	zunnar_sash = {
		kind = "cosmetic",
		nameKey = "item.zunnar_sash.name",
		descKey = "item.zunnar_sash.desc",
		stackMax = 1,
		price = 30,
		slot = "waist",
		icon = "sash",
		iconColor = "#A4302A",
	},

	-- Back
	abaya_brown = {
		kind = "cosmetic",
		nameKey = "item.abaya_brown.name",
		descKey = "item.abaya_brown.desc",
		stackMax = 1,
		price = 120,
		slot = "back",
		icon = "cloak",
		iconColor = "#5A4030",
	},
	shawl_embroidered = {
		kind = "cosmetic",
		nameKey = "item.shawl_embroidered.name",
		descKey = "item.shawl_embroidered.desc",
		stackMax = 1,
		price = 100,
		slot = "back",
		icon = "cloak",
		iconColor = "#2E8B87",
	},
}

return Items
