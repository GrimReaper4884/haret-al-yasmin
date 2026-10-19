--!strict
-- Checks for the bigger lane's zone table (Config/LaneZones, LP-D00). Pure.

local LaneZoneLogic = {}

-- Whether two { x0, z0, x1, z1 } rectangles share area (touching edges do not count).
function LaneZoneLogic.overlaps(a: { number }, b: { number }): boolean
	return a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]
end

-- The planned part total: what the slice has now plus every zone's budget.
function LaneZoneLogic.plannedParts(current: number, zones: { { budget: number } }): number
	local total = current
	for _, z in zones do
		total += z.budget
	end
	return total
end

-- Pairs of zones that overlap each other or the slice (overhead zones may sit over the slice).
function LaneZoneLogic.conflicts(zones: { any }, existing: { any }, overhead: { [string]: boolean }): { string }
	local out = {}
	for i, a in zones do
		for j = i + 1, #zones do
			local b = zones[j]
			if not overhead[a.id] and not overhead[b.id] and LaneZoneLogic.overlaps(a.bounds, b.bounds) then
				table.insert(out, a.id .. "/" .. b.id)
			end
		end
		if not overhead[a.id] then
			for _, e in existing do
				if LaneZoneLogic.overlaps(a.bounds, e.bounds) then
					table.insert(out, a.id .. "/" .. e.id)
				end
			end
		end
	end
	return out
end

return LaneZoneLogic
