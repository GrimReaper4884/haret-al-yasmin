--!nocheck
-- Touch HUD layout (docs/MOBILE_HUD_PLAN.md MH-01): profiles, the UIScale floors and presets, the
-- reserved corners and the hotbar / rail / lobby bar never sitting under them.

return function(t)
	local HudLayout = t.logic("HudLayout")
	local Hud = t.config("Hud")
	local TD = t.config("TD")

	local function size(x, y)
		return { x = x, y = y }
	end
	local function profileOf(input, display, x, y)
		return HudLayout.profile(Hud, { preferredInput = input, displaySize = display, safeSize = size(x, y) })
	end

	-- The three sizes the plan names, with the profile each must get.
	local CASES = {
		{ name = "phone 750x381", profile = "touch-phone", safe = size(750, 381) },
		{ name = "tablet 1024x768", profile = "touch-tablet", safe = size(1024, 768) },
		{ name = "desktop 1920x1080", profile = "desktop", safe = size(1920, 1080) },
	}

	local function hotbarRect(bar)
		return { x0 = bar.x, y0 = bar.y, x1 = bar.x + bar.width, y1 = bar.y + bar.slotH }
	end

	t.describe("HudLayout", function()
		t.it("picks the profile from input, display size and safe height", function()
			t.eq(profileOf("Touch", "Small", 750, 381), "touch-phone")
			t.eq(profileOf("Touch", "Small", 1024, 768), "touch-tablet")
			t.eq(profileOf("KeyboardAndMouse", "Medium", 1920, 1080), "desktop")
			t.eq(profileOf("Touch", "Medium", 1366, 768), "touch-tablet", "a touch laptop is a tablet")
			t.eq(profileOf("Gamepad", "Large", 1920, 1080), "desktop")
			t.eq(profileOf("Touch", "Small", 956, Hud.PHONE_MAX_HEIGHT - 1), "touch-phone")
			t.eq(profileOf("Touch", "Small", 956, Hud.PHONE_MAX_HEIGHT), "touch-tablet")
			t.eq(profileOf("KeyboardAndMouse", "Small", 750, 381), "desktop", "a phone with a keyboard last used")
		end)

		t.it("never scales below 1.0 on touch or 0.9 on desktop, never above max", function()
			for _, h in { 280, 324, 360, 381, 430, 600, 768, 1032, 1440 } do
				for _, preset in { "small", "default", "large", "huge" } do
					local s = HudLayout.scale(Hud, "touch-phone", size(1600, h), preset, 6)
					t.truthy(s >= Hud.SCALE.touchMin, "touch floor at h=" .. h .. " " .. preset .. ": " .. s)
					t.truthy(s <= Hud.SCALE.max)
					local d = HudLayout.scale(Hud, "desktop", size(2560, h), preset, 6)
					t.truthy(d >= Hud.SCALE.desktopMin, "desktop floor at h=" .. h .. " " .. preset .. ": " .. d)
					t.truthy(d <= Hud.SCALE.max)
				end
			end
		end)

		t.it("multiplies by the preset where no clamp bites", function()
			local safe = size(2560, 468) -- 468 / 390 = 1.2
			local base = HudLayout.scale(Hud, "desktop", safe, "default", 6)
			t.truthy(math.abs(base - 1.2) < 1e-9, "default " .. base)
			t.truthy(math.abs(HudLayout.scale(Hud, "desktop", safe, "small", 6) - 1.2 * 0.85) < 1e-9)
			t.truthy(math.abs(HudLayout.scale(Hud, "desktop", safe, "large", 6) - 1.2 * 1.15) < 1e-9)
			t.eq(HudLayout.scale(Hud, "desktop", safe, "huge", 6), Hud.SCALE.max, "1.2 × 1.3 is capped")
			t.eq(HudLayout.scale(Hud, "desktop", safe, "nonsense", 6), base, "unknown preset = default")
		end)

		t.it("fits a 7-slot hotbar into the width at the chosen scale, 640 … 2560 wide", function()
			for w = 640, 2560, 40 do
				for _, h in { 282, 324, 360, 600, 768, 1080, 1440 } do
					for _, profile in { "touch-phone", "touch-tablet", "desktop" } do
						for _, preset in { "default", "huge" } do
							local safe = size(w, h)
							local s = HudLayout.scale(Hud, profile, safe, preset, TD.LOADOUT_SLOTS + 1)
							local bar = HudLayout.hotbar(Hud, profile, s, safe, TD.LOADOUT_SLOTS + 1, {})
							local where = string.format("%s %s %dx%d s=%.3f", profile, preset, w, h, s)
							t.truthy(bar.x >= 0 and bar.x + bar.width <= w / s + 1e-6, "hotbar off screen: " .. where)
							t.truthy(bar.slotW >= Hud.TOUCH_MIN, "slot under TOUCH_MIN: " .. where)
						end
					end
				end
			end
		end)

		t.it("reserves the corners only on touch while the controls show", function()
			local safe = size(750, 381)
			local none = HudLayout.reserved(Hud, "desktop", true, safe)
			t.eq(none.left, nil)
			t.eq(none.right, nil)
			local off = HudLayout.reserved(Hud, "touch-phone", false, safe)
			t.eq(off.right, nil, "watchtower view hides the controls")
			local r = HudLayout.reserved(Hud, "touch-phone", true, safe)
			t.eq(r.left.x1, 160)
			t.eq(r.left.y0, 381 - 160)
			t.eq(r.right.x0, 750 - 140)
			t.eq(r.right.y0, 381 - 140)
			-- A measured jump button (the iPhone 17 Pro run) replaces the fallback, padded.
			local m = HudLayout.reserved(Hud, "touch-phone", true, size(750, 324), { jump = { x0 = 655, y0 = 234, x1 = 725, y1 = 304 } })
			t.eq(m.right.x0, 655 - Hud.RESERVED.pad)
			t.eq(m.right.y0, 234 - Hud.RESERVED.pad)
			t.eq(m.right.x1, 750)
			t.eq(m.right.y1, 324)
			t.eq(m.left.x1, 160, "dynamic thumbstick keeps the fallback")
			local band = HudLayout.freeBand(size(750, 324), m)
			t.eq(band.x0, 160)
			t.eq(band.x1, 655 - Hud.RESERVED.pad)
		end)

		t.it("keeps the hotbar, the rail and the lobby bar out of the corners", function()
			for _, c in CASES do
				local profile = HudLayout.profile(Hud, {
					preferredInput = if c.profile == "desktop" then "KeyboardAndMouse" else "Touch",
					displaySize = if c.profile == "desktop" then "Medium" else "Small",
					safeSize = c.safe,
				})
				t.eq(profile, c.profile, c.name)
				local reserved = HudLayout.reserved(Hud, profile, true, c.safe)
				for _, n in { TD.LOADOUT_SLOTS, TD.LOADOUT_SLOTS + 1 } do
					local s = HudLayout.scale(Hud, profile, c.safe, "default", n)
					local bar = HudLayout.hotbar(Hud, profile, s, c.safe, n, reserved)
					t.truthy(HudLayout.fits(HudLayout.toScreen(hotbarRect(bar), s), reserved), "hotbar in a corner: " .. c.name .. " n=" .. n)
					for count = 1, Hud.RAIL.maxButtons do
						local rail = HudLayout.rail(Hud, profile, s, c.safe, "right", count, reserved)
						t.eq(#rail.buttons, count)
						for _, b in rail.buttons do
							local r = { x0 = b.x, y0 = b.y, x1 = b.x + rail.size, y1 = b.y + rail.size }
							t.truthy(HudLayout.fits(HudLayout.toScreen(r, s), reserved), "rail in a corner: " .. c.name)
							t.truthy(r.y0 >= rail.menu.y + rail.menu.size, "rail under the menu button: " .. c.name)
							t.truthy(not HudLayout.overlaps(r, hotbarRect(bar)), "rail on the hotbar: " .. c.name)
						end
					end
					local lobby = HudLayout.lobbyBar(Hud, profile, s, c.safe, 5, reserved)
					local lr = { x0 = lobby.x, y0 = lobby.y, x1 = lobby.x + lobby.width, y1 = lobby.y + lobby.size }
					t.truthy(HudLayout.fits(HudLayout.toScreen(lr, s), reserved), "lobby bar in a corner: " .. c.name)
					t.truthy(lobby.size >= Hud.TOUCH_MIN)
				end
			end
		end)

		t.it("narrows the phone hotbar to the band and mirrors the rail for the left hand", function()
			local safe = size(640, 282)
			local reserved = HudLayout.reserved(Hud, "touch-phone", true, safe, { jump = { x0 = 545, y0 = 192, x1 = 615, y1 = 262 } })
			local s = HudLayout.scale(Hud, "touch-phone", safe, "default", 6)
			t.eq(s, 1)
			local bar = HudLayout.hotbar(Hud, "touch-phone", s, safe, 6, reserved)
			t.truthy(bar.slotW < Hud.HOTBAR.slot.touch[1] and bar.slotW >= Hud.TOUCH_MIN, "slot " .. bar.slotW)
			t.truthy(HudLayout.fits(hotbarRect(bar), reserved), "six slots between the corners at 640")
			local seven = HudLayout.hotbar(Hud, "touch-phone", s, safe, 7, reserved)
			t.truthy(HudLayout.fits(hotbarRect(seven), reserved), "seven slots between the measured corners at 640")
			local right = HudLayout.rail(Hud, "touch-phone", s, safe, "right", 3, reserved)
			local left = HudLayout.rail(Hud, "touch-phone", s, safe, "left", 3, reserved)
			t.truthy(right.buttons[1].x > 640 / 2 and left.buttons[1].x < 640 / 2)
			t.truthy(right.columns >= 1 and right.columns <= 3)
			t.eq(left.menu.x, Hud.RAIL.margin)
		end)

		t.it("puts Place on the rail side and Cancel opposite, beside the hotbar, on screen", function()
			for _, c in CASES do
				local profile = if c.profile == "desktop" then "touch-tablet" else c.profile
				local reserved = HudLayout.reserved(Hud, profile, true, c.safe)
				local s = HudLayout.scale(Hud, profile, c.safe, "default", 6)
				local bar = HudLayout.hotbar(Hud, profile, s, c.safe, 6, reserved)
				local br = hotbarRect(bar)
				for _, side in { "right", "left" } do
					local pair = HudLayout.placePair(Hud, s, c.safe, br, side)
					for name, b in pair do
						local r = { x0 = b.x, y0 = b.y, x1 = b.x + b.w, y1 = b.y + b.h }
						t.truthy(b.w >= Hud.PRIMARY and b.h >= Hud.PRIMARY, name .. " under PRIMARY: " .. c.name)
						t.truthy(r.x0 >= 0 and r.x1 <= c.safe.x / s + 1e-6 and r.y1 <= c.safe.y / s + 1e-6, name .. " off screen: " .. c.name)
						t.truthy(not HudLayout.overlaps(r, br), name .. " on the hotbar: " .. c.name)
					end
					local placeRight = pair.place.x > pair.cancel.x
					t.eq(placeRight, side == "right", "Place follows the rail side")
				end
			end
		end)

		t.it("recognises taps by slop and time", function()
			local slop, tmax = Hud.PLACE.TAP_SLOP_PX, Hud.PLACE.TAP_MAX_S
			t.truthy(HudLayout.isTap(Hud, 0, 0, 0))
			t.truthy(HudLayout.isTap(Hud, slop, 0, tmax))
			t.eq(HudLayout.isTap(Hud, slop + 0.01, 0, 0.1), false)
			t.eq(HudLayout.isTap(Hud, 0, 0, tmax + 0.01), false)
			t.truthy(HudLayout.isTap(Hud, 8, 8, 0.2), "11.3 px diagonal")
			t.eq(HudLayout.isTap(Hud, 9, 9, 0.2), false, "12.7 px diagonal")
		end)

		t.it("clamps the watchtower pan to the bounds plus the margin at all four edges", function()
			local b = { -74, -42, 74, 32 }
			local m = Hud.CAMERA.BOUNDS_MARGIN
			local x, z = HudLayout.clampPan(-500, 0, b, m)
			t.eq(x, -74 - m)
			x, z = HudLayout.clampPan(500, 0, b, m)
			t.eq(x, 74 + m)
			x, z = HudLayout.clampPan(0, -500, b, m)
			t.eq(z, -42 - m)
			x, z = HudLayout.clampPan(0, 500, b, m)
			t.eq(z, 32 + m)
			x, z = HudLayout.clampPan(10, -5, b, m)
			t.eq(x, 10)
			t.eq(z, -5)
		end)
	end)
end
