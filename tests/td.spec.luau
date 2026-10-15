--!nocheck
-- Tower defense: path math, wave generation, the simulation, tower rules, rewards and unlocks.

return function(t)
	local Path = t.logic("Path")
	local WaveLogic = t.logic("WaveLogic")
	local TdSim = t.logic("TdSim")
	local TdTowers = t.logic("TdTowers")
	local UnitLogic = t.logic("UnitLogic")
	local MatchRewards = t.logic("MatchRewards")
	local Units = t.config("Units")
	local Enemies = t.config("Enemies")
	local Waves = t.config("Waves")
	local Arenas = t.config("Arenas")
	local Modes = t.config("Modes")
	local TD = t.config("TD")
	local Traits = t.config("Traits")

	local NORMAL = TD.DIFFICULTIES.normal

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

	local function sim(points, waveFn, totalWaves, cash)
		return TdSim.new(points, { "p1" }, cash or 100000, 100, totalWaves, 1, {
			between = 2,
			waveBonusBase = TD.WAVE_BONUS_BASE,
			waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
			rewardMul = 1,
			enemies = Enemies,
		}, waveFn)
	end

	local function run(state, seconds)
		local all = {}
		local steps = math.floor(seconds / TD.TICK)
		for _ = 1, steps do
			for _, e in TdSim.step(state, TD.TICK) do
				table.insert(all, e)
			end
		end
		return all
	end

	local function count(events, kind)
		local n = 0
		for _, e in events do
			if e.type == kind then
				n += 1
			end
		end
		return n
	end

	t.describe("Path", function()
		t.it("measures length and interpolates", function()
			local p = Path.build({ { 0, 0 }, { 10, 0 }, { 10, 10 } })
			t.eq(p.length, 20)
			local x, z = Path.position(p, 5)
			t.eq(x, 5)
			t.eq(z, 0)
			x, z = Path.position(p, 15)
			t.eq(x, 10)
			t.eq(z, 5)
			x, z = Path.position(p, 999)
			t.eq(x, 10)
			t.eq(z, 10)
		end)
		t.it("distance to the polyline", function()
			local p = Path.build({ { 0, 0 }, { 10, 0 } })
			t.eq(Path.distanceTo(p, 5, 3), 3)
			t.eq(Path.distanceTo(p, 13, 4), 5)
		end)
	end)

	t.describe("WaveLogic", function()
		t.it("story waves grow, are sorted, and end with the boss", function()
			local ep = Waves.episodes.ep1
			local w1 = WaveLogic.story(ep, 1, NORMAL)
			local w9 = WaveLogic.story(ep, 9, NORMAL)
			t.truthy(w9.count > w1.count, "later waves are bigger")
			for i = 2, #w9.spawns do
				t.truthy(w9.spawns[i].at >= w9.spawns[i - 1].at, "sorted by time")
			end
			local w10 = WaveLogic.story(ep, 10, NORMAL)
			t.eq(w10.boss, "sergeant")
			t.eq(w10.spawns[#w10.spawns].enemy, "sergeant")
			t.truthy(w10.spawns[1].hpMul > w1.spawns[1].hpMul, "HP scales")
		end)
		t.it("every episode references real enemies and bosses", function()
			for id, ep in Waves.episodes do
				for _, e in ep.pool do
					t.truthy(Enemies[e.enemy], id .. " pool " .. e.enemy)
				end
				for w, boss in ep.bosses do
					t.truthy(Enemies[boss], id .. " boss " .. boss)
					t.truthy(w <= ep.waves, id .. " boss wave in range")
				end
			end
			for _, b in Waves.infinite.bossCycle do
				t.truthy(Enemies[b] and Enemies[b].boss, "infinite boss " .. b)
			end
		end)
		t.it("infinite waves scale and cycle bosses", function()
			local w10 = WaveLogic.infinite(Waves.infinite, 10, NORMAL)
			local w20 = WaveLogic.infinite(Waves.infinite, 20, NORMAL)
			t.eq(w10.boss, "sergeant")
			t.eq(w20.boss, "chief_thief")
			t.truthy(w20.spawns[1].hpMul > w10.spawns[1].hpMul)
			t.truthy(w20.count <= 91, "capped")
		end)
	end)

	t.describe("TdSim", function()
		local straight = { { 0, 0 }, { 100, 0 } }
		local function oneThief()
			return { spawns = { { at = 0, enemy = "thief", hpMul = 1, speedMul = 1 } }, count = 1 }
		end

		t.it("an undefended enemy reaches the gate and costs HP", function()
			local s = sim(straight, oneThief, 3)
			local ev = run(s, 1.1) -- prep is 1 s
			t.eq(count(ev, "waveStart"), 1)
			t.eq(count(ev, "spawn"), 1)
			ev = run(s, 100 / 8.5 + 0.5)
			t.eq(count(ev, "reached"), 1)
			t.eq(s.gateHp, 99)
			t.eq(s.phase, "prep", "wave ended, next countdown")
			t.eq(s.wave, 2)
			t.eq(s.players.p1.cash, 100000 + TD.WAVE_BONUS_BASE + TD.WAVE_BONUS_PER_WAVE)
		end)

		t.it("a tower kills the enemy, earns cash and the match is won after the last wave", function()
			local s = sim(straight, oneThief, 2)
			local ok, err, tower = TdTowers.place(s, "p1", "qabaday", Units.qabaday, 50, 4, 0, nil, rules())
			t.truthy(ok, err)
			t.eq(tower.level, 1)
			local ev = run(s, 30)
			t.eq(count(ev, "death"), 2, "one kill per wave")
			t.truthy(count(ev, "attack") >= 2)
			t.eq(s.phase, "won")
			t.eq(count(ev, "won"), 1)
			t.eq(s.players.p1.kills, 2)
			t.eq(s.gateHp, 100)
		end)

		t.it("non-detecting towers ignore stealth enemies", function()
			local s = sim(straight, oneThief, 1)
			t.truthy(TdTowers.place(s, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules()))
			local ev = run(s, 20)
			t.eq(count(ev, "attack"), 0)
			t.eq(count(ev, "reached"), 1)
		end)

		t.it("the gate falls → lost, and nothing moves afterwards", function()
			local s = sim(straight, function()
				return { spawns = { { at = 0, enemy = "colonel", hpMul = 1, speedMul = 1 } }, count = 1 }
			end, 5)
			s.gateHp = 10
			s.gateMax = 10
			local ev = run(s, 40)
			t.eq(count(ev, "lost"), 1)
			t.eq(s.phase, "lost")
			t.eq(#TdSim.step(s, 1), 0)
		end)

		t.it("skipCountdown starts the wave at once", function()
			local s = sim(straight, oneThief, 2)
			TdSim.skipCountdown(s)
			local ev = TdSim.step(s, TD.TICK)
			t.eq(count(ev, "waveStart"), 1)
		end)

		t.it("farms pay their owner at the end of a wave; healers mend the gate", function()
			local s = sim(straight, oneThief, 3)
			s.gateHp = 50
			t.truthy(TdTowers.place(s, "p1", "qahwaji", Units.qahwaji, 50, 6, 0, nil, rules()))
			t.truthy(TdTowers.place(s, "p1", "umm_hara", Units.umm_hara, 50, 10, 0, nil, rules()))
			local cashBefore = s.players.p1.cash
			run(s, 100 / 8.5 + 2)
			t.eq(s.wavesCleared, 1)
			t.eq(s.players.p1.cash, cashBefore + TD.WAVE_BONUS_BASE + TD.WAVE_BONUS_PER_WAVE + 90)
			t.eq(s.gateHp, 50 - 1 + 6)
		end)

		t.it("splash hits a group and slows apply", function()
			local s = sim(straight, function()
				local spawns = {}
				for i = 1, 5 do
					spawns[i] = { at = 0, enemy = "gendarme", hpMul = 1, speedMul = 1 }
				end
				return { spawns = spawns, count = 5 }
			end, 1)
			t.truthy(TdTowers.place(s, "p1", "saqqa", Units.saqqa, 20, 4, 0, nil, rules()))
			run(s, 3.2)
			local slowed = 0
			for _, e in s.enemies do
				if e.slowUntil > s.time then
					slowed += 1
				end
			end
			t.truthy(slowed >= 2, "several enemies slowed by one splash hit, got " .. slowed)
		end)
	end)

	t.describe("TdTowers rules", function()
		local straight = { { 0, 0 }, { 100, 0 } }
		local function fresh(cash)
			return sim(straight, function()
				return { spawns = {}, count = 0 }
			end, 1, cash)
		end

		t.it("rejects the path, spacing, caps, bounds and poverty", function()
			local s = fresh(100000)
			local r = rules()
			local ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 50, 1, 0, nil, r)
			t.eq(ok, false)
			t.eq(err, "on_path")
			t.truthy(TdTowers.place(s, "p1", "walad", Units.walad, 50, 6, 0, nil, r))
			ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 51, 6, 0, nil, r)
			t.eq(err, "too_close")
			ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 500, 6, 0, nil, r)
			t.eq(err, "out_of_bounds")
			ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 0 / 0, 6, 0, nil, r)
			t.eq(err, "bad_position")
			ok, err = TdTowers.place(s, "p2", "walad", Units.walad, 10, 6, 0, nil, r)
			t.eq(err, "not_in_match")
			for i = 2, Units.walad.maxPlaced do
				t.truthy(TdTowers.place(s, "p1", "walad", Units.walad, 50 + i * 3, 6, 0, nil, r))
			end
			ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 10, 6, 0, nil, r)
			t.eq(err, "unit_cap")
			local poor = fresh(10)
			ok, err = TdTowers.place(poor, "p1", "walad", Units.walad, 10, 6, 0, nil, r)
			t.eq(err, "cannot_afford")
		end)

		t.it("upgrades cost, strengthen and cap; selling refunds a share", function()
			local s = fresh(10000)
			local r = rules()
			local _, _, tower = TdTowers.place(s, "p1", "hallaq", Units.hallaq, 10, 6, 0, nil, r)
			local dmg1 = tower.stats.damage
			local ok = TdTowers.upgrade(s, "p1", tower.id, Units.hallaq, r)
			t.truthy(ok)
			t.eq(tower.level, 2)
			t.truthy(tower.stats.damage > dmg1)
			t.eq(s.players.p1.cash, 10000 - 280 - 190)
			for _ = 1, 10 do
				TdTowers.upgrade(s, "p1", tower.id, Units.hallaq, r)
			end
			local ok2, err = TdTowers.upgrade(s, "p1", tower.id, Units.hallaq, r)
			t.eq(ok2, false)
			t.eq(err, "max_level")
			t.eq(tower.level, #Units.hallaq.levels)
			local invested = tower.invested
			local ok3, _, refund = TdTowers.sell(s, "p1", tower.id, r)
			t.truthy(ok3)
			t.eq(refund, math.floor(invested * TD.SELL_REFUND))
			t.eq(#s.towers, 0)
			t.eq(TdTowers.sell(s, "p1", tower.id, r), false, "already sold")
			t.eq(TdTowers.setTargeting(s, "p1", 999, "first"), false)
		end)

		t.it("stars and traits raise the stats", function()
			local base = UnitLogic.stats(Units.zaim, 1, 0, nil, TD.STAR_BONUS)
			local starred = UnitLogic.stats(Units.zaim, 1, 3, nil, TD.STAR_BONUS)
			t.eq(starred.damage, base.damage * 1.15)
			local legend = UnitLogic.stats(Units.zaim, 1, 0, Traits.traits.legend, TD.STAR_BONUS)
			t.eq(legend.damage, base.damage * 1.5)
			t.truthy(legend.cooldown < base.cooldown)
			t.eq(UnitLogic.stars(0, TD.STAR_COPIES), 0)
			t.eq(UnitLogic.stars(4, TD.STAR_COPIES), 3)
			t.eq(UnitLogic.stars(99, TD.STAR_COPIES), 5)
		end)
	end)

	t.describe("Config integrity (TD)", function()
		t.it("units have rising costs, valid levels and banner pools per rarity", function()
			local perRarity = {}
			for id, u in Units do
				t.truthy(#u.levels >= 5, id .. " levels")
				for i, lv in u.levels do
					t.truthy(lv.cost > 0 and lv.cost % 1 == 0, id .. " level " .. i .. " cost")
					if i > 1 and u.role ~= "farm" and u.role ~= "support" and u.role ~= "healer" then
						t.truthy(lv.damage >= u.levels[i - 1].damage, id .. " damage grows")
					end
				end
				t.truthy(u.maxPlaced >= 1, id .. " maxPlaced")
				if not u.noBanner then
					perRarity[u.rarity] = (perRarity[u.rarity] or 0) + 1
				end
			end
			for _, r in { "rare", "epic", "legendary", "mythic" } do
				t.truthy((perRarity[r] or 0) >= 2, "at least 2 banner units of " .. r)
			end
		end)
		t.it("arenas and modes are consistent", function()
			for id, a in Arenas do
				t.truthy(#a.path >= 2, id .. " path")
				local p = Path.build(a.path)
				t.truthy(p.length > 100, id .. " long enough")
				local b = a.bounds
				for _, pt in a.path do
					t.truthy(pt[1] >= b[1] and pt[1] <= b[3] and pt[2] >= b[2] and pt[2] <= b[4], id .. " path inside bounds")
				end
			end
			for id, m in Modes do
				t.truthy(Arenas[m.arena], id .. " arena")
				if m.kind == "story" then
					t.truthy(Waves.episodes[m.episode], id .. " episode")
					t.truthy(TD.STORY_REWARDS[m.episode], id .. " rewards")
				end
				if m.requires then
					t.truthy(Modes[m.requires], id .. " requires")
				end
			end
		end)
	end)

	t.describe("MatchRewards", function()
		local function profile()
			return { td = { matches = 0, wins = 0, kills = 0, cleared = {}, bestInfinite = 0 } }
		end
		local never = function()
			return 0.99
		end

		t.it("story win pays double on first clear, then normal", function()
			local p = profile()
			local won = { won = true, wavesCleared = 20, totalWaves = 20 }
			local r = MatchRewards.compute("ep1", Modes.ep1, "normal", won, p, false, TD, never)
			t.eq(r.lira, TD.STORY_REWARDS.ep1.lira * 2)
			t.truthy(r.firstClear)
			MatchRewards.record(p, "ep1", Modes.ep1, "normal", won, 50, TD)
			t.eq(p.td.cleared.ep1, "normal")
			t.eq(p.td.wins, 1)
			local r2 = MatchRewards.compute("ep1", Modes.ep1, "normal", won, p, false, TD, never)
			t.eq(r2.lira, TD.STORY_REWARDS.ep1.lira)
			t.eq(r2.firstClear, false)
			local hard = MatchRewards.compute("ep1", Modes.ep1, "hard", won, p, true, TD, never)
			t.eq(hard.lira, math.floor(TD.STORY_REWARDS.ep1.lira * 1.6 * 2 * 1.25 + 0.5))
		end)
		t.it("a loss pays a share by waves reached", function()
			local p = profile()
			local lost = { won = false, wavesCleared = 10, totalWaves = 20 }
			local r = MatchRewards.compute("ep1", Modes.ep1, "normal", lost, p, false, TD, never)
			t.eq(r.lira, math.floor(TD.STORY_REWARDS.ep1.lira * TD.LOSS_SHARE * 0.5 + 0.5))
			t.eq(r.firstClear, false)
		end)
		t.it("infinite pays per 10-wave tier", function()
			local p = profile()
			local r = MatchRewards.compute("infinite", Modes.infinite, "normal", { won = false, wavesCleared = 25 }, p, false, TD, never)
			t.eq(r.lira, 100 + 230)
			MatchRewards.record(p, "infinite", Modes.infinite, "normal", { won = false, wavesCleared = 25 }, 10, TD)
			t.eq(p.td.bestInfinite, 25)
		end)
		t.it("unlocks: episodes and difficulties gate in order", function()
			local p = profile()
			t.truthy(MatchRewards.canPlay(p, "ep1", Modes, "normal", TD))
			local ok, err = MatchRewards.canPlay(p, "ep2", Modes, "normal", TD)
			t.eq(err, "locked_mode")
			ok, err = MatchRewards.canPlay(p, "ep1", Modes, "hard", TD)
			t.eq(err, "locked_difficulty")
			p.td.cleared.ep1 = "normal"
			t.truthy(MatchRewards.canPlay(p, "ep2", Modes, "normal", TD))
			t.truthy(MatchRewards.canPlay(p, "ep1", Modes, "hard", TD))
			ok, err = MatchRewards.canPlay(p, "ep1", Modes, "nightmare", TD)
			t.eq(err, "locked_difficulty")
			t.truthy(MatchRewards.canPlay(p, "infinite", Modes, "nightmare", TD), "infinite has no difficulty ladder")
			t.eq(MatchRewards.canPlay(p, "nope", Modes, "normal", TD), false)
		end)
	end)
end
