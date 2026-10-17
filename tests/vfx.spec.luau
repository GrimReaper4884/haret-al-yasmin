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
			t.truthy(Vfx.DEATH.petals >= 2 and Vfx.DEATH.petals <= Vfx.MAX_PER_FRAME, "a poof fits in one frame")
			t.truthy(Vfx.BOSS.pulses * 1 <= Vfx.MAX_PER_FRAME)
			for _, e in { Vfx.HIT, Vfx.DEATH, Vfx.GATE_HIT } do
				t.truthy(e.life > 0 and e.life <= 1.5, "effects are short")
			end
		end)
	end)
end
