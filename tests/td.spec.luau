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
			buffCap = TD.BUFF_CAP,
			hasteFloor = TD.HASTE_FLOOR,
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

		t.it("Abu Samih's bounty pays for every death in his range, whoever lands the blow (S1-A07)", function()
			local function cashAfterKill(hx, hz)
				local s = sim(straight, function()
					return { spawns = { { at = 0, enemy = "gendarme", hpMul = 1, speedMul = 1 } }, count = 1 }
				end, 1)
				TdTowers.place(s, "p1", "qabaday", Units.qabaday, 20, 4, 0, nil, rules())
				if hx then
					t.truthy(TdTowers.place(s, "p1", "hummus", Units.hummus, hx, hz, 0, nil, rules()))
				end
				local before = s.players.p1.cash
				local ev = run(s, 20)
				local reward = 0
				for _, e in ev do
					if e.type == "death" then
						reward += e.cash
					end
				end
				return s.players.p1.cash - before - reward
			end
			local bounty = Units.hummus.levels[1].bounty
			local near = cashAfterKill(16, -5) -- the gendarme falls at about x = 15, inside his range
			local without = cashAfterKill(nil, nil)
			t.eq(near - without, bounty, "the bounty is the only difference (wave bonuses cancel out)")
		end)
		t.it("the new defenders' effects (S1-A07): nails slow, steam slows and douses, The Cry stuns", function()
			local isk = UnitLogic.stats(Units.iskafi, 1, 0, nil, 0)
			t.eq(isk.slow, 0.6)
			t.truthy(isk.splash and isk.splash >= 3)
			local steam = UnitLogic.stats(Units.hammam, 1, 0, nil, 0)
			t.eq(steam.douse, 1)
			t.eq(steam.slow, 0.8)
			t.eq(steam.cooldown, 3)
			local cry = UnitLogic.stats(Units.matriarch, 1, 0, nil, 0)
			t.eq(cry.ability.kind, "sweep")
			t.eq(cry.ability.stun, 1.2)
			t.eq(Units.matriarch.hitsStealth, true)
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

		t.it("a defender's own auto switch overrides its owner's setting; nil follows it (LP-B01)", function()
			local function abilities(events, towerId)
				local n = 0
				for _, e in events do
					if e.type == "attack" and e.ability and e.tower == towerId then
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
			local function case(playerAuto, towerAuto)
				local s = sim(straight, crowd, 1)
				s.players.p1.autoAbility = playerAuto
				local _, _, tw = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 4, 0, nil, rules())
				if towerAuto ~= nil then
					t.truthy(TdTowers.setAutoAbility(s, "p1", tw.id, towerAuto))
					t.eq(tw.autoAbility, towerAuto)
				end
				return abilities(run(s, 25), tw.id)
			end
			t.truthy(case(false, true) >= 1, "on overrides a player who turned auto off")
			t.eq(case(true, false), 0, "off overrides a player whose auto is on")
			t.eq(case(false, nil), 0, "nil follows the player's off")
			t.truthy(case(nil, nil) >= 1, "nil follows the player's default on")
			-- Off still lets a tap through.
			local s = sim(straight, crowd, 1)
			local _, _, tw = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 4, 0, nil, rules())
			TdTowers.setAutoAbility(s, "p1", tw.id, false)
			run(s, 3)
			t.truthy(TdTowers.useAbility(s, "p1", tw.id))
			t.eq(abilities(run(s, 2), tw.id), 1, "a tap still fires when its auto is off")
		end)

		t.it("setAutoAbility refuses foreign, ally, ability-less towers, non-booleans and a finished match", function()
			local s = sim(straight, oneThief, 1)
			local _, _, tw = TdTowers.place(s, "p1", "zaim", Units.zaim, 10, 4, 0, nil, rules())
			local _, _, plain = TdTowers.place(s, "p1", "walad", Units.walad, 30, 4, 0, nil, rules())
			local function err(owner, id, on)
				local ok, e = TdTowers.setAutoAbility(s, owner, id, on)
				t.eq(ok, false)
				return e
			end
			t.eq(err("p2", tw.id, true), "not_yours")
			t.eq(err("p1", 9999, true), "not_yours")
			t.eq(err("p1", "1", true), "not_yours")
			t.eq(err("p1", tw.id, "yes"), "bad_request")
			t.eq(err("p1", tw.id, 1), "bad_request")
			t.eq(err("p1", tw.id, nil), "bad_request")
			t.eq(err("p1", plain.id, true), "no_ability")
			local ally = TdTowers.addAlly(s, "zaim", Units.zaim, 1, 50, 4, rules())
			t.eq(err("p1", ally.id, true), "not_yours", "a story ally takes no orders")
			t.eq(tw.autoAbility, nil, "nothing changed")
			s.phase = "won"
			t.eq(err("p1", tw.id, true), "match_over")
		end)

		t.it("non-detecting towers ignore stealth enemies", function()
			local s = sim(straight, oneThief, 1)
			t.truthy(TdTowers.place(s, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules()))
			local ev = run(s, 20)
			t.eq(count(ev, "attack"), 0)
			t.eq(count(ev, "reached"), 1)
		end)

		t.it("a sabotaged Natour's lantern is dark until the sabotage wears off", function()
			local s = sim(straight, oneThief, 1)
			local _, _, tk = TdTowers.place(s, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules())
			local _, _, tn = TdTowers.place(s, "p1", "natour", Units.natour, 50, 14, 0, nil, rules())
			t.eq(TdSim.revealerFor(s, tk), tn, "lit")
			tn.disabledUntil = s.time + 5
			t.eq(TdSim.revealerFor(s, tk), nil, "dark while sabotaged")
			t.eq(TdSim.seesStealth(s, tk), false)
			s.time += 5
			t.eq(TdSim.revealerFor(s, tk), tn, "lit again once it is back")
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

		t.it("Umm Baki's lamp lights stealth for defenders in range, and she never slows (S1-A03)", function()
			local q = Units.qabilah
			t.eq(q.revealsStealth, true)
			t.eq(q.hitsStealth, true)
			t.eq(q.rarity, "rare")
			for _, l in q.levels do
				t.eq((l :: any).slow, nil, "no slow at any level")
			end
			local s = sim(straight, oneThief, 1)
			local _, _, tk = TdTowers.place(s, "p1", "khayyat", Units.khayyat, 50, 4, 0, nil, rules())
			local _, _, tq = TdTowers.place(s, "p1", "qabilah", q, 50, 12, 0, nil, rules())
			t.eq(TdSim.revealerFor(s, tk), tq)
			t.eq(TdSim.seesStealth(s, tk), true)
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

		-- LP-A02: supports stack additively up to TD.BUFF_CAP, hastes multiply down to TD.HASTE_FLOOR,
		-- a sabotaged support stops helping, and the per-tower cache follows every change.
		local function wall()
			return { spawns = { { at = 0, enemy = "colonel", hpMul = 1000, speedMul = 0.01 } }, count = 1 }
		end
		local function maxedAt(s, owner, id, x, z, path)
			local ok, err, tw = TdTowers.place(s, owner, id, Units[id], x, z, 0, nil, rules())
			t.truthy(ok, err)
			for _ = 2, #Units[id].levels do
				t.truthy(TdTowers.upgrade(s, owner, tw.id, Units[id], rules()))
			end
			if path then
				t.truthy(TdTowers.upgrade(s, owner, tw.id, Units[id], rules(), path))
			end
			return tw
		end
		local function near(a, b)
			return math.abs(a - b) < 1e-9
		end

		local function party(n)
			local keys = {}
			for i = 1, n do
				table.insert(keys, "p" .. i)
			end
			return TdSim.new(straight, keys, 1e7, 100, 1, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = Enemies,
				buffCap = TD.BUFF_CAP,
				hasteFloor = TD.HASTE_FLOOR,
			}, wall)
		end

		t.it("in the sim, two players' Abu Bader both count (capped); one player's two count once", function()
			local top = Units.mukhtar.levels[#Units.mukhtar.levels].buff
			local function dealt(owners)
				local s = party(2)
				t.truthy(TdTowers.place(s, "p1", "qabaday", Units.qabaday, 2, 4, 0, nil, rules()))
				local spots = { { 6, 6 }, { 2, 8 } }
				for i, owner in owners do
					maxedAt(s, owner, "mukhtar", spots[i][1], spots[i][2])
				end
				run(s, 10)
				return s.enemies[1].maxHp - s.enemies[1].hp
			end
			local base = dealt({})
			t.truthy(base > 0)
			t.truthy(near(dealt({ "p1" }) / base, top), "one: " .. dealt({ "p1" }) / base)
			t.truthy(near(dealt({ "p1", "p1" }) / base, top), "one player's second copy adds nothing")
			local want = math.min(1 + 2 * (top - 1), TD.BUFF_CAP)
			t.truthy(want > top, "the cap still leaves room to stack")
			t.truthy(near(dealt({ "p1", "p2" }) / base, want), "two players stack to " .. want .. ": " .. dealt({ "p1", "p2" }) / base)
		end)

		t.it("buffInfo adds different supports, caps the total and excludes the tower itself", function()
			local s = party(2)
			local fighter = select(3, TdTowers.place(s, "p1", "qabaday", Units.qabaday, 10, 5, 0, nil, rules()))
			-- Level 1 everywhere: the sums stay under the cap, so the addition shows exactly.
			local bader = select(3, TdTowers.place(s, "p1", "mukhtar", Units.mukhtar, 7, 5, 0, nil, rules()))
			local b1 = Units.mukhtar.levels[1].buff
			local h1 = Units.umm_hara.levels[1].buff
			local info = TdSim.buffInfo(s, fighter)
			t.eq(info.count, 1)
			t.truthy(near(info.mul, b1))
			t.eq(info.sources[1], bader.id)
			TdTowers.place(s, "p1", "umm_hara", Units.umm_hara, 10, 8, 0, nil, rules())
			info = TdSim.buffInfo(s, fighter)
			t.eq(info.count, 2, "Abu Hissam with Abu Bader")
			t.truthy(near(info.mul, 1 + (b1 - 1) + (h1 - 1)), "additive: " .. info.mul)
			-- The owner's case (2026-10-19): two Abu Hissam near a unit both count (one per player).
			TdTowers.place(s, "p2", "umm_hara", Units.umm_hara, 13, 5, 0, nil, rules())
			info = TdSim.buffInfo(s, fighter)
			t.eq(info.count, 3, "a second player's Abu Hissam counts too")
			t.truthy(near(info.mul, 1 + (b1 - 1) + 2 * (h1 - 1)))
			-- The same player's second Abu Bader counts once (the stronger copy).
			local second = select(3, TdTowers.place(s, "p1", "mukhtar", Units.mukhtar, 13, 8, 0, nil, rules()))
			TdTowers.upgrade(s, "p1", second.id, Units.mukhtar, rules())
			info = TdSim.buffInfo(s, fighter)
			t.eq(info.count, 3, "one player's copies of a unit count once")
			t.truthy(table.find(info.sources, second.id) ~= nil and table.find(info.sources, bader.id) == nil, "the stronger copy is the one counted")
			t.eq(TdSim.buffInfo(s, bader).count, 3, "a support is buffed by the others (its twin included), never by itself")
			-- Maxed, the stack hits the cap; one support alone is never cut by it.
			for _ = 3, #Units.mukhtar.levels do
				TdTowers.upgrade(s, "p1", second.id, Units.mukhtar, rules())
			end
			t.eq(TdSim.buffFor(s, fighter), TD.BUFF_CAP, "buffFor returns the capped total")
			t.truthy(TD.BUFF_CAP >= Units.mukhtar.signature.a.set.buff, "the cap never cuts Loud on its own")
			t.truthy(TD.BUFF_CAP >= Units.umm_hara.signature.b.set.buff, "nor Elder")
		end)

		t.it("Abu Hissam's buff applies on its own", function()
			local s = sim(straight, wall, 1, 1e7)
			local fighter = select(3, TdTowers.place(s, "p1", "qabaday", Units.qabaday, 10, 5, 0, nil, rules()))
			maxedAt(s, "p1", "umm_hara", 10, 8)
			t.truthy(near(TdSim.buffFor(s, fighter), Units.umm_hara.levels[#Units.umm_hara.levels].buff))
		end)

		t.it("a support out of range does not count", function()
			local s = sim(straight, wall, 1, 1e7)
			local fighter = select(3, TdTowers.place(s, "p1", "qabaday", Units.qabaday, 10, 5, 0, nil, rules()))
			local far = 10 + Units.mukhtar.levels[1].range + 1
			TdTowers.place(s, "p1", "mukhtar", Units.mukhtar, far, 5, 0, nil, rules())
			local info = TdSim.buffInfo(s, fighter)
			t.eq(info.count, 0)
			t.eq(info.mul, 1)
		end)

		t.it("a sabotaged support stops buffing and resumes when it is back", function()
			local s = sim(straight, wall, 1, 1e7)
			local fighter = select(3, TdTowers.place(s, "p1", "qabaday", Units.qabaday, 10, 5, 0, nil, rules()))
			local sup = maxedAt(s, "p1", "mukhtar", 7, 5)
			run(s, 1.5) -- past prep: the wave runs and towersAct fills the cache
			t.truthy(near(fighter.buffMul, 1.65), "cached buff")
			t.eq(fighter.buffCount, 1)
			-- What saboteursAct does on a hit
			sup.disabledUntil = s.time + 2
			s.buffsDirty = true
			t.eq(TdSim.buffInfo(s, fighter).count, 0, "silent while sabotaged")
			run(s, TD.TICK)
			t.eq(fighter.buffMul, 1, "the cache drops it at once")
			run(s, 2.1)
			t.truthy(near(fighter.buffMul, 1.65), "back mid-wave once the sabotage wears off")
		end)

		t.it("the buff cache follows place, upgrade and sell on the next step", function()
			local s = sim(straight, wall, 1, 1e7)
			local fighter = select(3, TdTowers.place(s, "p1", "qabaday", Units.qabaday, 10, 5, 0, nil, rules()))
			local ok, _, sup = TdTowers.place(s, "p1", "mukhtar", Units.mukhtar, 7, 5, 0, nil, rules())
			t.truthy(ok)
			run(s, 1.5)
			t.truthy(near(fighter.buffMul, Units.mukhtar.levels[1].buff))
			TdTowers.upgrade(s, "p1", sup.id, Units.mukhtar, rules())
			run(s, TD.TICK)
			t.truthy(near(fighter.buffMul, Units.mukhtar.levels[2].buff), "upgrade")
			local _, _, sup2 = TdTowers.place(s, "p1", "umm_hara", Units.umm_hara, 13, 5, 0, nil, rules())
			run(s, TD.TICK)
			t.eq(fighter.buffCount, 2, "place")
			TdTowers.sell(s, "p1", sup2.id, rules())
			run(s, TD.TICK)
			t.eq(fighter.buffCount, 1, "sell")
			t.truthy(near(fighter.buffMul, TdSim.buffFor(s, fighter)), "cache = fresh scan")
		end)

		t.it("hastes multiply and stop at the floor", function()
			local s = TdSim.new(straight, { "p1", "p2", "p3", "p4" }, 1e7, 100, 1, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = Enemies,
				buffCap = TD.BUFF_CAP,
				hasteFloor = TD.HASTE_FLOOR,
			}, wall)
			local w = select(3, TdTowers.place(s, "p1", "walad", Units.walad, 20, 8, 0, nil, rules()))
			local spots = { { 17, 8 }, { 23, 8 }, { 20, 11 }, { 20, 5 } }
			local mul = Units.zaim_akbar.signature.b.haste.mul
			for i, owner in { "p1", "p2", "p3", "p4" } do
				maxedAt(s, owner, "zaim_akbar", spots[i][1], spots[i][2], "b")
				local want = math.max(mul ^ i, TD.HASTE_FLOOR)
				t.truthy(near(TdSim.hasteFor(s, w), want), i .. " rallies: " .. TdSim.hasteFor(s, w))
			end
			t.eq(TdSim.hasteFor(s, w), TD.HASTE_FLOOR, "four rallies hit the floor")
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

	-- Boss behaviours, batch 1 (STORY_PLAN §10.1, S1-S05) on the real Config/Enemies: Abu Jawdan's
	-- summons, Lateef's telegraphed teleport, Abu Shatour's burning torch.
	t.describe("Boss behaviours (S1-S05)", function()
		local straight = { { 0, 0 }, { 400, 0 } }
		local function bossSim(list)
			return TdSim.new(straight, { "p1" }, 100000, 1000, 2, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = Enemies,
				maxSpeedMul = WaveLogic.MAX_SPEED_MUL,
				burnMax = TD.BURN_MAX_STACKS,
				burnTick = TD.BURN_TICK,
				burnDamage = TD.BURN_DAMAGE,
				burnFor = TD.BURN_SECONDS,
			}, function()
				local spawns = {}
				for _, id in list do
					table.insert(spawns, { at = 0, enemy = id, hpMul = 2, speedMul = 1 })
				end
				return { spawns = spawns, count = #spawns }
			end)
		end
		local function byId(state, enemyId)
			local out = {}
			for _, e in state.enemies do
				if e.enemyId == enemyId and e.alive then
					table.insert(out, e)
				end
			end
			return out
		end

		t.it("Abu Jawdan calls two corporals every 15 s at his spot, with the wave's HP, until he falls", function()
			local sm = Enemies.abu_jawdan.summon
			t.eq(sm.enemy, "corporal_minion")
			local s = bossSim({ "abu_jawdan" })
			run(s, 1.05)
			t.eq(#byId(s, "corporal_minion"), 0)
			local ev = run(s, sm.every)
			t.eq(count(ev, "summon"), 1)
			local escorts = byId(s, "corporal_minion")
			t.eq(#escorts, sm.count)
			local boss = byId(s, "abu_jawdan")[1]
			for _, c in escorts do
				t.truthy(c.dist <= boss.dist and c.dist >= boss.dist - sm.count, "steps out right behind him")
				t.eq(c.maxHp, Enemies.corporal_minion.hp * 2, "inherits the wave HP multiplier")
			end
			run(s, sm.every)
			t.eq(#byId(s, "corporal_minion"), 2 * sm.count, "again 15 s later")
			-- He falls: no more corporals, and the wave waits for the escorts still walking.
			boss.hp = 0
			boss.alive = false
			ev = run(s, sm.every * 2)
			t.eq(count(ev, "summon"), 0)
			t.eq(s.phase, "wave", "escorts count toward the wave")
		end)

		t.it("Lateef telegraphs once at half HP, jumps a fifth of the road 2 s later, never past the gate", function()
			local tp = Enemies.lateef.teleport
			local s = bossSim({ "lateef" })
			run(s, 1.05)
			local l = byId(s, "lateef")[1]
			local ev = run(s, 1)
			t.eq(count(ev, "telegraph"), 0, "not before half HP")
			l.hp = l.maxHp * tp.atHp * 0.98
			ev = run(s, TD.TICK)
			t.eq(count(ev, "telegraph"), 1)
			local tg
			for _, e in ev do
				if e.type == "telegraph" then
					tg = e
				end
			end
			t.truthy(math.abs(tg.to - (tg.from + tp.fraction * s.path.length)) < 1e-9, "a fifth of the road")
			local before = l.dist
			ev = run(s, tp.telegraph - TD.TICK * 2)
			t.eq(count(ev, "teleport"), 0, "the warning lasts the telegraph")
			ev = run(s, TD.TICK * 5) -- run() floors seconds/TICK, so cover the landing tick generously
			t.eq(count(ev, "teleport"), 1)
			t.truthy(l.dist >= tg.to and l.dist > before + 30, "landed ahead")
			l.hp = l.maxHp * 0.1
			ev = run(s, tp.telegraph * 2)
			t.eq(count(ev, "telegraph") + count(ev, "teleport"), 0, "only once")
			-- Close to the gate the jump stops a stud short of it.
			local g = bossSim({ "lateef" })
			run(g, 1.05)
			local lg = byId(g, "lateef")[1]
			lg.dist = g.path.length - 10
			lg.hp = lg.maxHp * 0.3
			ev = run(g, TD.TICK)
			for _, e in ev do
				if e.type == "telegraph" then
					t.eq(e.to, g.path.length - 1, "never past the gate")
				end
			end
		end)

		t.it("Abu Shatour's torch lays three burn stacks on the gate", function()
			t.eq(Enemies.abu_shatour.burn, 3)
			local s = bossSim({ "abu_shatour", "abu_shatour" }) -- the second keeps the wave going
			run(s, 1.05)
			local b = byId(s, "abu_shatour")[1]
			b.dist = s.path.length - 0.1
			run(s, TD.TICK * 2)
			t.eq(s.gateBurn.stacks, 3)
		end)
	end)

	-- Story mechanics, batch 2 (STORY_PLAN §10.1, S1-S06): sabotage, split, enrage, heal aura and the
	-- `mark` ability. Stand-in attackers until S1-S08 adds the real rifleman, cart, brute and hakim.
	t.describe("Story mechanics (S1-S06)", function()
		local straight = { { 0, 0 }, { 200, 0 } }
		local V = Enemies.gendarme.visual
		local E = setmetatable({
			rifle = { nameKey = "x", hp = 1e6, speed = 5, reward = 38, gateDamage = 2, sabotage = { range = 10, duration = 2.5, cooldown = 8 }, visual = V },
			cart = { nameKey = "x", hp = 3, speed = 3.4, reward = 60, gateDamage = 3, split = { enemy = "thug", count = 4 }, visual = V },
			brute = { nameKey = "x", hp = 380, speed = 4.2, reward = 65, gateDamage = 3, enrage = { belowHp = 0.5, speed = 1.6 }, visual = V },
			hakim = { nameKey = "x", hp = 200, speed = 4.6, reward = 50, gateDamage = 1, healAura = { radius = 8, pct = 0.02 }, visual = V },
			wall = { nameKey = "x", hp = 1e6, speed = 0.5, reward = 0, gateDamage = 0, visual = V },
		}, { __index = Enemies })
		local function simE(list, totalWaves)
			return TdSim.new(straight, { "p1" }, 100000, 100, totalWaves or 2, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = E,
				maxSpeedMul = WaveLogic.MAX_SPEED_MUL,
			}, function()
				local spawns = {}
				for _, sp in list do
					table.insert(spawns, { at = sp[2] or 0, enemy = sp[1], hpMul = sp[3] or 1, speedMul = sp[4] or 1 })
				end
				return { spawns = spawns, count = #spawns }
			end)
		end
		local function find(state, enemyId)
			for _, e in state.enemies do
				if e.enemyId == enemyId and e.alive then
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

		t.it("sabotage: the rifleman stops, the nearest defender goes quiet for 2.5 s, again after 8 s", function()
			local s = simE({ { "rifle" } })
			local _, _, w = TdTowers.place(s, "p1", "walad", Units.walad, 30, 4, 0, nil, rules())
			local _, _, far = TdTowers.place(s, "p1", "walad", Units.walad, 60, 4, 0, nil, rules())
			local ev = run(s, 1 + 4.5)
			local hitTower
			for _, e in ev do
				if e.type == "towerDisabled" then
					hitTower = e.tower
				end
			end
			t.eq(hitTower, w.id, "the nearest defender")
			t.eq(far.disabledUntil, nil, "one defender per shot")
			local r = find(s, "rifle")
			local d0 = r.dist
			ev = run(s, 2.0)
			t.eq(attacksBy(ev, w.id), 0, "disabled: no attacks")
			t.truthy(math.abs(r.dist - d0) < 1e-9, "the rifleman stands still while aiming")
			ev = run(s, 1.5)
			t.truthy(attacksBy(ev, w.id) > 0, "back after the duration")
			t.truthy(r.dist > d0, "and he walks on")
			ev = run(s, 6)
			t.eq(count(ev, "towerDisabled"), 1, "the next shot only after the cooldown")
		end)

		t.it("split: a cart releases 4 thugs where it dies, with its wave HP; its reward is paid once", function()
			local s = simE({ { "cart", 0, 2 } })
			local _, _, w = TdTowers.place(s, "p1", "walad", Units.walad, 12, 4, 0, nil, rules())
			local cash0 = s.players.p1.cash
			local ev = run(s, 4)
			local deaths, splits = 0, 0
			for _, e in ev do
				if e.type == "death" and e.tower == w.id then
					deaths += 1
				elseif e.type == "split" then
					splits += 1
				end
			end
			t.eq(splits, 1)
			local thugs = 0
			for _, e in s.enemies do
				if e.enemyId == "thug" then
					thugs += 1
					t.eq(e.maxHp, Enemies.thug.hp * 2, "inherits the wave HP")
				end
			end
			t.eq(thugs + math.max(0, deaths - 1), 4, "four passengers")
			t.truthy(s.players.p1.cash - cash0 >= E.cart.reward, "the cart's reward")
		end)

		t.it("enrage: below half HP the brute walks ×1.6, held at the speed cap", function()
			local s = simE({ { "brute" }, { "brute", 0, 1, 1.5 } })
			run(s, 1.05)
			local b1, b2
			for _, e in s.enemies do
				if e.speed == E.brute.speed then
					b1 = e
				else
					b2 = e
				end
			end
			local d0 = b1.dist
			run(s, 1)
			local calm = b1.dist - d0
			b1.hp = b1.maxHp * 0.4
			b2.hp = b2.maxHp * 0.4
			d0 = b1.dist
			local e0 = b2.dist
			run(s, 1)
			t.truthy(math.abs((b1.dist - d0) / calm - E.brute.enrage.speed) < 0.06, "×1.6 when wounded")
			t.truthy(b2.dist - e0 <= E.brute.speed * WaveLogic.MAX_SPEED_MUL + 0.01, "a fast brute stops at the cap")
		end)

		t.it("heal aura: others nearby regain 2 %/s of max HP, never past max, the hakim not himself", function()
			local s = simE({ { "hakim" }, { "gendarme" }, { "wall" } })
			run(s, 1.05)
			local h, g = find(s, "hakim"), find(s, "gendarme")
			g.hp = g.maxHp * 0.5
			h.hp = h.maxHp * 0.5
			run(s, 1)
			t.truthy(math.abs(g.hp - g.maxHp * 0.52) < g.maxHp * 0.002, "≈ +2 % in one second")
			t.eq(h.hp, h.maxHp * 0.5, "no self-heal")
			g.hp = g.maxHp - 0.01
			run(s, 1)
			t.eq(g.hp, g.maxHp, "capped at max")
		end)

		t.it("mark: the strongest in range takes ×1.4 from every defender for 4 s; marks don't stack", function()
			local marker = table.clone(Units.hallaq)
			marker.ability = { kind = "mark", cooldown = 10, multiplier = 1.4, duration = 4 }
			local s = simE({ { "wall" }, { "gendarme" } })
			run(s, 1.05)
			local wall = find(s, "wall")
			local _, _, m = TdTowers.place(s, "p1", "hallaq", marker, 2, 4, 0, nil, rules())
			local _, _, m2 = TdTowers.place(s, "p1", "hallaq", marker, 2, -4, 0, nil, rules())
			local ev = run(s, TD.TICK * 2)
			t.truthy(count(ev, "mark") >= 1)
			t.eq(wall.markMul, 1.4, "the strongest one, and two markers don't make it 1.96")
			t.truthy(wall.markedUntil > s.time and wall.markedUntil <= s.time + 4)
			-- A plain defender's hit on the marked enemy lands ×1.4.
			local _, _, w = TdTowers.place(s, "p1", "walad", Units.walad, 6, 4, 0, nil, rules())
			w.targeting = "strong"
			local before = wall.hp
			ev = run(s, TD.TICK)
			local hitsW = attacksBy(ev, w.id)
			local hitsM = attacksBy(ev, m.id) + attacksBy(ev, m2.id)
			t.eq(hitsW, 1)
			local expect = Units.walad.levels[1].damage * 1.4 + hitsM * Units.hallaq.levels[1].damage * 1.4
			t.truthy(math.abs((before - wall.hp) - expect) < 1e-6, "every defender's damage ×1.4")
			run(s, 4.2)
			t.truthy(s.time >= wall.markedUntil, "the mark wears off")
			before = wall.hp
			ev = run(s, TD.TICK)
			local plain = attacksBy(ev, w.id) * Units.walad.levels[1].damage + (attacksBy(ev, m.id) + attacksBy(ev, m2.id)) * Units.hallaq.levels[1].damage
			t.truthy(math.abs((before - wall.hp) - plain) < 1e-6, "back to plain damage")
		end)

		t.it("a sabotaged defender is back for the next wave", function()
			local s = simE({ { "rifle" } }, 3)
			local _, _, w = TdTowers.place(s, "p1", "walad", Units.walad, 30, 4, 0, nil, rules())
			run(s, 1 + 4.5)
			t.truthy(w.disabledUntil ~= nil)
			find(s, "rifle").alive = false
			run(s, TD.TICK * 2)
			t.eq(s.phase, "prep")
			t.eq(w.disabledUntil, nil)
		end)
	end)

	-- Level-7 signatures (STORY_PLAN §7.1, S1-S10): data, the D-047 cap, the upgrade rules and the
	-- new effects in the sim.
	t.describe("Signatures (S1-S10)", function()
		local Strings = t.config("Strings")
		local straight = { { 0, 0 }, { 200, 0 } }
		local function hasKey(key)
			for _, lang in Strings.languages do
				if Strings[lang][key] == nil then
					return false
				end
			end
			return true
		end
		-- Own damage per second (single target): attacks plus the ability's extra.
		local function dps(st)
			if st.damage <= 0 then
				return 0
			end
			local v = st.damage / st.cooldown
			local ab = st.ability
			if ab and ab.kind == "shabriyeh" then
				v += (ab.multiplier - 1) * st.damage / ab.cooldown
			elseif ab and ab.kind == "sweep" then
				v += ab.multiplier * st.damage / ab.cooldown
			end
			return v
		end
		-- Effects a path can change, grouped (a slow is its strength and length together).
		local EFFECTS = {
			stun = function(st)
				return st.stun
			end,
			slow = function(st)
				return tostring(st.slow) .. "/" .. tostring(st.slowFor)
			end,
			splash = function(st)
				return st.splash
			end,
			buff = function(st)
				return st.buff
			end,
			heal = function(st)
				return st.heal
			end,
			range = function(st)
				return st.range
			end,
			reveal = function(st)
				return st.revealsStealth
			end,
			haste = function(st)
				return st.haste and st.haste.mul
			end,
			abRadius = function(st)
				return st.ability and st.ability.radius
			end,
			abStun = function(st)
				return st.ability and st.ability.stun
			end,
			abSlow = function(st)
				return st.ability and (tostring(st.ability.slow) .. "/" .. tostring(st.ability.slowFor))
			end,
			abCount = function(st)
				return st.ability and st.ability.count
			end,
			douse = function(st)
				return st.douse
			end,
		}

		t.it("every Epic+ banner unit has paths a and b, priced ≈ 1.5 × its last level, with EN/AR names", function()
			local n = 0
			for id, u in Units do
				local epicPlus = u.rarity ~= "rare" and not u.noBanner
				if epicPlus then
					t.truthy(u.signature and u.signature.a and u.signature.b, id .. " has a signature")
				end
				if u.signature then
					n += 1
					local last = u.levels[#u.levels].cost
					for _, path in { "a", "b" } do
						local sig = u.signature[path]
						t.truthy(sig.cost >= last * 1.4 and sig.cost <= last * 1.6, id .. "." .. path .. " cost ≈ 1.5 × level " .. #u.levels)
						t.truthy(hasKey("unit." .. id .. ".sig." .. sig.key .. ".name") and hasKey("unit." .. id .. ".sig." .. sig.key .. ".desc"), id .. "." .. path .. " strings")
					end
					t.truthy(u.signature.a.key ~= u.signature.b.key, id .. " two different paths")
				end
			end
			t.eq(n, 11, "the ten Epic+ banner units (with Abu Basim and Su'da Khanum, S1-A07) and Al-Adashari")
		end)

		t.it("cap (D-047): a path adds ≤ +35 % damage per second or exactly one effect, never both", function()
			for id, u in Units do
				if u.signature then
					local top = #u.levels
					local s6 = UnitLogic.stats(u, top, 0, nil, 0)
					for _, path in { "a", "b" } do
						local s7 = UnitLogic.stats(u, top + 1, 0, nil, 0, nil, path)
						t.eq(s7.signature, path)
						local d6, d7 = dps(s6), dps(s7)
						local changed = 0
						for _, f in EFFECTS do
							if f(s6) ~= f(s7) then
								changed += 1
							end
						end
						local where = id .. "." .. path
						if d6 == 0 then
							-- A defender who never struck starts to: that is its one new effect.
							t.truthy(changed + (if d7 > 0 then 1 else 0) == 1, where .. " one effect")
						else
							t.truthy(d7 / d6 <= 1.35 + 1e-9, string.format("%s dps ×%.3f > 1.35", where, d7 / d6))
							t.truthy(changed <= 1, where .. " at most one effect, changed " .. changed)
							t.truthy(not (d7 > d6 + 1e-9 and changed > 0), where .. " damage and an effect together")
							t.truthy(d7 > d6 + 1e-9 or changed == 1, where .. " does something")
						end
					end
				end
			end
		end)

		t.it("upgrade rules: level 7 only from the last level, with a path, once; prices and miser apply", function()
			local s = sim(straight, function()
				return { spawns = {}, count = 0 }
			end, 1, 1e6)
			local _, _, q = TdTowers.place(s, "p1", "qabaday", Units.qabaday, 50, 4, 0, nil, rules())
			local ok, err = TdTowers.upgrade(s, "p1", q.id, Units.qabaday, rules(), "a")
			t.eq(err, "bad_path", "no path below the last level")
			for _ = 2, #Units.qabaday.levels do
				t.truthy(TdTowers.upgrade(s, "p1", q.id, Units.qabaday, rules()))
			end
			ok, err = TdTowers.upgrade(s, "p1", q.id, Units.qabaday, rules())
			t.eq(err, "bad_path", "the signature needs a path")
			ok, err = TdTowers.upgrade(s, "p1", q.id, Units.qabaday, rules(), "c")
			t.eq(err, "bad_path")
			local cash = s.players.p1.cash
			ok = TdTowers.upgrade(s, "p1", q.id, Units.qabaday, rules(), "a")
			t.truthy(ok)
			t.eq(cash - s.players.p1.cash, Units.qabaday.signature.a.cost)
			t.eq(q.level, 7)
			t.eq(q.path, "a")
			t.eq(q.stats.ability.cooldown, 8, "Rage")
			t.eq(Units.qabaday.ability.cooldown, 12, "the config itself is untouched")
			ok, err = TdTowers.upgrade(s, "p1", q.id, Units.qabaday, rules(), "b")
			t.eq(err, "max_level", "a second choice is refused")
			-- A Rare has no level 7.
			local _, _, w = TdTowers.place(s, "p1", "walad", Units.walad, 70, 4, 0, nil, rules())
			for _ = 2, #Units.walad.levels do
				TdTowers.upgrade(s, "p1", w.id, Units.walad, rules())
			end
			ok, err = TdTowers.upgrade(s, "p1", w.id, Units.walad, rules(), "a")
			t.eq(err, "max_level")
			-- Miser pays 10 % less for a signature too.
			local _, _, z = TdTowers.place(s, "p1", "zaim", Units.zaim, 90, 4, 0, Traits.traits.miser, rules())
			for _ = 2, #Units.zaim.levels do
				TdTowers.upgrade(s, "p1", z.id, Units.zaim, rules())
			end
			cash = s.players.p1.cash
			t.truthy(TdTowers.upgrade(s, "p1", z.id, Units.zaim, rules(), "b"))
			t.eq(cash - s.players.p1.cash, UnitLogic.costFor(Units.zaim.signature.b.cost, Traits.traits.miser))
		end)

		t.it("both paths of every signature unit change exactly what their config says", function()
			for id, u in Units do
				if u.signature then
					local top = #u.levels
					local s6 = UnitLogic.stats(u, top, 0, nil, 0)
					for _, path in { "a", "b" } do
						local sig = u.signature[path]
						local s7 = UnitLogic.stats(u, top + 1, 0, nil, 0, nil, path)
						for k, v in sig.set or {} do
							t.eq(s7[k], v, id .. "." .. path .. " sets " .. k)
						end
						for k, v in sig.ability or {} do
							t.eq(s7.ability[k], v, id .. "." .. path .. " ability " .. k)
						end
						if sig.cooldownMul then
							t.truthy(math.abs(s7.cooldown - s6.cooldown * sig.cooldownMul) < 1e-9, id .. "." .. path .. " cooldown")
						end
						if sig.revealsStealth then
							t.eq(s7.revealsStealth, true)
						end
						if sig.haste then
							t.eq(s7.haste, sig.haste)
						end
						t.eq(s7.range, s6.range, id .. "." .. path .. " keeps its range")
					end
				end
			end
		end)

		t.it("in the sim: Mercy slows with the shabriyeh, Pin stuns with the sweep, Rally hastes, Brave strikes", function()
			local function oneWall()
				return function()
					return { spawns = { { at = 0, enemy = "colonel", hpMul = 100, speedMul = 1 } }, count = 1 }
				end
			end
			local function maxed(s, id, x, z, path)
				local _, _, tw = TdTowers.place(s, "p1", id, Units[id], x, z, 0, nil, rules())
				for _ = 2, #Units[id].levels do
					TdTowers.upgrade(s, "p1", tw.id, Units[id], rules())
				end
				if path then
					TdTowers.upgrade(s, "p1", tw.id, Units[id], rules(), path)
				end
				return tw
			end
			-- Mercy: the first attack is the shabriyeh (ready at once) and it slows to 0.5.
			local s = sim(straight, oneWall(), 1)
			run(s, 1.05)
			local boss = s.enemies[1]
			maxed(s, "zaim", 3, 4, "b")
			run(s, TD.TICK * 2)
			t.eq(boss.slowMul, 0.5)
			t.truthy(boss.slowUntil > s.time + 2.5)
			-- Pin: the sweep stuns.
			local s2 = sim(straight, oneWall(), 1)
			run(s2, 1.05)
			local b2 = s2.enemies[1]
			maxed(s2, "pahlawan", 3, 4, "b")
			run(s2, TD.TICK * 2)
			t.truthy(b2.stunUntil >= s2.time + 1.4, "stunned ~1.5 s by the sweep")
			-- Rally: a defender near the 'akeed attacks 10 % faster.
			local s3 = sim(straight, oneWall(), 1)
			local w = maxed(s3, "walad", 20, 4)
			local akeed = maxed(s3, "zaim_akbar", 24, 4, "b")
			t.eq(TdSim.hasteFor(s3, w), 0.9)
			t.eq(TdSim.hasteFor(s3, akeed), 1, "not itself")
			-- Brave: the mukhtar finally attacks.
			local s4 = sim(straight, oneWall(), 1)
			run(s4, 1.05)
			local m = maxed(s4, "mukhtar", 3, 4, "b")
			local ev = run(s4, 3)
			local n = 0
			for _, e in ev do
				if e.type == "attack" and e.tower == m.id then
					n += 1
				end
			end
			t.truthy(n >= 2, "Brave attacks")
		end)
	end)

	-- Twin gates and the ally (STORY_PLAN §10.1, S1-S07): two roads that merge before the gate, and a
	-- story defender that belongs to nobody.
	t.describe("Two roads and the ally (S1-S07)", function()
		t.it("an episode may send every boss down one road (Waves bossRoad, S1-M05)", function()
			local ep = { waves = 10, hpPerWave = 0.1, pool = { { enemy = "gendarme", from = 1, base = 2, perWave = 0, gap = 1 } }, bosses = { [5] = "sergeant" }, bossRoad = 2 }
			local w = WaveLogic.story(ep, 5, TD.DIFFICULTIES.normal)
			local last = w.spawns[#w.spawns]
			t.eq(last.boss, true)
			t.eq(last.path, 2)
			t.eq(w.spawns[1].path, nil, "regular spawns still alternate")
			ep.bossRoad = nil
			local w2 = WaveLogic.story(ep, 5, TD.DIFFICULTIES.normal)
			t.eq(w2.spawns[#w2.spawns].path, nil)
		end)
		local A = { { 0, 40 }, { 50, 0 }, { 120, 0 } }
		local B = { { 0, -40 }, { 50, 0 }, { 120, 0 } }
		local function twin(list, totalWaves)
			return TdSim.new({ A, B }, { "p1" }, 100000, 100, totalWaves or 2, 1, {
				between = 2,
				waveBonusBase = TD.WAVE_BONUS_BASE,
				waveBonusPerWave = TD.WAVE_BONUS_PER_WAVE,
				rewardMul = 1,
				enemies = Enemies,
			}, function()
				local spawns = {}
				for i, id in list do
					table.insert(spawns, { at = (i - 1) * 0.2, enemy = id, hpMul = 1, speedMul = 1 })
				end
				return { spawns = spawns, count = #spawns }
			end)
		end

		t.it("merge geometry: both roads meet at their first shared point and end at the same gate", function()
			local paths = Path.buildAll({ path = A, paths = { A, B } })
			t.eq(#paths, 2)
			local da, db = Path.merge(paths[1], paths[2])
			t.truthy(math.abs(da - math.sqrt(50 * 50 + 40 * 40)) < 1e-9)
			t.eq(da, db, "symmetric roads merge at the same distance")
			t.eq(Path.merge(Path.build({ { 0, 0 }, { 10, 0 } }), Path.build({ { 0, 5 }, { 10, 5 } })), nil, "parallel roads never merge")
			t.eq(#Path.buildAll({ path = A }), 1, "a one-road arena")
			local ax, az = Path.position(paths[1], paths[1].length)
			local bx, bz = Path.position(paths[2], paths[2].length)
			t.eq(ax, bx)
			t.eq(az, bz)
		end)

		t.it("placement keeps clear of either road", function()
			local s = twin({})
			local ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 25, 22, 0, nil, rules())
			t.eq(err, "on_path", "next to road A")
			ok, err = TdTowers.place(s, "p1", "walad", Units.walad, 25, -22, 0, nil, rules())
			t.eq(err, "on_path", "next to road B")
			ok = TdTowers.place(s, "p1", "walad", Units.walad, 25, 0, 0, nil, rules())
			t.truthy(ok, "between the roads is fine")
			t.truthy(TdSim.distanceToRoads(s, 25, -22) < TD.PATH_HALF_WIDTH)
		end)

		t.it("spawns alternate between the roads; escorts keep their boss's road; both roads reach the gate", function()
			local s = twin({ "gendarme", "gendarme", "gendarme", "abu_jawdan" })
			local ev = run(s, 1.7)
			local roads = {}
			for _, e in s.enemies do
				roads[e.id] = e.pathIndex
			end
			local seq = {}
			for _, e in ev do
				if e.type == "spawn" then
					table.insert(seq, roads[e.id])
				end
			end
			t.eq(table.concat(seq, ","), "1,2,1,2")
			local _, z1 = TdSim.enemyPosition(s, s.enemies[1])
			local _, z2 = TdSim.enemyPosition(s, s.enemies[2])
			t.truthy(z1 > 30 and z2 < -30, "each on its own road")
			local boss = s.enemies[4]
			run(s, Enemies.abu_jawdan.summon.every)
			for _, e in s.enemies do
				if e.enemyId == "corporal_minion" then
					t.eq(e.pathIndex, boss.pathIndex, "escort on the boss's road")
				end
			end
			ev = run(s, 40)
			local reached = 0
			for _, e in ev do
				if e.type == "reached" then
					reached += 1
				end
			end
			t.truthy(reached >= 3, "gendarmes from both roads reach the gate")
		end)

		t.it("the ally: nobody can sell, upgrade, retarget or trigger it; its shield absorbs exactly its amount", function()
			local s = twin({ "gendarme", "gendarme", "gendarme" }, 1)
			local ally = TdTowers.addAlly(s, "walad", Units.walad, 3, 200, 200, rules(), 2)
			t.eq(ally.ally, true)
			t.eq(ally.level, 3)
			t.eq(s.allyShield, 2)
			for _, who in { "p1", TdTowers.ALLY_OWNER } do
				t.eq(select(2, TdTowers.sell(s, who, ally.id, rules())), "not_yours", who .. " cannot sell it")
				t.eq(select(2, TdTowers.upgrade(s, who, ally.id, Units.walad, rules())), "not_yours", who .. " cannot upgrade it")
				t.eq(select(2, TdTowers.setTargeting(s, who, ally.id, "last")), "not_yours")
				t.eq(select(2, TdTowers.useAbility(s, who, ally.id)), "not_yours")
			end
			run(s, 30)
			t.eq(s.gateHp, 100 - (3 * Enemies.gendarme.gateDamage - 2), "two points absorbed, the rest on the gate")
			t.eq(s.allyShield, 0)
			t.eq(s.players.p1.cash, 100000 + TD.WAVE_BONUS_BASE + TD.WAVE_BONUS_PER_WAVE, "the ally pays nobody")
		end)

		t.it("a wave script puts the ally at the arena's spot on its wave, once", function()
			local script = { [2] = { kind = "ally", unit = "walad", level = 3, shield = 20 } }
			local s = twin({})
			t.eq(TdTowers.runScript(s, script, 1, Units, rules(), { 10, 10 }), nil, "not on wave 1")
			local ally = TdTowers.runScript(s, script, 2, Units, rules(), { 10, 10 })
			t.truthy(ally and ally.ally)
			t.eq(ally.x, 10)
			t.eq(s.allyShield, 20)
			t.eq(TdTowers.runScript(s, script, 2, Units, rules(), nil), nil, "no spot, no ally")
			t.eq(TdTowers.runScript(s, { [3] = { kind = "ally", unit = "nobody" } }, 3, Units, rules(), { 0, 0 }), nil, "unknown unit")
		end)
	end)

	-- Shabriyeh beads (STORY_PLAN §7.4, S1-S11): kinds per unit, the +12 % cap (D-050), threading a
	-- bead, and the drops (first clears, Hard+ wins of Episodes 7–9 within a daily cap).
	t.describe("Beads (S1-S11)", function()
		local Beads = t.config("Beads")
		local Grants = t.logic("Grants")
		local ProfileSchema = t.logic("ProfileSchema")

		t.it("every unit takes three known bead kinds", function()
			for id, u in Units do
				local kinds = UnitLogic.beadKinds(u, Beads)
				t.eq(#kinds, Beads.slots, id .. " has three kinds")
				for _, k in kinds do
					t.truthy(Beads.kinds[k], id .. " kind " .. k)
				end
			end
		end)

		t.it("cap: whatever three beads a unit wears, no stat gains more than +12 %", function()
			local cap = Beads.cap
			for id, u in Units do
				local kinds = UnitLogic.beadKinds(u, Beads)
				for lvl = 1, #u.levels do
					local base = UnitLogic.stats(u, lvl, 0, nil, 0)
					t.eq(UnitLogic.beadBonus({ "", "", "" }, Beads), nil, "empty slots: no bonus")
					for _, a in kinds do
						for _, b in kinds do
							for _, c in kinds do
								local st = UnitLogic.stats(u, lvl, 0, nil, 0, nil, nil, UnitLogic.beadBonus({ a, b, c }, Beads))
								local where = id .. " L" .. lvl .. " " .. a .. "+" .. b .. "+" .. c
								t.truthy(st.range <= base.range * (1 + cap) + 1e-9, where .. " range")
								t.truthy(st.cooldown >= base.cooldown * (1 - cap) - 1e-9, where .. " cooldown")
								t.truthy(st.cash <= base.cash * (1 + cap) + 1e-9, where .. " cash")
								if base.heal then
									t.truthy(st.heal <= base.heal * (1 + cap) + 1e-9, where .. " heal")
								end
								if base.buff then
									t.truthy(st.buff <= base.buff * (1 + cap) + 1e-9, where .. " buff")
								end
								t.eq(st.damage, base.damage, where .. " beads never add damage")
							end
						end
					end
				end
			end
			-- And they do something below the cap: one range bead on the Lane Boy is +1 stud.
			local one = UnitLogic.stats(Units.walad, 1, 0, nil, 0, nil, nil, UnitLogic.beadBonus({ "range", "", "" }, Beads))
			t.eq(one.range, Units.walad.levels[1].range + 1)
			local cd = UnitLogic.stats(Units.walad, 1, 0, nil, 0, nil, nil, UnitLogic.beadBonus({ "cooldown", "cooldown", "" }, Beads))
			t.truthy(math.abs(cd.cooldown - Units.walad.levels[1].cooldown * 0.96 * 0.96) < 1e-9)
		end)

		t.it("threading a bead: owned unit, slot 1–3, a kind it takes, one bead spent, no double charge", function()
			local p = { units = { walad = { copies = 0, trait = "steady", at = 0 } }, beads = 2 }
			t.eq(select(2, UnitLogic.setBead(p, "zaim", Units.zaim, 1, "range", Beads)), "not_owned")
			t.eq(select(2, UnitLogic.setBead(p, "walad", Units.walad, 4, "range", Beads)), "bad_request", "slot 4")
			t.eq(select(2, UnitLogic.setBead(p, "walad", Units.walad, 1.5, "range", Beads)), "bad_request")
			t.eq(select(2, UnitLogic.setBead(p, "walad", Units.walad, 1, "heal", Beads)), "bad_request", "a healer's bead on the boy")
			t.truthy(UnitLogic.setBead(p, "walad", Units.walad, 2, "range", Beads))
			t.eq(p.beads, 1)
			t.eq(table.concat(p.units.walad.beads, ","), ",range,")
			t.eq(select(2, UnitLogic.setBead(p, "walad", Units.walad, 2, "range", Beads)), "same_bead")
			t.eq(p.beads, 1, "no charge for the same bead")
			t.truthy(UnitLogic.setBead(p, "walad", Units.walad, 2, "cash", Beads))
			t.eq(p.beads, 0)
			t.eq(select(2, UnitLogic.setBead(p, "walad", Units.walad, 3, "cash", Beads)), "no_beads")
		end)

		t.it("drops: first Hard clears of Episodes 5 and 7, then one per Hard+ win of Episodes 7–9, 3 a day", function()
			local function prof()
				return { td = { cleared = {}, beadDay = 0, beadDayCount = 0 }, beads = 0 }
			end
			local ep5 = { kind = "story", episode = "ep5" }
			local ep7 = { kind = "story", episode = "ep7" }
			local ep1 = { kind = "story", episode = "ep1" }
			local win = { won = true, wavesCleared = 45, totalWaves = 45 }
			local p = prof()
			t.eq(MatchRewards.beads(p, "ep5", ep5, "normal", win, Beads, TD, 100), 0, "Normal: nothing")
			p.td.cleared.ep5 = "normal"
			t.eq(MatchRewards.beads(p, "ep5", ep5, "hard", win, Beads, TD, 100), 1, "first Hard clear of ep5")
			p.td.cleared.ep5 = "hard"
			t.eq(MatchRewards.beads(p, "ep5", ep5, "hard", win, Beads, TD, 100), 0, "only once (ep5 drops nothing per win)")
			local q = prof()
			t.eq(MatchRewards.beads(q, "ep7", ep7, "nightmare", win, Beads, TD, 100), 3, "a first Nightmare clear counts as the first Hard one: 2 + the win's 1")
			q.td.cleared.ep7 = "nightmare"
			t.eq(MatchRewards.beads(q, "ep7", ep7, "hard", win, Beads, TD, 100), 1)
			t.eq(MatchRewards.beads(q, "ep7", ep7, "hard", win, Beads, TD, 100), 1)
			t.eq(MatchRewards.beads(q, "ep7", ep7, "hard", win, Beads, TD, 100), 0, "3 a day")
			t.eq(MatchRewards.beads(q, "ep7", ep7, "hard", win, Beads, TD, 101), 1, "next day")
			t.eq(MatchRewards.beads(q, "ep7", ep7, "hard", { won = false, wavesCleared = 9, totalWaves = 50 }, Beads, TD, 101), 0, "a loss")
			t.eq(MatchRewards.beads(q, "ep1", ep1, "nightmare", win, Beads, TD, 101), 0, "Episode 1 drops none")
			-- Granted through Grants (capped at Beads.maxBeads), in the reward's own mutation.
			local r = { beads = Beads.maxBeads - 1, pass = { xp = 0 } }
			local g = Grants.apply(r, { beads = 5 }, { maxQirsh = 1, maxLira = 1, maxStones = 1, items = {}, units = {}, traits = Traits, rng = math.random, now = 0, maxBeads = Beads.maxBeads })
			t.eq(r.beads, Beads.maxBeads)
			t.eq(g.beads, 1)
			local r2 = { beads = 0, pass = { xp = 0 } }
			Grants.apply(r2, { beads = 2 }, { maxQirsh = 1, maxLira = 1, maxStones = 1, items = {}, units = {}, traits = Traits, rng = math.random, now = 0 })
			t.eq(r2.beads, 0, "no maxBeads in the context: no beads granted")
		end)

		t.it("the profile keeps clean bead slots and a clamped bead count", function()
			local ctx = {
				schemaVersion = 2,
				maxQirsh = 1e6,
				maxLira = 1e7,
				maxStones = 1e5,
				receiptHistory = 100,
				items = {},
				units = Units,
				traits = Traits.traits,
				starterUnit = TD.STARTER_UNIT,
				season = "s1",
				beads = Beads,
			}
			local p = ProfileSchema.default(0, 2, ctx)
			p.beads = 5000
			p.units.walad.beads = { "range", "heal", 7, "x" }
			p.units.zaim = { copies = 0, trait = "steady", at = 0, beads = "junk" }
			ProfileSchema.sanitize(p, ctx, 0)
			t.eq(p.beads, Beads.maxBeads)
			t.eq(#p.units.walad.beads, 3)
			t.eq(table.concat(p.units.walad.beads, ","), "range,,", "unknown kinds and the 4th slot dropped")
			t.eq(p.units.zaim.beads, nil)
			t.eq(p.td.beadDayCount, 0)
		end)
	end)

	-- Al-Adashari, the secret unit (STORY_PLAN §7.6, owner's drop rule D-048, S1-S12).
	t.describe("Al-Adashari (S1-S12)", function()
		local drop = TD.SECRET_DROP
		local ep9 = { kind = "story", episode = "ep9" }
		local win = { won = true, wavesCleared = 60, totalWaves = 60 }
		local function prof(cleared)
			return { td = { cleared = cleared or {}, secretPity = 0 } }
		end

		t.it("is a secret, never from a banner, one per player, with the capped Oath", function()
			local u = Units.adashari
			t.eq(u.rarity, "secret")
			t.eq(u.noBanner, true)
			t.eq(u.maxPlaced, 1)
			t.eq(u.hitsStealth, true)
			t.eq(u.ability.kind, "mark")
			t.truthy(u.ability.multiplier <= 1.4)
			t.eq(drop.unit, "adashari")
			t.eq(drop.chance.normal, 0.01)
			t.eq(drop.chance.hard, 0.025)
			t.eq(drop.chance.nightmare, 0.06)
			t.eq(drop.pity, 40)
		end)

		t.it("the roll: 1 / 2.5 / 6 %, only Episode 9 wins, pity 40, the first Nightmare clear guarantees", function()
			local function always(v)
				return function()
					return v
				end
			end
			-- The chance, exactly at the edge.
			for d, c in drop.chance do
				local cleared = if d == "nightmare" then { ep9 = "nightmare" } else {}
				t.eq(MatchRewards.secretDrop(prof(cleared), "ep9", ep9, d, win, drop, TD, always(c - 1e-6)), "adashari", d .. " just under the chance")
				t.eq(MatchRewards.secretDrop(prof(cleared), "ep9", ep9, d, win, drop, TD, always(c + 1e-6)), nil, d .. " just over")
			end
			-- Never on a loss or another episode.
			t.eq(MatchRewards.secretDrop(prof(), "ep9", ep9, "hard", { won = false, wavesCleared = 50, totalWaves = 60 }, drop, TD, always(0)), nil)
			t.eq(MatchRewards.secretDrop(prof(), "ep8", { kind = "story", episode = "ep8" }, "hard", win, drop, TD, always(0)), nil)
			-- Pity: an unlucky player gets him on the 40th win at the latest, and the counter resets.
			local p = prof()
			local got
			for i = 1, drop.pity do
				got = MatchRewards.secretDrop(p, "ep9", ep9, "normal", win, drop, TD, always(0.999))
				if i < drop.pity then
					t.eq(got, nil, "win " .. i)
					t.eq(p.td.secretPity, i)
				end
			end
			t.eq(got, "adashari", "the 40th win")
			t.eq(p.td.secretPity, 0)
			-- The first Nightmare clear guarantees him; later Nightmare wins roll normally.
			t.eq(MatchRewards.secretDrop(prof({ ep9 = "hard" }), "ep9", ep9, "nightmare", win, drop, TD, always(0.999)), "adashari")
			t.eq(MatchRewards.secretDrop(prof({ ep9 = "nightmare" }), "ep9", ep9, "nightmare", win, drop, TD, always(0.999)), nil)
			-- The long-run rate on Hard (pity aside) is the configured 2.5 %.
			local n, hits = 20000, 0
			local seed = 7
			local function rng()
				seed = (seed * 1103515245 + 12345) % 2147483648
				return seed / 2147483648
			end
			for _ = 1, n do
				local q = prof()
				if MatchRewards.secretDrop(q, "ep9", ep9, "hard", win, drop, TD, rng) then
					hits += 1
				end
			end
			local rate = hits / n
			t.truthy(math.abs(rate - 0.025) < 0.005, "hard rate " .. rate)
		end)

		t.it("the Oath marks the strongest; Repentance marks two; the Warehouse douses two stacks", function()
			local straight = { { 0, 0 }, { 200, 0 } }
			local function twoBosses()
				return { spawns = { { at = 0, enemy = "colonel", hpMul = 10, speedMul = 1 }, { at = 0, enemy = "sergeant", hpMul = 10, speedMul = 1 } }, count = 2 }
			end
			local function maxed(s, path)
				local _, _, tw = TdTowers.place(s, "p1", "adashari", Units.adashari, 2, 4, 0, nil, rules())
				for _ = 2, #Units.adashari.levels do
					TdTowers.upgrade(s, "p1", tw.id, Units.adashari, rules())
				end
				if path then
					TdTowers.upgrade(s, "p1", tw.id, Units.adashari, rules(), path)
				end
				return tw
			end
			local s = sim(straight, twoBosses, 1)
			run(s, 1.05)
			maxed(s, nil)
			local ev = run(s, TD.TICK * 2)
			t.eq(count(ev, "mark"), 1, "one mark")
			local strongest = if s.enemies[1].hp > s.enemies[2].hp then s.enemies[1] else s.enemies[2]
			t.eq(strongest.markMul, 1.4)
			local s2 = sim(straight, twoBosses, 1)
			run(s2, 1.05)
			local r = maxed(s2, "a")
			t.eq(r.stats.ability.count, 2)
			ev = run(s2, TD.TICK * 2)
			t.eq(count(ev, "mark"), 2, "Repentance marks two")
			t.truthy(s2.enemies[1].markMul == 1.4 and s2.enemies[2].markMul == 1.4)
			local s3 = sim(straight, twoBosses, 1)
			local w = maxed(s3, "b")
			t.eq(w.stats.douse, 2, "Guard of the Warehouse")
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
		t.it("cash curve: what each wave added, never negative (LP-C06)", function()
			local curve = MatchRewards.cashCurve({ 800, 1100, 1100, 1700 }, 600)
			t.eq(table.concat(curve, ","), "200,300,0,600")
			t.eq(#MatchRewards.cashCurve({}, 600), 0)
			t.eq(MatchRewards.cashCurve({ 500 }, 600)[1], 0, "a dip below the start counts as zero")
		end)
		t.it("sparkline points fit the box, the top value at y = 0", function()
			local pts = MatchRewards.sparkline({ 200, 300, 0, 600 }, 120, 30)
			t.eq(#pts, 4)
			t.eq(pts[1][1], 0)
			t.eq(pts[4][1], 120)
			t.eq(pts[4][2], 0, "the highest value at the top")
			t.eq(pts[3][2], 30, "zero at the bottom")
			for _, p in pts do
				t.truthy(p[1] >= 0 and p[1] <= 120 and p[2] >= 0 and p[2] <= 30)
			end
			t.eq(#MatchRewards.sparkline({}, 120, 30), 0)
			local one = MatchRewards.sparkline({ 5 }, 120, 30)
			t.eq(#one, 2, "one wave draws a flat line")
			t.eq(one[2][1], 120)
			local flat = MatchRewards.sparkline({ 0, 0 }, 120, 30)
			t.eq(flat[1][2], 30)
		end)
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
		t.it("the first Normal clear of Episode 6 gives Umm Baki, once (S1-A03)", function()
			local p = profile()
			local won = { won = true, wavesCleared = 50, totalWaves = 50 }
			local r = MatchRewards.compute("ep6", Modes.ep6, "normal", won, p, false, TD, never)
			t.eq(r.unit, "qabilah")
			MatchRewards.record(p, "ep6", Modes.ep6, "normal", won, 0, TD)
			t.eq(MatchRewards.compute("ep6", Modes.ep6, "normal", won, p, false, TD, never).unit, nil, "only once")
			local lost = { won = false, wavesCleared = 40, totalWaves = 50 }
			t.eq(MatchRewards.compute("ep6", Modes.ep6, "normal", lost, profile(), false, TD, never).unit, nil, "never on a loss")
			t.eq(MatchRewards.compute("ep5", Modes.ep5, "normal", won, profile(), false, TD, never).unit, nil)
			t.truthy(Units[TD.STORY_FIRST_CLEAR.ep6.normal.unit], "the gift is a real unit")
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
			-- Abu Hares's lantern covers the road: revealed, and then everyone can hit it.
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

		-- Season Story 1 continues the ladder (STORY_PLAN §5.3, S1-S04; TOWER_DEFENSE §5 has the table).
		t.it("Episodes 4–6 Normal: never won by the tier below the target (S1-S04)", function()
			t.eq(play("ep4", "normal", "re10up").won, false, "ep4: 10 upgraded Rare/Epic fall to Abu Jawdan")
			t.truthy(play("ep4", "normal", "leg10up").won, "ep4: Legendaries win")
			t.eq(play("ep5", "normal", "re10up").won, false, "ep5: Rare/Epic fall")
			t.truthy(play("ep5", "normal", "leg10up").won, "ep5: Legendaries with Fawza win")
			t.eq(play("ep6", "normal", "leg10up").won, false, "ep6: Legendaries without signatures fall to Lateef")
			t.truthy(play("ep6", "normal", "leg10up+sig").won, "ep6: level-7 signatures win")
		end)
		t.it("Episode 6 asks for its answer: two lanterns (S1-S04)", function()
			t.eq(AutoBattle.play("ep6", "normal", "leg10up+sig", { raw = true }).won, false, "ep6 without lanterns")
			t.eq(AutoBattle.adapt(AutoBattle.POLICIES.leg10up, nil), AutoBattle.POLICIES.leg10up, "stock modes untouched")
		end)
		t.it("Episodes 4–6 Hard and Nightmare climb one step at a time (S1-S04)", function()
			t.truthy(play("ep4", "hard", "leg10up").won, "ep4 Hard: Legendaries")
			t.eq(play("ep4", "nightmare", "myth12up+beads").won, false, "ep4 Nightmare is past beads")
			t.truthy(play("ep4", "nightmare", "whale").won, "ep4 Nightmare: the whale")
			t.eq(play("ep5", "hard", "re10up").won, false, "ep5 Hard: not Rare/Epic")
			t.truthy(play("ep5", "nightmare", "whale").won, "ep5 Nightmare: the whale")
			t.eq(play("ep6", "hard", "leg10up+sig").won, false, "ep6 Hard: past Legendaries")
			t.truthy(play("ep6", "hard", "myth12up+beads").won, "ep6 Hard: Mythics with beads")
			t.eq(play("ep6", "nightmare", "whale").won, false, "ep6 Nightmare: past the whale")
			t.truthy(play("ep6", "nightmare", "whale2").won, "ep6 Nightmare: whale2")
		end)
		-- Episodes 7–9 meet every cell of the STORY_PLAN §5.3 ladder (S1-S09, D-066).
		t.it("Episodes 7–9 climb the ladder: each cell won by its target and by no tier below it (S1-S09)", function()
			local TARGET = {
				ep7 = { normal = "myth12up", hard = "myth12up+beads", nightmare = "whale2" },
				ep8 = { normal = "myth12up+beads", hard = "whale2", nightmare = "whale2" },
				ep9 = { normal = "myth12up+beads", hard = "whale2", nightmare = "whale2" },
			}
			local order = AutoBattle.POLICY_ORDER
			for ep, cells in TARGET do
				for diff, target in cells do
					t.truthy(play(ep, diff, target).won, ep .. " " .. diff .. ": won by " .. target)
					for i = table.find(order, "leg10up") :: number, (table.find(order, target) :: number) - 1 do
						t.eq(play(ep, diff, order[i]).won, false, ep .. " " .. diff .. ": not won by " .. order[i])
					end
				end
			end
		end)
		t.it("Episodes 8 and 9 walk both roads and bring the ally (S1-S09)", function()
			for _, id in { "ep8", "ep9" } do
				t.eq(Modes[id].arena, "twin_gates")
				t.eq(Modes[id].twinRoads, true)
			end
			local turn = Waves.episodes.ep8.script[41]
			t.eq(turn.kind, "ally")
			t.eq(turn.unit, "adashari")
			t.eq(Waves.episodes.ep8.bosses[40], "chief_thief", "he comes as the thief on wave 40, then turns")
			local guard = Waves.episodes.ep9.script[1]
			t.eq(guard.unit, "adashari")
			t.eq(guard.shield, 20, "he takes the first 20 gate damage")
			t.eq(Modes.ep7.twinRoads, nil, "Episode 7 has one road")
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
