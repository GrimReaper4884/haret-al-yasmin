--!strict
-- Where arena dressing goes (POLISH_PLAN PV-E03): kerb props along the road and wires across it.
-- Deterministic for a given road, so every match of an arena looks the same. Pure.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require
	return dynamicRequire((script :: any).Parent[name])
end

local Path = sibling("Path")

local ArenaDressing = {}

export type Spot = { x: number, z: number, yaw: number, side: number }

-- Spots beside the road: walking each segment from `margin` to `length - margin` every `every`
-- studs, alternating sides at `inset` from the centreline. A spot that would sit on another stretch
-- of road (closer than `inset` to any part of the path) or within `spawnClear` of `spawn` is skipped.
function ArenaDressing.kerbSpots(pts: { { number } }, cfg: any, spawn: { number }?): { Spot }
	local path = Path.build(pts)
	local out: { Spot } = {}
	local side = 1
	for i = 1, #pts - 1 do
		local ax, az = pts[i][1], pts[i][2]
		local bx, bz = pts[i + 1][1], pts[i + 1][2]
		local dx, dz = bx - ax, bz - az
		local len = math.sqrt(dx * dx + dz * dz)
		if len > 2 * cfg.margin then
			local ux, uz = dx / len, dz / len
			local nx, nz = -uz, ux -- left normal
			local d = cfg.margin
			while d <= len - cfg.margin + 1e-9 do
				local x = ax + ux * d + nx * cfg.inset * side
				local z = az + uz * d + nz * cfg.inset * side
				local clearOfRoad = Path.distanceTo(path, x, z) >= cfg.inset - 1e-6
				local clearOfSpawn = spawn == nil
					or (x - spawn[1]) ^ 2 + (z - spawn[2]) ^ 2 >= cfg.spawnClear * cfg.spawnClear
				if clearOfRoad and clearOfSpawn then
					table.insert(out, { x = x, z = z, yaw = math.atan2(-ux, -uz), side = side })
				end
				side = -side
				d += cfg.every
			end
		end
	end
	return out
end

-- A wire across segment `seg` at fraction `t` along it: the two post positions and the midpoint.
function ArenaDressing.wire(
	pts: { { number } },
	seg: number,
	t: number,
	inset: number
): (number, number, number, number, number, number)
	local a, b = pts[seg], pts[seg + 1]
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local len = math.sqrt(dx * dx + dz * dz)
	local mx, mz = a[1] + dx * t, a[2] + dz * t
	local nx, nz = -dz / len, dx / len
	return mx - nx * inset, mz - nz * inset, mx + nx * inset, mz + nz * inset, mx, mz
end

-- House-block spots along the outside of the bounds: every `every` studs on each edge, centred
-- `out` studs beyond the edge, skipping any within `clearStart` of the road's first point or
-- `clearEnd` of its last. Returns x, z and the yaw that faces the field.
function ArenaDressing.houseSpots(
	bounds: { number },
	pts: { { number } },
	every: number,
	out: number,
	clearStart: number,
	clearEnd: number
): { Spot }
	local x0, z0, x1, z1 = bounds[1], bounds[2], bounds[3], bounds[4]
	local first, last = pts[1], pts[#pts]
	local spots: { Spot } = {}
	local function add(x: number, z: number, yaw: number)
		if (x - first[1]) ^ 2 + (z - first[2]) ^ 2 < clearStart * clearStart then
			return
		end
		if (x - last[1]) ^ 2 + (z - last[2]) ^ 2 < clearEnd * clearEnd then
			return
		end
		table.insert(spots, { x = x, z = z, yaw = yaw, side = 0 })
	end
	local x = x0 + every / 2
	while x < x1 do
		add(x, z1 + out, 0) -- north edge: the front faces -Z, into the field
		add(x, z0 - out, math.pi) -- south edge faces +Z
		x += every
	end
	local z = z0 + every / 2
	while z < z1 do
		add(x0 - out, z, -math.pi / 2) -- west edge faces +X
		add(x1 + out, z, math.pi / 2) -- east edge faces -X
		z += every
	end
	return spots
end

return ArenaDressing
