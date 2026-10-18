--!nocheck
-- Placement flow (docs/MOBILE_HUD_PLAN.md MH-06): touch aims and the Place button commits, a click
-- or a quick-place tap commits at once; and the client-shaped match view PlacementController builds
-- gives TdTowers.canPlace the same answers the server gets, on a two-road arena.

return function(t)
	local PlaceFlow = t.logic("PlaceFlow")
	local TdTowers = t.logic("TdTowers")
	local Path = t.logic("Path")
	local Arenas = t.config("Arenas")
	local TD = t.config("TD")
	local Units = t.config("Units")
	local Traits = t.config("Traits")

	local TOUCH = { touch = true, quickPlace = false }
	local QUICK = { touch = true, quickPlace = true }
	local MOUSE = { touch = false, quickPlace = false }
	local GOOD = { valid = true, x = 10, z = 4 }
	local BAD = { valid = false, reason = "on_path", x = 0, z = 0 }

	local function kinds(actions)
		local out = {}
		for _, a in actions do
			table.insert(out, a.kind)
		end
		return table.concat(out, ",")
	end
	local function aimingAt(unitId)
		local f = PlaceFlow.step(PlaceFlow.new(), { type = "pick", unitId = unitId, affordable = true }, MOUSE)
		return f
	end

	t.describe("PlaceFlow", function()
		t.it("picks a unit into aiming with a ghost", function()
			local f, a = PlaceFlow.step(PlaceFlow.new(), { type = "pick", unitId = "natour", affordable = true }, TOUCH)
			t.eq(f.mode, "aiming")
			t.eq(f.unitId, "natour")
			t.eq(kinds(a), "showGhost")
		end)

		t.it("never commits on a touch tap without quick place", function()
			local f = aimingAt("natour")
			for _, c in { GOOD, BAD, { valid = false, tower = 3 } } do
				local g, a = PlaceFlow.step(f, { type = "tap", screen = 1, check = c }, TOUCH)
				t.eq(g.mode, "aiming")
				t.eq(kinds(a), "moveGhost", "a touch tap only moves the ghost")
			end
		end)

		t.it("commits a valid quick-place tap and a valid click once", function()
			for _, flags in { QUICK, MOUSE } do
				local f, a = PlaceFlow.step(aimingAt("natour"), { type = "tap", screen = 1, check = GOOD }, flags)
				t.eq(f.mode, "committing")
				local commits = 0
				for _, x in a do
					if x.kind == "commit" then
						commits += 1
						t.eq(x.unitId, "natour")
						t.eq(x.x, 10)
						t.eq(x.z, 4)
					end
				end
				t.eq(commits, 1)
				local last = a[#a]
				t.eq(last.kind, "clear", "the ghost clears after the commit")
			end
		end)

		t.it("an invalid quick-place tap shows the reason and keeps aiming", function()
			local f, a = PlaceFlow.step(aimingAt("natour"), { type = "tap", screen = 1, check = BAD }, QUICK)
			t.eq(f.mode, "aiming")
			t.eq(kinds(a), "moveGhost,toast")
			t.eq(a[2].reason, "on_path")
		end)

		t.it("Place commits the aimed spot, or says why not and keeps aiming", function()
			local f = PlaceFlow.step(aimingAt("natour"), { type = "move", screen = 1, check = BAD }, TOUCH)
			local g, a = PlaceFlow.step(f, { type = "place" }, TOUCH)
			t.eq(g.mode, "aiming")
			t.eq(kinds(a), "toast")
			t.eq(a[1].reason, "on_path")
			f = PlaceFlow.step(f, { type = "tap", screen = 2, check = GOOD }, TOUCH)
			g, a = PlaceFlow.step(f, { type = "place" }, TOUCH)
			t.eq(g.mode, "committing")
			t.eq(kinds(a), "commit,clear")
			local h, b = PlaceFlow.step(g, { type = "done", ok = true }, TOUCH)
			t.eq(h.mode, "idle")
			t.eq(kinds(b), "")
		end)

		t.it("a server refusal toasts and returns to idle", function()
			local f = PlaceFlow.step(aimingAt("natour"), { type = "tap", check = GOOD }, MOUSE)
			local g, a = PlaceFlow.step(f, { type = "done", ok = false, reason = "too_close" }, MOUSE)
			t.eq(g.mode, "idle")
			t.eq(kinds(a), "toast")
		end)

		t.it("picking the same unit again cancels; another unit swaps the ghost", function()
			local f = aimingAt("natour")
			local g, a = PlaceFlow.step(f, { type = "pick", unitId = "natour", affordable = true }, TOUCH)
			t.eq(g.mode, "idle")
			t.eq(kinds(a), "clear")
			g, a = PlaceFlow.step(f, { type = "pick", unitId = "qahwaji", affordable = true }, TOUCH)
			t.eq(g.mode, "aiming")
			t.eq(g.unitId, "qahwaji")
			t.eq(kinds(a), "clear,showGhost")
		end)

		t.it("cannot_afford on pick toasts and stays idle", function()
			local f, a = PlaceFlow.step(PlaceFlow.new(), { type = "pick", unitId = "natour", affordable = false }, TOUCH)
			t.eq(f.mode, "idle")
			t.eq(kinds(a), "toast")
			t.eq(a[1].reason, "cannot_afford")
		end)

		t.it("cancel and long press clear the ghost", function()
			for _, ev in { "cancel", "longPress" } do
				local f, a = PlaceFlow.step(aimingAt("natour"), { type = ev }, TOUCH)
				t.eq(f.mode, "idle")
				t.eq(kinds(a), "clear")
			end
			local f, a = PlaceFlow.step(PlaceFlow.new(), { type = "cancel" }, TOUCH)
			t.eq(f.mode, "idle")
			t.eq(kinds(a), "", "nothing to cancel")
		end)

		t.it("selecting a defender while aiming clears the ghost first", function()
			local f, a = PlaceFlow.step(aimingAt("natour"), { type = "selectTower", id = 7 }, TOUCH)
			t.eq(f.mode, "idle")
			t.eq(kinds(a), "clear,select")
			t.eq(a[2].id, 7)
			-- A click on a defender while placing (the old mouse rule) does the same.
			f, a = PlaceFlow.step(aimingAt("natour"), { type = "tap", check = { valid = false, reason = "too_close", tower = 7 } }, MOUSE)
			t.eq(f.mode, "idle")
			t.eq(kinds(a), "clear,select")
		end)

		t.it("an idle tap selects what is under it (nil clears)", function()
			local f, a = PlaceFlow.step(PlaceFlow.new(), { type = "tap", check = { valid = false, tower = 4 } }, MOUSE)
			t.eq(f.mode, "idle")
			t.eq(kinds(a), "select")
			t.eq(a[1].id, 4)
			f, a = PlaceFlow.step(PlaceFlow.new(), { type = "tap", check = { valid = false } }, MOUSE)
			t.eq(a[1].id, nil)
		end)

		t.it("a touch tap on empty ground keeps the selection; on a defender it switches (MH-08)", function()
			for _, flags in { TOUCH, QUICK } do
				local f, a = PlaceFlow.step(PlaceFlow.new(), { type = "tap", check = { valid = false, x = 1, z = 2 } }, flags)
				t.eq(f.mode, "idle")
				t.eq(kinds(a), "", "nothing deselects")
				f, a = PlaceFlow.step(PlaceFlow.new(), { type = "tap", check = { valid = false, tower = 9 } }, flags)
				t.eq(kinds(a), "select")
				t.eq(a[1].id, 9)
			end
		end)
	end)

	t.describe("client-shaped canPlace", function()
		-- What PlacementController builds from MatchState, towerPlaced events and Path.buildAll.
		local arena = Arenas.twin_gates
		t.truthy(arena.paths and #arena.paths == 2, "twin_gates has two roads")
		local rules = {
			bounds = arena.bounds,
			pathHalfWidth = TD.PATH_HALF_WIDTH,
			spacing = TD.TOWER_SPACING,
			towerCap = TD.TOWER_CAP,
			sellRefund = TD.SELL_REFUND,
			starBonus = TD.STAR_BONUS,
			traitCaps = Traits.caps,
		}
		local unitId = "natour"
		local def = Units[unitId]
		local function view(cash, towers)
			return { players = { me = { cash = cash } }, phase = "prep", paths = Path.buildAll(arena), towers = towers or {} }
		end

		t.it("rejects both roads, the bounds, spacing and caps with the server's reasons", function()
			local roadA, roadB = arena.paths[1][2], arena.paths[2][2] -- a corner on each road
			local ok, why = TdTowers.canPlace(view(9999), "me", unitId, def, roadA[1], roadA[2], rules)
			t.eq(ok, false)
			t.eq(why, "on_path")
			ok, why = TdTowers.canPlace(view(9999), "me", unitId, def, roadB[1], roadB[2], rules)
			t.eq(why, "on_path", "the second road counts too")
			ok, why = TdTowers.canPlace(view(9999), "me", unitId, def, arena.bounds[3] + 5, 0, rules)
			t.eq(why, "out_of_bounds")
			-- A legal spot: off both roads, inside the bounds.
			local spot
			for x = arena.bounds[1] + 2, arena.bounds[3] - 2, 2 do
				for z = arena.bounds[2] + 2, arena.bounds[4] - 2, 2 do
					if not spot and Path.distanceToAll(Path.buildAll(arena), x, z) > TD.PATH_HALF_WIDTH + 1 then
						spot = { x, z }
					end
				end
			end
			t.truthy(spot, "found a free spot")
			ok, why = TdTowers.canPlace(view(9999), "me", unitId, def, spot[1], spot[2], rules)
			t.truthy(ok, tostring(why))
			ok, why = TdTowers.canPlace(view(0), "me", unitId, def, spot[1], spot[2], rules)
			t.eq(why, "cannot_afford")
			local near = { { owner = "other", unitId = "qahwaji", x = spot[1] + 0.5, z = spot[2] } }
			ok, why = TdTowers.canPlace(view(9999, near), "me", unitId, def, spot[1], spot[2], rules)
			t.eq(why, "too_close")
			local mine = {}
			for i = 1, def.maxPlaced do
				table.insert(mine, { owner = "me", unitId = unitId, x = 9000 + i * 100, z = 0 })
			end
			ok, why = TdTowers.canPlace(view(9999, mine), "me", unitId, def, spot[1], spot[2], rules)
			t.eq(why, "unit_cap")
			local v = view(9999)
			v.phase = "won"
			ok, why = TdTowers.canPlace(v, "me", unitId, def, spot[1], spot[2], rules)
			t.eq(why, "match_over")
		end)
	end)
end
