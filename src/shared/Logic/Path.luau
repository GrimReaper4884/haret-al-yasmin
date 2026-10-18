--!strict
-- Polyline math for enemy paths. Pure (no Roblox datatypes) so it runs in Lune tests and on
-- both server (simulation) and client (rendering).

export type Path = {
	pts: { { number } }, -- { x, z }
	cum: { number }, -- cumulative length at each point
	length: number,
}

local Path = {}

function Path.build(points: { { number } }): Path
	local cum = { 0 }
	local total = 0
	for i = 2, #points do
		local dx = points[i][1] - points[i - 1][1]
		local dz = points[i][2] - points[i - 1][2]
		total += math.sqrt(dx * dx + dz * dz)
		cum[i] = total
	end
	return { pts = points, cum = cum, length = total }
end

-- Position and unit direction at `dist` along the path (clamped to the ends).
function Path.position(path: Path, dist: number): (number, number, number, number)
	local pts, cum = path.pts, path.cum
	local n = #pts
	if n == 1 then
		return pts[1][1], pts[1][2], 0, -1
	end
	dist = math.clamp(dist, 0, path.length)
	-- Find the segment (linear scan: paths have < 20 points)
	local i = 1
	while i < n - 1 and cum[i + 1] < dist do
		i += 1
	end
	local a, b = pts[i], pts[i + 1]
	local segLen = cum[i + 1] - cum[i]
	local t = if segLen > 0 then (dist - cum[i]) / segLen else 0
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local len = math.sqrt(dx * dx + dz * dz)
	local ux, uz = if len > 0 then dx / len else 0, if len > 0 then dz / len else -1
	return a[1] + dx * t, a[2] + dz * t, ux, uz
end

-- Every road of an arena: `paths` (two or more polylines that end at the same gate, twin-gate
-- arenas, STORY_PLAN §10.1) or the single `path`. Built.
function Path.buildAll(arena: { path: { { number } }, paths: { { { number } } }? }): { Path }
	local out = {}
	local roads: { { { number } } } = arena.paths or { arena.path }
	for _, pts in roads do
		table.insert(out, Path.build(pts))
	end
	return out
end

-- Where two roads merge: the distance along each at their first shared point (they share every
-- point after it, up to the gate). nil when they never meet.
function Path.merge(a: Path, b: Path): (number?, number?)
	for i, p in a.pts do
		for j, q in b.pts do
			if p[1] == q[1] and p[2] == q[2] then
				return a.cum[i], b.cum[j]
			end
		end
	end
	return nil, nil
end

-- Shortest distance from a point to any of several roads.
function Path.distanceToAll(paths: { Path }, x: number, z: number): number
	local best = math.huge
	for _, p in paths do
		best = math.min(best, Path.distanceTo(p, x, z))
	end
	return best
end

-- Shortest distance from a point to the polyline.
function Path.distanceTo(path: Path, x: number, z: number): number
	local best = math.huge
	local pts = path.pts
	for i = 1, #pts - 1 do
		local ax, az = pts[i][1], pts[i][2]
		local bx, bz = pts[i + 1][1], pts[i + 1][2]
		local dx, dz = bx - ax, bz - az
		local len2 = dx * dx + dz * dz
		local t = if len2 > 0 then math.clamp(((x - ax) * dx + (z - az) * dz) / len2, 0, 1) else 0
		local px, pz = ax + dx * t, az + dz * t
		local d = math.sqrt((x - px) ^ 2 + (z - pz) ^ 2)
		if d < best then
			best = d
		end
	end
	if #pts == 1 then
		best = math.sqrt((x - pts[1][1]) ^ 2 + (z - pts[1][2]) ^ 2)
	end
	return best
end

return Path
