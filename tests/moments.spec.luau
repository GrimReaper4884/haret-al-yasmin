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
