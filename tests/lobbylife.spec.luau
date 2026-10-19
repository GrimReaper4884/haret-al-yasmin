--!nocheck
-- Lobby life (POLISH_PLAN PV-E02): Effects gating, sway bounds, the flock, cat turning, ripples,
-- the oven trigger, and the config's budgets.

return function(t)
	local LobbyLife = t.logic("LobbyLife")
	local Cfg = t.config("LobbyLife")

	t.describe("LobbyLife", function()
		t.it("Effects full draws everything, reduced drops particles, off draws nothing", function()
			local full, reduced, off =
				LobbyLife.tier("full"), LobbyLife.tier("reduced"), LobbyLife.tier("off")
			t.eq(full.particles, true)
			t.eq(full.motion, true)
			t.eq(reduced.particles, false)
			t.eq(reduced.motion, true)
			t.eq(reduced.static, true)
			t.eq(off.static, false)
			t.eq(off.motion, false)
			t.eq(off.particles, false)
			t.eq(LobbyLife.tier("nonsense").motion, false, "unknown levels count as off")
		end)

		t.it("pieces stop beyond 120 studs", function()
			t.eq(Cfg.radius, 120)
			t.eq(LobbyLife.near(119, 0, 0, Cfg.radius), true)
			t.eq(LobbyLife.near(100, 50, 50, Cfg.radius), false)
		end)

		t.it("washing sways inside its amplitude and moves smoothly", function()
			local l = Cfg.laundry
			local prev = LobbyLife.sway(0, 1.3, l.amp, l.hz)
			for i = 1, 600 do
				local v = LobbyLife.sway(i / 30, 1.3, l.amp, l.hz)
				t.truthy(math.abs(v) <= l.amp + 1e-9, "within amp")
				t.truthy(math.abs(v - prev) < 1.5, "no jumps between frames")
				prev = v
			end
		end)

		t.it("the flock circles above the square, spread out, heading along its path", function()
			local b = Cfg.birds
			t.eq(b.count, 6)
			for _, tt in { 0, 7.5, 40 } do
				local seen = {}
				for i = 1, b.count do
					local x, y, z, yaw, roll = LobbyLife.bird(i, tt, b)
					local r = math.sqrt((x - b.center[1]) ^ 2 + (z - b.center[2]) ^ 2)
					t.truthy(math.abs(r - b.radius) <= b.spread + 1e-6, "on its circle")
					t.truthy(math.abs(y - b.height) <= b.bob + 0.6 + 1e-6, "at flight height")
					t.truthy(math.abs(roll) <= math.rad(b.flap) + 1e-9, "wing beat bounded")
					-- Heading matches the next position
					local x2, _, z2 = LobbyLife.bird(i, tt + 0.05, b)
					local want = math.atan2(-(x2 - x), -(z2 - z))
					t.truthy(math.abs(LobbyLife.angleDiff(yaw, want)) < 0.2, "faces where it flies")
					for _, o in seen do
						t.truthy((o[1] - x) ^ 2 + (o[2] - z) ^ 2 > 1, "birds don't overlap")
					end
					table.insert(seen, { x, z })
				end
			end
		end)

		t.it("a cat turns the short way and never overshoots", function()
			t.eq(LobbyLife.yawToward(0, 0, 0, -10), 0, "facing -Z is yaw 0")
			t.truthy(math.abs(LobbyLife.yawToward(0, 0, -10, 0) - math.pi / 2) < 1e-9, "facing -X is +90°")
			local step = LobbyLife.turnStep(math.rad(170), math.rad(-170), math.rad(5))
			t.truthy(step > 0, "wraps across ±180° the short way")
			t.truthy(math.abs(step - math.rad(5)) < 1e-9, "capped")
			t.truthy(math.abs(LobbyLife.turnStep(0, 0.01, 1) - 0.01) < 1e-9, "no overshoot")
		end)

		t.it("ripples cycle 0..1 and are staggered", function()
			local r = Cfg.fountain.ripples
			for tt = 0, 10, 0.37 do
				local p = LobbyLife.ripple(tt, 1, r.count, r.period)
				t.truthy(p >= 0 and p < 1)
			end
			t.truthy(LobbyLife.ripple(0, 1, r.count, r.period) ~= LobbyLife.ripple(0, 2, r.count, r.period))
		end)

		t.it("the oven puffs when a player passes, then waits its cooldown, and the flare settles", function()
			local o = Cfg.oven
			t.eq(LobbyLife.ovenPuff(o.trigger - 1, 100, -math.huge, o.trigger, o.cooldown), true)
			t.eq(LobbyLife.ovenPuff(o.trigger + 1, 100, -math.huge, o.trigger, o.cooldown), false, "too far")
			t.eq(
				LobbyLife.ovenPuff(1, 100, 100 - o.cooldown + 0.1, o.trigger, o.cooldown),
				false,
				"cooling down"
			)
			t.eq(LobbyLife.flare(0, o.boost, o.flare), o.boost)
			t.eq(LobbyLife.flare(o.flare, o.boost, o.flare), 1)
			local mid = LobbyLife.flare(o.flare / 2, o.boost, o.flare)
			t.truthy(mid > 1 and mid < o.boost)
		end)

		t.it("a walker's route is a deterministic loop: stand, walk, stand (LP-D02)", function()
			local function near(a, b, eps, msg)
				t.truthy(math.abs(a - b) <= eps, (msg or "near") .. ": " .. tostring(a) .. " vs " .. tostring(b))
			end
			local pts = { { 0, 0 }, { 0, -12 }, { 9, -12 } } -- legs of 12, 9 and 15 studs
			local speed, pause = 3, 2
			t.eq(LobbyLife.routeCycle(pts, speed, pause), 3 * 2 + (12 + 9 + 15) / 3)
			local x, z, yaw, moving = LobbyLife.route(pts, speed, pause, 1)
			t.eq(x, 0)
			t.eq(z, 0)
			t.eq(moving, false, "stands at the first point first")
			near(yaw, LobbyLife.yawToward(9, -12, 0, 0), 1e-9, "faces along the leg it came in on")
			x, z, yaw, moving = LobbyLife.route(pts, speed, pause, 2 + 2) -- 2 s into the first leg
			t.eq(moving, true)
			near(x, 0, 1e-9)
			near(z, -6, 1e-9)
			near(yaw, 0, 1e-9, "walking -Z faces yaw 0")
			x, z, _, moving = LobbyLife.route(pts, speed, pause, 2 + 4 + 1) -- standing at point 2
			t.eq(moving, false)
			near(z, -12, 1e-9)
			local cycle = LobbyLife.routeCycle(pts, speed, pause)
			for _, at in { 0.5, 3.3, 9.9, 17.2 } do
				local ax, az, ayaw, am = LobbyLife.route(pts, speed, pause, at)
				local bx, bz, byaw, bm = LobbyLife.route(pts, speed, pause, at + cycle * 7)
				near(ax, bx, 1e-6)
				near(az, bz, 1e-6)
				near(ayaw, byaw, 1e-6)
				t.eq(am, bm, "the same every cycle")
			end
			x, z = LobbyLife.route(pts, speed, pause, cycle - 0.01)
			t.truthy(math.abs(x) < 0.1 and math.abs(z) < 0.1, "the last leg closes the loop")
			t.eq(select(4, LobbyLife.route({ { 4, 5 } }, speed, pause, 10)), false, "a one-point route stands")
		end)

		t.it("the rooftop call comes every period, takes turns and waves first (LP-D07)", function()
			local r = Cfg.rooftop
			local n = #r.lines
			t.eq(n, 4)
			local idx, wave = LobbyLife.callAt(r.offset + 0.5, r.every, r.show, n, r.offset, r.wave)
			t.eq(idx, 1)
			t.eq(wave, true, "waves at the start")
			idx, wave = LobbyLife.callAt(r.offset + r.wave + 0.5, r.every, r.show, n, r.offset, r.wave)
			t.eq(idx, 1)
			t.eq(wave, false, "then just talks")
			t.eq((LobbyLife.callAt(r.offset + r.show + 0.1, r.every, r.show, n, r.offset, r.wave)), nil, "quiet after `show` s")
			t.eq((LobbyLife.callAt(r.offset + r.every + 1, r.every, r.show, n, r.offset, r.wave)), 2, "the next line next period")
			t.eq((LobbyLife.callAt(r.offset + 4 * r.every + 1, r.every, r.show, n, r.offset, r.wave)), 1, "and round again")
			t.eq((LobbyLife.callAt(r.offset - 1, r.every, r.show, n, r.offset, r.wave)), nil, "quiet just before")
			t.eq((LobbyLife.callAt(5, 90, 7, 0, 0, 1)), nil, "no lines, no call")
			t.truthy(r.show < r.every and r.wave <= r.show)
			local Strings = t.config("Strings")
			for _, key in r.lines do
				t.truthy(Strings.en[key] and Strings.ar[key], key .. " in en and ar")
			end
		end)

		t.it("the lane clock: phase boundaries, determinism, fades (LP-D09)", function()
			local C = Cfg.CLOCK
			local function phase(sec)
				return (LobbyLife.clock(sec, C))
			end
			t.eq(C.cycle, 720, "a 12-minute day")
			t.eq(phase(0), "dawn")
			t.eq(phase(59.9), "dawn")
			t.eq(phase(60), "day")
			t.eq(phase(479.9), "day")
			t.eq(phase(480), "evening")
			t.eq(phase(599.9), "evening")
			t.eq(phase(600), "night")
			t.eq(phase(719.9), "night")
			t.eq(phase(720), "dawn", "the cycle wraps")
			t.eq(phase(1.8e9 + 600), phase(600), "the same at any epoch (server time)")
			t.eq(phase(-120), "night", "times before the epoch wrap too")
			local _, into = LobbyLife.clock(60 + 12, C)
			t.eq(into, 12)
			-- every minute of the cycle belongs to exactly one phase, in order
			local last = 0
			for _, p in C.phases do
				t.eq(p.from, last, p.id .. " starts where the last ended")
				last = p.to
			end
			t.eq(last * 60, C.cycle)
			-- the fade: night into dawn at the top of the cycle, done after `fade` s
			local from, to, k = LobbyLife.lightBlend(0, C)
			t.eq(from, "night")
			t.eq(to, "dawn")
			t.eq(k, 0)
			from, to, k = LobbyLife.lightBlend(480 + C.fade / 2, C)
			t.eq(from, "day")
			t.eq(to, "evening")
			t.truthy(k > 0.4 and k < 0.6, "half way through the fade")
			from, to, k = LobbyLife.lightBlend(480 + C.fade + 1, C)
			t.eq(from, "evening")
			t.eq(k, 1)
			local Light = t.config("Lighting")
			for _, p in C.phases do
				local look = Light.lane[p.id]
				t.truthy(look, p.id .. " has a look")
				t.truthy(look.brightness > 0 and look.lanterns > 0 and look.lanterns <= 1.5 and look.clockTime >= 0 and look.clockTime < 24)
			end
			t.truthy(Light.lane.night.brightness < Light.lane.evening.brightness and Light.lane.evening.brightness < Light.lane.day.brightness, "the light falls through the evening into night")
		end)

		t.it("the beats keep to their parts of the day (LP-D10)", function()
			local C, B = Cfg.CLOCK, Cfg.beats
			-- the patrol at 90 s and 330 s of every cycle (day); its 570 s slot falls in the evening: skipped
			t.eq(LobbyLife.beatAt(90, C, B.patrol), 0)
			t.eq(LobbyLife.beatAt(90 + 30, C, B.patrol), 30)
			t.eq(LobbyLife.beatAt(90 + B.patrol.length + 1, C, B.patrol), nil, "over")
			t.eq(LobbyLife.beatAt(330 + 5, C, B.patrol), 5)
			t.eq(LobbyLife.beatAt(570 + 5, C, B.patrol), nil, "not in the evening")
			t.eq(LobbyLife.beatAt(720 * 9 + 90 + 1, C, B.patrol), 1, "the same every cycle")
			t.truthy(330 + B.patrol.length <= 480, "the last patrol ends before the evening")
			-- the patrol route takes no longer than its window
			t.truthy(LobbyLife.routeCycle(B.patrol.route, B.patrol.speed, 0) + 2 * B.patrol.gap <= B.patrol.length)
			-- a dispute window that would start in the day and run into the evening is dropped once it crosses
			local d = { phases = { "day" }, every = 300, offset = 470, length = 26 }
			t.eq(LobbyLife.beatAt(475, C, d), 5, "still day")
			t.eq(LobbyLife.beatAt(485, C, d), nil, "the evening has begun")
			-- the gate: open by day, half shut by night, open again at dawn
			local g = B.gate
			t.eq(LobbyLife.gateAngle(300, C, g), 100)
			t.eq(LobbyLife.gateAngle(600, C, g), 100, "the night's first instant")
			t.eq(LobbyLife.gateAngle(600 + g.swing, C, g), g.nightAngle)
			t.eq(LobbyLife.gateAngle(700, C, g), g.nightAngle)
			t.eq(LobbyLife.gateAngle(720, C, g), g.nightAngle, "dawn starts shut")
			t.eq(LobbyLife.gateAngle(720 + g.swing, C, g), 100)
			t.truthy(12 - 2 * 6 * math.cos(math.rad(g.nightAngle)) >= 4, "a 4-stud gap stays between the leaves")
			-- evening tale lines and night calls
			t.eq(LobbyLife.inPhase(480 + 41, C, "evening", 40, 54), 1)
			t.eq(LobbyLife.inPhase(480 + 55, C, "evening", 40, 54), nil)
			t.eq(LobbyLife.inPhase(300, C, "evening", 0, 999), nil, "only in its phase")
			t.truthy(#B.coffee.seats == 6 and #B.coffee.tales == 5 and B.coffee.lineAt[3] + B.coffee.lineSeconds <= 120)
			local Strings = t.config("Strings")
			local keys = {}
			for _, k in B.dispute.lines do
				table.insert(keys, k)
			end
			for _, c in B.watch.calls do
				table.insert(keys, c.key)
			end
			for _, tale in B.coffee.tales do
				for i = 1, 3 do
					table.insert(keys, "afk.line." .. tale .. "." .. i)
				end
			end
			table.insert(keys, "beat.fund")
			for _, k in keys do
				t.truthy(Strings.en[k] and Strings.ar[k], k .. " in en and ar")
			end
		end)

		t.it("the 'arada every third evening; the musaharati only in its event (LP-D11)", function()
			local C, A = Cfg.CLOCK, Cfg.beats.arada
			t.eq(LobbyLife.aradaAt(480 + A.from + 1, C, A), 1, "the first evening of three")
			t.eq(LobbyLife.aradaAt(720 + 480 + A.from + 1, C, A), nil, "not the second")
			t.eq(LobbyLife.aradaAt(1440 + 480 + A.from + 1, C, A), nil, "not the third")
			t.eq(LobbyLife.aradaAt(2160 + 480 + A.from + 1, C, A), 1, "the fourth again: every 36 minutes")
			t.eq(LobbyLife.aradaAt(480 + A.from + A.length + 1, C, A), nil, "over")
			t.truthy(A.from + A.length <= 120, "inside the evening")
			t.eq(LobbyLife.pathLength({ { 0, 0 }, { 3, 4 }, { 3, 10 } }), 11)
			t.truthy(LobbyLife.pathLength(A.route) / A.speed + 2 * A.gap <= A.length, "the last rank reaches the gate in time")
			local M0 = Cfg.beats.musaharati
			t.truthy(LobbyLife.pathLength(M0.route) / M0.speed <= M0.length, "the musaharati finishes his round")
			local EventLogic = t.logic("EventLogic")
			local M = Cfg.beats.musaharati
			local now = 1800000000
			t.eq(EventLogic.isActive(({} :: any)[M.event], now), false, "no such event: no musaharati")
			local running = { [M.event] = { startsAt = now - 10, endsAt = now + 10 } }
			t.eq(EventLogic.isActive(running[M.event], now), true, "while it runs")
			t.eq(EventLogic.isActive(running[M.event], now + 11), false, "and not after")
			local Events = t.config("Events")
			t.eq(Events[M.event], nil, "no Ramadan event is configured yet (the owner adds it)")
			local Strings = t.config("Strings")
			for _, k in M.calls do
				t.truthy(Strings.en[k] and Strings.ar[k], k .. " in en and ar")
			end
		end)

		t.it("config stays inside the plan's budgets", function()
			t.eq(Cfg.fountain.rate, 6)
			t.eq(Cfg.steam.rate, 4)
			t.eq(#Cfg.vines.spots, 6)
			t.truthy(Cfg.birds.height > 25, "birds fly above the rooftops (facades are 20–22 studs)")
		end)
	end)
end
