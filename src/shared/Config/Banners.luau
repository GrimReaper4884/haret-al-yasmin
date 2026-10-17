--!strict
-- Summon banners. Pure data. The active banner rotates every TD.BANNER_ROTATION seconds in this
-- order (Logic/SummonLogic.activeBanner). Each banner features one Legendary and one Mythic that
-- take TD.FEATURED_SHARE of their rarity's rolls; the rest of the rarity is split evenly among
-- all banner-eligible units of that rarity (Units without noBanner).

export type BannerDef = {
	nameKey: string,
	featuredLegendary: string,
	featuredMythic: string,
}

local Banners: { BannerDef } = {
	{ nameKey = "banner.zaim.name", featuredLegendary = "zaim", featuredMythic = "zaim_akbar" },
	{ nameKey = "banner.pahlawan.name", featuredLegendary = "pahlawan", featuredMythic = "arada" },
	{ nameKey = "banner.umm_hara.name", featuredLegendary = "umm_hara", featuredMythic = "zaim_akbar" },
}

return Banners
