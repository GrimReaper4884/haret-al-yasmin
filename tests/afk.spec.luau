--!nocheck
-- AFK chamber (the Hakawati's room): cups, tales, the daily cap, bonuses, carry, sanitising.

return function(t)
	local AfkLogic = t.logic("AfkLogic")
	local ProfileSchema = t.logic("ProfileSchema")
	local Settings = t.logic("Settings")
	local Afk = t.config("Afk")
	local Strings = t.config("Strings")
	local Items = t.config("Items")
	local Units = t.config("Units")
	local Traits = t.config("Traits")
	local TD = t.config("TD")

	local DAY = 86400
	local NOW = 20000 * DAY + 3600

	local function profile()
		return {
			qirsh = 0,
			lira = 0,
			traitStones = 0,
			inventory = {},
			units = {},
			pass = { season = "s1", xp = 0, premium = false, claimedFree = {}, claimedPremium = {} },
			afk = AfkLogic.sanitize(nil),
		}
	end

	local function ctx()
		return {
			maxQirsh = 1000000,
			maxLira = TD.MAX_LIRA,
			maxStones = TD.MAX_TRAIT_STONES,
			items = Items,
			units = Units,
			traits = Traits,
			rng = math.random,
			now = NOW,
		}
	end

	local never = function()
		return 0.999
	end
	local always = function()
		return 0
	end

	-- Sits `seconds` in flush-sized steps, like the server does. Returns all payouts.
	local function sit(p, seconds, mult, rng, now)
		local all = {}
		while seconds > 0 do
			local step = math.min(seconds, Afk.FLUSH_SECONDS)
			seconds -= step
			local ok, _, payouts = AfkLogic.accrue(p, step, now or NOW, Afk, mult or 1, rng or never, ctx())
			assert(ok)
			for _, x in payouts do
				table.insert(all, x)
			end
		end
		return all
	end

	t.describe("AfkLogic", function()
		t.it("pours one cup every CUP_SECONDS and keeps the carry", function()
			local p = profile()
			t.eq(#sit(p, Afk.CUP_SECONDS - 1), 0, "no cup before the time")
			t.eq(p.afk.carry, Afk.CUP_SECONDS - 1)
			local pays = sit(p, 1)
			t.eq(#pays, 1)
			t.eq(pays[1].kind, "cup")
			t.eq(p.lira, Afk.CUP.lira)
			t.eq(p.qirsh, Afk.CUP.qirsh)
			t.eq(p.pass.xp, Afk.CUP.xp)
			t.eq(p.afk.carry, 0)
			t.eq(p.afk.cups, 1)
		end)

		t.it("finishes a tale every CUPS_PER_TALE cups and moves to the next tale", function()
			local p = profile()
			local pays = sit(p, Afk.CUP_SECONDS * Afk.CUPS_PER_TALE)
			t.eq(#pays, Afk.CUPS_PER_TALE + 1)
			local last = pays[#pays]
			t.eq(last.kind, "tale")
			t.eq(last.tale, Afk.TALES[1])
			t.eq(p.afk.tales, 1)
			local next, poured = AfkLogic.tale(p, Afk)
			t.eq(next, Afk.TALES[2])
			t.eq(poured, 0)
			t.eq(p.lira, Afk.CUP.lira * Afk.CUPS_PER_TALE + Afk.TALE.lira)
		end)

		t.it("a finished tale can drop a trait stone", function()
			local p = profile()
			sit(p, Afk.CUP_SECONDS * Afk.CUPS_PER_TALE, 1, always)
			t.eq(p.traitStones, 1)
		end)

		t.it("an hour at ×1 pays about 12% of an active hour's lira", function()
			local p = profile()
			sit(p, 3600)
			t.eq(p.lira, 80, "60 from cups + 20 from two tales")
		end)

		t.it("stops paying lira at the day's cap, then pays the overflow", function()
			local p = profile()
			sit(p, 24 * 3600)
			local cap = AfkLogic.cap(Afk, 1)
			t.eq(p.lira, cap, "lira capped")
			t.eq(p.afk.lira, cap)
			t.eq(AfkLogic.paidToday(p, NOW), cap)
			local q = p.qirsh
			local pays = sit(p, Afk.CUP_SECONDS)
			t.eq(#pays, 1)
			t.truthy(pays[1].capped, "capped flag")
			t.eq(p.lira, cap, "no more lira")
			t.eq(p.qirsh - q, Afk.OVERFLOW.qirsh)
		end)

		t.it("a new UTC day resets the cap", function()
			local p = profile()
			sit(p, 24 * 3600)
			t.eq(AfkLogic.paidToday(p, NOW + DAY), 0)
			local before = p.lira
			sit(p, Afk.CUP_SECONDS, 1, never, NOW + DAY)
			t.eq(p.lira - before, Afk.CUP.lira)
			t.eq(p.afk.day, AfkLogic.day(NOW + DAY))
		end)

		t.it("VIP doubles the pay and the cap; Premium adds half; both stack additively", function()
			t.eq(AfkLogic.multiplier(Afk, false, false), 1)
			t.eq(AfkLogic.multiplier(Afk, true, false), 2)
			t.eq(AfkLogic.multiplier(Afk, false, true), 1.5)
			t.eq(AfkLogic.multiplier(Afk, true, true), 2.5)
			local p = profile()
			sit(p, Afk.CUP_SECONDS, 2)
			t.eq(p.lira, Afk.CUP.lira * 2)
			local v = profile()
			sit(v, 48 * 3600, 2)
			t.eq(v.lira, Afk.DAILY_CAP_LIRA * 2)
			local b = profile()
			sit(b, Afk.CUP_SECONDS, 2.5)
			t.eq(b.lira, math.floor(Afk.CUP.lira * 2.5 + 0.5))
		end)

		t.it("rejects bad input and clamps a stalled server's burst", function()
			local p = profile()
			t.eq((AfkLogic.accrue(p, 0, NOW, Afk, 1, never, ctx())), false)
			t.eq((AfkLogic.accrue(p, -5, NOW, Afk, 1, never, ctx())), false)
			t.eq((AfkLogic.accrue(p, 0 / 0, NOW, Afk, 1, never, ctx())), false)
			local ok, _, pays = AfkLogic.accrue(p, 10 * 3600, NOW, Afk, 1, never, ctx())
			t.truthy(ok)
			t.eq(#pays, 0, "one call adds at most FLUSH_SECONDS × 4")
			t.eq(p.afk.carry, Afk.FLUSH_SECONDS * 4)
		end)

		t.it("sanitize repairs garbage and keeps valid values", function()
			local a = AfkLogic.sanitize({
				day = -1,
				lira = "x",
				carry = 0 / 0,
				cups = 7.9,
				tales = math.huge,
				seconds = 12.5,
			})
			t.eq(a.day, 0)
			t.eq(a.lira, 0)
			t.eq(a.carry, 0)
			t.eq(a.cups, 7)
			t.eq(a.tales, 0)
			t.eq(a.seconds, 12.5)
			t.truthy(
				t.deepEq(
					AfkLogic.sanitize("bad"),
					{ day = 0, lira = 0, carry = 0, cups = 0, tales = 0, seconds = 0 }
				)
			)
		end)

		t.it("profiles get an afk record, and saved ones keep it", function()
			local ctxS = t.schemaCtx()
			local fresh = ProfileSchema.load(nil, ctxS, NOW)
			t.truthy(t.deepEq(fresh.afk, AfkLogic.sanitize(nil)))
			fresh.afk.carry = 123.5
			fresh.afk.cups = 9
			local again = ProfileSchema.load(ProfileSchema.clone(fresh), ctxS, NOW)
			t.eq(again.afk.carry, 123.5)
			t.eq(again.afk.cups, 9)
		end)

		t.it("the autoAfk setting is a boolean, on by default", function()
			t.truthy(Settings.accept("autoAfk", false))
			t.eq(Settings.accept("autoAfk", "yes"), false)
			t.eq(Settings.get({}, "autoAfk"), true)
		end)

		t.it("every tale has a name and its lines in every language", function()
			for _, lang in Strings.languages do
				for _, id in Afk.TALES do
					t.truthy(Strings[lang]["afk.tale." .. id], lang .. " afk.tale." .. id)
					for i = 1, Afk.LINES do
						t.truthy(
							Strings[lang]["afk.line." .. id .. "." .. i],
							lang .. " afk.line." .. id .. "." .. i
						)
					end
				end
				for _, key in
					{
						"afk.err.in_match",
						"afk.err.not_loaded",
						"afk.err.no_character",
						"afk.err.in_afk",
						"hud.afk",
						"settings.autoAfk",
					}
				do
					t.truthy(Strings[lang][key], lang .. " " .. key)
				end
			end
		end)
	end)
end
