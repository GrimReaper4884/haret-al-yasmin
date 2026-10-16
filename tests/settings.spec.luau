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
			t.eq(Settings.accept("effects", "ultra"), false)
			t.eq(Settings.accept("skipSummon", "yes"), false)
			t.eq(Settings.accept("camera", 1), false)
			t.eq(Settings.accept("language", "en"), false, "language has its own remote")
			t.eq(Settings.accept("lira", 999), false)
			t.eq(Settings.accept(nil, true), false)
			t.eq(Settings.accept({}, true), false)
		end)

		t.it("resolves defaults for missing or bad values", function()
			local r = Settings.resolve({ effects = "off", camera = "sideways" })
			t.eq(r.effects, "off")
			t.eq(r.camera, "walk")
			t.eq(r.skipSummon, false)
			t.eq(r.autoUlt, true)
			t.eq(Settings.resolve(nil).effects, "full")
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
