--!strict
-- Shops: which NPC runs them and which items they sell. Prices come from Items.

export type ShopDef = { npc: string, titleKey: string, items: { string } }

local Shops: { [string]: ShopDef } = {
	khalil_tailor = {
		npc = "khalil_tailor",
		titleKey = "shop.khalil_tailor.title",
		items = {
			"tarboosh_red",
			"tarboosh_black",
			"taqiyah_white",
			"hatta_agal",
			"sidriyye_black",
			"qumbaz_striped",
			"sherwal_black",
			"sherwal_indigo",
			"zunnar_sash",
			"abaya_brown",
			"shawl_embroidered",
			-- Robux-only (Config/Products)
			"tarboosh_gold",
			"qumbaz_wedding",
		},
	},
}

return Shops
