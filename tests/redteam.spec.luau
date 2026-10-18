--!nocheck
-- Red-team pass (BUILD_PLAN P3-09). Every client-reachable handler's pure logic under hostile
-- input: floods (1,000 calls), NaN / inf / huge numbers, wrong types, over-long or foreign ids,
-- actions out of phase, overspending, other players' towers, replayed receipts and codes.
-- Each case checks the refusal AND that the profile or match state did not move: an attack must
-- leave no trace. The server-glue findings (RemoteGuard wiring, MatchService, MetaService,
-- DataService) are recorded in docs/review/REDTEAM_P3-09.md.

return function(t)
	local Validate = t.logic("Validate")
	local RateLimiter = t.logic("RateLimiter")
	local TdSim = t.logic("TdSim")
	local TdTowers = t.logic("TdTowers")
	local SummonLogic = t.logic("SummonLogic")
	local UnitLogic = t.logic("UnitLogic")
	local CodesLogic = t.logic("CodesLogic")
	local PassLogic = t.logic("PassLogic")
	local DailyLogic = t.logic("DailyLogic")
	local EventLogic = t.logic("EventLogic")
	local ShopLogic = t.logic("ShopLogic")
	local Settings = t.logic("Settings")
	local DialogueLogic = t.logic("DialogueLogic")
	local PartyLogic = t.logic("PartyLogic")
	local MonetizationLogic = t.logic("MonetizationLogic")
	local MatchRewards = t.logic("MatchRewards")
	local Grants = t.logic("Grants")
	local Ledger = t.logic("Ledger")
	local DeviceTelemetry = t.logic("DeviceTelemetry")
	local Hud = t.config("Hud")
	local ProfileSchema = t.logic("ProfileSchema")
	local Units = t.config("Units")
	local Enemies = t.config("Enemies")
	local Banners = t.config("Banners")
	local Traits = t.config("Traits")
	local SeasonPass = t.config("SeasonPass")
	local Codes = t.config("Codes")
	local Daily = t.config("Daily")
	local Events = t.config("Events")
	local Items = t.config("Items")
	local Shops = t.config("Shops")
	local Dialogue = t.config("Dialogue")
	local Modes = t.config("Modes")
	local TD = t.config("TD")
	local Economy = t.config("Economy")

	local NOW = 1760000000 -- 2025-10, inside every code's window and the olive event

	-- Values a hostile client can put in any argument (nil is tested on its own: it can't sit in a list).
	local HOSTILE = {
		0 / 0,
		math.huge,
		-math.huge,
		1e308,
		-1e308,
		2 ^ 53,
		-1,
		0,
		1.5,
		"",
		" ",
		"1",
		"10",
		"natour",
		string.rep("a", 65),
		string.rep("z", 10000),
		"ياسمين",
		"a\0b",
		{},
		{ 1 },
		{ ok = true },
		true,
		false,
		print,
	}

	local function named(v)
		if type(v) == "string" then
			return string.format("%q", if #v > 20 then string.sub(v, 1, 17) .. "..." else v)
		end
		return type(v) .. ":" .. tostring(v)
	end

	local function profile(over)
		local ctx = t.schemaCtx()
		local p = ProfileSchema.default(NOW, ctx.schemaVersion, ctx)
		for k, v in pairs(over or {}) do
			p[k] = v
		end
		return p
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
			now = NOW,
			userId = 1,
			passTiers = SeasonPass.tiers,
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
			rng = rng or function()
				return 0.5
			end,
			now = NOW,
		}
	end

	-- Asserts fn(...) is refused and leaves `subject` byte-for-byte unchanged.
	local function refused(subject, label, fn)
		local before = t.deepCopy(subject)
		local ok = fn()
		t.eq(ok, false, label .. " should be refused")
		t.truthy(t.deepEq(subject, before), label .. " changed state")
	end

	------------------------------------------------------------------------------------------
	t.describe("Red team: Validate (the first line of every handler)", function()
		t.it("finite / integer checks reject NaN, inf, strings, tables and booleans", function()
			for _, v in { 0 / 0, math.huge, -math.huge, "1", "", {}, true, print } do
				t.eq(Validate.isFiniteNumber(v), false, named(v))
				t.eq(Validate.isPositiveInteger(v), false, named(v))
			end
			t.eq(Validate.isFiniteNumber(nil), false)
			t.eq(Validate.isPositiveInteger(nil), false)
			for _, v in { -1, 0, 1.5, -1e308 } do
				t.eq(Validate.isPositiveInteger(v), false, named(v))
			end
			-- Huge integers pass the type check: every consumer must bound them itself (specs below).
			t.truthy(Validate.isPositiveInteger(2 ^ 53))
			t.truthy(Validate.isPositiveInteger(1e308))
		end)
		t.it("identifiers are 1–64 ASCII word characters; short strings are bounded", function()
			t.truthy(Validate.isIdentifier(string.rep("a", 64)))
			for _, v in { string.rep("a", 65), string.rep("z", 10000), "", " ", "a b", "a-b", "../x", "ياسمين", "a\0b", "a\n", 5, {}, true } do
				t.eq(Validate.isIdentifier(v), false, named(v))
			end
			t.eq(Validate.isIdentifier(nil), false)
			t.truthy(Validate.isShortString(string.rep("a", 40), 40))
			t.eq(Validate.isShortString(string.rep("a", 41), 40), false)
			t.eq(Validate.isShortString("", 40), false)
			t.eq(Validate.isShortString({}, 40), false)
			t.eq(Validate.isShortString(nil, 40), false)
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: RateLimiter (RemoteGuard DEFAULT 8 burst / 4 per s, STRICT 3 / 1)", function()
		local function flood(capacity, perSecond, calls, window)
			local l = RateLimiter.new(capacity, perSecond)
			local allowed = 0
			for i = 1, calls do
				if RateLimiter.allow(l, "attacker", (i - 1) * window / calls) then
					allowed += 1
				end
			end
			return allowed, l
		end
		t.it("1,000 calls in the same instant let exactly the burst through", function()
			t.eq((flood(8, 4, 1000, 0)), 8)
			t.eq((flood(3, 1, 1000, 0)), 3)
		end)
		t.it("1,000 calls spread over one second let through burst + refill, never more", function()
			local allowed = flood(8, 4, 1000, 1)
			t.truthy(allowed >= 8 and allowed <= 12, "DEFAULT allowed " .. allowed)
			allowed = flood(3, 1, 1000, 1)
			t.truthy(allowed >= 3 and allowed <= 4, "STRICT allowed " .. allowed)
		end)
		t.it("1,000 calls over a minute settle at the refill rate", function()
			local allowed = flood(3, 1, 1000, 60)
			t.truthy(allowed <= 3 + 60, "STRICT allowed " .. allowed)
			t.truthy(allowed >= 60, "STRICT allowed " .. allowed)
		end)
		t.it("the clock is the server's (os.clock, monotonic): a step back mints nothing, NaN fails closed", function()
			local l = RateLimiter.new(3, 1)
			for _ = 1, 3 do
				t.truthy(RateLimiter.allow(l, "p", 100))
			end
			t.eq(RateLimiter.allow(l, "p", 100), false)
			t.eq(RateLimiter.allow(l, "p", 50), false, "time went backwards")
			t.eq(RateLimiter.allow(l, "p", 50.5), false, "still inside the same second")
			t.truthy(RateLimiter.allow(l, "p", 51.1), "one token a second after the rewound clock")
			-- A non-finite clock (impossible from os.clock) used to refill the bucket on every call;
			-- it is now denied outright and never touches the bucket.
			local n = RateLimiter.new(3, 1)
			for _, bad in { 0 / 0, math.huge, -math.huge, "1", nil } do
				for _ = 1, 100 do
					t.eq(RateLimiter.allow(n, "p", bad), false, "clock " .. tostring(bad))
				end
			end
			t.eq(n.buckets.p, nil, "a bad clock created a bucket")
			for _ = 1, 3 do
				t.truthy(RateLimiter.allow(n, "p", 2000))
			end
			t.eq(RateLimiter.allow(n, "p", 2000), false)
		end)
		t.it("one attacker cannot drain another player's bucket; forget resets only that key", function()
			local l = RateLimiter.new(3, 1)
			for _ = 1, 10 do
				RateLimiter.allow(l, "attacker", 0)
			end
			t.truthy(RateLimiter.allow(l, "victim", 0))
			RateLimiter.forget(l, "attacker")
			t.truthy(RateLimiter.allow(l, "attacker", 0), "a rejoin starts a fresh burst (bounded by the join rate)")
			t.eq(l.buckets.victim.tokens, 2)
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: match remotes (PlaceTower, UpgradeTower, SellTower, SetTargeting, UseAbility)", function()
		local straight = { { 0, 0 }, { 100, 0 } }
		local function rules()
			return {
				bounds = { -100, -100, 100, 100 },
				pathHalfWidth = TD.PATH_HALF_WIDTH,
				spacing = TD.TOWER_SPACING,
				towerCap = TD.TOWER_CAP,
				sellRefund = TD.SELL_REFUND,
				starBonus = TD.STAR_BONUS,
			}
		end
		local function match(cash)
			return TdSim.new(straight, { "p1", "p2" }, cash or 100000, 100, 3, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = Enemies,
			}, function()
				return { spawns = {}, count = 0 }
			end)
		end
		local function snapshot(s)
			return { cash1 = s.players.p1.cash, cash2 = s.players.p2.cash, towers = #s.towers, nextId = s.nextId }
		end
		local function unchanged(s, snap, label)
			t.truthy(t.deepEq(snapshot(s), snap), label .. " moved match state")
		end

		t.it("hostile coordinates (NaN, ±inf, 1e308, strings, tables) never place and never spend", function()
			local s = match()
			local snap = snapshot(s)
			for _, x in HOSTILE do
				if type(x) == "number" and x == x and math.abs(x) <= 100 then
					continue -- an ordinary in-bounds coordinate, not an attack
				end
				local ok = TdTowers.place(s, "p1", "walad", Units.walad, x, 6, 0, nil, rules())
				t.eq(ok, false, "x=" .. named(x))
				ok = TdTowers.place(s, "p1", "walad", Units.walad, 10, x, 0, nil, rules())
				t.eq(ok, false, "z=" .. named(x))
			end
			t.eq(TdTowers.place(s, "p1", "walad", Units.walad, nil, nil, 0, nil, rules()), false)
			unchanged(s, snap, "hostile coordinates")
		end)

		t.it("placing before a match exists, after it ended, or as a stranger is refused", function()
			local s = match()
			local snap = snapshot(s)
			local ok, err = TdTowers.place(s, "stranger", "walad", Units.walad, 10, 6, 0, nil, rules())
			t.eq(err, "not_in_match")
			for _, phase in { "won", "lost" } do
				s.phase = phase
				ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 10, 6, 0, nil, rules())
				t.eq(ok, false)
				t.eq(err, "match_over")
			end
			s.phase = "prep"
			unchanged(s, snap, "out-of-phase placement")
		end)

		t.it("1,000 placements stop at the tower cap and the unit cap; cash never goes negative", function()
			local s = match(10 ^ 9)
			local placed = 0
			local maxPerUnit = 0
			local ids = { "walad", "hallaq", "zaim" }
			for i = 1, 1000 do
				local unitId = ids[(i % #ids) + 1]
				local ok = TdTowers.place(s, "p1", unitId, Units[unitId], (i % 60) * 3 - 90, 6 + (i // 60) * 3, 0, nil, rules())
				if ok then
					placed += 1
				end
				t.truthy(s.players.p1.cash >= 0, "cash went negative")
			end
			t.eq(placed, #s.towers)
			t.truthy(#s.towers <= TD.TOWER_CAP, "tower cap broken: " .. #s.towers)
			for _, unitId in ids do
				maxPerUnit = math.max(maxPerUnit, TdTowers.countOwned(s, "p1", unitId))
				t.truthy(TdTowers.countOwned(s, "p1", unitId) <= Units[unitId].maxPlaced, "unit cap broken for " .. unitId)
			end
			t.truthy(maxPerUnit > 0)
		end)

		t.it("spending more than owned: exactly cost-1 cash cannot place; exactly cost can, once", function()
			local cost = Units.walad.levels[1].cost
			local s = match(cost - 1)
			local snap = snapshot(s)
			local ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 10, 6, 0, nil, rules())
			t.eq(err, "cannot_afford")
			unchanged(s, snap, "poverty")
			s = match(cost)
			t.truthy(TdTowers.place(s, "p1", "walad", Units.walad, 10, 6, 0, nil, rules()))
			t.eq(s.players.p1.cash, 0)
			ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 20, 6, 0, nil, rules())
			t.eq(err, "cannot_afford")
			t.eq(s.players.p1.cash, 0)
		end)

		t.it("another player's tower cannot be upgraded, sold, retargeted or ulted", function()
			local s = match()
			local _, _, tower = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 6, 0, nil, rules())
			t.truthy(tower)
			tower.abilityAt = 0
			local before = t.deepCopy(tower)
			local snap = snapshot(s)
			local ok, err = TdTowers.upgrade(s, "p2", tower.id, Units.zaim, rules())
			t.eq(ok, false)
			t.eq(err, "not_yours")
			ok, err = TdTowers.sell(s, "p2", tower.id, rules())
			t.eq(ok, false)
			t.eq(err, "not_yours")
			ok, err = TdTowers.setTargeting(s, "p2", tower.id, "last")
			t.eq(ok, false)
			t.eq(err, "not_yours")
			ok, err = TdTowers.useAbility(s, "p2", tower.id)
			t.eq(ok, false)
			t.eq(err, "not_yours")
			ok, err = TdTowers.upgrade(s, "stranger", tower.id, Units.zaim, rules())
			t.eq(err, "not_yours")
			t.truthy(t.deepEq(tower, before), "the victim's tower changed")
			unchanged(s, snap, "attack on another player's tower")
		end)

		t.it("hostile tower ids (NaN, inf, 0, negative, huge, strings, tables) find nothing", function()
			local s = match()
			local _, _, tower = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 6, 0, nil, rules())
			local snap = snapshot(s)
			local before = t.deepCopy(tower)
			for _, id in HOSTILE do
				t.eq(TdTowers.upgrade(s, "p1", id, Units.zaim, rules()), false, "upgrade " .. named(id))
				t.eq(TdTowers.sell(s, "p1", id, rules()), false, "sell " .. named(id))
				t.eq(TdTowers.setTargeting(s, "p1", id, "last"), false, "target " .. named(id))
				t.eq(TdTowers.useAbility(s, "p1", id), false, "ability " .. named(id))
			end
			t.eq(TdTowers.upgrade(s, "p1", nil, Units.zaim, rules()), false)
			t.eq(TdTowers.sell(s, "p1", nil, rules()), false)
			t.truthy(t.deepEq(tower, before))
			unchanged(s, snap, "hostile tower ids")
		end)

		t.it("selling twice refunds once; upgrading past the top level costs nothing", function()
			local s = match()
			local _, _, tower = TdTowers.place(s, "p1", "hallaq", Units.hallaq, 10, 6, 0, nil, rules())
			for _ = 1, #Units.hallaq.levels + 5 do
				TdTowers.upgrade(s, "p1", tower.id, Units.hallaq, rules())
			end
			t.eq(tower.level, #Units.hallaq.levels)
			local afterMax = s.players.p1.cash
			local ok, err = TdTowers.upgrade(s, "p1", tower.id, Units.hallaq, rules())
			t.eq(ok, false)
			t.eq(err, "max_level")
			t.eq(s.players.p1.cash, afterMax)
			local ok2, _, refund = TdTowers.sell(s, "p1", tower.id, rules())
			t.truthy(ok2)
			t.eq(s.players.p1.cash, afterMax + refund)
			for _ = 1, 100 do
				t.eq(TdTowers.sell(s, "p1", tower.id, rules()), false, "double sell")
			end
			t.eq(s.players.p1.cash, afterMax + refund, "a second sell paid again")
			t.eq(#s.towers, 0)
		end)

		t.it("targeting accepts only the four modes; anything else leaves the tower alone", function()
			local s = match()
			local _, _, tower = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 6, 0, nil, rules())
			for _, mode in HOSTILE do
				local ok, err = TdTowers.setTargeting(s, "p1", tower.id, mode)
				t.eq(ok, false, named(mode))
				t.eq(err, "bad_request", named(mode))
			end
			t.eq(TdTowers.setTargeting(s, "p1", tower.id, "FIRST"), false, "case matters")
			t.eq(TdTowers.setTargeting(s, "p1", tower.id, nil), false)
			t.eq(tower.targeting, "first")
			for _, mode in { "first", "last", "strong", "close" } do
				t.truthy(TdTowers.setTargeting(s, "p1", tower.id, mode))
				t.eq(tower.targeting, mode)
			end
		end)

		t.it("an ultimate cannot be queued after the match, or twice before it fires", function()
			local s = match()
			local _, _, tower = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 6, 0, nil, rules())
			if tower.stats.ability then
				tower.abilityAt = s.time + 100
				local ok, err = TdTowers.useAbility(s, "p1", tower.id)
				t.eq(err, "not_ready")
				t.eq(tower.abilityQueued, nil)
				tower.abilityAt = 0
				s.phase = "won"
				ok, err = TdTowers.useAbility(s, "p1", tower.id)
				t.eq(ok, false)
				t.eq(err, "match_over")
				t.eq(tower.abilityQueued, nil)
			end
		end)

		t.it("a thousand hostile placements never change nextId or the tower list", function()
			local s = match()
			local snap = snapshot(s)
			for i = 1, 1000 do
				local v = HOSTILE[(i % #HOSTILE) + 1]
				TdTowers.place(s, "p1", "walad", Units.walad, v, v, 0, nil, rules())
			end
			unchanged(s, snap, "flood of hostile placements")
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: Summon", function()
		t.it("n must be exactly 1 or 10: every other count is refused without touching lira or pity", function()
			local p = profile({ lira = 100000 })
			for _, n in HOSTILE do
				local cost = if type(n) == "number" then SummonLogic.cost(n, TD.SUMMON_COST, TD.SUMMON_TEN_COST, TD.VIP_SUMMON_DISCOUNT, false) else 0
				refused(p, "summon n=" .. named(n), function()
					return (SummonLogic.summon(p, n, cost, summonCtx()))
				end)
			end
			refused(p, "summon n=nil", function()
				return (SummonLogic.summon(p, nil, 0, summonCtx()))
			end)
			-- A negative count would compute a negative cost (a lira grant); the n check runs first.
			t.truthy(SummonLogic.cost(-1, TD.SUMMON_COST, TD.SUMMON_TEN_COST, TD.VIP_SUMMON_DISCOUNT, false) < 0)
			refused(p, "summon n=-1 with its negative cost", function()
				return (SummonLogic.summon(p, -1, -TD.SUMMON_COST, summonCtx()))
			end)
		end)
		t.it("1,000 pulls on a budget: only the affordable ones happen and lira ends at zero, never below", function()
			local budget = 7 * TD.SUMMON_COST + 3
			local p = profile({ lira = budget })
			local done = 0
			for _ = 1, 1000 do
				local ok = SummonLogic.summon(p, 1, TD.SUMMON_COST, summonCtx())
				if ok then
					done += 1
				end
				t.truthy(p.lira >= 0, "lira went negative")
			end
			t.eq(done, 7)
			t.eq(p.lira, 3)
			t.eq(p.summons.total, 7)
			local ok, err = SummonLogic.summon(p, 10, TD.SUMMON_TEN_COST, summonCtx())
			t.eq(ok, false)
			t.eq(err, "no_lira")
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: SetLoadout and RerollTrait", function()
		t.it("loadouts over the slot count, duplicated, unowned, unknown or non-string are refused whole", function()
			local p = profile()
			p.units.hallaq = { copies = 0, trait = "steady", at = NOW }
			p.loadout = { "walad" }
			local slots = TD.LOADOUT_SLOTS
			local bad = {
				{ "walad", "walad" },
				{ "zaim" }, -- real unit, not owned
				{ "nobody" },
				{ string.rep("a", 65) },
				{ 1 },
				{ {} },
				{ true },
				{ "walad", 0 / 0 },
				{ "walad", nil, "hallaq" },
			}
			local over = {}
			for _ = 1, slots + 1 do
				table.insert(over, "walad")
			end
			table.insert(bad, over)
			for i, list in bad do
				refused(p, "loadout #" .. i, function()
					return (UnitLogic.setLoadout(p, list, slots, Units))
				end)
			end
			for _, v in HOSTILE do
				if type(v) ~= "table" then
					refused(p, "loadout " .. named(v), function()
						return (UnitLogic.setLoadout(p, v, slots, Units))
					end)
				end
			end
			refused(p, "loadout nil", function()
				return (UnitLogic.setLoadout(p, nil, slots, Units))
			end)
			-- A hash-only table has length 0: it reads as an empty loadout (allowed, nothing granted).
			t.truthy(UnitLogic.setLoadout(p, { foo = "walad", [2 ^ 40] = "hallaq" }, slots, Units))
			t.eq(#p.loadout, 0)
		end)
		t.it("a slot count from a perk the player lacks is never trusted: the server passes it", function()
			local p = profile()
			local ids = {}
			for id in Units do
				p.units[id] = { copies = 0, trait = "steady", at = NOW }
				table.insert(ids, id)
			end
			table.sort(ids)
			local seven = { table.unpack(ids, 1, 7) }
			t.eq(UnitLogic.setLoadout(p, seven, TD.LOADOUT_SLOTS, Units), false, "7 without the pass")
			t.truthy(UnitLogic.setLoadout(p, seven, TD.LOADOUT_SLOTS + 1, Units), "7 with the pass")
		end)
		t.it("1,000 reroll taps with three stones reroll exactly three times; stones never go negative", function()
			local p = profile({ traitStones = 3 })
			local rolls = 0
			local rng = function()
				rolls += 1
				return (rolls % 7) / 7
			end
			local done = 0
			for _ = 1, 1000 do
				if UnitLogic.rerollTrait(p, "walad", TD.TRAIT_REROLL_COST, Traits.traits, Traits.order, rng) then
					done += 1
				end
				t.truthy(p.traitStones >= 0, "stones went negative")
			end
			t.eq(done, 3)
			t.eq(p.traitStones, 0)
			refused(p, "reroll an unowned unit", function()
				p.traitStones = 5
				local ok = UnitLogic.rerollTrait(p, "zaim", TD.TRAIT_REROLL_COST, Traits.traits, Traits.order, rng)
				p.traitStones = 0
				return (ok)
			end)
			t.truthy(Traits.traits[p.units.walad.trait], "trait left the config")
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: RedeemCode", function()
		local function codeCtx(userId)
			local c = grantCtx()
			c.userId = userId or 1
			return c
		end
		t.it("hostile codes (wrong type, too long, NUL, Arabic, blank) are refused and record nothing", function()
			local p = profile()
			for _, v in HOSTILE do
				refused(p, "code " .. named(v), function()
					return (CodesLogic.redeem(p, v, Codes, codeCtx()))
				end)
				t.eq(CodesLogic.isMatchCash(v, Codes), false, named(v))
				t.eq(CodesLogic.redeemMatchCash(v, Codes, { userId = 2465538767, now = NOW, inMatch = true }), false, named(v))
			end
			refused(p, "code nil", function()
				return (CodesLogic.redeem(p, nil, Codes, codeCtx()))
			end)
			t.eq(CodesLogic.normalize(string.rep("A", 33)), nil, "33 chars")
			t.truthy(CodesLogic.normalize(string.rep("A", 32)), "32 chars")
			t.eq(CodesLogic.normalize("YAS%sMIN"), nil, "pattern characters")
		end)
		t.it("1,000 replays of one code, in every case and spacing, grant exactly once", function()
			local p = profile()
			local before = p.lira
			local variants = { "YASMIN", "yasmin", " Yasmin ", "ya smin", "\tYASMIN\n" }
			local grants = 0
			for i = 1, 1000 do
				local ok, err = CodesLogic.redeem(p, variants[(i % #variants) + 1], Codes, codeCtx())
				if ok then
					grants += 1
				else
					t.eq(err, "already_redeemed")
				end
			end
			t.eq(grants, 1)
			t.eq(p.lira, before + Codes.YASMIN.lira)
			local n = 0
			for _ in p.codes do
				n += 1
			end
			t.eq(n, 1, "one record per code")
		end)
		t.it("expired codes and codes locked to other users are refused the same way as typos", function()
			local p = profile()
			local c = codeCtx()
			c.now = Codes.DIARY.expiresAt + 1
			refused(p, "expired", function()
				local ok, err = CodesLogic.redeem(p, "DIARY", Codes, c)
				t.eq(err, "expired")
				return ok
			end)
			refused(p, "owner-only code as a stranger", function()
				local ok, err = CodesLogic.redeem(p, "MONEY50K", Codes, codeCtx(42))
				t.eq(err, "unknown_code")
				return ok
			end)
			refused(p, "match code through the profile path", function()
				local ok, err = CodesLogic.redeem(p, "MONEY50K", Codes, codeCtx(2465538767))
				t.eq(err, "match_only")
				return ok
			end)
			local ok, err = CodesLogic.redeemMatchCash("MONEY50K", Codes, { userId = 2465538767, now = NOW, inMatch = false })
			t.eq(ok, false)
			t.eq(err, "match_only", "match cash outside a match")
			ok, err = CodesLogic.redeemMatchCash("MONEY50K", Codes, { userId = 42, now = NOW, inMatch = true })
			t.eq(err, "unknown_code", "match cash as a stranger")
		end)
		t.it("every published code has an expiry or an owner list, and none grants a currency past its cap", function()
			for id, def in Codes do
				t.truthy(def.expiresAt or def.onlyUserIds, id .. " never expires and is open to everyone")
				t.truthy((def.lira or 0) <= TD.MAX_LIRA and (def.qirsh or 0) <= Economy.MAX_QIRSH, id)
			end
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: ClaimPass", function()
		local tiers = SeasonPass.tiers
		local function leveled(n, premium)
			local p = profile()
			p.pass.premium = premium == true
			PassLogic.addLevels(p, n, tiers)
			return p
		end
		t.it("hostile tiers and tracks are refused without touching balances or claims", function()
			local p = leveled(5)
			for _, tier in HOSTILE do
				refused(p, "tier " .. named(tier), function()
					return (PassLogic.claim(p, tier, "free", tiers, grantCtx()))
				end)
			end
			refused(p, "tier nil", function()
				return (PassLogic.claim(p, nil, "free", tiers, grantCtx()))
			end)
			refused(p, "tier beyond the season", function()
				return (PassLogic.claim(p, #tiers + 1, "free", tiers, grantCtx()))
			end)
			for _, track in { "free2", "Premium", "", {}, 1, true, "premium " } do
				refused(p, "track " .. named(track), function()
					return (PassLogic.claim(p, 1, track, tiers, grantCtx()))
				end)
			end
			refused(p, "track nil", function()
				return (PassLogic.claim(p, 1, nil, tiers, grantCtx()))
			end)
		end)
		t.it("claiming above the reached level, the premium track without premium, or a tier twice is refused", function()
			local p = leveled(2)
			refused(p, "tier 3 at level 2", function()
				local ok, err = PassLogic.claim(p, 3, "free", tiers, grantCtx())
				t.eq(err, "locked")
				return ok
			end)
			refused(p, "premium track without premium", function()
				local ok, err = PassLogic.claim(p, 1, "premium", tiers, grantCtx())
				t.eq(err, "premium_required")
				return ok
			end)
			t.truthy(PassLogic.claim(p, 1, "free", tiers, grantCtx()))
			local claimed = 0
			for _ = 1, 1000 do
				local ok, err = PassLogic.claim(p, 1, "free", tiers, grantCtx())
				if ok then
					claimed += 1
				else
					t.eq(err, "already_claimed")
				end
			end
			t.eq(claimed, 0, "a tier was claimed twice")
		end)
		t.it("a level skip never passes the last tier, whatever the amount", function()
			local p = profile()
			PassLogic.addLevels(p, 10 ^ 9, tiers)
			t.eq((PassLogic.level(p.pass.xp, tiers)), #tiers)
			local xp = p.pass.xp
			PassLogic.addLevels(p, 10 ^ 9, tiers)
			t.eq(p.pass.xp, xp, "xp kept growing past the season")
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: ClaimDaily", function()
		t.it("1,000 claims in one day pay once; the next UTC day pays again", function()
			local p = profile()
			local grants = 0
			for _ = 1, 1000 do
				if DailyLogic.claim(p, NOW, Daily, grantCtx()) then
					grants += 1
				end
			end
			t.eq(grants, 1)
			t.eq(DailyLogic.claim(p, NOW + 86399 - (NOW % 86400), Daily, grantCtx()), false, "last second of the day")
			t.truthy(DailyLogic.claim(p, NOW + 86400, Daily, grantCtx()), "next day")
			t.eq(p.daily.streak, 2)
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: EventBuy", function()
		local eventId = "olive_harvest"
		local def = Events[eventId]
		local during = def.startsAt + 60
		local function rich()
			local p = profile()
			p.events[eventId] = { currency = def.maxCurrency, bought = {} }
			return p
		end
		t.it("hostile event ids and shop keys are refused without touching event currency", function()
			local p = rich()
			for _, v in HOSTILE do
				refused(p, "event " .. named(v), function()
					return (EventLogic.buy(p, Events, v, "qirsh_400", during, grantCtx()))
				end)
				refused(p, "key " .. named(v), function()
					return (EventLogic.buy(p, Events, eventId, v, during, grantCtx()))
				end)
			end
			refused(p, "nil ids", function()
				return (EventLogic.buy(p, Events, nil, nil, during, grantCtx()))
			end)
		end)
		t.it("buying before the window opens or after it closes is refused", function()
			local p = rich()
			for _, when in { def.startsAt - 1, def.endsAt, def.endsAt + 10 ^ 9, 0 } do
				refused(p, "buy at " .. when, function()
					local ok, err = EventLogic.buy(p, Events, eventId, "qirsh_400", when, grantCtx())
					t.eq(err, "event_over")
					return ok
				end)
			end
		end)
		t.it("1,000 buys of a limited item stop at its stock; currency never goes negative", function()
			for _, entry in def.shop do
				local p = rich()
				p.events[eventId].currency = 10 ^ 8
				local bought = 0
				for _ = 1, 1000 do
					if EventLogic.buy(p, Events, eventId, entry.key, during, grantCtx()) then
						bought += 1
					end
					t.truthy(p.events[eventId].currency >= 0, "event currency went negative")
				end
				t.eq(bought, entry.stock, entry.key)
				t.eq(p.events[eventId].bought[entry.key], entry.stock)
			end
			local poor = rich()
			poor.events[eventId].currency = def.shop[1].cost - 1
			refused(poor, "one short", function()
				local ok, err = EventLogic.buy(poor, Events, eventId, def.shop[1].key, during, grantCtx())
				t.eq(err, "not_enough")
				return ok
			end)
		end)
		t.it("match currency from hostile wave counts is clamped and never negative", function()
			local p = rich()
			p.events[eventId].currency = 0
			t.eq(EventLogic.addCurrency(p, eventId, def, 0 / 0), 0)
			t.eq(EventLogic.addCurrency(p, eventId, def, -1e9), 0)
			t.eq(EventLogic.addCurrency(p, eventId, def, "100"), 0)
			t.eq(p.events[eventId].currency, 0)
			t.eq(EventLogic.addCurrency(p, eventId, def, math.huge), def.maxCurrency)
			t.eq(EventLogic.matchCurrency(def, false, -5), 0)
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: ShopPurchase and SetWorn", function()
		local shop = Shops.khalil_tailor
		t.it("hostile item ids never buy, wear or spend", function()
			local p = profile({ qirsh = 10 ^ 6 })
			for _, v in HOSTILE do
				refused(p, "buy " .. named(v), function()
					return (ShopLogic.purchase(p, shop, v, Items))
				end)
				refused(p, "wear " .. named(v), function()
					return (ShopLogic.setWorn(p, v, true, Items))
				end)
			end
			refused(p, "buy nil", function()
				return (ShopLogic.purchase(p, shop, nil, Items))
			end)
		end)
		t.it("1,000 purchases of a cosmetic buy it once; a stranger's shop is refused", function()
			local p = profile({ qirsh = 10 ^ 6 })
			local bought = 0
			for _ = 1, 1000 do
				if ShopLogic.purchase(p, shop, "tarboosh_red", Items) then
					bought += 1
				end
			end
			t.eq(bought, 1)
			t.eq(p.qirsh, 10 ^ 6 - Items.tarboosh_red.price)
			refused(p, "no shop session", function()
				return (ShopLogic.purchase(p, nil, "tarboosh_black", Items))
			end)
			refused(p, "shop that does not sell it", function()
				return (ShopLogic.purchase(p, { items = {} }, "tarboosh_black", Items))
			end)
		end)
		t.it("Robux-only cosmetics cannot be bought with qirsh, and unowned ones cannot be worn", function()
			local p = profile({ qirsh = 10 ^ 6 })
			refused(p, "qirsh for a Robux item", function()
				return (ShopLogic.purchase(p, shop, "tarboosh_gold", Items))
			end)
			refused(p, "wear unowned", function()
				return (ShopLogic.setWorn(p, "tarboosh_gold", true, Items))
			end)
			refused(p, "unwear not worn", function()
				return (ShopLogic.setWorn(p, "tarboosh_red", false, Items))
			end)
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: SetSetting, SetLanguage, DialogueChoose, parties", function()
		t.it("settings: hostile keys and values are refused", function()
			for _, v in HOSTILE do
				t.eq(Settings.accept(v, true), false, "key " .. named(v))
				t.eq(Settings.accept("effects", v), false, "effects=" .. named(v))
				t.eq(Settings.accept("autoUlt", if v == true or v == false then "x" else v), false, "autoUlt=" .. named(v))
			end
			t.eq(Settings.accept(nil, true), false)
			t.eq(Settings.accept("effects", nil), false)
			t.eq(Settings.accept("language", "en"), false, "language has its own handler")
			t.eq(Settings.accept("__index", true), false)
			t.truthy(Settings.accept("effects", "reduced"))
		end)
		t.it("dialogue: hostile choice indices resolve to nothing", function()
			for _, v in HOSTILE do
				t.eq(DialogueLogic.choice(Dialogue.abu_nadim, "offer", v), nil, named(v))
			end
			t.eq(DialogueLogic.choice(Dialogue.abu_nadim, "offer", nil), nil)
			for _, v in HOSTILE do
				if type(v) == "string" then
					t.eq(DialogueLogic.choice(Dialogue.abu_nadim, v, 1), nil, "node " .. named(v))
				end
			end
		end)
		t.it("parties: no fifth member, no double join, no stranger's start, no negative size", function()
			local party = PartyLogic.new(1, "ep1", "normal", "host", 0, TD.QUEUE_SECONDS)
			local members = { "a", "b", "c", "d", "e", "f" }
			local joined = 0
			for _ = 1, 100 do
				for _, m in members do
					if PartyLogic.join(party, m, TD.MAX_PLAYERS, 0, TD.QUEUE_FULL_SECONDS) then
						joined += 1
					end
				end
			end
			t.eq(joined, TD.MAX_PLAYERS - 1)
			t.eq(#party.players, TD.MAX_PLAYERS)
			local startAt = party.startAt
			t.eq(PartyLogic.startSoon(party, "a", 0, 3), false)
			t.eq(PartyLogic.startSoon(party, "nobody", 0, 3), false)
			t.eq(party.startAt, startAt)
			t.eq(PartyLogic.leave(party, "nobody"), false)
			t.eq(#party.players, TD.MAX_PLAYERS)
			t.eq(PartyLogic.nextMode(Modes, "nonexistent"), nil)
		end)
		t.it("unlock gates: a locked mode or difficulty cannot be queued", function()
			local p = profile()
			t.eq(MatchRewards.canPlay(p, "ep2", Modes, "normal", TD), false, "ep2 before ep1")
			t.eq(MatchRewards.canPlay(p, "ep1", Modes, "hard", TD), false, "hard before normal")
			t.eq(MatchRewards.canPlay(p, "ep1", Modes, "nightmare", TD), false)
			t.eq(MatchRewards.canPlay(p, "nope", Modes, "normal", TD), false)
			t.eq(MatchRewards.canPlay(p, "ep1", Modes, "NORMAL", TD), false)
			t.truthy(MatchRewards.canPlay(p, "ep1", Modes, "normal", TD))
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: leaving a match (LeaveMatch rewards)", function()
		t.it("leaving at wave 0 pays nothing in any mode, so join-and-quit cannot farm", function()
			local p = profile()
			local zero = { won = false, wavesCleared = 0, totalWaves = 10 }
			for id, mode in Modes do
				local r = MatchRewards.compute(id, mode, "normal", zero, p, true, TD, function()
					return 0
				end)
				t.eq(r.lira + r.qirsh + r.xp + r.traitStones, 0, id)
			end
		end)
		t.it("a quit never pays more than the same loss, and never a first-clear bonus", function()
			local p = profile()
			for _, waves in { 1, 5, 9 } do
				local loss = { won = false, wavesCleared = waves, totalWaves = 10 }
				local r = MatchRewards.compute("ep1", Modes.ep1, "normal", loss, p, false, TD, function()
					return 0
				end)
				t.eq(r.firstClear, false)
				t.eq(r.traitStones, 0)
				local win = MatchRewards.compute("ep1", Modes.ep1, "normal", { won = true, wavesCleared = 10, totalWaves = 10 }, p, false, TD, function()
					return 1
				end)
				t.truthy(r.lira * 2 < win.lira, "a loss paid as much as a win")
			end
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: ProcessReceipt and product prompts", function()
		local pouch = { kind = "qirsh", amount = 100, nameKey = "product.qirsh_pouch" }
		t.it("1,000 replays of one receipt grant once and leave one receipt record", function()
			local p = profile({ qirsh = 0 })
			local grants = 0
			for _ = 1, 1000 do
				local ok, _, result = MonetizationLogic.grantReceipt(p, "r-1", pouch, grantCtx())
				t.truthy(ok)
				if result == "granted" then
					grants += 1
				else
					t.eq(result, "already")
				end
			end
			t.eq(grants, 1)
			t.eq(p.qirsh, 100)
			local n = 0
			for _ in p.receipts do
				n += 1
			end
			t.eq(n, 1)
		end)
		t.it("hostile receipt ids, unknown products and bad amounts grant nothing and record nothing", function()
			local p = profile({ qirsh = 0 })
			for _, id in HOSTILE do
				if type(id) ~= "string" or id == "" then
					refused(p, "receipt " .. named(id), function()
						return (MonetizationLogic.grantReceipt(p, id, pouch, grantCtx()))
					end)
				end
			end
			refused(p, "receipt nil", function()
				return (MonetizationLogic.grantReceipt(p, nil, pouch, grantCtx()))
			end)
			refused(p, "unknown product", function()
				return (MonetizationLogic.grantReceipt(p, "r-2", nil, grantCtx()))
			end)
			for _, amount in { 0 / 0, math.huge, -1, 0, 1.5, "100" } do
				refused(p, "amount " .. named(amount), function()
					return (MonetizationLogic.grantReceipt(p, "r-3", { kind = "qirsh", amount = amount }, grantCtx()))
				end)
			end
			refused(p, "unknown kind", function()
				return (MonetizationLogic.grantReceipt(p, "r-4", { kind = "robux", amount = 1 }, grantCtx()))
			end)
		end)
		t.it("prompts: unknown keys, unpublished ids and restricted regions never open a purchase", function()
			local p = profile()
			t.eq(MonetizationLogic.canPrompt(p, nil, nil, false), false)
			for _, id in { 0, -1, 0 / 0, math.huge, "5", {}, true } do
				t.eq(MonetizationLogic.canPrompt(p, pouch, id, false), false, named(id))
			end
			t.eq(MonetizationLogic.canPrompt(p, pouch, nil, false), false)
			for _, product in {
				{ kind = "lira", amount = 100 },
				{ kind = "stones", amount = 1 },
				{ kind = "passPremium", season = "s1" },
				{ kind = "passSkip", amount = 5 },
				{ kind = "bundle", bundle = { lira = 1 } },
				{ kind = "bundle", bundle = { traitStones = 1 } },
				{ kind = "bundle", bundle = { qirsh = 1 }, fallbackLira = 10 },
			} do
				t.eq(MonetizationLogic.canPrompt(p, product, 123, true), false, product.kind .. " while restricted")
				t.truthy(MonetizationLogic.canPrompt(p, product, 123, false), product.kind .. " unrestricted")
			end
			t.truthy(MonetizationLogic.canPrompt(p, pouch, 123, true), "qirsh is not a random item")
		end)
	end)

	------------------------------------------------------------------------------------------
	t.describe("Red team: Grants and the audit ledger (DataService.mutate path)", function()
		t.it("hostile reward amounts (NaN, inf, negative, fractional, strings) grant nothing; huge ones cap", function()
			local p = profile({ lira = 0, qirsh = 0, traitStones = 0 })
			for _, v in { 0 / 0, -math.huge, -1, 0, 1.5, "100", {}, true } do
				refused(p, "reward " .. named(v), function()
					local g = Grants.apply(p, { lira = v, qirsh = v, traitStones = v, xp = v }, grantCtx())
					return next(g) ~= nil
				end)
			end
			Grants.apply(p, { lira = 1e308, qirsh = 2 ^ 53, traitStones = 1e300 }, grantCtx())
			t.eq(p.lira, TD.MAX_LIRA)
			t.eq(p.qirsh, Economy.MAX_QIRSH)
			t.eq(p.traitStones, TD.MAX_TRAIT_STONES)
			refused(p, "unknown item and unit", function()
				local g = Grants.apply(p, { item = "nothing", unit = "nobody" }, grantCtx())
				return next(g) ~= nil
			end)
		end)
		t.it("a refused mutation writes no ledger line; a hostile meta never breaks the entry", function()
			local p = profile({ lira = 100 })
			local entry, ok = Ledger.mutate(p, function(prof)
				prof.lira -= 50
				return false, "refused"
			end, { src = "attack" }, NOW, Economy.LEDGER_SIZE)
			t.eq(entry, nil)
			t.eq(ok, false)
			t.eq(#p.ledger, 0)
			p.lira = 100
			for _, meta in { { src = 0 / 0 }, { src = {} }, { src = "" }, { src = "x", key = 5, seed = 0 / 0 }, { src = "x", seed = math.huge } } do
				local e = Ledger.mutate(p, function(prof)
					prof.lira += 1
					return true
				end, meta, NOW, Economy.LEDGER_SIZE)
				t.truthy(e, "entry missing")
				t.truthy(type(e.src) == "string" and #e.src > 0, "src not a string")
				t.eq(e.seed, nil, "hostile seed kept")
			end
		end)
		t.it("1,000 mutations never grow the ledger past LEDGER_SIZE, and a replayed key never writes twice", function()
			local p = profile({ lira = 0 })
			for i = 1, 1000 do
				Ledger.mutate(p, function(prof)
					prof.lira += 1
					return true
				end, { src = "flood", key = "k" .. (i % 10) }, NOW, Economy.LEDGER_SIZE)
			end
			t.truthy(#p.ledger <= Economy.LEDGER_SIZE, "ledger grew to " .. #p.ledger)
			t.eq(#p.ledger, 10, "only the first write of each key is recorded")
			-- The ledger is an audit, not the guard: the balance did move 1,000 times, because this
			-- mutation had no receipts/codes table. Replays are stopped by those tables (specs above).
			t.eq(p.lira, 1000)
		end)
		t.it("a mutation that errors mid-way leaves no ledger line (the service pcall swallows it)", function()
			local p = profile({ lira = 100 })
			local ok = pcall(Ledger.mutate, p, function(prof)
				prof.lira -= 100
				error("boom")
			end, { src = "x" }, NOW, Economy.LEDGER_SIZE)
			t.eq(ok, false)
			t.eq(#p.ledger, 0)
			-- Documented: the partial write survives. Logic modules validate before writing, so no
			-- shipped mutation errors after a balance change (REDTEAM_P3-09.md, DataService row).
			t.eq(p.lira, 0)
		end)
		t.it("stored ledgers with hostile entries load clean", function()
			local raw = {
				{ at = 0 / 0, src = "x", lira = 1 },
				{ at = 1, src = 5, lira = 1 },
				{ at = 1, src = string.rep("s", 1000), lira = 0 / 0, qirsh = math.huge, stones = 1e300 },
				{ at = 1, src = "ok", lira = 1, key = string.rep("k", 1000), seed = 0 / 0 },
				"junk",
				5,
			}
			local clean = Ledger.sanitize(raw, Economy.LEDGER_SIZE)
			t.eq(#clean, 2)
			t.eq(#clean[1].src, 64)
			t.eq(clean[1].lira, nil)
			t.eq(clean[1].qirsh, nil)
			t.eq(clean[1].stones, 1e300)
			t.eq(#clean[2].key, 64)
			t.eq(clean[2].seed, nil)
		end)
	end)
	------------------------------------------------------------------------------------------
	t.describe("Red team: ClientProfile and PlaceCancelled (MOBILE_HUD_PLAN MH-17)", function()
		t.it("the profile enum takes exactly the three HUD profiles; anything else is dropped", function()
			t.eq(DeviceTelemetry.index(Hud, "desktop"), 0)
			t.eq(DeviceTelemetry.index(Hud, "touch-phone"), 1)
			t.eq(DeviceTelemetry.index(Hud, "touch-tablet"), 2)
			local hostile = { "Desktop", "touch", "", string.rep("x", 1000), "touch-phone\0", 1, 0 / 0, math.huge, true, {}, nil }
			for i = 1, 11 do
				local session = DeviceTelemetry.newSession()
				local ok, why = DeviceTelemetry.report(Hud, session, hostile[i])
				t.eq(ok, false)
				t.eq(why, "bad_profile")
				t.eq(session.profile, nil)
			end
		end)
		t.it("only the first valid report of a session counts; 1,000 later reports change nothing", function()
			local session = DeviceTelemetry.newSession()
			t.eq((DeviceTelemetry.report(Hud, session, "touch-phone")), true)
			for i = 1, 1000 do
				local ok, why = DeviceTelemetry.report(Hud, session, if i % 2 == 0 then "desktop" else "touch-tablet")
				t.eq(ok, false)
				t.eq(why, "already_reported")
			end
			t.eq(session.profile, "touch-phone")
			t.eq(session.dropped, 1000)
		end)
		t.it("PlaceTower results: placed, refused spots count as invalid, every other refusal is ignored", function()
			t.eq(DeviceTelemetry.classify(Hud, true, nil), "placed")
			for _, err in { "bad_position", "out_of_bounds", "on_path", "too_close" } do
				t.eq(DeviceTelemetry.classify(Hud, false, err), "invalid")
			end
			for _, err in { "bad_request", "not_in_match", "match_over", "not_in_loadout", "tower_cap", "unit_cap", "cannot_afford", "rate_limited", "error", nil } do
				t.eq(DeviceTelemetry.classify(Hud, false, err), nil)
			end
		end)
		t.it("a cancel flood stops at the rate limit and the per-match cap; events carry the device", function()
			local limit = Hud.TELEMETRY.cancelLimit
			local l = RateLimiter.new(limit.capacity, limit.perSecond)
			local counts = DeviceTelemetry.newCounts()
			for i = 1, 1000 do
				if RateLimiter.allow(l, "attacker", (i - 1) / 1000) then
					DeviceTelemetry.add(Hud, counts, "cancelled")
				end
			end
			t.truthy(counts.cancelled <= limit.capacity + limit.perSecond, "cancels let through " .. counts.cancelled)
			for _ = 1, 5000 do
				DeviceTelemetry.add(Hud, counts, "invalid")
			end
			t.eq(counts.invalid, Hud.TELEMETRY.maxPerMatch)
			t.eq(counts.placed, 0)
			local session = DeviceTelemetry.newSession()
			DeviceTelemetry.report(Hud, session, "touch-phone")
			local events = DeviceTelemetry.events(counts, session)
			t.eq(#events, 2, "no event for a zero count")
			t.eq(events[1].name, "place_outcome_invalid")
			t.eq(events[1].value, Hud.TELEMETRY.maxPerMatch)
			t.eq(events[1].profile, "touch-phone")
			t.eq(events[2].name, "place_outcome_cancelled")
			t.eq(DeviceTelemetry.events(DeviceTelemetry.newCounts(), nil)[1], nil)
			counts.placed = 3
			t.eq(DeviceTelemetry.events(counts, nil)[1].profile, "unknown")
		end)
	end)

	t.describe("Red team: SetSpeed (LP-A03)", function()
		t.it("only exact members of TD.SPEEDS pass; anything above the host's ceiling needs a pass", function()
			local free, premium = TD.FREE_SPEED, TD.PREMIUM_SPEED
			for _, bad in { 0, -1, 6, 99, 2.5, 0 / 0, math.huge, -math.huge, "3", true, {}, nil } do
				local ok, why = MonetizationLogic.checkSpeed(bad, premium, TD)
				t.eq(ok, false, "refused: " .. tostring(bad))
				t.eq(why, "bad_speed")
			end
			for _, s in TD.SPEEDS do
				t.eq((MonetizationLogic.checkSpeed(s, premium, TD)), true, "premium host may pick " .. s)
				local ok, why = MonetizationLogic.checkSpeed(s, free, TD)
				if s <= free then
					t.eq(ok, true)
				else
					t.eq(why, "needs_pass", s .. "x needs a pass")
				end
			end
		end)
		t.it("1,000 requests of 5x from a free host never get through", function()
			local passed = 0
			for _ = 1, 1000 do
				if MonetizationLogic.checkSpeed(5, TD.FREE_SPEED, TD) then
					passed += 1
				end
			end
			t.eq(passed, 0)
		end)
	end)

	t.describe("Red team: SetAutoAbility (LP-B01)", function()
		t.it("the token bucket lets a burst of 10 through and then 10 a second, never 1,000", function()
			local lim = TD.AUTO_ABILITY_LIMIT
			t.eq(lim.capacity, 10)
			t.eq(lim.perSecond, 10)
			local l = RateLimiter.new(lim.capacity, lim.perSecond)
			local allowed = 0
			for i = 1, 1000 do
				if RateLimiter.allow(l, "attacker", i / 1000) then -- 1,000 calls in one second
					allowed += 1
				end
			end
			t.truthy(allowed <= lim.capacity + lim.perSecond + 1, "allowed " .. allowed)
		end)
	end)
end
