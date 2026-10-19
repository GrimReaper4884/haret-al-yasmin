--!nocheck
-- The bigger lane's zone table (Config/LaneZones, Logic/LaneZoneLogic; LOOK_AND_PLAY_PLAN LP-D00).

return function(t)
	local LaneZones = t.config("LaneZones")
	local LaneZoneLogic = t.logic("LaneZoneLogic")

	-- The slice's measured part count when LP-D00 landed ([World] built … in Studio).
	local SLICE_PARTS = 1423

	t.describe("Lane zones (LP-D00)", function()
		t.it("rectangles overlap only when they share area", function()
			t.eq(LaneZoneLogic.overlaps({ 0, 0, 10, 10 }, { 5, 5, 15, 15 }), true)
			t.eq(LaneZoneLogic.overlaps({ 0, 0, 10, 10 }, { 10, 0, 20, 10 }), false, "touching edges")
			t.eq(LaneZoneLogic.overlaps({ 0, 0, 10, 10 }, { 20, 20, 30, 30 }), false)
		end)

		t.it("no new zone overlaps another or the slice (overhead zones excepted)", function()
			local c = LaneZoneLogic.conflicts(LaneZones.zones, LaneZones.existing, LaneZones.overhead)
			t.eq(#c, 0, "conflicts: " .. table.concat(c, ", "))
		end)

		t.it("every zone is well-formed and inside its own budget cap", function()
			local seen = {}
			for _, z in LaneZones.zones do
				t.truthy(not seen[z.id], z.id .. " is unique")
				seen[z.id] = true
				t.truthy(string.match(z.id, "^[a-z_]+$"), z.id .. " is lower_snake")
				t.truthy(string.match(z.module, "^%u%a+$"), z.id .. " module is PascalCase")
				local b = z.bounds
				t.truthy(b[1] < b[3] and b[2] < b[4], z.id .. " bounds are ordered")
				t.truthy(z.budget > 0 and z.budget <= LaneZones.ZONE_MAX, z.id .. " budget")
				t.truthy(string.match(z.task, "^LP%-D%d%d$"), z.id .. " names its task")
			end
		end)

		t.it("the slice plus every planned zone fits the lobby budget", function()
			local planned = LaneZoneLogic.plannedParts(SLICE_PARTS, LaneZones.zones)
			t.truthy(planned <= LaneZones.PART_BUDGET, "planned " .. planned .. " of " .. LaneZones.PART_BUDGET)
			t.truthy(LaneZones.STREAM_BUDGET < LaneZones.PART_BUDGET)
		end)
	end)
end
