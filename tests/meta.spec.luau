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

	-- P2-12: Monte-Carlo checks of the published odds, the pity bounds and the trait reroll
	-- disclosure. Seeded math.random so a failure reproduces; the whole suite stays under 10 s.
	t.describe("Odds and pity simulation", function()
		local PULLS = 1000000
		local simStart = os.clock()

		local function seeded(seed)
			math.randomseed(seed)
			return function()
				return math.random()
			end
		end

		t.it("1,000,000 pulls without pity match TD.ODDS within 4 sigma", function()
			local c = ctx(seeded(2026))
			c.pityLegendary = math.huge
			c.pityMythic = math.huge
			local summons = { total = 0, sinceLegendary = 0, sinceMythic = 0 }
			local counts = {}
			for _, rarity in TD.RARITY_ORDER do
				counts[rarity] = 0
			end
			for _ = 1, PULLS do
				local rarity, pity = SummonLogic.rollRarity(summons, c)
				t.eq(pity, false, "pity never fires when disabled")
				counts[rarity] += 1
			end
			local lines = {}
			for _, rarity in TD.RARITY_ORDER do
				local p = TD.ODDS[rarity]
				if p then
					local expected = p * PULLS
					local sigma = math.sqrt(PULLS * p * (1 - p))
					local z = (counts[rarity] - expected) / sigma
					table.insert(lines, string.format("%s %d (expected %.0f, sigma %.1f, z %+.2f)", rarity, counts[rarity], expected, sigma, z))
					t.truthy(math.abs(z) <= 4, rarity .. " outside 4 sigma: " .. lines[#lines])
				else
					t.eq(counts[rarity], 0, rarity .. " never drops from a summon")
				end
			end
			print("    odds sim: " .. table.concat(lines, "; "))
		end)

		t.it("1,000,000 pulls with pity: no Legendary+ gap over 50, no Mythic gap over 400", function()
			local p = profile()
			p.lira = math.huge
			local c = ctx(seeded(1917))
			local sinceLegendary, sinceMythic = 0, 0
			local maxLegendaryGap, maxMythicGap = 0, 0
			local pityHits, mythics = 0, 0
			for _ = 1, PULLS / 10 do
				local ok, err, results = SummonLogic.summon(p, 10, 0, c)
				t.truthy(ok, err)
				for _, r in results do
					sinceLegendary += 1
					sinceMythic += 1
					if r.rarity == "mythic" then
						mythics += 1
						maxMythicGap = math.max(maxMythicGap, sinceMythic)
						maxLegendaryGap = math.max(maxLegendaryGap, sinceLegendary)
						sinceMythic, sinceLegendary = 0, 0
					elseif r.rarity == "legendary" then
						maxLegendaryGap = math.max(maxLegendaryGap, sinceLegendary)
						sinceLegendary = 0
					end
					if r.pity then
						pityHits += 1
					end
				end
			end
			t.eq(p.summons.total, PULLS)
			t.truthy(maxLegendaryGap <= TD.PITY_LEGENDARY, "legendary gap " .. maxLegendaryGap)
			t.truthy(maxMythicGap <= TD.PITY_MYTHIC, "mythic gap " .. maxMythicGap)
			t.truthy(mythics >= PULLS / TD.PITY_MYTHIC, "pity alone guarantees this many mythics")
			print(string.format("    pity sim: max Legendary+ gap %d (cap %d), max Mythic gap %d (cap %d), %d mythics, %d pity hits", maxLegendaryGap, TD.PITY_LEGENDARY, maxMythicGap, TD.PITY_MYTHIC, mythics, pityHits))
		end)

		t.it("trait reroll odds sum to 1 for every current trait and match the roll", function()
			for _, current in Traits.order do
				local sum = 0
				for _, row in UnitLogic.rerollOdds(Traits.traits, Traits.order, current) do
					sum += row.percent / 100
					t.truthy(row.percent > 0, row.trait .. " has a chance from " .. current)
				end
				t.truthy(math.abs(sum - 1) < 1e-9, "reroll odds from " .. current .. " sum to " .. sum)
			end
			local sum = 0
			for _, row in UnitLogic.rerollOdds(Traits.traits, Traits.order, nil) do
				sum += row.percent / 100
			end
			t.truthy(math.abs(sum - 1) < 1e-9, "fresh roll odds sum to " .. sum)

			-- The disclosed reroll odds are what rerollTrait actually does (nudge included).
			local N = 200000
			local current = "steady"
			local rng = seeded(1516)
			local counts = {}
			for _, id in Traits.order do
				counts[id] = 0
			end
			for _ = 1, N do
				local prof = { units = { u = { copies = 0, trait = current, at = 0 } }, traitStones = 1 }
				local ok, _, got = UnitLogic.rerollTrait(prof, "u", 1, Traits.traits, Traits.order, rng)
				t.truthy(ok)
				counts[got] += 1
			end
			for _, row in UnitLogic.rerollOdds(Traits.traits, Traits.order, current) do
				local pr = row.percent / 100
				local sigma = math.sqrt(N * pr * (1 - pr))
				local z = (counts[row.trait] - N * pr) / sigma
				t.truthy(math.abs(z) <= 4, string.format("reroll %s from %s: %d vs %.0f (z %+.2f)", row.trait, current, counts[row.trait], N * pr, z))
			end
		end)

		t.it("the simulations stay under 10 s", function()
			local elapsed = os.clock() - simStart
			print(string.format("    sim time: %.2f s", elapsed))
			t.truthy(elapsed < 10, "simulation took " .. elapsed .. " s")
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
			t.eq(p.units.walad.trait, Traits.order[#Traits.order], "second roll after a repeat (the last trait in the order)")
			t.eq(UnitLogic.rerollTrait(p, "nope", 1, Traits.traits, Traits.order, seq({ 0 })), false)
		end)
		t.it("displayed reroll odds list every trait, sum to 100 and match the real roll exactly", function()
			-- Every trait weight is a multiple of 0.5 out of 120, so a 240-step grid of rng midpoints
			-- for both draws enumerates the roll exactly.
			local N = 240
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
			t.truthy(math.abs(fresh[1].percent - 100 * 30 / 120) < 1e-9, "no current trait = plain weights (30 of 120)")
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
			-- A unit code (the secret QITT code retired with the Cat, S1-S12b): grants a Rare.
			t.truthy(CodesLogic.redeem(p, "RARE", { RARE = { unit = "natour" } }, c))
			t.truthy(p.units.natour, "a unit from a code")
			ok, err = CodesLogic.redeem(p, "QITT", Codes, ctx(seq({ 0 }), Codes.QITT.expiresAt + 1))
			t.eq(err, "expired", "QITT expired with the Cat")
		end)
		t.it("an allUnits code grants every missing defender once, and respects onlyUserIds", function()
			local p = profile()
			p.units.walad = { copies = 2, trait = "steady", at = 0 }
			local c = ctx(seq({ 0.5 }), 1000)
			local codes = { ALL = { allUnits = true }, MINE = { allUnits = true, onlyUserIds = { 42 } } }
			local ok, err, granted = CodesLogic.redeem(p, "all", codes, c)
			t.truthy(ok, err)
			local total = 0
			for id in Units do
				total += 1
				t.truthy(p.units[id], id .. " owned")
			end
			t.eq(#granted.units, total - 1)
			t.eq(p.units.walad.copies, 2)
			t.eq(p.units.adashari.copies, 0, "the secret unit too, for testers")
			ok, err = CodesLogic.redeem(profile(), "MINE", codes, c)
			t.eq(err, "unknown_code")
			c.userId = 42
			t.truthy(CodesLogic.redeem(profile(), "MINE", codes, c))
		end)
		t.it("every code grants something real", function()
			for code, def in Codes do
				t.truthy(string.match(code, "^[%u%d_]+$"), code .. " upper-case")
				t.truthy(def.lira or def.qirsh or def.traitStones or def.unit or def.allUnits or def.matchCash, code .. " grants")
				if def.unit then
					-- A code for a retired unit (the Cat, S1-S12b) must already be expired.
					t.truthy(Units[def.unit] or (def.expiresAt and def.expiresAt <= 1792281600), code .. " unit")
				end
			end
		end)
		t.it("MONEY50K adds 50,000 wave cash for the owner, in a match only, every time", function()
			local c = { userId = 1, now = 1000, inMatch = true }
			t.truthy(CodesLogic.isMatchCash(" money50k ", Codes))
			t.eq(CodesLogic.isMatchCash("YASMIN", Codes), false)
			local ok, err, amount = CodesLogic.redeemMatchCash("MONEY50K", Codes, c)
			t.eq(ok, false)
			t.eq(err, "unknown_code")
			c.userId = 2465538767
			for _ = 1, 3 do
				ok, err, amount = CodesLogic.redeemMatchCash("money50k", Codes, c)
				t.truthy(ok, err)
				t.eq(amount, 50000)
			end
			c.inMatch = false
			ok, err = CodesLogic.redeemMatchCash("MONEY50K", Codes, c)
			t.eq(err, "match_only")
			ok, err = CodesLogic.redeemMatchCash("YASMIN", Codes, c)
			t.eq(err, "unknown_code")
			-- The profile path refuses match codes and records nothing.
			local p = profile()
			local pc = ctx(seq({ 0 }), 1000)
			pc.userId = 2465538767
			ok, err = CodesLogic.redeem(p, "MONEY50K", Codes, pc)
			t.eq(err, "match_only")
			t.eq(p.codes.MONEY50K, nil)
			t.eq(p.lira, 1000)
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
