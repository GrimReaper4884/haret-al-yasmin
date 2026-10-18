--!nocheck
-- Loading screen (POLISH_PLAN PV-D05): bar progress, finish rule, line cycling, and the values the
-- ReplicatedFirst config copies from Shared (it runs before Shared replicates).

return function(t)
	local LoadingLogic = require("../src/first/LoadingLogic")
	local Look = require("../src/first/LoadingLook")
	local fs = require("@lune/fs")
	-- Palette builds Color3s (no Color3 under Lune): read its hex strings from the source instead.
	local paletteSrc = fs.readFile("src/shared/Config/Palette.luau")
	local function paletteHex(key)
		return string.match(paletteSrc, key .. '%s*=%s*Color3%.fromHex%("(#%x+)"%)')
	end
	local Vfx = t.config("Vfx")

	t.describe("LoadingScreen", function()
		t.it("the bar fills as the asset queue drains and never goes back", function()
			t.eq(LoadingLogic.progress(0, 0), 1, "nothing to load = full")
			t.eq(LoadingLogic.progress(40, 40), 0)
			t.eq(LoadingLogic.progress(40, 10), 0.75)
			t.eq(LoadingLogic.ease(0.6, 0.4, 0.016, 6), 0.6, "never backwards")
			local v = LoadingLogic.ease(0.2, 1, 0.016, 6)
			t.truthy(v > 0.2 and v < 1, "eases toward the target")
			t.eq(LoadingLogic.ease(0.9, 1, 10, 6), 1, "large dt lands on the target")
		end)

		t.it("hands over after the minimum time once loaded, empty and the character exists", function()
			local ready = { elapsed = 2, loaded = true, queue = 0, ready = true }
			t.eq(LoadingLogic.done(ready, Look.minTime, Look.maxTime), true)
			t.eq(
				LoadingLogic.done(
					{ elapsed = 0.5, loaded = true, queue = 0, ready = true },
					Look.minTime,
					Look.maxTime
				),
				false,
				"minimum time"
			)
			t.eq(
				LoadingLogic.done(
					{ elapsed = 5, loaded = true, queue = 3, ready = true },
					Look.minTime,
					Look.maxTime
				),
				false,
				"queue"
			)
			t.eq(
				LoadingLogic.done(
					{ elapsed = 5, loaded = false, queue = 0, ready = true },
					Look.minTime,
					Look.maxTime
				),
				false,
				"not loaded"
			)
			t.eq(
				LoadingLogic.done(
					{ elapsed = 5, loaded = true, queue = 0, ready = false },
					Look.minTime,
					Look.maxTime
				),
				false,
				"no character"
			)
			t.eq(
				LoadingLogic.done(
					{ elapsed = Look.maxTime, loaded = false, queue = 9, ready = false },
					Look.minTime,
					Look.maxTime
				),
				true,
				"gives up at maxTime"
			)
		end)

		t.it("a cached join is over within 2.5 s and the cap stays under the 60 s join rule", function()
			t.truthy(Look.minTime + Look.fade <= 2.5)
			t.truthy(Look.maxTime + Look.fade < 60)
		end)

		t.it("bilingual lines cycle and every line has both languages", function()
			t.truthy(#Look.lines >= 2)
			for _, l in Look.lines do
				t.truthy(#l.en > 0 and #l.ar > 0)
			end
			t.eq(LoadingLogic.line(0, Look.lineEvery, #Look.lines), 1)
			t.eq(
				LoadingLogic.line(Look.lineEvery * #Look.lines + 0.1, Look.lineEvery, #Look.lines),
				1,
				"wraps"
			)
			t.eq(LoadingLogic.line(Look.lineEvery + 0.01, Look.lineEvery, #Look.lines), 2)
		end)

		t.it("copied colours and the petal sprite match Shared config", function()
			t.eq(Look.colors.backdrop, paletteHex("stoneLight"), "backdrop = Palette.stoneLight")
			t.eq(Look.colors.basalt, paletteHex("basalt"))
			t.eq(Look.colors.honey, paletteHex("stoneWarm"))
			t.eq(Look.colors.door, paletteHex("wood"))
			t.eq(Look.images.petal, Vfx.TEXTURES.petal.id)
		end)

		t.it("stripe gradients stay within Roblox's ColorSequence rules", function()
			for _, bands in { 1, 9, 10 } do
				local stops = LoadingLogic.stripeStops(bands)
				t.truthy(#stops <= 20, "at most 20 keypoints")
				t.eq(stops[1][1], 0, "starts at 0")
				t.eq(stops[#stops][1], 1, "ends at exactly 1")
				for k = 2, #stops do
					t.truthy(stops[k][1] >= stops[k - 1][1], "times never go back")
				end
			end
		end)

		t.it("logo image ids match the upload manifest", function()
			local serde = require("@lune/serde")
			local manifest = serde.decode("json", fs.readFile("tools/upload_manifest.json"))
			t.eq(Look.images.mark, manifest.files["assets/marketing/logo/mark_256.png"].id)
			t.eq(Look.images.wordmark, manifest.files["assets/marketing/logo/wordmark.png"].id)
		end)
	end)
end
