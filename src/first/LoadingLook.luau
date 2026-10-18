--!strict
-- Loading screen numbers and text (POLISH_PLAN PV-D05). Lives in ReplicatedFirst with the loading
-- screen because it must run before ReplicatedStorage.Shared has replicated, so it cannot read
-- Config/Strings, Palette or Vfx; tests/loading.spec.luau keeps the copied values in step with them.
-- The logo images (PV-D01, owner picked mark variant 3 on 2026-10-18) swap in over the drawn mark
-- and the text wordmark once they have loaded; id 0 = fallbacks only. Pure data.

return {
	minTime = 1.2, -- seconds on screen even when everything is cached (finish ≤ 2.5 s with the fade)
	maxTime = 30, -- give up waiting and show the lobby anyway (D-013 keeps join → lobby ≤ 60 s)
	fade = 0.4, -- crossfade into the lobby
	markFade = 0.5, -- the mark fading in
	lineEvery = 2.2, -- seconds per bilingual line

	colors = {
		backdrop = "#E6D5B8", -- Palette.stoneLight
		basalt = "#3D3A38", -- Palette.basalt
		honey = "#D9BF94", -- Palette.stoneWarm
		door = "#6B4423", -- Palette.wood
		leaf = "#4F7A32",
		jasmine = "#FBF8F1", -- Palette.jasmine
		text = "#3A2612",
		gold = "#F6D68C",
	},

	images = {
		mark = 94560000612541, -- assets/marketing/logo/mark_256.png (tools/upload_manifest.json)
		wordmark = 124741548596324, -- assets/marketing/logo/wordmark.png
		petal = 134057751781553, -- Config/Vfx.TEXTURES.petal
	},

	petals = { count = 12, minSize = 14, maxSize = 26, minFall = 5, maxFall = 9 }, -- px, seconds per fall

	wordmark = { ar = "حارة الياسمين", en = "Haret Al-Yasmin" },

	lines = {
		{ en = "Jasmine Lane is waking up…", ar = "حارة الياسمين عم تصحى…" },
		{ en = "The baker lights the oven…", ar = "الفرّان عم يولّع الفرن…" },
		{ en = "Lanterns are being lit…", ar = "عم يضوّوا الفوانيس…" },
		{ en = "The watchman opens the gate…", ar = "الناطور عم يفتح البوابة…" },
	},
}
