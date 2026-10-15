--!strict
-- Item catalogue. Pure data (no Roblox datatypes) so Lune tests can load it.
-- Visuals for cosmetics live in CosmeticVisuals.luau.

export type ItemDef = {
	kind: "quest" | "cosmetic",
	nameKey: string,
	descKey: string,
	stackMax: number,
	price: number?, -- qirsh; cosmetics only
	slot: string?, -- cosmetics only
	icon: string, -- unicode glyph used by the slice UI
}

local Items: { [string]: ItemDef } = {
	basket_kaak = {
		kind = "quest",
		nameKey = "item.basket_kaak.name",
		descKey = "item.basket_kaak.desc",
		stackMax = 1,
		icon = "🧺",
	},
	tarboosh_red = {
		kind = "cosmetic",
		nameKey = "item.tarboosh_red.name",
		descKey = "item.tarboosh_red.desc",
		stackMax = 1,
		price = 40,
		slot = "head",
		icon = "🎩",
	},
}

return Items
