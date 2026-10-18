--!nocheck
-- Effects budget (Logic/VfxBudget, Config/Vfx; BUILD_PLAN P2-17): live and per-frame caps.

return function(t)
	local VfxBudget = t.logic("VfxBudget")
	local Vfx = t.config("Vfx")

	t.describe("VfxBudget", function()
		t.it("caps parts per frame and resets the frame counter", function()
			local b = VfxBudget.new(100, 3)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), false, "fourth part this frame is refused")
			t.eq(b.live, 3)
			t.eq(b.skipped, 1)
			VfxBudget.newFrame(b)
			t.eq(b.frame, 0)
			t.eq(b.skipped, 0)
			t.eq(VfxBudget.take(b), true, "next frame has a fresh budget")
			t.eq(b.live, 4, "live parts carry over")
		end)

		t.it("caps live parts regardless of frames", function()
			local b = VfxBudget.new(2, 10)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), false)
			VfxBudget.newFrame(b)
			t.eq(VfxBudget.take(b), false, "still full after a new frame")
			VfxBudget.release(b)
			t.eq(b.live, 1)
			t.eq(VfxBudget.take(b), true)
			VfxBudget.release(b)
			VfxBudget.release(b)
			VfxBudget.release(b)
			t.eq(b.live, 0, "never negative")
		end)

		t.it("play information uses the reserve and skips the frame cap; decoration never touches it", function()
			local b = VfxBudget.new(10, 2, 4)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), false, "frame cap for decoration")
			t.eq(VfxBudget.takeInfo(b), true, "information ignores the frame cap")
			VfxBudget.newFrame(b)
			t.eq(VfxBudget.take(b), true)
			t.eq(VfxBudget.take(b), true)
			VfxBudget.newFrame(b)
			t.eq(b.live, 5)
			t.eq(VfxBudget.take(b), true, "6th live part: decoration stops at maxLive - reserve")
			t.eq(VfxBudget.take(b), false)
			t.eq(VfxBudget.allow(b, 5), 0, "allow() respects the reserve")
			for _ = 1, 4 do
				t.eq(VfxBudget.takeInfo(b), true, "the reserve is there for information")
			end
			t.eq(VfxBudget.takeInfo(b), false, "never past maxLive")
			t.eq(b.live, 10)
			local plain = VfxBudget.new(3, 3)
			t.eq(plain.reserve, 0, "no reserve unless asked")
		end)

		t.it("allow() shrinks a multi-part effect to what fits", function()
			local b = VfxBudget.new(10, 5)
			t.eq(VfxBudget.allow(b, 6), 5, "frame cap")
			for _ = 1, 3 do
				VfxBudget.take(b)
			end
			t.eq(VfxBudget.allow(b, 6), 2)
			VfxBudget.newFrame(b)
			b.live = 9
			t.eq(VfxBudget.allow(b, 6), 1, "live cap")
			b.live = 10
			t.eq(VfxBudget.allow(b, 6), 0)
		end)

		t.it("a busy wave never exceeds the configured caps", function()
			local b = VfxBudget.new(Vfx.MAX_LIVE, Vfx.MAX_PER_FRAME)
			local peakLive, peakFrame = 0, 0
			for frame = 1, 200 do
				VfxBudget.newFrame(b)
				-- 40 hits a frame asked for, each wanting one part; parts live for 10 frames
				for _ = 1, 40 do
					VfxBudget.take(b)
				end
				peakLive = math.max(peakLive, b.live)
				peakFrame = math.max(peakFrame, b.frame)
				if frame % 10 == 0 then
					for _ = 1, Vfx.MAX_PER_FRAME * 10 do
						VfxBudget.release(b)
					end
				end
			end
			t.truthy(peakLive <= Vfx.MAX_LIVE, "live peak " .. peakLive)
			t.eq(peakFrame, Vfx.MAX_PER_FRAME)
		end)
	end)

	t.describe("HitFx (PV-B02)", function()
		local HitFx = t.logic("HitFx")

		t.it("plans by Effects level: full draws all, reduced only numbers, off nothing", function()
			local off = HitFx.plan("off", true, true)
			t.eq(off.number or off.spark or off.flash or off.punch, false)
			local reduced = HitFx.plan("reduced", true, true)
			t.eq(reduced.number, true)
			t.eq(reduced.spark or reduced.flash or reduced.punch, false, "reduced: numbers only")
			local crowd = HitFx.plan("full", false, false)
			t.eq(crowd.number and crowd.spark and crowd.punch, true)
			t.eq(crowd.flash, false, "no Highlight for the crowd")
			t.eq(HitFx.plan("full", true, false).flash, true, "bosses flash")
			t.eq(HitFx.plan("full", false, true).flash, true, "the watched target flashes")
			t.eq(HitFx.plan("full", true, false).punch, false, "a flash replaces the nudge")
		end)

		t.it("the number pool reuses free slots, then the oldest, never grows", function()
			local cfg = Vfx.DAMAGE_NUMBERS
			local pool = HitFx.newPool(cfg.pool)
			t.eq(#pool.untilAt, cfg.pool)
			local seen = {}
			for i = 1, cfg.pool do
				seen[HitFx.acquire(pool, 0, cfg.life)] = true
			end
			local n = 0
			for _ in seen do
				n += 1
			end
			t.eq(n, cfg.pool, "a burst fills every slot once")
			t.eq(HitFx.busy(pool, 0.1), cfg.pool)
			-- Full: the next number recycles the slot that frees soonest
			pool.untilAt[7] = 0.2
			t.eq(HitFx.acquire(pool, 0.1, cfg.life), 7, "oldest recycled")
			t.eq(#pool.untilAt, cfg.pool, "never grows")
			-- After the life, everything is free again
			t.eq(HitFx.busy(pool, 10), 0)
			t.eq(HitFx.acquire(pool, 10, cfg.life), 1, "first free slot")
		end)

		t.it("a crowd of hits at Endless wave 30 stays inside the pool and the Highlight cap", function()
			local cfg = Vfx.DAMAGE_NUMBERS
			local pool = HitFx.newPool(cfg.pool)
			-- 4 players x 15 towers, a hit every 0.6 s each = 100 hits/s for 10 s at 60 fps
			local peak = 0
			local dt = 1 / 60
			local acc = 0
			for frame = 1, 600 do
				local now = frame * dt
				acc += 100 * dt
				while acc >= 1 do
					acc -= 1
					HitFx.acquire(pool, now, cfg.life)
				end
				peak = math.max(peak, HitFx.busy(pool, now))
			end
			t.truthy(peak <= cfg.pool, "busy " .. peak)
			t.truthy(Vfx.HIT_FLASH.max <= 31, "Roblox caps Highlights at 31")
		end)

		t.it("coins arc from the body to the pill; shakes decay to zero (PV-B03)", function()
			local x, y = HitFx.arc(0, 100, 300, 500, 600, 80)
			t.eq(x, 100)
			t.eq(y, 300)
			x, y = HitFx.arc(1, 100, 300, 500, 600, 80)
			t.eq(x, 500)
			t.eq(y, 600)
			local _, ym = HitFx.arc(0.5, 100, 300, 500, 600, 80)
			t.truthy(ym < 300, "the middle of the flight is lifted above both ends")
			local c = Vfx.BOSS_DEATH
			local sx, sy = HitFx.shake(c.shake, c.shake, c.amplitude, 1)
			t.eq(sx, 0)
			t.eq(sy, 0)
			sx, sy = HitFx.shake(0.01, c.shake, c.amplitude, 1)
			t.truthy(math.abs(sx) <= c.amplitude and math.abs(sy) <= c.amplitude)
			t.truthy(Vfx.COIN_FLIGHT.max >= 1 and Vfx.COIN_FLIGHT.max <= 12, "few coins in flight")
			t.truthy(Vfx.GATE_SHUDDER.dust <= Vfx.MAX_PER_FRAME, "the gate dust fits in one frame")
			t.truthy(c.shake <= 0.3, "a short shake")
		end)

		t.it("numbers rise with an ease-out and the nudge returns to zero", function()
			local h = Vfx.DAMAGE_NUMBERS.rise
			t.eq(HitFx.rise(0, h), 0)
			t.eq(HitFx.rise(1, h), h)
			t.truthy(HitFx.rise(0.5, h) > h / 2, "ease-out: past half way at half time")
			t.eq(HitFx.rise(2, h), h, "clamped")
			local p = Vfx.HIT_PUNCH
			t.eq(HitFx.knock(0, p.life, p.knock), p.knock)
			t.eq(HitFx.knock(p.life, p.life, p.knock), 0)
			t.eq(HitFx.knock(-1, p.life, p.knock), 0)
			t.truthy(HitFx.knock(p.life / 2, p.life, p.knock) < p.knock)
		end)
	end)

	t.describe("Particle sprites (PV-B01)", function()
		t.it("eight sprite kinds with whole ids and sane particle numbers; the emitter pool stays small", function()
			local n = 0
			for kind, tex in Vfx.TEXTURES do
				n += 1
				t.truthy(tex.id >= 0 and tex.id == math.floor(tex.id), kind .. " id")
				t.truthy(tex.size > 0 and tex.life > 0 and tex.life <= 2 and tex.speed >= 0, kind .. " numbers")
				t.truthy(tex.light >= 0 and tex.light <= 1, kind .. " light emission")
			end
			t.eq(n, 8)
			t.truthy(Vfx.MAX_EMITTERS <= 24, "POLISH_PLAN §2 caps live emitters at 24")
		end)
	end)

	t.describe("Role impacts (PV-B04)", function()
		local Units = t.config("Units")
		t.it("every unit role has an impact entry with a known kind", function()
			local kinds = {}
			for _, k in Vfx.ROLE_KINDS do
				kinds[k] = true
			end
			for id, def in Units do
				local r = Vfx.ROLES[def.role]
				t.truthy(r, id .. ": role '" .. tostring(def.role) .. "' has no Config/Vfx.ROLES entry")
				t.truthy(kinds[r.kind], id .. ": unknown impact kind " .. tostring(r.kind))
			end
			for role, r in Vfx.ROLES do
				if r.kind ~= "none" then
					t.truthy(type(r.color) == "string" and string.match(r.color, "^#%x%x%x%x%x%x$"), role .. " colour")
					t.truthy(r.life > 0 and r.life <= 1, role .. " life")
				end
			end
			t.truthy(Vfx.ROLES.splash.hitStop <= 0.1, "a hit-stop is a blink, not a pause")
			t.truthy(Vfx.ROLES.splash.dust + 1 <= Vfx.MAX_PER_FRAME, "a splash fits one frame's budget")
			t.truthy(Vfx.abilitySlow.factor > 0 and Vfx.abilitySlow.factor < 1 and Vfx.abilitySlow.seconds <= 0.5)
		end)
	end)

	t.describe("Tower moments (PV-B05)", function()
		t.it("placement, upgrade and sell effects fit the budgets", function()
			local c = Vfx.TOWER
			t.truthy(c.petals + 1 <= Vfx.MAX_PER_FRAME, "dust ring + petals fit one frame")
			t.truthy(c.stars <= Vfx.MAX_PER_FRAME, "the star burst fits one frame")
			t.truthy(c.coins <= Vfx.COIN_FLIGHT.max, "the sell shower never outgrows the coin pool")
			t.truthy(c.punch > 1 and c.punch <= 1.25 and c.punchLife <= 0.5)
			t.truthy(c.glowLevel >= 2)
			t.eq(c.dashes % 2, 0, "ablaq dashes alternate, so an even count")
			for _, k in { "dustColor", "petalColor", "starColor", "glowColor", "dashDark", "dashLight" } do
				t.truthy(string.match(c[k], "^#%x%x%x%x%x%x$"), k)
			end
		end)
	end)

	t.describe("Enemy read (PV-A04)", function()
		t.it("markers, disc and boss bar are small and well-formed", function()
			local r = Vfx.ENEMY_READ
			t.truthy(string.match(r.barStroke, "^#%x%x%x%x%x%x$") and string.match(r.discColor, "^#%x%x%x%x%x%x$"))
			t.truthy(r.marker >= 10 and r.marker <= 16, "markers stay small next to a 44 px bar")
			t.truthy(r.portrait >= 48, "the boss portrait reads on a phone")
			t.truthy(r.discTransparency > 0 and r.discTransparency < 1)
		end)
	end)

	t.describe("Match moments (PV-B06)", function()
		t.it("moment effects stay inside the budget", function()
			local m = Vfx.MOMENTS
			t.truthy(m.bossPush <= 1.5, "a short push")
			t.truthy(#m.ribbonColors == 2 and m.ribbonSegments * 2 <= Vfx.MAX_PER_FRAME, "both ribbons fit one frame")
			local live = (m.petalFall / m.petalEvery) * m.petalsPer + m.ribbonSegments * 2
			t.truthy(live <= Vfx.MAX_LIVE, "petals + ribbons peak " .. live .. " of " .. Vfx.MAX_LIVE)
			t.truthy(m.lanternBoost > 1 and m.lanternBoost <= 1.3)
			for _, c in m.ribbonColors do
				t.truthy(string.match(c, "^#%x%x%x%x%x%x$"))
			end
			t.truthy(string.match(m.finalTint, "^#%x%x%x%x%x%x$"))
		end)
	end)

	t.describe("Config/Vfx", function()
		t.it("has sane budgets and well-formed colours", function()
			t.truthy(Vfx.MAX_PER_FRAME >= 4 and Vfx.MAX_PER_FRAME <= Vfx.MAX_LIVE)
			t.truthy(Vfx.MAX_LIVE <= 200, "the pool must stay small on phones")
			local function hex(s)
				t.truthy(type(s) == "string" and string.match(s, "^#%x%x%x%x%x%x$"), "hex colour " .. tostring(s))
			end
			for _, c in Vfx.DEATH.petalColors do
				hex(c)
			end
			for _, c in Vfx.DEATH.ashColors do
				hex(c)
			end
			hex(Vfx.GATE_HIT.color)
			hex(Vfx.BOSS.color)
			hex(Vfx.SWEEP.dustColor)
			hex(Vfx.DAMAGE_NUMBERS.color)
			hex(Vfx.DAMAGE_NUMBERS.critColor)
			hex(Vfx.HIT_FLASH.color)
			hex(Vfx.BOSS_DEATH.dustColor)
			hex(Vfx.GATE_SHUDDER.dustColor)
			t.truthy(Vfx.DAMAGE_NUMBERS.pool >= 8 and Vfx.DAMAGE_NUMBERS.pool <= 64)
			t.truthy(Vfx.DAMAGE_NUMBERS.critScale > 1)
			t.truthy(Vfx.DEATH.petals >= 2 and Vfx.DEATH.petals <= Vfx.MAX_PER_FRAME, "a poof fits in one frame")
			t.truthy(Vfx.BOSS.pulses * 1 <= Vfx.MAX_PER_FRAME)
			for _, e in { Vfx.HIT, Vfx.DEATH, Vfx.GATE_HIT, Vfx.DAMAGE_NUMBERS, Vfx.HIT_FLASH, Vfx.HIT_PUNCH } do
				t.truthy(e.life > 0 and e.life <= 1.5, "effects are short")
			end
		end)
	end)

	-- Season Story 1 mechanics on the match HUD (S1-C02, Logic/MechanicFx, Config/Vfx.STORY).
	t.describe("Story mechanics (S1-C02)", function()
		local MechanicFx = t.logic("MechanicFx")
		local Enemies = t.config("Enemies")
		local TD = t.config("TD")
		local Icons = t.config("Icons")
		local S = Vfx.STORY

		t.it("health-bar markers: armour, stealth, and a ? until the disguise falls", function()
			t.truthy(t.deepEq(MechanicFx.markers(Enemies.thief, false), { "eye" }))
			t.truthy(t.deepEq(MechanicFx.markers(Enemies.porter, false), { "shield" }))
			local d = MechanicFx.markers(Enemies.disguised, false)
			t.eq(d[#d], "mech_disguise", "the disguised man shows a ?")
			for _, m in MechanicFx.markers(Enemies.disguised, true) do
				t.truthy(m ~= "mech_disguise", "revealed: the ? is gone")
			end
			local beggar = MechanicFx.markers(Enemies.beggar, false)
			t.truthy(table.find(beggar, "eye") and table.find(beggar, "mech_disguise"), "the beggar is hidden and disguised")
			for id, def in Enemies do
				for _, m in MechanicFx.markers(def, false) do
					t.truthy(Icons.images[m], id .. ": marker " .. m .. " is in Config/Icons")
				end
			end
		end)

		t.it("rings: the drummer carries his aura, the porter his shield, at their real radii", function()
			local dr = MechanicFx.ring(Enemies.drummer)
			t.eq(dr.kind, "aura")
			t.eq(dr.radius, Enemies.drummer.aura.radius)
			local po = MechanicFx.ring(Enemies.porter)
			t.eq(po.kind, "shield")
			t.eq(po.radius, Enemies.porter.shield.radius)
			t.eq(MechanicFx.ring(Enemies.thief), nil)
			for id, def in Enemies do
				local r = MechanicFx.ring(def)
				if def.aura or def.shield then
					t.truthy(r and r.radius > 0 and r.radius <= 20, id .. " ring radius")
				end
			end
		end)

		t.it("ring slots are capped per kind and given back", function()
			local counts = {}
			for _ = 1, S.aura.max do
				t.eq(MechanicFx.admit(counts, "aura", S.aura.max), true)
			end
			t.eq(MechanicFx.admit(counts, "aura", S.aura.max), false, "one ring too many")
			t.eq(MechanicFx.admit(counts, "shield", S.shield.max), true, "kinds are counted apart")
			MechanicFx.release(counts, "aura")
			t.eq(MechanicFx.admit(counts, "aura", S.aura.max), true)
			MechanicFx.release(counts, "nothing")
			t.eq(counts.nothing, 0, "never negative")
		end)

		t.it("Effects levels: off draws no world part, reduced keeps play information", function()
			t.truthy(t.deepEq(MechanicFx.plan("off"), { rings = false, telegraph = false, flashes = false }))
			t.truthy(t.deepEq(MechanicFx.plan("reduced"), { rings = true, telegraph = true, flashes = false }))
			t.truthy(t.deepEq(MechanicFx.plan("full"), { rings = true, telegraph = true, flashes = true }))
		end)

		t.it("telegraph dashes run from where he is to where he lands, capped", function()
			local d = MechanicFx.dashes(10, 25, S.telegraph.spacing, S.telegraph.maxDashes)
			t.eq(#d, 5)
			t.truthy(d[1] > 10 and d[#d] < 25, "inside the jump")
			for i = 2, #d do
				t.truthy(d[i] > d[i - 1], "in order")
			end
			-- Lateef's real jump on the longest road stays under the cap.
			local long = MechanicFx.dashes(0, 400, S.telegraph.spacing, S.telegraph.maxDashes)
			t.eq(#long, S.telegraph.maxDashes)
			t.eq(#MechanicFx.dashes(20, 20, 3, 14), 0, "no jump, no dashes")
			t.eq(#MechanicFx.dashes(20, 10, 3, 14), 0, "never backwards")
			t.eq(#MechanicFx.dashes(0, 1, 3, 14), 1, "a short jump still shows one")
		end)

		t.it("flame pips follow the burn stacks, clamped to the cap", function()
			t.eq(MechanicFx.burnPips(0, TD.BURN_MAX_STACKS), 0)
			t.eq(MechanicFx.burnPips(3, TD.BURN_MAX_STACKS), 3)
			t.eq(MechanicFx.burnPips(99, TD.BURN_MAX_STACKS), TD.BURN_MAX_STACKS)
			t.eq(MechanicFx.burnPips(nil, TD.BURN_MAX_STACKS), 0)
			t.eq(MechanicFx.burnPips(0 / 0, TD.BURN_MAX_STACKS), 0)
			t.truthy(S.burnPip * TD.BURN_MAX_STACKS <= 120, "the pips fit under the gate bar")
		end)

		t.it("the story effects fit inside the effects budget", function()
			local function hex(c)
				t.truthy(type(c) == "string" and string.match(c, "^#%x%x%x%x%x%x$"), "hex colour " .. tostring(c))
			end
			for _, k in { "aura", "shield", "reveal", "telegraph", "summon" } do
				hex(S[k].color)
			end
			-- Worst case at once: every ring slot, a whole telegraph (+ its landing ring), a reveal and a summon.
			local worst = S.aura.max + S.shield.max + S.telegraph.maxDashes + 1 + 1 + 1
			t.truthy(worst <= Vfx.MAX_LIVE / 2, "story parts leave half the pool for hits and deaths")
			local info = S.aura.max + S.shield.max + S.telegraph.maxDashes + 1
			t.truthy(Vfx.INFO_RESERVE >= info - 1 and Vfx.INFO_RESERVE <= Vfx.MAX_LIVE / 2, "the reserve covers rings and a telegraph, and leaves decoration most of the pool")
			t.truthy(S.telegraph.maxDashes + 1 <= Vfx.MAX_PER_FRAME + 1, "a telegraph is drawn in about one frame")
			t.truthy(S.aura.transparency >= 0.6 and S.shield.transparency >= 0.6, "rings stay subtle")
			t.truthy(S.reveal.life <= 1.5 and S.summon.life <= 1.5, "flashes are short")
		end)
	end)
end
