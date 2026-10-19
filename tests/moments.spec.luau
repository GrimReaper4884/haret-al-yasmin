--!nocheck
-- Match presentation moments (Logic/MatchMoments, POLISH_PLAN PV-B06).

return function(t)
	local M = t.logic("MatchMoments")
	local Settings = t.logic("Settings")

	local function kinds(list)
		local out = {}
		for _, m in list do
			table.insert(out, m.kind)
		end
		return table.concat(out, ",")
	end

	local full = { totalWaves = 20, cutscenes = true, effects = "full", reducedMotion = false }

	t.describe("MatchMoments", function()
		t.it("plain and boss wave starts; the last wave is also the final-wave moment", function()
			t.eq(kinds(M.fromEvent({ type = "waveStart", wave = 3 }, full)), "waveStart")
			local boss = M.fromEvent({ type = "waveStart", wave = 10, boss = "sergeant" }, full)
			t.eq(kinds(boss), "bossIntro")
			t.eq(boss[1].boss, "sergeant")
			t.eq(boss[1].camera, true)
			t.eq(kinds(M.fromEvent({ type = "waveStart", wave = 20, boss = "chief_thief" }, full)), "bossIntro,finalWave")
			t.eq(kinds(M.fromEvent({ type = "waveStart", wave = 20 }, { totalWaves = nil, cutscenes = true, effects = "full", reducedMotion = false })), "waveStart", "endless has no final wave")
		end)

		t.it("the boss camera push respects cutscenes, effects off and reduced motion", function()
			local e = { type = "waveStart", wave = 10, boss = "sergeant" }
			t.eq(M.fromEvent(e, { totalWaves = 20, cutscenes = false, effects = "full", reducedMotion = false })[1].camera, false)
			t.eq(M.fromEvent(e, { totalWaves = 20, cutscenes = true, effects = "off", reducedMotion = false })[1].camera, false)
			t.eq(M.fromEvent(e, { totalWaves = 20, cutscenes = true, effects = "reduced", reducedMotion = true })[1].camera, false)
			t.eq(M.fromEvent(e, { totalWaves = 20, cutscenes = true, effects = "reduced", reducedMotion = false })[1].camera, true)
		end)

		t.it("the ally turns only where the story has the beat; the camera follows the boss rule (S1-C05)", function()
			local Story = t.config("Story")
			local line = Story.episodes.ep8.moments.ally_turn
			local e = { type = "ally", id = 7, unitId = "adashari", shield = 0 }
			local withLine = { totalWaves = 55, cutscenes = true, effects = "full", reducedMotion = false, allyLine = line }
			local turn = M.fromEvent(e, withLine)
			t.eq(kinds(turn), "allyTurn")
			t.eq(turn[1].id, 7)
			t.eq(turn[1].unit, "adashari")
			t.eq(turn[1].line, line)
			t.eq(turn[1].camera, true)
			t.eq(kinds(M.fromEvent(e, full)), "", "Episode 9's guard from wave 1 has no turn beat")
			local still = M.fromEvent(e, { totalWaves = 55, cutscenes = true, effects = "full", reducedMotion = true, allyLine = line })
			t.eq(still[1].camera, false, "reduced motion: the line, no camera push")
			t.eq(Story.episodes.ep9.moments, nil, "Episode 9 has no turn beat")
		end)

		t.it("dusk falls to night by the configured wave", function()
			local Lighting = t.config("Lighting")
			local by = Lighting.dusk.nightByWave
			t.eq(M.nightFraction(1, by), 0)
			t.eq(M.nightFraction(by, by), 1)
			t.eq(M.nightFraction(by + 20, by), 1)
			t.eq(M.nightFraction(0, by), 0)
			local mid = M.nightFraction(math.floor((by + 1) / 2), by)
			t.truthy(mid > 0.4 and mid < 0.6, "half way at the middle wave")
			t.eq(M.nightFraction(5, 1), 1, "a one-wave fall is night at once")
			t.truthy(Lighting.dusk.modes.ep9, "Episode 9 opens at dusk")
			for id in Lighting.dusk.modes do
				t.truthy(t.config("Modes")[id], "dusk mode " .. id .. " exists")
			end
			t.truthy(Lighting.dusk.clockTime < Lighting.night.clockTime, "dusk comes before night")
		end)

		t.it("wave clears carry the bonus but not after the last wave", function()
			local c = M.fromEvent({ type = "waveEnd", wave = 4, bonus = 120 }, full)
			t.eq(kinds(c), "waveClear")
			t.eq(c[1].bonus, 120)
			t.eq(kinds(M.fromEvent({ type = "waveEnd", wave = 20, bonus = 300 }, full)), "", "victory covers the last wave")
		end)

		t.it("victory effects need full effects; defeat desaturates unless effects are off", function()
			t.eq(M.fromEvent({ type = "won" }, full)[1].fx, true)
			t.eq(M.fromEvent({ type = "won" }, { totalWaves = 20, cutscenes = true, effects = "reduced", reducedMotion = false })[1].fx, false)
			t.eq(M.fromEvent({ type = "lost" }, { totalWaves = 20, cutscenes = true, effects = "reduced", reducedMotion = false })[1].fx, true)
			t.eq(M.fromEvent({ type = "lost" }, { totalWaves = 20, cutscenes = true, effects = "off", reducedMotion = false })[1].fx, false)
			t.eq(#M.fromEvent({ type = "attack" }, full), 0, "other events draw nothing here")
		end)

		t.it("UI motion gate (PV-B07): reduced motion stops everything; effects trim the extras", function()
			local Motion = t.logic("Motion")
			for _, k in Motion.kinds do
				t.eq(Motion.allowed(k, "full", true, true), false, k .. " under Reduced Motion")
				t.eq(Motion.allowed(k, "off", false, true), k == "press", k .. " with effects off")
			end
			t.eq(Motion.allowed("shine", "reduced", false, true), false)
			t.eq(Motion.allowed("petals", "reduced", false, true), false)
			t.eq(Motion.allowed("flip", "reduced", false, true), true)
			t.eq(Motion.allowed("slide", "reduced", false, false), true)
			t.eq(Motion.allowed("tilt", "full", false, false), false, "no hover tilt on touch")
			t.eq(Motion.allowed("tilt", "full", false, true), true)
			t.eq(Motion.allowed("wobble", "full", false, false), true)
			-- Theme v2 (LP-C01): the breathing Play button and the ready shimmer are decorative extras;
			-- staggered lists follow the pop.
			t.eq(Motion.allowed("breathe", "reduced", false, true), false)
			t.eq(Motion.allowed("ready", "reduced", false, true), false)
			t.eq(Motion.allowed("breathe", "full", false, false), true)
			t.eq(Motion.allowed("stagger", "reduced", false, false), true)
		end)

		t.it("lantern flicker stays in range and moves smoothly (PV-E01)", function()
			local Flicker = t.logic("Flicker")
			local L = t.config("Lighting")
			local f = L.flicker
			local prev = nil
			local lo, hi = math.huge, -math.huge
			for i = 0, 600 do
				local tt = i / f.hz
				local v = Flicker.value(tt, 3.7, f.min, f.max)
				t.truthy(v >= f.min - 1e-9 and v <= f.max + 1e-9, "in range")
				if prev then
					t.truthy(math.abs(v - prev) <= (f.max - f.min) * 0.5, "no strobe between ticks")
				end
				prev = v
				lo, hi = math.min(lo, v), math.max(hi, v)
			end
			t.truthy(hi - lo > (f.max - f.min) * 0.4, "it does flicker")
			t.truthy(Flicker.value(1, 1, f.min, f.max) ~= Flicker.value(1, 2, f.min, f.max), "seeds differ")
			t.truthy(L.night.density > L.day.density and L.flicker.maxLights <= 40)
		end)

		t.it("the cutscenes setting exists, is a boolean and defaults on", function()
			t.truthy(Settings.accept("cutscenes", false))
			t.eq(Settings.accept("cutscenes", "off"), false)
			t.eq(Settings.get(nil, "cutscenes"), true)
		end)
	end)
end
