--!nocheck
-- Audit ledger (Logic/Ledger, BUILD_PLAN P2-15): every currency change is recorded inside the
-- mutation that made it; replays never write twice; summons and rerolls carry their roll seed.

return function(t)
	local Ledger = t.logic("Ledger")
	local SummonLogic = t.logic("SummonLogic")
	local UnitLogic = t.logic("UnitLogic")
	local CodesLogic = t.logic("CodesLogic")
	local MonetizationLogic = t.logic("MonetizationLogic")
	local ProfileSchema = t.logic("ProfileSchema")
	local Units = t.config("Units")
	local Banners = t.config("Banners")
	local Traits = t.config("Traits")
	local Items = t.config("Items")
	local Codes = t.config("Codes")
	local TD = t.config("TD")
	local Economy = t.config("Economy")

	local MAX = Economy.LEDGER_SIZE

	local function profile()
		return {
			qirsh = 100,
			lira = 1000,
			traitStones = 3,
			inventory = {},
			equipped = {},
			quests = {},
			receipts = {},
			units = { natour = { copies = 0, trait = "steady", at = 0 } },
			loadout = {},
			bundles = {},
			codes = {},
			ledger = {},
			summons = { total = 0, sinceLegendary = 0, sinceMythic = 0 },
			pass = { season = "s1", xp = 0, premium = false, claimedFree = {}, claimedPremium = {} },
		}
	end

	local function grantCtx(rng)
		return {
			maxQirsh = Economy.MAX_QIRSH,
			maxLira = TD.MAX_LIRA,
			maxStones = TD.MAX_TRAIT_STONES,
			items = Items,
			units = Units,
			traits = Traits,
			rng = rng or function()
				return 0.5
			end,
			now = 10,
			userId = 1,
		}
	end

	local function summonCtx(rng)
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
			now = 10,
		}
	end

	-- Deterministic rng from a seed, the way MetaService.seededRng does it in Studio (Random.new
	-- is not available in Lune, so a tiny LCG stands in for it).
	local function seededRng(seed)
		local state = seed
		return function()
			state = (state * 1103515245 + 12345) % 2147483648
			return state / 2147483648
		end
	end

	t.describe("Ledger", function()
		t.it("records the signed deltas, source, key and seed of a mutation", function()
			local p = profile()
			local entry, ok = Ledger.mutate(p, function(prof)
				prof.lira -= 50
				prof.qirsh += 20
				return true
			end, { src = "test", key = "k1", seed = 42 }, 1000, MAX)
			t.truthy(ok)
			t.eq(entry.src, "test")
			t.eq(entry.lira, -50)
			t.eq(entry.qirsh, 20)
			t.eq(entry.stones, nil, "unchanged currencies are absent")
			t.eq(entry.key, "k1")
			t.eq(entry.seed, 42)
			t.eq(entry.at, 1000)
			t.eq(#p.ledger, 1)
			t.eq(p.ledger[1], entry)
		end)

		t.it("writes nothing when no currency moved or the mutation was refused", function()
			local p = profile()
			local entry, ok = Ledger.mutate(p, function(prof)
				prof.loadout = { "natour" }
				return true
			end, { src = "loadout" }, 1, MAX)
			t.truthy(ok)
			t.eq(entry, nil)
			local entry2, ok2, err = Ledger.mutate(p, function(prof)
				prof.lira -= 10 -- a buggy fn that writes then refuses: still not audited as a success
				return false, "no"
			end, { src = "bad" }, 1, MAX)
			t.eq(ok2, false)
			t.eq(err, "no")
			t.eq(entry2, nil)
			t.eq(#p.ledger, 0)
		end)

		t.it("passes every return value of the mutation through", function()
			local p = profile()
			local entry, ok, a, b, c = Ledger.mutate(p, function()
				return true, "x", nil, 3
			end, nil, 1, MAX)
			t.eq(entry, nil)
			t.truthy(ok)
			t.eq(a, "x")
			t.eq(b, nil)
			t.eq(c, 3)
		end)

		t.it("names a missing source 'unknown' so the audit stays complete", function()
			local p = profile()
			local entry = Ledger.mutate(p, function(prof)
				prof.lira += 1
				return true
			end, nil, 1, MAX)
			t.eq(entry.src, Ledger.UNKNOWN_SOURCE)
		end)

		t.it("is a ring buffer: the oldest entries fall off", function()
			local p = profile()
			for i = 1, MAX + 25 do
				Ledger.mutate(p, function(prof)
					prof.qirsh += 1
					return true
				end, { src = "tick" }, i, MAX)
			end
			t.eq(#p.ledger, MAX)
			t.eq(p.ledger[1].at, 26)
			t.eq(p.ledger[MAX].at, MAX + 25)
		end)

		t.it("never records the same idempotency key twice", function()
			local p = profile()
			local e1 = Ledger.mutate(p, function(prof)
				prof.lira += 100
				return true
			end, { src = "receipt:x", key = "receipt:1" }, 1, MAX)
			local e2 = Ledger.mutate(p, function(prof)
				prof.lira += 100
				return true
			end, { src = "receipt:x", key = "receipt:1" }, 2, MAX)
			t.truthy(e1)
			t.eq(e2, nil)
			t.eq(#p.ledger, 1)
			t.truthy(Ledger.hasKey(p, "receipt:1"))
			t.eq(Ledger.hasKey(p, "receipt:2"), false)
		end)

		t.it("a replayed Robux receipt produces exactly one entry", function()
			local p = profile()
			local product = { kind = "lira", amount = 500, nameKey = "lira_small" }
			local meta = { src = "receipt:lira_small", key = "receipt:PURCHASE-1" }
			local e1, ok1, _, r1 = Ledger.mutate(p, function(prof)
				return MonetizationLogic.grantReceipt(prof, "PURCHASE-1", product, grantCtx())
			end, meta, 1, MAX)
			t.truthy(ok1)
			t.eq(r1, "granted")
			t.eq(e1.lira, 500)
			t.eq(e1.key, "receipt:PURCHASE-1")
			local e2, ok2, _, r2 = Ledger.mutate(p, function(prof)
				return MonetizationLogic.grantReceipt(prof, "PURCHASE-1", product, grantCtx())
			end, meta, 2, MAX)
			t.truthy(ok2, "a replay is acknowledged")
			t.eq(r2, "already")
			t.eq(e2, nil, "but not granted or audited again")
			t.eq(p.lira, 1500)
			t.eq(#p.ledger, 1)
		end)

		t.it("a replayed code produces exactly one entry", function()
			local code = nil
			for id, def in Codes do
				if def.lira and not def.onlyUserIds and not def.matchCash then
					code = id
					break
				end
			end
			t.truthy(code, "a public lira code exists in Config/Codes")
			local p = profile()
			local meta = { src = "code:" .. code, key = "code:" .. code }
			local redeem = function(prof)
				return CodesLogic.redeem(prof, code, Codes, grantCtx())
			end
			local e1, ok1 = Ledger.mutate(p, redeem, meta, 1, MAX)
			t.truthy(ok1)
			t.truthy(e1)
			t.eq(e1.lira, Codes[code].lira)
			local e2, ok2, err = Ledger.mutate(p, redeem, meta, 2, MAX)
			t.eq(ok2, false)
			t.eq(err, "already_redeemed")
			t.eq(e2, nil)
			t.eq(#p.ledger, 1)
		end)

		t.it("summon entries carry the roll seed and replay to the same units", function()
			local seed = 20261017
			local p = profile()
			p.lira = 100000
			local cost = SummonLogic.cost(10, TD.SUMMON_COST, TD.SUMMON_TEN_COST, TD.VIP_SUMMON_DISCOUNT, false)
			local entry, ok, _, results = Ledger.mutate(p, function(prof)
				return SummonLogic.summon(prof, 10, cost, summonCtx(seededRng(seed)))
			end, { src = "summon_x10", seed = seed }, 5, MAX)
			t.truthy(ok)
			t.eq(entry.src, "summon_x10")
			t.eq(entry.seed, seed)
			t.eq(entry.lira, -cost)
			-- Replay from the audited seed: identical pulls.
			local again = profile()
			again.lira = 100000
			local _, _, _, replay = Ledger.mutate(again, function(prof)
				return SummonLogic.summon(prof, 10, cost, summonCtx(seededRng(entry.seed)))
			end, { src = "summon_x10", seed = entry.seed }, 6, MAX)
			for i = 1, 10 do
				t.eq(replay[i].unitId, results[i].unitId, "pull " .. i)
				t.eq(replay[i].rarity, results[i].rarity)
			end
		end)

		t.it("trait reroll entries carry the roll seed", function()
			local p = profile()
			local entry, ok, _, trait = Ledger.mutate(p, function(prof)
				return UnitLogic.rerollTrait(prof, "natour", TD.TRAIT_REROLL_COST, Traits.traits, Traits.order, seededRng(7))
			end, { src = "reroll:natour", seed = 7 }, 1, MAX)
			t.truthy(ok)
			t.truthy(Traits.traits[trait])
			t.eq(entry.src, "reroll:natour")
			t.eq(entry.seed, 7)
			t.eq(entry.stones, -TD.TRAIT_REROLL_COST)
		end)

		t.it("sanitize drops malformed entries, trims text and keeps the newest N", function()
			local raw = {
				{ at = 1, src = "a", lira = 5 },
				{ at = "x", src = "b", lira = 5 }, -- bad time
				{ at = 2, src = 3, lira = 5 }, -- bad source
				{ at = 3, src = "c" }, -- nothing moved
				{ at = 4, src = string.rep("s", 100), qirsh = -2, key = string.rep("k", 100), seed = 1.5 },
				"junk",
				{ at = 5, src = "d", stones = 1, seed = 0 / 0 },
			}
			local clean = Ledger.sanitize(raw, 2)
			t.eq(#clean, 2)
			t.eq(clean[1].at, 4)
			t.eq(#clean[1].src, 64)
			t.eq(#clean[1].key, 64)
			t.eq(clean[1].seed, 1.5)
			t.eq(clean[2].at, 5)
			t.eq(clean[2].seed, nil, "NaN seeds are dropped")
			t.eq(#Ledger.sanitize(nil, 5), 0)
			t.eq(#Ledger.sanitize("nope", 5), 0)
		end)

		t.it("survives a profile round trip through ProfileSchema", function()
			local ctx = t.schemaCtx({ ledgerSize = 3 })
			local p = ProfileSchema.default(1, ctx.schemaVersion, ctx)
			t.deepEq(p.ledger, {})
			for i = 1, 5 do
				Ledger.mutate(p, function(prof)
					prof.lira += i
					return true
				end, { src = "s" .. i }, i, 10)
			end
			local loaded = ProfileSchema.load(ProfileSchema.clone(p), ctx, 100)
			t.eq(#loaded.ledger, 3, "the schema's ledger size wins on load")
			t.eq(loaded.ledger[1].src, "s3")
			t.eq(loaded.ledger[3].src, "s5")
			t.eq(loaded.ledger[3].lira, 5)
			-- Fresh default is a fixed point (a profile with no ledger gets an empty one)
			local legacy = ProfileSchema.load({ schemaVersion = 2, lira = 10 }, ctx, 1)
			t.deepEq(legacy.ledger, {})
		end)
	end)
end
