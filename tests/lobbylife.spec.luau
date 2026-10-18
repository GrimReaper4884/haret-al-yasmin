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

		t.it("config stays inside the plan's budgets", function()
			t.eq(Cfg.fountain.rate, 6)
			t.eq(Cfg.steam.rate, 4)
			t.eq(#Cfg.vines.spots, 6)
			t.truthy(Cfg.birds.height > 25, "birds fly above the rooftops (facades are 20–22 studs)")
		end)
	end)
end
