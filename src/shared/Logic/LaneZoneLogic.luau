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

-- A backdrop cell { x0, z0, x1, z1 } trimmed along X so it no longer covers any `zones` rectangle
-- (Skyline roofs give way to a built zone, LP-D03): a zone on the cell's west side pushes its west
-- edge out past the zone (+ `gap`), one on its east side pulls its east edge in; nil when the cell
-- is left narrower than `minWidth` or the zone spans it.
function LaneZoneLogic.clipX(cell: { number }, zones: { { number } }, gap: number, minWidth: number): { number }?
	local x0, z0, x1, z1 = cell[1], cell[2], cell[3], cell[4]
	for _, b in zones do
		if LaneZoneLogic.overlaps({ x0, z0, x1, z1 }, b) then
			if b[3] < x1 and b[1] <= x0 then
				x0 = b[3] + gap
			elseif b[1] > x0 and b[3] >= x1 then
				x1 = b[1] - gap
			else
				return nil
			end
		end
	end
	if x1 - x0 < minWidth then
		return nil
	end
	return { x0, z0, x1, z1 }
end

-- Whether zone `id` is built (an unknown id is not). The slice's modules ask this before opening a
-- passage into a zone (LP-D03 souq, LP-D04 hammam).
-- (`zones` is Config/LaneZones.zones; `any` because Luau tables are invariant and Zone has more fields)
function LaneZoneLogic.built(zones: { any }, id: string): boolean
	for _, z in zones do
		if z.id == id then
			return z.built
		end
	end
	return false
end

return LaneZoneLogic
