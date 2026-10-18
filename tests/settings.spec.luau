--!nocheck
-- Player settings: validation of client changes and sanitisation of stored values.

return function(t)
	local Settings = t.logic("Settings")
	local ProfileSchema = t.logic("ProfileSchema")

	t.describe("Settings", function()
		t.it("accepts only known keys with allowed values", function()
			t.truthy(Settings.accept("effects", "reduced"))
			t.truthy(Settings.accept("skipSummon", true))
			t.truthy(Settings.accept("camera", "overhead"))
			t.truthy(Settings.accept("autoSkip", true))
			t.eq(Settings.accept("autoSkip", "on"), false)
			t.eq(Settings.accept("effects", "ultra"), false)
			t.eq(Settings.accept("skipSummon", "yes"), false)
			t.eq(Settings.accept("camera", 1), false)
			t.eq(Settings.accept("language", "en"), false, "language has its own remote")
			t.eq(Settings.accept("lira", 999), false)
			t.eq(Settings.accept(nil, true), false)
			t.eq(Settings.accept({}, true), false)
		end)

		t.it("accepts the music and sfx toggles as booleans only, default on", function()
			for _, key in { "music", "sfx" } do
				t.truthy(Settings.accept(key, true))
				t.truthy(Settings.accept(key, false))
				t.eq(Settings.accept(key, "off"), false)
				t.eq(Settings.accept(key, 1), false)
				t.eq(Settings.accept(key, nil), false)
				t.eq(Settings.get(nil, key), true, key .. " defaults on")
				t.eq(Settings.get({ [key] = "off" }, key), true, "bad stored value falls back to the default")
				t.eq(Settings.get({ [key] = false }, key), false)
			end
			local s = Settings.sanitize({ music = 0, sfx = false })
			t.eq(s.music, nil)
			t.eq(s.sfx, false)
		end)

		t.it("resolves defaults for missing or bad values", function()
			local r = Settings.resolve({ effects = "off", camera = "sideways" })
			t.eq(r.effects, "off")
			t.eq(r.camera, "walk")
			t.eq(r.skipSummon, false)
			t.eq(r.autoUlt, true)
			t.eq(r.autoSkip, false, "auto skip is opt-in")
			t.eq(Settings.resolve(nil).effects, "full")
		end)

		t.it("knows the touch HUD settings (MOBILE_HUD_PLAN MH-02)", function()
			local r = Settings.resolve(nil)
			t.eq(r.uiScale, "default")
			t.eq(r.panelSide, "auto")
			t.eq(r.quickPlace, false, "quick place is opt-in")
			t.eq(r.railSide, "right")
			for _, v in { "small", "default", "large", "huge" } do
				t.truthy(Settings.accept("uiScale", v), v)
			end
			t.eq(Settings.accept("uiScale", "giant"), false)
			t.eq(Settings.accept("uiScale", 1.3), false)
			for _, v in { "auto", "side", "bottom" } do
				t.truthy(Settings.accept("panelSide", v), v)
			end
			t.eq(Settings.accept("panelSide", "top"), false)
			t.truthy(Settings.accept("quickPlace", true))
			t.eq(Settings.accept("quickPlace", "true"), false)
			t.truthy(Settings.accept("railSide", "left"))
			t.eq(Settings.accept("railSide", "middle"), false)
			local s = Settings.sanitize({ uiScale = "giant", panelSide = "bottom", quickPlace = 1, railSide = "left" })
			t.eq(s.uiScale, nil)
			t.eq(s.panelSide, "bottom")
			t.eq(s.quickPlace, nil)
			t.eq(s.railSide, "left")
			-- Every uiScale value is a Config/Hud preset, and the other way round.
			local Hud = t.config("Hud")
			local n = 0
			for _, v in Settings.defs.uiScale.values do
				t.truthy(Hud.SCALE.presets[v], "preset " .. v)
				n += 1
			end
			for _ in Hud.SCALE.presets do
				n -= 1
			end
			t.eq(n, 0)
		end)

		t.it("profile sanitize drops invalid settings but keeps language", function()
			local ctx = t.schemaCtx()
			local p = ProfileSchema.default(1000, ctx.schemaVersion, ctx)
			p.settings = { language = "ar", effects = "ultra", skipSummon = true, junk = 5 }
			local s = ProfileSchema.sanitize(p, ctx, 1000)
			t.eq(s.settings.language, "ar")
			t.eq(s.settings.effects, nil)
			t.eq(s.settings.skipSummon, true)
		end)
	end)
end
