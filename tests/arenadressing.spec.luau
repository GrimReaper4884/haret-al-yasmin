--!nocheck
-- Arena dressing (POLISH_PLAN PV-E03): kerb props stay off the road and the spawn, wires span the
-- road, house fronts stay outside the field and clear of both gates, themes are complete, and the
-- Rival Lane walks exactly the orchard's road (so balance is untouched).

return function(t)
	local ArenaDressing = t.logic("ArenaDressing")
	local Path = t.logic("Path")
	local Arenas = t.config("Arenas")
	local ArenaThemes = t.config("ArenaThemes")
	local Modes = t.config("Modes")
	local TD = t.config("TD")
	local PropPlacements = t.config("PropPlacements")

	t.describe("ArenaDressing", function()
		t.it("every arena names a complete theme", function()
			local keys = {
				"ground",
				"groundMaterial",
				"field",
				"fieldMaterial",
				"wall",
				"road",
				"kerb",
				"gateStone",
				"produce",
			}
			for id, def in Arenas do
				local th = ArenaThemes.themes[def.theme]
				t.truthy(th ~= nil, id .. " has a theme")
				for _, k in keys do
					t.truthy(th[k] ~= nil, id .. " theme has " .. k)
				end
				t.truthy(#th.produce >= 1)
			end
		end)

		t.it("Episode 2 plays the Rival Lane on the orchard's exact road", function()
			t.eq(Modes.ep2.arena, "rival_lane")
			local o, r = Arenas.orchard, Arenas.rival_lane
			t.eq(#r.path, #o.path)
			for i, p in o.path do
				t.eq(r.path[i][1], p[1])
				t.eq(r.path[i][2], p[2])
			end
			for i = 1, 4 do
				t.eq(r.bounds[i], o.bounds[i])
			end
			t.eq(r.playerSpawn[1], o.playerSpawn[1])
			t.eq(r.playerSpawn[2], o.playerSpawn[2])
			t.eq(ArenaThemes.themes[r.theme].houses, true)
		end)

		t.it(
			"kerb props sit beside the road, never on it, never on the party spawn, inside the field",
			function()
				local k = ArenaThemes.kerb
				t.truthy(k.inset > TD.PATH_HALF_WIDTH, "beyond the road's half width")
				for id, def in Arenas do
					local path = Path.build(def.path)
					local spots = ArenaDressing.kerbSpots(def.path, k, def.playerSpawn)
					t.truthy(#spots >= 8, id .. " gets some kerb props")
					t.truthy(#spots <= 40, id .. " stays sparse")
					local b = def.bounds
					for _, s in spots do
						t.truthy(Path.distanceTo(path, s.x, s.z) >= k.inset - 1e-6, "off the road")
						local sp = def.playerSpawn
						t.truthy((s.x - sp[1]) ^ 2 + (s.z - sp[2]) ^ 2 >= k.spawnClear ^ 2, "off the spawn")
						t.truthy(
							s.x >= b[1] and s.x <= b[3] and s.z >= b[2] and s.z <= b[4],
							"inside the field"
						)
					end
					-- Deterministic
					local again = ArenaDressing.kerbSpots(def.path, k, def.playerSpawn)
					t.eq(#again, #spots)
					t.eq(again[1].x, spots[1].x)
				end
			end
		)

		t.it("wires span the road with a post on each side", function()
			local w = ArenaThemes.wires
			for id, def in Arenas do
				local path = Path.build(def.path)
				for _, spot in def.wires or {} do
					t.truthy(spot.seg >= 1 and spot.seg < #def.path, id .. " wire segment exists")
					local ax, az, bx, bz, mx, mz = ArenaDressing.wire(def.path, spot.seg, spot.t, w.inset)
					t.truthy(Path.distanceTo(path, mx, mz) < 1e-6, "lantern hangs over the road")
					t.truthy(
						((ax - bx) ^ 2 + (az - bz) ^ 2) ^ 0.5 - 2 * w.inset < 1e-6,
						"posts on opposite sides"
					)
					t.truthy(Path.distanceTo(path, ax, az) > TD.PATH_HALF_WIDTH, "post a clear of the road")
					t.truthy(Path.distanceTo(path, bx, bz) > TD.PATH_HALF_WIDTH, "post b clear of the road")
				end
			end
		end)

		t.it("house fronts ring the field outside its wall and keep clear of both gates", function()
			local h = ArenaThemes.houses
			local def = Arenas.rival_lane
			local b = def.bounds
			local out = 2.2 + 1.2 + h.depth / 2
			local spots = ArenaDressing.houseSpots(b, def.path, h.every, out, h.clearStart, h.clearEnd)
			t.truthy(#spots >= 20, "a street's worth of houses")
			local first, last = def.path[1], def.path[#def.path]
			for _, s in spots do
				local inside = s.x > b[1] and s.x < b[3] and s.z > b[2] and s.z < b[4]
				t.eq(inside, false, "outside the field")
				t.truthy(
					(s.x - first[1]) ^ 2 + (s.z - first[2]) ^ 2 >= h.clearStart ^ 2,
					"clear of their gate"
				)
				t.truthy((s.x - last[1]) ^ 2 + (s.z - last[2]) ^ 2 >= h.clearEnd ^ 2, "clear of our gate")
				-- Faces the field: one step along its look vector gets closer to the centre
				local cx, cz = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
				local lx, lz = -math.sin(s.yaw), -math.cos(s.yaw)
				local before = (s.x - cx) ^ 2 + (s.z - cz) ^ 2
				local after = (s.x + lx - cx) ^ 2 + (s.z + lz - cz) ^ 2
				t.truthy(after < before, "front faces the field")
			end
		end)

		t.it("Meshy prop swaps (PV-E04) name the three new props with sane heights", function()
			local want = { "hanging_lantern", "market_bundle", "jasmine_pot" }
			for _, name in want do
				local sw = PropPlacements.swaps[name]
				t.truthy(sw ~= nil, name .. " has a swap")
				t.truthy(sw.height > 0.5 and sw.height < 4, name .. " height is prop-sized")
			end
		end)

		t.it("orchard_kit is the orchard look without the generated gardens", function()
			local o, k = ArenaThemes.themes.orchard, ArenaThemes.themes.orchard_kit
			t.eq(k.gardens, false)
			t.eq(o.gardens, nil, "the orchard keeps its gardens")
			for _, key in
				{
					"ground",
					"groundMaterial",
					"field",
					"fieldMaterial",
					"wall",
					"road",
					"kerb",
					"gateStone",
					"trees",
					"houses",
				}
			do
				t.eq(k[key], o[key], key .. " matches the orchard")
			end
		end)
	end)
end
