--!nocheck
-- Meta progression: summons (odds, pity, featured), collection, season pass, codes, dailies.

return function(t)
	local SummonLogic = t.logic("SummonLogic")
	local UnitLogic = t.logic("UnitLogic")
	local PassLogic = t.logic("PassLogic")
	local CodesLogic = t.logic("CodesLogic")
	local DailyLogic = t.logic("DailyLogic")
	local Grants = t.logic("Grants")
	local Units = t.config("Units")
	local Banners = t.config("Banners")
	local Traits = t.config("Traits")
	local SeasonPass = t.config("SeasonPass")
	local Codes = t.config("Codes")
	local Daily = t.config("Daily")
	local Items = t.config("Items")
	local TD = t.config("TD")

	-- Deterministic rng from a list of values (cycles)
	local function seq(values)
		local i = 0
		return function()
			i += 1
			return values[((i - 1) % #values) + 1]
		end
	end

	local function profile()
		return {
			qirsh = 0,
			lira = 1000,
			traitStones = 0,
			inventory = {},
			units = {},
			loadout = {},
			summons = { total = 0, sinceLegendary = 0, sinceMythic = 0 },
			pass = { season = "s1", xp = 0, premium = false, claimedFree = {}, claimedPremium = {} },
			codes = {},
			daily = { streak = 0, lastDay = 0 },
		}
	end

	local function ctx(rng, now)
		return {
			units = Units,
			banners = Banners,
			odds = TD.ODDS,
			rarityOrder = TD.RARITY_ORDER,
			pityLegendary = TD.PITY_LEGENDARY,
			pityMythic = TD.PITY_MYTHIC,
			featuredShare = TD.FEATURED_SHARE,
			rotation = TD.BANNER_ROTATION,
			traits = Traits,
			rng = rng,
			now = now or 0,
			maxQirsh = 1000000,
			maxLira = TD.MAX_LIRA,
			maxStones = TD.MAX_TRAIT_STONES,
			items = Items,
		}
	end

	t.describe("SummonLogic", function()
		t.it("odds sum to 100% and every rarity has a pool", function()
			local sum = 0
			for _, p in TD.ODDS do
				sum += p
			end
			t.truthy(math.abs(sum - 1) < 1e-9, "odds sum to 1, got " .. sum)
			for rarity in TD.ODDS do
				t.truthy(#SummonLogic.poolFor(Units, rarity) > 0, rarity .. " pool")
			end
			t.eq(#SummonLogic.poolFor(Units, "secret"), 0, "secrets never drop")
			for _, b in Banners do
				t.eq(Units[b.featuredLegendary].rarity, "legendary")
				t.eq(Units[b.featuredMythic].rarity, "mythic")
			end
		end)

		t.it("banners rotate on the clock", function()
			t.eq(SummonLogic.activeBannerIndex(0, 3, 3600), 1)
			t.eq(SummonLogic.activeBannerIndex(3600, 3, 3600), 2)
			t.eq(SummonLogic.activeBannerIndex(3 * 3600, 3, 3600), 1)
		end)

		t.it("rolls by odds, charges lira and records copies", function()
			local p = profile()
			-- rarity roll 0.0 → rare; unit roll 0.0 → first of the pool; trait roll 0.0 → first trait
			local ok, err, results = SummonLogic.summon(p, 1, 50, ctx(seq({ 0.0 })))
			t.truthy(ok, err)
			t.eq(p.lira, 950)
			t.eq(results[1].rarity, "rare")
			t.eq(results[1].result, "new")
			t.truthy(p.units[results[1].unitId])
			local ok2, _, r2 = SummonLogic.summon(p, 1, 50, ctx(seq({ 0.0 })))
			t.truthy(ok2)
			t.eq(r2[1].result, "copy")
			t.eq(p.units[r2[1].unitId].copies, 1)
			t.eq(p.summons.total, 2)
			-- 0.999 → mythic, featured check 0.1 < 0.5 → featured
			local _, _, r3 = SummonLogic.summon(p, 1, 50, ctx(seq({ 0.999, 0.1, 0.5 })))
			t.eq(r3[1].rarity, "mythic")
			t.truthy(r3[1].featured)
			t.eq(r3[1].unitId, Banners[1].featuredMythic)
			t.eq(p.summons.sinceMythic, 0)
		end)

		t.it("pity guarantees a legendary at 50 and a mythic at 400", function()
			local p = profile()
			p.lira = 1000000
			local always = seq({ 0.0 }) -- would always roll rare
			local legendaries, mythics = 0, 0
			for _ = 1, 400 do
				local _, _, r = SummonLogic.summon(p, 1, 50, ctx(always))
				if r[1].rarity == "legendary" then
					legendaries += 1
					t.truthy(r[1].pity)
				elseif r[1].rarity == "mythic" then
					mythics += 1
				end
			end
			t.eq(legendaries, 7, "one per 50 pulls (the 400th is the mythic)")
			t.eq(mythics, 1)
		end)

		t.it("ten-pull costs the bundle price, VIP gets the discount, no lira → refused", function()
			t.eq(SummonLogic.cost(10, 50, 500, 0.2, false), 500)
			t.eq(SummonLogic.cost(1, 50, 500, 0.2, true), 40)
			local p = profile()
			p.lira = 10
			local ok, err = SummonLogic.summon(p, 1, 50, ctx(seq({ 0 })))
			t.eq(ok, false)
			t.eq(err, "no_lira")
			t.eq(p.lira, 10)
			t.eq(SummonLogic.summon(p, 3, 50, ctx(seq({ 0 }))), false)
		end)

		t.it("displayOdds reflects pity", function()
			local p = profile()
			local odds = SummonLogic.displayOdds(p.summons, ctx(seq({ 0 })))
			t.eq(#odds, 4)
			p.summons.sinceLegendary = 49
			odds = SummonLogic.displayOdds(p.summons, ctx(seq({ 0 })))
			t.eq(odds[1].rarity, "legendary")
			t.eq(odds[1].percent, 100)
		end)
	end)

	t.describe("Collection", function()
		t.it("loadout must be owned, unique and within the slot count", function()
			local p = profile()
			p.units.walad = { copies = 0, trait = "steady", at = 0 }
			p.units.zaim = { copies = 0, trait = "steady", at = 0 }
			t.truthy(UnitLogic.setLoadout(p, { "walad", "zaim" }, 6, Units))
			t.eq(UnitLogic.setLoadout(p, { "walad", "walad" }, 6, Units), false)
			t.eq(UnitLogic.setLoadout(p, { "arada" }, 6, Units), false)
			t.eq(UnitLogic.setLoadout(p, { "walad", "zaim", "x", "y", "z", "w", "v" }, 6, Units), false)
			t.eq(UnitLogic.setLoadout(p, "walad", 6, Units), false)
			t.eq(#p.loadout, 2)
		end)
		t.it("trait reroll spends a stone and never returns the same trait", function()
			local p = profile()
			p.units.walad = { copies = 0, trait = "steady", at = 0 }
			local ok, err = UnitLogic.rerollTrait(p, "walad", 1, Traits.traits, Traits.order, seq({ 0 }))
			t.eq(ok, false)
			t.eq(err, "no_stones")
			p.traitStones = 2
			ok, err = UnitLogic.rerollTrait(p, "walad", 1, Traits.traits, Traits.order, seq({ 0.0, 0.999 }))
			t.truthy(ok, err)
			t.eq(p.traitStones, 1)
			t.eq(p.units.walad.trait, "legend", "second roll after a repeat")
			t.eq(UnitLogic.rerollTrait(p, "nope", 1, Traits.traits, Traits.order, seq({ 0 })), false)
		end)
		t.it("displayed reroll odds list every trait, sum to 100 and match the real roll exactly", function()
			-- Every trait weight is a multiple of 0.5 out of 100, so a 200-step grid of rng midpoints
			-- for both draws enumerates the roll exactly.
			local N = 200
			for _, current in { "steady", "legend", "keen" } do
				local odds = UnitLogic.rerollOdds(Traits.traits, Traits.order, current)
				t.eq(#odds, #Traits.order, "every trait listed")
				local sum = 0
				for _, o in odds do
					sum += o.percent
				end
				t.truthy(math.abs(sum - 100) < 1e-9, "sums to 100 from " .. current)
				local counts = {}
				local p = profile()
				p.traitStones = N * N
				p.units.walad = { copies = 0, trait = current, at = 0 }
				for i = 1, N do
					for j = 1, N do
						p.units.walad.trait = current
						local _, _, got = UnitLogic.rerollTrait(p, "walad", 1, Traits.traits, Traits.order, seq({ (i - 0.5) / N, (j - 0.5) / N }))
						counts[got] = (counts[got] or 0) + 1
					end
				end
				for _, o in odds do
					local actual = 100 * (counts[o.trait] or 0) / (N * N)
					t.truthy(math.abs(actual - o.percent) < 1e-9, string.format("%s from %s: shown %.4f, real %.4f", o.trait, current, o.percent, actual))
				end
			end
			local fresh = UnitLogic.rerollOdds(Traits.traits, Traits.order, nil)
			t.eq(fresh[1].trait, "steady")
			t.truthy(math.abs(fresh[1].percent - 30) < 1e-9, "no current trait = plain weights")
		end)
	end)

	t.describe("PassLogic", function()
		t.it("levels from cumulative xp", function()
			local tiers = SeasonPass.tiers
			t.eq(PassLogic.level(0, tiers), 0)
			t.eq(PassLogic.level(100, tiers), 1)
			local l, into, need = PassLogic.level(150, tiers)
			t.eq(l, 1)
			t.eq(into, 50)
			t.eq(need, 110)
			t.eq(PassLogic.level(1e9, tiers), 50)
		end)
		t.it("claims once per tier per track, premium gated", function()
			local p = profile()
			p.pass.xp = 210
			local c = ctx(seq({ 0 }))
			local ok, err = PassLogic.claim(p, 3, "free", SeasonPass.tiers, c)
			t.eq(err, "locked")
			ok, err = PassLogic.claim(p, 1, "free", SeasonPass.tiers, c)
			t.truthy(ok, err)
			t.eq(p.qirsh, 60)
			ok, err = PassLogic.claim(p, 1, "free", SeasonPass.tiers, c)
			t.eq(err, "already_claimed")
			ok, err = PassLogic.claim(p, 1, "premium", SeasonPass.tiers, c)
			t.eq(err, "premium_required")
			p.pass.premium = true
			ok = PassLogic.claim(p, 1, "premium", SeasonPass.tiers, c)
			t.truthy(ok)
			t.eq(p.lira, 1020)
			t.eq(PassLogic.claim(p, "1", "free", SeasonPass.tiers, c), false)
			t.eq(PassLogic.claim(p, 2, "vip", SeasonPass.tiers, c), false)
		end)
		t.it("level skips add exactly the xp of the next levels", function()
			local p = profile()
			p.pass.xp = 30
			PassLogic.addLevels(p, 10, SeasonPass.tiers)
			t.eq(PassLogic.level(p.pass.xp, SeasonPass.tiers), 10)
		end)
		t.it("tier 50 premium grants the season unit", function()
			local p = profile()
			p.pass.xp = 1e9
			p.pass.premium = true
			local ok, _, granted = PassLogic.claim(p, 50, "premium", SeasonPass.tiers, ctx(seq({ 0 })))
			t.truthy(ok)
			t.eq(granted.unit, "zaim_akbar")
			t.truthy(p.units.zaim_akbar)
		end)
	end)

	t.describe("CodesLogic", function()
		t.it("redeems once, case-insensitively, and respects expiry", function()
			local p = profile()
			local c = ctx(seq({ 0 }), 1000)
			local ok, err, granted = CodesLogic.redeem(p, " yasmin ", Codes, c)
			t.truthy(ok, err)
			t.eq(granted.lira, 100)
			t.eq(p.lira, 1100)
			ok, err = CodesLogic.redeem(p, "YASMIN", Codes, c)
			t.eq(err, "already_redeemed")
			ok, err = CodesLogic.redeem(p, "nope", Codes, c)
			t.eq(err, "unknown_code")
			ok, err = CodesLogic.redeem(p, { "YASMIN" }, Codes, c)
			t.eq(err, "bad_code")
			local late = ctx(seq({ 0 }), 9e9)
			ok, err = CodesLogic.redeem(p, "HARA", Codes, late)
			t.eq(err, "expired")
			t.truthy(CodesLogic.redeem(p, "QITT", Codes, c))
			t.truthy(p.units.qitt, "secret unit from a code")
		end)
		t.it("every code grants something real", function()
			for code, def in Codes do
				t.truthy(string.match(code, "^[%u%d_]+$"), code .. " upper-case")
				t.truthy(def.lira or def.qirsh or def.traitStones or def.unit, code .. " grants")
				if def.unit then
					t.truthy(Units[def.unit], code .. " unit")
				end
			end
		end)
	end)

	t.describe("DailyLogic", function()
		local DAY = 86400
		t.it("streaks continue on consecutive days and reset after a gap", function()
			local p = profile()
			local c = ctx(seq({ 0 }))
			local ok, _, _, day = DailyLogic.claim(p, 10 * DAY + 5, Daily, c)
			t.truthy(ok)
			t.eq(day, 1)
			t.eq(p.lira, 1020)
			local ok2, err = DailyLogic.claim(p, 10 * DAY + 500, Daily, c)
			t.eq(ok2, false)
			t.eq(err, "already_claimed")
			local _, _, _, day2 = DailyLogic.claim(p, 11 * DAY, Daily, c)
			t.eq(day2, 2)
			t.eq(p.daily.streak, 2)
			local _, _, _, day3 = DailyLogic.claim(p, 13 * DAY, Daily, c)
			t.eq(day3, 1, "missed a day → back to day 1")
			t.eq(p.daily.streak, 1)
		end)
		t.it("the 7-day cycle loops", function()
			local p = profile()
			local c = ctx(seq({ 0 }))
			for d = 1, 8 do
				DailyLogic.claim(p, d * DAY, Daily, c)
			end
			t.eq(DailyLogic.status(p, 8 * DAY, Daily).day, 1)
			t.eq(p.daily.streak, 8)
		end)
	end)

	t.describe("Grants", function()
		t.it("caps currencies, consoles an owned item, pays xp", function()
			local p = profile()
			p.inventory.tarboosh_gold = 1
			local c = ctx(seq({ 0 }))
			local g = Grants.apply(p, { lira = 1e12, item = "tarboosh_gold", xp = 30, traitStones = 2 }, c)
			t.eq(p.lira, TD.MAX_LIRA)
			t.eq(g.item, nil)
			t.eq(g.qirsh, 100)
			t.eq(p.pass.xp, 30)
			t.eq(p.traitStones, 2)
		end)
	end)
end
