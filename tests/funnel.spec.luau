--!nocheck
-- Onboarding funnel (Logic/FunnelLogic, BUILD_PLAN P2-16): first-time stamps, ordering, report.

return function(t)
	local FunnelLogic = t.logic("FunnelLogic")
	local ProfileSchema = t.logic("ProfileSchema")

	t.describe("FunnelLogic", function()
		t.it("has the seven steps in order with 1-based step numbers", function()
			t.deepEq(FunnelLogic.ORDER, { "join", "prompt", "summon", "portal", "wave1", "wave5", "clear" })
			for i, name in FunnelLogic.ORDER do
				t.eq(FunnelLogic.STEPS[name].step, i)
				t.eq(FunnelLogic.STEPS[name].name, name)
			end
			t.eq(FunnelLogic.WAVE_STEPS[1], "wave1")
			t.eq(FunnelLogic.WAVE_STEPS[5], "wave5")
			t.eq(FunnelLogic.WAVE_STEPS[2], nil)
		end)

		t.it("stamps a step the first time only", function()
			local p = {}
			t.eq(FunnelLogic.mark(p, "join", 100), true)
			t.eq(FunnelLogic.mark(p, "join", 200), false, "second join is not a funnel event")
			t.eq(p.funnel.join, 100)
			t.eq(FunnelLogic.reached(p, "join"), true)
			t.eq(FunnelLogic.reached(p, "wave1"), false)
			t.eq(FunnelLogic.mark(p, "nope", 1), false, "unknown steps are ignored")
			t.eq(p.funnel.nope, nil)
		end)

		t.it("measures join → step in seconds", function()
			local p = {}
			t.eq(FunnelLogic.sinceJoin(p, "wave1"), nil)
			FunnelLogic.mark(p, "join", 1000)
			t.eq(FunnelLogic.sinceJoin(p, "wave1"), nil, "not reached yet")
			FunnelLogic.mark(p, "portal", 1020)
			FunnelLogic.mark(p, "wave1", 1045)
			t.eq(FunnelLogic.sinceJoin(p, "portal"), 20)
			t.eq(FunnelLogic.sinceJoin(p, "wave1"), 45)
			t.truthy(FunnelLogic.sinceJoin(p, "wave1") <= 60, "the P2-16 target")
		end)

		t.it("reports one row per step in order", function()
			local p = {}
			FunnelLogic.mark(p, "join", 10)
			FunnelLogic.mark(p, "summon", 25)
			local rows = FunnelLogic.report(p)
			t.eq(#rows, 7)
			t.eq(rows[1].name, "join")
			t.eq(rows[1].at, 10)
			t.eq(rows[1].sinceJoin, 0)
			t.eq(rows[2].name, "prompt")
			t.eq(rows[2].at, nil)
			t.eq(rows[2].sinceJoin, nil)
			t.eq(rows[3].name, "summon")
			t.eq(rows[3].sinceJoin, 15)
			t.eq(rows[7].step, 7)
		end)

		t.it("sanitize keeps known finite stamps only", function()
			local clean = FunnelLogic.sanitize({ join = 5, wave1 = "soon", clear = 0 / 0, bogus = 3, wave5 = 99 })
			t.deepEq(clean, { join = 5, wave5 = 99 })
			t.deepEq(FunnelLogic.sanitize(nil), {})
			t.deepEq(FunnelLogic.sanitize(7), {})
		end)

		t.it("survives a profile round trip through ProfileSchema", function()
			local ctx = t.schemaCtx()
			local p = ProfileSchema.default(1, ctx.schemaVersion, ctx)
			t.deepEq(p.funnel, {})
			FunnelLogic.mark(p, "join", 1)
			FunnelLogic.mark(p, "wave1", 50)
			p.funnel.garbage = 1
			local loaded = ProfileSchema.load(ProfileSchema.clone(p), ctx, 100)
			t.deepEq(loaded.funnel, { join = 1, wave1 = 50 })
			t.eq(FunnelLogic.sinceJoin(loaded, "wave1"), 49)
			local legacy = ProfileSchema.load({ schemaVersion = 2 }, ctx, 1)
			t.deepEq(legacy.funnel, {})
		end)
	end)
end
