--!strict
-- Shops: which NPC runs them and which items they sell. Prices come from Items.

export type ShopDef = { npc: string, titleKey: string, items: { string } }

local Shops: { [string]: ShopDef } = {
	khalil_tailor = {
		npc = "khalil_tailor",
		titleKey = "shop.khalil_tailor.title",
		items = { "tarboosh_red" },
	},
}

return Shops
