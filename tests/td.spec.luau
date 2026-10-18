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
		t.it("difficulty growth bites late, boss HP and the endless wall scale on top", function()
			local ep = Waves.episodes.ep1
			local nm = TD.DIFFICULTIES.nightmare
			local n1, m1 = WaveLogic.story(ep, 1, NORMAL), WaveLogic.story(ep, 1, nm)
			t.eq(m1.spawns[1].hpMul, n1.spawns[1].hpMul * nm.hp, "wave 1 differs only by the base multiplier")
			local n20, m20 = WaveLogic.story(ep, 20, NORMAL), WaveLogic.story(ep, 20, nm)
			t.truthy(m20.spawns[1].hpMul / n20.spawns[1].hpMul > 2, "nightmare's late waves are much tougher")
			local boss = m20.spawns[#m20.spawns]
			t.truthy(boss.boss)
			t.eq(boss.hpMul, m20.spawns[1].hpMul * nm.boss)
			local inf = Waves.infinite
			local w50 = WaveLogic.infinite(inf, inf.lateFrom, NORMAL).spawns[1].hpMul
			local w60 = WaveLogic.infinite(inf, inf.lateFrom + 10, NORMAL).spawns[1].hpMul
			local quad = 1 + inf.hpPerWave * (inf.lateFrom + 10) + inf.hpPerWaveSq * (inf.lateFrom + 10) ^ 2
			t.truthy(math.abs(w60 - quad * (1 + inf.lateGrowth) ^ 10) < 1e-9, "compounds after lateFrom")
			t.truthy(w60 > w50)
		end)
		t.it("party scale: one entry per party size, clamped; solo is neutral; missing tables mean none", function()
			for _, key in { "PARTY_HP", "PARTY_BOSS_HP", "PARTY_CASH" } do
				t.eq(#TD[key], TD.MAX_PLAYERS, key .. " covers 1..MAX_PLAYERS")
				t.eq(TD[key][1], 1, key .. " leaves solo alone")
			end
			for n = 2, TD.MAX_PLAYERS do
				t.truthy(TD.PARTY_HP[n] > TD.PARTY_HP[n - 1], "regular HP grows with the party")
				t.truthy(TD.PARTY_BOSS_HP[n] > TD.PARTY_BOSS_HP[n - 1], "boss HP grows with the party")
				t.truthy(TD.PARTY_BOSS_HP[n] <= TD.PARTY_HP[n], "bosses scale no faster than the swarm")
				t.truthy(TD.PARTY_HP[n] < n, "a party is still stronger than one player")
			end
			local s4 = WaveLogic.partyScale(TD, 4)
			t.eq(s4.hp, TD.PARTY_HP[4])
			t.eq(s4.boss, TD.PARTY_BOSS_HP[4])
			t.eq(s4.cash, TD.PARTY_CASH[4])
			t.eq(WaveLogic.partyScale(TD, 9).hp, TD.PARTY_HP[TD.MAX_PLAYERS], "clamped high")
			t.eq(WaveLogic.partyScale(TD, 0).hp, 1, "clamped low")
			t.deepEq(WaveLogic.partyScale({}, 3), { hp = 1, boss = 1, cash = 1 })
		end)
		t.it("party scaling multiplies regular spawns by hp and the boss by boss, story and endless", function()
			local ep = Waves.episodes.ep1
			local party = { hp = 2.5, boss = 1.5, cash = 1 }
			local solo, p = WaveLogic.story(ep, 10, NORMAL), WaveLogic.story(ep, 10, NORMAL, party)
			t.deepEq(WaveLogic.story(ep, 10, NORMAL, WaveLogic.partyScale(TD, 1)), solo, "a party of one is solo")
			t.eq(p.count, solo.count, "same enemies, just tougher")
			for i, sp in p.spawns do
				local mul = if sp.boss then party.boss else party.hp
				t.truthy(math.abs(sp.hpMul - solo.spawns[i].hpMul * mul) < 1e-9, sp.enemy)
				t.eq(sp.speedMul, solo.spawns[i].speedMul)
			end
			t.truthy(p.spawns[#p.spawns].boss, "wave 10 ends with its boss")
			local hard = TD.DIFFICULTIES.hard
			local i1, i2 = WaveLogic.infinite(Waves.infinite, 60, hard), WaveLogic.infinite(Waves.infinite, 60, hard, party)
			t.truthy(math.abs(i2.spawns[1].hpMul - i1.spawns[1].hpMul * party.hp) < 1e-9)
			t.truthy(math.abs(i2.spawns[#i2.spawns].hpMul - i1.spawns[#i1.spawns].hpMul * party.boss) < 1e-9)
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
			-- Attack events report the damage the target took (after armour), for damage numbers.
			local armor = Enemies.thief.armor or 0
			for _, e in ev do
				if e.type == "attack" then
					local mul = if e.ability then tower.stats.ability.multiplier else 1
					t.eq(e.damage, math.floor(tower.stats.damage * mul * (1 - armor) + 0.5), "attack damage")
					t.eq(e.damage, math.floor(e.damage), "whole number")
				end
			end
			t.eq(s.phase, "won")
			t.eq(count(ev, "won"), 1)
			t.eq(s.players.p1.kills, 2)
			t.eq(s.gateHp, 100)
		end)

		t.it("ultimates: auto fires on cooldown; manual waits for a tap, and taps are validated", function()
			local function abilities(events)
				local n = 0
				for _, e in events do
					if e.type == "attack" and e.ability then
						n += 1
					end
				end
				return n
			end
			local function crowd()
				local spawns = {}
				for k = 0, 39 do
					table.insert(spawns, { at = k * 0.5, enemy = "colonel", hpMul = 50, speedMul = 0.2 })
				end
				return { spawns = spawns, count = #spawns }
			end
			-- Auto (default): fires without being asked.
			local a = sim(straight, crowd, 1)
			local _, _, ta = TdTowers.place(a, "p1", "zaim", Units.zaim, 10, 4, 0, nil, rules())
			t.truthy(abilities(run(a, 25)) >= 1, "auto ultimate fired")
			-- Manual: never fires until tapped, then once.
			local m = sim(straight, crowd, 1)
			m.players.p1.autoAbility = false
			local _, _, tm = TdTowers.place(m, "p1", "zaim", Units.zaim, 10, 4, 0, nil, rules())
			t.eq(abilities(run(m, 25)), 0, "manual ultimate waits")
			local ok, err = TdTowers.useAbility(m, "p2", tm.id)
			t.eq(ok, false)
			t.eq(err, "not_yours")
			t.truthy(TdTowers.useAbility(m, "p1", tm.id))
			t.eq(abilities(run(m, 2)), 1, "fires once after the tap")
			ok, err = TdTowers.useAbility(m, "p1", tm.id)
			t.eq(err, "not_ready", "cooldown restarts")
			-- A defender without an ultimate.
			local _, _, tw = TdTowers.place(m, "p1", "walad", Units.walad, 30, 4, 0, nil, rules())
			ok, err = TdTowers.useAbility(m, "p1", tw.id)
			t.eq(err, "no_ability")
			t.truthy(ta)
		end)

		t.it("non-detecting towers ignore stealth enemies", function()
			local s = sim(straight, oneThief, 1)
			t.truthy(TdTowers.place(s, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules()))
			local ev = run(s, 20)
			t.eq(count(ev, "attack"), 0)
			t.eq(count(ev, "reached"), 1)
		end)

		t.it("Natour's lantern lets defenders inside his range target stealth enemies", function()
			local function attacksBy(ev, towerId)
				local n = 0
				for _, e in ev do
					if e.type == "attack" and e.tower == towerId then
						n += 1
					end
				end
				return n
			end
			t.eq(Units.natour.revealsStealth, true)
			-- In range: the tailor (no hitsStealth of its own) now hits the thief.
			local s = sim(straight, oneThief, 1)
			local _, _, tk = TdTowers.place(s, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules())
			local _, _, tn = TdTowers.place(s, "p1", "natour", Units.natour, 50, 14, 0, nil, rules())
			t.eq(TdSim.revealerFor(s, tk), tn)
			t.eq(TdSim.seesStealth(s, tk), true)
			t.eq(TdSim.revealerFor(s, tn), nil, "a lantern doesn't count itself")
			t.truthy(attacksBy(run(s, 20), tk.id) > 0, "revealed defender attacks")
			-- Out of range: the lantern is too far, the tailor stays blind.
			local s2 = sim(straight, oneThief, 1)
			local _, _, tk2 = TdTowers.place(s2, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules())
			local _, _, tn2 = TdTowers.place(s2, "p1", "natour", Units.natour, 50, -16, 0, nil, rules())
			t.eq(TdSim.revealerFor(s2, tk2), nil)
			t.eq(attacksBy(run(s2, 20), tk2.id), 0)
			-- Selling the lantern takes the reveal away.
			local s3 = sim(straight, oneThief, 1)
			local _, _, tk3 = TdTowers.place(s3, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules())
			local _, _, tn3 = TdTowers.place(s3, "p1", "natour", Units.natour, 50, 14, 0, nil, rules())
			t.truthy(TdTowers.sell(s3, "p1", tn3.id, rules()))
			t.eq(TdSim.seesStealth(s3, tk3), false)
			t.truthy(tn2)
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

		t.it("a stack of stunners cannot pin an enemy forever: chains are capped, then a short immunity", function()
			local function pinned(cap, immunity)
				local s = TdSim.new(straight, { "p1" }, 1e9, 100, 1, 1, {
					between = 2,
					waveBonusBase = 0,
					waveBonusPerWave = 0,
					rewardMul = 1,
					enemies = Enemies,
					stunChainMax = cap,
					stunImmunity = immunity,
				}, function()
					return { spawns = { { at = 0, enemy = "colonel", hpMul = 1e6, speedMul = 1 } }, count = 1 }
				end)
				for k, id in { "haddad", "haddad", "haddad", "haddad", "pahlawan", "pahlawan" } do
					local x = k * 3 - 1
					local ok, err, tw = TdTowers.place(s, "p1", id, Units[id], x, if k % 2 == 0 then 4 else -4, 0, nil, rules())
					t.truthy(ok, err)
					while TdTowers.upgrade(s, "p1", tw.id, Units[id], rules()) do
					end
				end
				local longest = 0
				for _ = 1, math.floor(40 / TD.TICK) do
					TdSim.step(s, TD.TICK)
					local e = s.enemies[1]
					if e and e.stunUntil > s.time then
						longest = math.max(longest, e.stunUntil - e.stunSince)
					end
				end
				return s.enemies[1], longest
			end
			local locked = pinned(nil, nil)
			t.truthy(locked.dist < 10, "without a cap 4 Blacksmiths + 2 Strongmen hold the Commandant near the spawn (dist " .. locked.dist .. ")")
			local freed, longest = pinned(5, 1)
			t.truthy(longest <= 5 + 1e-9, "no chain longer than the cap, got " .. longest)
			t.truthy(freed.dist > locked.dist + 5, "the capped enemy keeps walking (" .. freed.dist .. " vs " .. locked.dist .. ")")
			-- The live numbers: a minute-long cap still read as an infinite stun to players (Discord,
			-- 2026-10-17). An enemy must walk at least a third of the time under any stun pattern.
			t.truthy(TD.STUN_CHAIN_MAX > 0 and TD.STUN_CHAIN_MAX <= 10, "the live cap is seconds, not a minute")
			t.truthy(TD.STUN_IMMUNITY / (TD.STUN_CHAIN_MAX + TD.STUN_IMMUNITY) >= 1 / 3, "free at least a third of the time")
			local live, liveLongest = pinned(TD.STUN_CHAIN_MAX, TD.STUN_IMMUNITY)
			t.truthy(liveLongest <= TD.STUN_CHAIN_MAX + 1e-9, "live chains end at the cap, got " .. liveLongest)
			-- The Commandant walks 40 s × its speed unstunned; with the live cap it covers at least a third.
			t.truthy(live.dist >= Enemies.colonel.speed * (40 - 1) / 3, "the live cap keeps it walking (dist " .. live.dist .. ")")
		end)

		t.it("supports multiply the damage of defenders in their range, not outside it", function()
			local function dealt(withMukhtar, mx)
				local s = sim(straight, function()
					return { spawns = { { at = 0, enemy = "colonel", hpMul = 1000, speedMul = 0.01 } }, count = 1 }
				end, 1)
				t.truthy(TdTowers.place(s, "p1", "qabaday", Units.qabaday, 2, 4, 0, nil, rules()))
				if withMukhtar then
					local ok, err = TdTowers.place(s, "p1", "mukhtar", Units.mukhtar, mx, 6, 0, nil, rules())
					t.truthy(ok, err)
				end
				run(s, 10)
				return s.enemies[1].maxHp - s.enemies[1].hp
			end
			local base = dealt(false)
			t.truthy(base > 0, "the defender hits")
			local buffed = dealt(true, 6)
			t.truthy(math.abs(buffed / base - Units.mukhtar.levels[1].buff) < 1e-6, "Mukhtar's buff in range: " .. buffed / base)
			t.eq(dealt(true, 2 + Units.mukhtar.levels[1].range + 3), base, "no buff out of range")
		end)

		t.it("a fractional cash share still pays whole wave bonuses", function()
			local s = TdSim.new(straight, { "p1", "p2" }, 300, 100, 3, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE * 0.75,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE * 0.75,
				rewardMul = 1,
				enemies = Enemies,
			}, oneThief)
			run(s, 100 / 8.5 + 2)
			t.eq(s.wavesCleared, 1)
			local bonus = s.players.p1.cash - 300
			t.eq(bonus, math.floor((TD.WAVE_BONUS_BASE + TD.WAVE_BONUS_PER_WAVE) * 0.75 + 0.5))
			t.eq(s.players.p2.cash, s.players.p1.cash, "every player gets the bonus")
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

	-- Traits v2 (docs/STORY_PLAN.md §7.2, S1-S02): 12 traits, a second slot at TD.TRAIT2_STARS
	-- stars, the better trait per stat, and the D-041 caps.
	t.describe("Traits v2 (S1-S02)", function()
		local straight = { { 0, 0 }, { 100, 0 } }
		local caps = Traits.caps
		local function capped()
			local r = rules()
			r.traitCaps = caps
			return r
		end
		local function fresh()
			return sim(straight, function()
				return { spawns = {}, count = 0 }
			end, 1, 100000)
		end

		t.it("12 traits; the first eight keep their weights; legend stays ≈ 0.4 %; odds sum to 100", function()
			t.eq(#Traits.order, 12)
			local total, seen = 0, {}
			for _, id in Traits.order do
				t.truthy(Traits.traits[id], id .. " in the table")
				t.truthy(not seen[id], id .. " listed once")
				seen[id] = true
				total += Traits.traits[id].weight
			end
			for id in Traits.traits do
				t.truthy(seen[id], id .. " is in the order (the Rates panel lists the order)")
			end
			t.eq(total, 120)
			local old = { steady = 30, swift = 22, keen = 18, sharp = 14, golden = 8, hawk = 5, zaim = 2.5, legend = 0.5 }
			for id, w in old do
				t.eq(Traits.traits[id].weight, w, id .. " weight unchanged")
			end
			local sum, legend = 0, 0
			for _, row in UnitLogic.rerollOdds(Traits.traits, Traits.order, nil) do
				sum += row.percent
				if row.trait == "legend" then
					legend = row.percent
				end
			end
			t.truthy(math.abs(sum - 100) < 1e-9, "fresh odds sum " .. sum)
			t.truthy(math.abs(legend - 0.5 / 1.2) < 1e-9, "legend " .. legend .. " %")
		end)

		t.it("UnitLogic.stats clamps trait damage ≤ 1.5×, range ≤ 1.25×, cooldown ≥ 0.85×", function()
			local def = Units.qabaday
			local base = UnitLogic.stats(def, 1, 0, nil, 0, caps)
			local wild = { damage = 3, range = 2, cooldown = 0.4 }
			local st = UnitLogic.stats(def, 1, 0, wild, 0, caps)
			t.eq(st.damage, base.damage * caps.damage)
			t.eq(st.range, base.range * caps.range)
			t.eq(st.cooldown, base.cooldown * caps.cooldown)
			local raw = UnitLogic.stats(def, 1, 0, wild, 0)
			t.eq(raw.damage, base.damage * 3, "no caps = no clamp (old callers)")
			-- Every pair of real traits, merged and clamped, stays inside the caps; stars stay on top.
			for _, a in Traits.order do
				for _, b in Traits.order do
					local m = UnitLogic.combineTraits(Traits.traits[a], Traits.traits[b])
					local s = UnitLogic.stats(def, 1, 0, m, 0, caps)
					t.truthy(s.damage <= base.damage * caps.damage + 1e-9, a .. "+" .. b .. " damage")
					t.truthy(s.range <= base.range * caps.range + 1e-9, a .. "+" .. b .. " range")
					t.truthy(s.cooldown >= base.cooldown * caps.cooldown - 1e-9, a .. "+" .. b .. " cooldown")
				end
			end
			local five = UnitLogic.stats(def, 1, 5, Traits.traits.legend, TD.STAR_BONUS, caps)
			t.truthy(math.abs(five.damage - base.damage * 1.5 * (1 + 5 * TD.STAR_BONUS)) < 1e-9, "stars are not a trait")
		end)

		t.it("two traits never stack a stat: the better one wins", function()
			local m = UnitLogic.combineTraits(Traits.traits.legend, Traits.traits.zaim)
			t.eq(m.damage, 1.5, "not 1.5 × 1.3")
			t.eq(m.range, 1.2)
			t.eq(m.cooldown, 0.85)
			local s = UnitLogic.combineTraits(Traits.traits.steady, Traits.traits.sharp)
			t.eq(s.damage, 1.15)
			local mix = UnitLogic.combineTraits(Traits.traits.swift, Traits.traits.lantern)
			t.eq(mix.cooldown, 0.92)
			t.eq(mix.hitsStealth, true)
			t.eq(UnitLogic.combineTraits(nil, Traits.traits.swift), Traits.traits.swift)
			t.eq(UnitLogic.combineTraits(nil, nil), nil)
		end)

		t.it("the second slot opens at 3 stars; rerolling it spends a stone and leaves slot 1 alone", function()
			local rule = { starCopies = TD.STAR_COPIES, stars = TD.TRAIT2_STARS }
			local copies3 = TD.STAR_COPIES[TD.TRAIT2_STARS]
			local function prof(copies)
				return { units = { u = { copies = copies, trait = "steady", at = 0 } }, traitStones = 5 }
			end
			local i = 0
			local function rng()
				i += 1
				return (i * 0.37) % 1
			end
			local p = prof(copies3 - 1)
			local ok, err = UnitLogic.rerollTrait(p, "u", 1, Traits.traits, Traits.order, rng, 2, rule)
			t.eq(ok, false)
			t.eq(err, "slot_locked")
			t.eq(p.traitStones, 5, "no stone spent")
			t.eq(p.units.u.trait2, nil)
			ok, err = UnitLogic.rerollTrait(prof(copies3), "u", 1, Traits.traits, Traits.order, rng, 2, nil)
			t.eq(err, "slot_locked", "no unlock rule, no second slot")
			ok, err = UnitLogic.rerollTrait(prof(copies3), "u", 1, Traits.traits, Traits.order, rng, 3, rule)
			t.eq(err, "bad_request")
			local q = prof(copies3)
			local got
			ok, err, got = UnitLogic.rerollTrait(q, "u", 1, Traits.traits, Traits.order, rng, 2, rule)
			t.truthy(ok, err)
			t.eq(q.units.u.trait2, got)
			t.eq(q.units.u.trait, "steady", "slot 1 untouched")
			t.eq(q.traitStones, 4)
			ok = UnitLogic.rerollTrait(q, "u", 1, Traits.traits, Traits.order, rng)
			t.truthy(ok)
			t.eq(q.units.u.trait2, got, "slot 1 reroll leaves slot 2 alone")
			-- ownedTrait merges slot 2 only from the threshold on.
			local owned = { copies = copies3 - 1, trait = "steady", trait2 = "legend", at = 0 }
			t.eq(UnitLogic.ownedTrait(owned, Traits.traits, TD.STAR_COPIES, TD.TRAIT2_STARS), Traits.traits.steady)
			owned.copies = copies3
			t.eq(UnitLogic.ownedTrait(owned, Traits.traits, TD.STAR_COPIES, TD.TRAIT2_STARS).damage, 1.5)
		end)

		t.it("lantern sees stealth, miser pays 10 % less, twin places one more, fireproof douses", function()
			local s = fresh()
			local tr = Traits.traits
			local _, _, lw = TdTowers.place(s, "p1", "khayyat", Units.khayyat, 10, 4, 0, tr.lantern, capped())
			t.eq(lw.stats.hitsStealth, true)
			local before = s.players.p1.cash
			local _, _, mz = TdTowers.place(s, "p1", "qabaday", Units.qabaday, 20, 4, 0, tr.miser, capped())
			t.eq(before - s.players.p1.cash, UnitLogic.costFor(Units.qabaday.levels[1].cost, tr.miser))
			t.eq(UnitLogic.costFor(Units.qabaday.levels[1].cost, tr.miser), math.floor(Units.qabaday.levels[1].cost * 0.9 + 0.5))
			before = s.players.p1.cash
			t.truthy(TdTowers.upgrade(s, "p1", mz.id, Units.qabaday, capped()))
			t.eq(before - s.players.p1.cash, math.floor(Units.qabaday.levels[2].cost * 0.9 + 0.5), "upgrades too")
			t.eq(mz.invested, UnitLogic.costFor(Units.qabaday.levels[1].cost, tr.miser) + UnitLogic.costFor(Units.qabaday.levels[2].cost, tr.miser), "sell refunds what was paid")
			-- twin: maxPlaced + 1
			local cap = Units.zaim.maxPlaced
			local x = 30
			for _ = 1, cap do
				t.truthy(TdTowers.place(s, "p1", "zaim", Units.zaim, x, 4, 0, nil, capped()))
				x += 4
			end
			local ok, err = TdTowers.place(s, "p1", "zaim", Units.zaim, x, 4, 0, nil, capped())
			t.eq(err, "unit_cap")
			ok = TdTowers.place(s, "p1", "zaim", Units.zaim, x, 4, 0, tr.twin, capped())
			t.truthy(ok, "the twin trait allows one more")
			x += 4
			_, err = TdTowers.place(s, "p1", "zaim", Units.zaim, x, 4, 0, tr.twin, capped())
			t.eq(err, "unit_cap", "but only one more")
			local _, _, fp = TdTowers.place(s, "p1", "walad", Units.walad, 80, 4, 0, tr.fireproof, capped())
			t.eq(fp.stats.douse, 1)
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

	-- Season Story 1 mechanics, batch 1 (docs/STORY_PLAN.md §10.1, S1-S01). The enemies that carry
	-- these flags arrive with S1-S03, so the specs use stand-in defs on top of the real ones.
	t.describe("Story mechanics (S1-S01)", function()
		local straight = { { 0, 0 }, { 100, 0 } }
		local function V()
			return Enemies.gendarme.visual
		end
		local E = setmetatable({
			swarmer = { nameKey = "x", hp = 16, speed = 9.5, reward = 6, gateDamage = 1, swarm = true, visual = V() },
			drummer = { nameKey = "x", hp = 110, speed = 5, reward = 28, gateDamage = 1, aura = { speed = 1.25, radius = 7 }, visual = V() },
			bigdrum = { nameKey = "x", hp = 110, speed = 5, reward = 28, gateDamage = 1, aura = { speed = 3, radius = 7 }, visual = V() },
			porter = { nameKey = "x", hp = 260, speed = 3.6, reward = 45, gateDamage = 2, shield = { radius = 6, reduce = 0.3 }, visual = V() },
			torch = { nameKey = "x", hp = 70, speed = 50, reward = 20, gateDamage = 1, burn = 1, visual = V() },
			tank = { nameKey = "x", hp = 1e9, speed = 1, reward = 0, gateDamage = 0, visual = V() },
			neighbour = { nameKey = "x", hp = 1e6, speed = 2, reward = 32, gateDamage = 2, disguised = true, visual = V() },
		}, { __index = Enemies })
		local function simE(points, waveFn, totalWaves)
			return TdSim.new(points, { "p1" }, 100000, 100, totalWaves, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = E,
				maxSpeedMul = WaveLogic.MAX_SPEED_MUL,
				burnMax = TD.BURN_MAX_STACKS,
				burnTick = TD.BURN_TICK,
				burnDamage = TD.BURN_DAMAGE,
				burnFor = TD.BURN_SECONDS,
			}, waveFn)
		end
		local function waveOf(list)
			return function()
				local spawns = {}
				for _, s in list do
					table.insert(spawns, { at = s[2] or 0, enemy = s[1], hpMul = 1, speedMul = s[3] or 1 })
				end
				return { spawns = spawns, count = #spawns }
			end
		end
		local function find(state, enemyId)
			for _, e in state.enemies do
				if e.enemyId == enemyId then
					return e
				end
			end
			return nil
		end
		local function attacksBy(ev, towerId)
			local n = 0
			for _, e in ev do
				if e.type == "attack" and e.tower == towerId then
					n += 1
				end
			end
			return n
		end

		t.it("swarm: a 12-group spawns whole, groups go to 60, and swarms weigh half in the 90 cap", function()
			local ep = { hpPerWave = 0, bosses = {}, pool = { { enemy = "swarmer", from = 1, base = 12, perWave = 0, gap = 0.2 } } }
			local w = WaveLogic.story(ep, 1, NORMAL, nil, E)
			t.eq(w.count, 12)
			t.truthy(w.spawns[1].swarm)
			local big = { hpPerWave = 0, bosses = {}, pool = { { enemy = "swarmer", from = 1, base = 100, perWave = 0, gap = 0.1 } } }
			t.eq(WaveLogic.story(big, 1, NORMAL, nil, E).count, WaveLogic.SWARM_PER_GROUP)
			local plain = { hpPerWave = 0, bosses = {}, pool = { { enemy = "gendarme", from = 1, base = 100, perWave = 0, gap = 0.1 } } }
			t.eq(WaveLogic.story(plain, 1, NORMAL, nil, E).count, 40, "regular groups keep 40")
			t.eq(WaveLogic.story(big, 1, NORMAL).count, 40, "without the enemy table nothing is a swarm")
			local mixed = {
				hpPerWave = 0,
				bosses = { [1] = "sergeant" },
				pool = {
					{ enemy = "gendarme", from = 1, base = 40, perWave = 0, gap = 0.5 },
					{ enemy = "thug", from = 1, base = 40, perWave = 0, gap = 0.5 },
					{ enemy = "swarmer", from = 1, base = 60, perWave = 0, gap = 0.2 },
				},
			}
			local m = WaveLogic.story(mixed, 1, NORMAL, nil, E)
			local weight = WaveLogic.weight(m.spawns)
			t.truthy(weight <= WaveLogic.MAX_PER_WAVE, "cap holds: " .. weight)
			t.truthy(weight > WaveLogic.MAX_PER_WAVE - 1, "the cap is filled, not under-filled")
			t.truthy(#m.spawns - 1 > WaveLogic.MAX_PER_WAVE, "more bodies than the old 90 because swarms weigh half")
			t.eq(m.spawns[#m.spawns].enemy, "sergeant", "the boss still closes the wave")
		end)

		t.it("aura: drummers speed others up (not themselves), never stack, never past MAX_SPEED_MUL", function()
			local s = simE(straight, waveOf({ { "drummer" }, { "drummer" }, { "gendarme" }, { "gendarme", 0, 1.5 } }), 1)
			run(s, 1.05)
			local muls = TdSim.auraMuls(s)
			local g1, g2
			for _, e in s.enemies do
				if e.enemyId == "gendarme" then
					if e.speed == Enemies.gendarme.speed then
						g1 = e
					else
						g2 = e
					end
				end
			end
			t.eq(muls[g1], 1.25, "two drummers: the best aura, not 1.25²")
			t.eq(muls[find(s, "drummer")], 1.25, "a drummer is sped up by the other drummer")
			local cap = WaveLogic.MAX_SPEED_MUL / 1.5
			t.truthy(math.abs(muls[g2] - math.min(1.25, cap)) < 1e-9, "a fast gendarme is held at the cap")
			local lone = simE(straight, waveOf({ { "drummer" } }), 1)
			run(lone, 1.05)
			t.eq(TdSim.auraMuls(lone)[find(lone, "drummer")], nil, "a lone drummer doesn't speed itself")
			local huge = simE(straight, waveOf({ { "bigdrum" }, { "gendarme" } }), 1)
			run(huge, 1.05)
			local g = find(huge, "gendarme")
			t.truthy(math.abs(TdSim.auraMuls(huge)[g] * g.speed - g.baseSpeed * WaveLogic.MAX_SPEED_MUL) < 1e-9, "a ×3 aura is capped")
			local d0 = g.dist
			run(huge, 1)
			t.truthy(g.dist - d0 <= g.baseSpeed * WaveLogic.MAX_SPEED_MUL + 1e-6, "it really walks no faster than the cap")
			local far = simE(straight, waveOf({ { "drummer" }, { "gendarme", 3 } }), 1)
			run(far, 4.2)
			t.eq(TdSim.auraMuls(far)[find(far, "gendarme")], nil, "out of the radius: no boost")
		end)

		t.it("shield: one porter takes 30 % off, two porters still 30 %, the porter covers itself", function()
			local s = simE(straight, waveOf({ { "porter" }, { "gendarme" } }), 1)
			run(s, 1.05)
			t.eq(TdSim.shieldFor(s, find(s, "gendarme")), 0.3)
			t.eq(TdSim.shieldFor(s, find(s, "porter")), 0.3)
			local s2 = simE(straight, waveOf({ { "porter" }, { "porter" }, { "gendarme" } }), 1)
			run(s2, 1.05)
			t.eq(TdSim.shieldFor(s2, find(s2, "gendarme")), 0.3, "not stacking")
			local s3 = simE(straight, waveOf({ { "porter" }, { "gendarme", 0, 4 } }), 1)
			run(s3, 2.5)
			t.eq(TdSim.shieldFor(s3, find(s3, "gendarme")), 0, "outside the radius")
			-- The damage itself: a single hit on a shielded gendarme loses 30 %.
			local s4 = simE(straight, waveOf({ { "porter" }, { "gendarme" } }), 1)
			local _, _, tw = TdTowers.place(s4, "p1", "walad", Units.walad, 6, 4, 0, nil, rules())
			tw.targeting = "close"
			local ev = run(s4, 1.1)
			local g = find(s4, "gendarme")
			local p = find(s4, "porter")
			local lost = (g.maxHp - g.hp) + (p.maxHp - p.hp)
			t.truthy(attacksBy(ev, tw.id) >= 1)
			t.truthy(math.abs(lost - attacksBy(ev, tw.id) * Units.walad.levels[1].damage * 0.7) < 1e-9, "damage × 0.7")
		end)

		t.it("burn: stacks cap at 5, tick 1 HP per stack per 2 s, a douser takes them off, a cleared wave puts it out", function()
			local spawns = { { "tank" } }
			for _ = 1, 7 do
				table.insert(spawns, { "torch" })
			end
			local s = simE(straight, waveOf(spawns), 2)
			run(s, 1 + 100 / 50 + 0.1)
			t.eq(s.gateBurn.stacks, TD.BURN_MAX_STACKS, "7 torches, 5 stacks")
			t.eq(s.gateHp, 100 - 7, "each torch still hits for its gate damage")
			local ev = run(s, TD.BURN_TICK)
			t.eq(s.gateHp, 100 - 7 - TD.BURN_MAX_STACKS * TD.BURN_DAMAGE, "one tick: stacks × damage")
			t.truthy(count(ev, "gateBurn") >= 1)
			-- The stacks expire BURN_SECONDS after the newest one.
			run(s, TD.BURN_SECONDS)
			t.eq(s.gateBurn.stacks, 0)
			local hp = s.gateHp
			run(s, 5)
			t.eq(s.gateHp, hp, "nothing burns once the stacks are gone")

			-- A douser (Fawza) takes a stack off with each attack; the tank keeps the wave going.
			local d = simE(straight, waveOf(spawns), 2)
			run(d, 1 + 100 / 50 + 0.1)
			t.eq(d.gateBurn.stacks, 5)
			local _, _, fz = TdTowers.place(d, "p1", "saqqa", Units.saqqa, 4, 4, 0, nil, rules())
			t.eq(fz.stats.douse, 1)
			ev = run(d, Units.saqqa.levels[1].cooldown + 0.1)
			local doused = 0
			for _, e in ev do
				if e.type == "gateBurn" and e.doused == fz.id then
					doused += 1
				end
			end
			t.eq(doused, 2)
			t.eq(d.gateBurn.stacks, 3, "two attacks, two stacks gone")

			-- No burning between waves: the last enemy dies, the stacks go out with the wave.
			local w = simE(straight, waveOf({ { "torch" }, { "torch" } }), 3)
			run(w, 1 + 100 / 50 + 0.1)
			t.eq(w.phase, "prep", "the wave ended")
			t.eq(w.gateBurn.stacks, 0)
			hp = w.gateHp
			run(w, 1.5)
			t.eq(w.gateHp, hp)
		end)

		t.it("disguised: no target for a Lane Boy, a lantern unmasks it, a lit single hit unmasks it, splash never", function()
			local function one()
				return simE(straight, waveOf({ { "neighbour" } }), 1)
			end
			-- The Lane Boy (hitsStealth, no lantern) cannot target one.
			local s = one()
			local _, _, w = TdTowers.place(s, "p1", "walad", Units.walad, 20, 4, 0, nil, rules())
			t.eq(attacksBy(run(s, 12), w.id), 0)
			t.eq(find(s, "neighbour").disguised, true)
			-- Abu Fares's lantern covers the road: revealed, and then everyone can hit it.
			local s2 = one()
			local _, _, w2 = TdTowers.place(s2, "p1", "walad", Units.walad, 20, 4, 0, nil, rules())
			local _, _, n2 = TdTowers.place(s2, "p1", "natour", Units.natour, 40, -6, 0, nil, rules()) -- too far to light the boy
			t.eq(TdSim.seesDisguised(s2, w2), false, "the boy is outside the light")
			local ev = run(s2, 20)
			local revealedBy = nil
			for _, e in ev do
				if e.type == "revealed" then
					revealedBy = e.by
				end
			end
			t.eq(revealedBy, n2.id, "the lantern revealed it")
			t.eq(find(s2, "neighbour").disguised, false)
			t.truthy(attacksBy(ev, w2.id) > 0, "after the reveal the Lane Boy attacks")
			-- A lantern whose light misses the road still lights the tailor next to it; the tailor's
			-- single hit is what unmasks the neighbour.
			local s3 = one()
			local _, _, k3 = TdTowers.place(s3, "p1", "khayyat", Units.khayyat, 20, 4, 0, nil, rules())
			TdTowers.place(s3, "p1", "natour", Units.natour, 20, 14, 0, nil, rules())
			t.eq(TdSim.seesDisguised(s3, k3), true)
			ev = run(s3, 12)
			local by = nil
			for _, e in ev do
				if e.type == "revealed" then
					by = by or e.by
				end
			end
			t.eq(by, k3.id, "revealed by the tailor's hit")
			-- A lit splash defender still cannot touch an unrevealed one.
			local s4 = one()
			local _, _, f4 = TdTowers.place(s4, "p1", "saqqa", Units.saqqa, 20, 4, 0, nil, rules())
			TdTowers.place(s4, "p1", "natour", Units.natour, 20, 14, 0, nil, rules())
			t.eq(TdSim.seesDisguised(s4, f4), false)
			t.eq(attacksBy(run(s4, 12), f4.id), 0)
			t.eq(find(s4, "neighbour").hp, find(s4, "neighbour").maxHp, "splash-immune")
		end)
	end)

	-- The balance targets (docs/TOWER_DEFENSE.md §5), played by the auto-battler on the real config.
	-- Full report: `lune run tests/balance`.
	t.describe("Balance (auto-battler)", function()
		local AutoBattle = require("./autobattle")
		local function play(mode, diff, policy)
			return AutoBattle.play(mode, diff, policy, { maxWaves = 120 })
		end

		-- Season Story 1 must not move Episodes 1–3 (STORY_PLAN §11): every cell of their
		-- `lune run tests/balance --md` rows, frozen on 2026-10-18 (after D-031). Re-freeze only with
		-- a TUNE row in DECISIONS.
		t.it("Episodes 1–3 rows stay frozen (STORY_PLAN §11)", function()
			local FROZEN = {
				["ep1/normal"] = { re6 = "lost w14", re4up = "WIN 100/100", re6up = "WIN 100/100", re10up = "WIN 100/100", leg6 = "lost w19", leg10up = "WIN 100/100", myth12up = "WIN 100/100", whale = "WIN 100/100" },
				["ep1/hard"] = { re6 = "lost w10", re4up = "lost w18", re6up = "lost w14", re10up = "WIN 14/60", leg6 = "lost w11", leg10up = "WIN 57/60", myth12up = "WIN 54/60", whale = "WIN 60/60" },
				["ep1/nightmare"] = { re6 = "lost w9", re4up = "lost w10", re6up = "lost w10", re10up = "lost w10", leg6 = "lost w10", leg10up = "lost w10", myth12up = "WIN 32/35", whale = "WIN 35/35" },
				["ep2/normal"] = { re6 = "lost w11", re4up = "lost w19", re6up = "WIN 88/100", re10up = "WIN 88/100", leg6 = "lost w15", leg10up = "WIN 90/100", myth12up = "WIN 80/100", whale = "WIN 96/100" },
				["ep2/hard"] = { re6 = "lost w9", re4up = "lost w10", re6up = "lost w10", re10up = "lost w10", leg6 = "lost w10", leg10up = "WIN 40/60", myth12up = "WIN 33/60", whale = "WIN 50/60" },
				["ep2/nightmare"] = { re6 = "lost w7", re4up = "lost w7", re6up = "lost w8", re10up = "lost w8", leg6 = "lost w8", leg10up = "lost w10", myth12up = "WIN 3/35", whale = "WIN 22/35" },
				["ep3/normal"] = { re6 = "lost w11", re4up = "lost w15", re6up = "lost w13", re10up = "lost w20", leg6 = "lost w14", leg10up = "WIN 94/100", myth12up = "WIN 83/100", whale = "WIN 96/100" },
				["ep3/hard"] = { re6 = "lost w10", re4up = "lost w10", re6up = "lost w10", re10up = "lost w10", leg6 = "lost w10", leg10up = "lost w20", myth12up = "WIN 26/60", whale = "WIN 56/60" },
				["ep3/nightmare"] = { re6 = "lost w8", re4up = "lost w8", re6up = "lost w8", re10up = "lost w8", leg6 = "lost w8", leg10up = "lost w10", myth12up = "lost w10", whale = "WIN 29/35" },
			}
			local drift = {}
			for row, cells in FROZEN do
				local mode, diff = string.match(row, "^(%w+)/(%w+)$")
				for policy, want in cells do
					local r = AutoBattle.play(mode, diff, policy, { maxWaves = 150 })
					local got = if r.won then string.format("WIN %d/%d", r.gateHp, r.gateMax) else string.format("lost w%d", r.wavesCleared + 1)
					if got ~= want then
						table.insert(drift, row .. " " .. policy .. ": " .. want .. " → " .. got)
					end
				end
			end
			table.sort(drift)
			t.eq(#drift, 0, "balance drift: " .. table.concat(drift, "; "))
		end)

		t.it("Episode 1 Normal: 4–6 upgraded Rare/Epic win; without upgrades the wave-10 boss breaks you", function()
			t.truthy(play("ep1", "normal", "re4up").won, "4 R/E + upgrades")
			t.truthy(play("ep1", "normal", "re6up").won, "6 R/E + upgrades")
			local r = play("ep1", "normal", "re6")
			t.eq(r.won, false, "6 R/E without upgrades")
			t.truthy(r.waves[10].bossLeaked, "the Sergeant gets through")
			t.eq(play("ep1", "normal", "leg6").won, false, "a Legendary without upgrades still falls")
		end)
		t.it("A new player's upgraded starter units hold Episode 1 to the final boss (they see stealth thieves)", function()
			local r = play("ep1", "normal", "starter")
			t.truthy(r.won or r.wavesCleared >= 19, "starter-only fell on wave " .. tostring(r.wavesCleared + 1))
		end)
		t.it("Hard needs upgrades on a bigger team or a Legendary", function()
			t.eq(play("ep1", "hard", "re6up").won, false)
			t.eq(play("ep1", "hard", "leg6").won, false)
			t.truthy(play("ep1", "hard", "re10up").won)
			t.truthy(play("ep1", "hard", "leg10up").won)
		end)
		t.it("Nightmare needs Mythics", function()
			t.eq(play("ep1", "nightmare", "leg10up").won, false)
			t.truthy(play("ep1", "nightmare", "myth12up").won)
		end)
		t.it("Parties of 2–4 Rare/Epic players keep Episode 1 Normal's ladder", function()
			for n = 2, TD.MAX_PLAYERS do
				local function partyPlay(policy)
					return AutoBattle.play("ep1", "normal", policy, { party = n })
				end
				t.eq(partyPlay("re6").won, false, n .. " × 6 R/E without upgrades")
				t.truthy(partyPlay("re4up").won, n .. " × 4 R/E + upgrades")
				t.truthy(partyPlay("re6up").won, n .. " × 6 R/E + upgrades")
				t.truthy(partyPlay("re10up").won, n .. " × 10 R/E + upgrades")
			end
		end)
		t.it("A party of 4 keeps the tiers above: Hard needs more than 6 R/E, Nightmare needs the whale", function()
			local function p4(mode, diff, policy)
				return AutoBattle.play(mode, diff, policy, { party = 4, maxWaves = 120 })
			end
			t.eq(p4("ep1", "hard", "re6up").won, false)
			t.truthy(p4("ep1", "hard", "re10up").won)
			t.truthy(p4("ep1", "hard", "leg10up").won)
			t.eq(p4("ep1", "nightmare", "leg10up").won, false)
			t.truthy(p4("ep1", "nightmare", "whale").won)
			-- Three whales used to stun-lock endless wave 80 at the spawn forever (the match never ended).
			local r = p4("infinite", "hard", "whale")
			t.truthy(r.lost, "endless still ends for a party of whales")
		end)
		t.it("Endless becomes unwinnable between waves 60 and 100", function()
			local r = play("infinite", "normal", "myth12up")
			t.truthy(r.lost and r.wavesCleared >= 60 and r.wavesCleared < 100, "Mythic team died after wave " .. r.wavesCleared)
			local w = play("infinite", "normal", "whale")
			t.truthy(w.lost and w.wavesCleared < 110, "maxed team died after wave " .. w.wavesCleared)
		end)
	end)
end
