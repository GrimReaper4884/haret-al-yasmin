--!nocheck
-- Auto Play and layout codes (BUILD_PLAN P3-06): the planner players switch on, and the codes that
-- share a layout. Malformed codes are refused; Auto Play clears Episode 1 Normal with re6up.

return function(t)
	local AutoPlay = _G.LogicRequire("AutoPlay")
	local LayoutCode = _G.LogicRequire("LayoutCode")
	local Path = _G.LogicRequire("Path")
	local TD = t.config("TD")
	local Units = t.config("Units")
	local Arenas = t.config("Arenas")
	local AutoBattle = require("./autobattle")

	local limits = { arenas = Arenas, maxSlots = TD.LOADOUT_SLOTS + 1, towerCap = TD.TOWER_CAP }

	t.describe("Auto Play", function()
		t.it("plans one of each loadout unit cheapest first, then more copies up to maxPlaced and the tower cap", function()
			local loadout = { "mukhtar", "hallaq", "walad", "natour", "qabaday", "haddad" }
			local plan = AutoPlay.planFor(loadout, Units, TD.TOWER_CAP)
			local seen = {}
			for i = 1, #loadout do
				t.truthy(not seen[plan[i]], "first pass: one of each")
				seen[plan[i]] = true
				if i > 1 then
					t.truthy(Units[plan[i - 1]].levels[1].cost <= Units[plan[i]].levels[1].cost, "cheapest first")
				end
			end
			t.truthy(#plan <= TD.TOWER_CAP, "never above the tower cap")
			local count = {}
			for _, id in plan do
				count[id] = (count[id] or 0) + 1
			end
			for id, n in count do
				t.truthy(n <= Units[id].maxPlaced, id .. " within maxPlaced")
			end
			t.eq(#AutoPlay.planFor({}, Units, TD.TOWER_CAP), 0, "empty loadout, empty plan")
			t.eq(#AutoPlay.planFor({ "nobody" }, Units, TD.TOWER_CAP), 0, "unknown ids are skipped")
		end)

		t.it("switching it on again continues from the towers you already have", function()
			local plan = { "khayyat", "walad", "khayyat", "hallaq", "khayyat" }
			local towers = {
				{ owner = "me", unitId = "khayyat" },
				{ owner = "me", unitId = "khayyat" },
				{ owner = "other", unitId = "walad" },
			}
			local left = AutoPlay.remaining(plan, towers, "me")
			t.eq(#left, 3)
			t.eq(left[1], "walad", "another player's walad does not count")
			t.eq(left[2], "hallaq")
			t.eq(left[3], "khayyat", "the third copy is still to place")
			t.eq(#AutoPlay.remaining(plan, {}, "me"), #plan)
		end)

		t.it("with an anchor, every spot it picks is within the radius", function()
			local arena = Arenas.orchard
			local spots = AutoPlay.spots(arena, TD.PATH_HALF_WIDTH)
			local road = Path.buildAll(arena)[1]
			local ax, az = Path.position(road, road.length / 2)
			local anchor = { x = ax, z = az }
			local state = { towers = {} }
			local spot = AutoPlay.bestSpot(state, spots, Units.hallaq, TD.TOWER_SPACING, anchor, TD.AUTO_PLAY.anchorRadius)
			t.truthy(spot, "a spot near the road's middle")
			t.truthy((spot.x - ax) ^ 2 + (spot.z - az) ^ 2 <= TD.AUTO_PLAY.anchorRadius ^ 2, "inside the radius")
			local far = AutoPlay.bestSpot(state, spots, Units.hallaq, TD.TOWER_SPACING, { x = 1e5, z = 1e5 }, TD.AUTO_PLAY.anchorRadius)
			t.eq(far, nil, "an anchor far off the map finds nothing")
		end)

		t.it("a player's Auto Play (planFor re6, anchored mid-road) clears Episode 1 Normal with upgrades (re6up)", function()
			local loadout = AutoBattle.POLICIES.re6up.plan
			local plan = AutoPlay.planFor(loadout, Units, TD.TOWER_CAP)
			local road = Path.buildAll(Arenas.orchard)[1]
			local ax, az = Path.position(road, road.length / 2)
			local r = AutoBattle.play("ep1", "normal", { plan = plan, upgrades = true }, {
				raw = true,
				anchor = { x = ax, z = az },
				anchorRadius = TD.AUTO_PLAY.anchorRadius,
			})
			t.truthy(r.won, string.format("won (gate %d/%d, waves %d)", r.gateHp, r.gateMax, r.wavesCleared))
		end)

		t.it("never fires an ability (the planner only places and upgrades)", function()
			local fired = 0
			local state = { players = { p = { cash = 1e6 } }, towers = {} }
			local spots = AutoPlay.spots(Arenas.orchard, TD.PATH_HALF_WIDTH)
			local nextId = 0
			AutoPlay.think({ key = "p", policy = { plan = { "hallaq" }, upgrades = true }, planIndex = 1 }, state, spots, Units, TD.TOWER_SPACING, {
				place = function(unitId, x, z)
					nextId += 1
					table.insert(state.towers, { id = nextId, owner = "p", unitId = unitId, x = x, z = z, level = 1, stats = { damage = 1 } })
					return true
				end,
				upgrade = function(tower)
					if tower.level >= #Units[tower.unitId].levels then
						return false
					end
					tower.level += 1
					return true
				end,
				useAbility = function()
					fired += 1
				end,
			})
			t.eq(fired, 0)
			t.eq(#state.towers, 1)
			t.eq(state.towers[1].level, #Units.hallaq.levels, "upgraded to the top with endless cash")
		end)
	end)

	t.describe("Layout codes", function()
		local entries = { { slot = 1, x = 10.5, z = -4 }, { slot = 6, x = -73, z = 31.5 }, { slot = 2, x = 0, z = 0 } }

		t.it("round-trips the arena, the slots and half-stud positions", function()
			local code = LayoutCode.encode("orchard", entries)
			t.truthy(string.sub(code, 1, 4) == "HY1-" and #code <= LayoutCode.MAX_LEN)
			local layout, err = LayoutCode.decode(code, limits)
			t.truthy(layout, tostring(err))
			t.eq(layout.arena, "orchard")
			t.eq(#layout.entries, 3)
			for i, e in entries do
				t.eq(layout.entries[i].slot, e.slot)
				t.eq(layout.entries[i].x, e.x)
				t.eq(layout.entries[i].z, e.z)
			end
		end)

		t.it("a full 20-tower layout on every arena fits MAX_LEN and decodes", function()
			for arenaId, arena in Arenas do
				local many = {}
				for i = 1, TD.TOWER_CAP do
					table.insert(many, { slot = (i % 6) + 1, x = arena.bounds[1], z = arena.bounds[4] })
				end
				local code = LayoutCode.encode(arenaId, many)
				t.truthy(#code <= LayoutCode.MAX_LEN, arenaId .. " " .. #code)
				local layout = LayoutCode.decode(code, limits)
				t.truthy(layout and #layout.entries == TD.TOWER_CAP, arenaId)
			end
		end)

		t.it("refuses malformed codes", function()
			local good = LayoutCode.encode("orchard", entries)
			local cases = {
				{ nil, "bad_code" },
				{ 42, "bad_code" },
				{ {}, "bad_code" },
				{ "", "bad_code" },
				{ "HY1-", "bad_code" },
				{ "XX1-" .. string.sub(good, 5), "bad_code" },
				{ good .. string.rep("A", LayoutCode.MAX_LEN), "bad_code" },
				{ "HY1-!!!!", "bad_code" },
				{ "HY1-A", "bad_code" },
				{ string.sub(good, 1, #good - 4), "bad_code" }, -- truncated
				{ good .. "AAAA", "bad_code" }, -- trailing bytes
				{ LayoutCode.encode("nowhere", entries), "unknown_arena" },
				{ LayoutCode.encode("Orchard", entries), "bad_code" }, -- not an identifier
				{ LayoutCode.encode("orchard", { { slot = 0, x = 0, z = 0 } }), "bad_slot" },
				{ LayoutCode.encode("orchard", { { slot = TD.LOADOUT_SLOTS + 2, x = 0, z = 0 } }), "bad_slot" },
				{ LayoutCode.encode("orchard", { { slot = 1, x = 500, z = 0 } }), "out_of_bounds" },
				{ LayoutCode.encode("orchard", { { slot = 1, x = 0, z = -500 } }), "out_of_bounds" },
			}
			local tooMany = {}
			for i = 1, TD.TOWER_CAP + 1 do
				tooMany[i] = { slot = 1, x = 0, z = 0 }
			end
			table.insert(cases, { LayoutCode.encode("orchard", tooMany), "too_many" })
			for i, c in cases do
				local layout, err = LayoutCode.decode(c[1], limits)
				t.eq(layout, nil, "case " .. i .. " decoded")
				t.eq(err, c[2], "case " .. i)
			end
			-- a wrong version byte: flip the first payload character
			local v2 = "HY1-B" .. string.sub(good, 6) -- version byte 1 -> 5
			local layout, err = LayoutCode.decode(v2, limits)
			t.eq(layout, nil)
			t.eq(err, "bad_version")
		end)

		t.it("reads slots against the importer's loadout and skips empty slots", function()
			local layout = LayoutCode.decode(LayoutCode.encode("orchard", entries), limits)
			local plan, spots = LayoutCode.toPlan(layout, { "walad", "hallaq", "natour" })
			t.eq(#plan, 2, "slot 6 is empty in a 3-unit loadout")
			t.eq(plan[1], "walad")
			t.eq(plan[2], "hallaq")
			t.eq(spots[2].x, 0)
		end)
	end)
end
