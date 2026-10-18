--!strict
-- Match arenas. Pure data. Coordinates are LOCAL to the arena origin (ground Y = 0); the server
-- places each arena at its own offset. The path is a polyline the enemies walk from `path[1]`
-- (the road outside) to the last point (the lane gate). Towers may be placed anywhere inside
-- `bounds` that is farther than TD.PATH_HALF_WIDTH from the path.

export type ArenaDef = {
	nameKey: string,
	path: { { number } }, -- { x, z }
	bounds: { number }, -- x0, z0, x1, z1
	gateYaw: number, -- degrees the gate faces (0 = -Z)
	spawnYaw: number,
	playerSpawn: { number }, -- x, z where the party appears
	seed: string,
	theme: string, -- key in Config/ArenaThemes.themes (looks only)
	wires: { { seg: number, t: number } }?, -- lanterns on wires across road segment `seg` at fraction `t`
}

-- The orchard road (Episode 1). "The Rival Lane" (Episode 2) walks the very same road so balance
-- is untouched; only its theme differs (POLISH_PLAN PV-E03, DECISIONS D-033).
local ORCHARD_PATH = {
	{ -64, -34 },
	{ -64, 12 },
	{ -28, 12 },
	{ -28, -18 },
	{ 12, -18 },
	{ 12, 20 },
	{ 50, 20 },
	{ 50, -26 },
}

local Arenas: { [string]: ArenaDef } = {
	-- The orchard road: a winding country lane between garden walls, ending at the hara gate.
	orchard = {
		nameKey = "arena.orchard.name",
		path = ORCHARD_PATH,
		bounds = { -74, -42, 74, 32 },
		gateYaw = 180,
		spawnYaw = 0,
		playerSpawn = { 30, -32 },
		seed = "orchard",
		theme = "orchard",
		wires = { { seg = 2, t = 0.5 }, { seg = 5, t = 0.5 } },
	},
	-- The Rival Lane: the next quarter's paved street, same road as the orchard.
	rival_lane = {
		nameKey = "arena.rival_lane.name",
		path = ORCHARD_PATH,
		bounds = { -74, -42, 74, 32 },
		gateYaw = 180,
		spawnYaw = 0,
		playerSpawn = { 30, -32 },
		seed = "rival_lane",
		theme = "rival",
		wires = { { seg = 2, t = 0.35 }, { seg = 4, t = 0.5 }, { seg = 6, t = 0.5 } },
	},
	-- The siege: a long straight approach with two bends, under the walls of the quarter.
	siege = {
		nameKey = "arena.siege.name",
		path = {
			{ -70, 24 },
			{ -40, 24 },
			{ -40, -22 },
			{ 0, -22 },
			{ 0, 22 },
			{ 36, 22 },
			{ 36, -10 },
			{ 64, -10 },
		},
		bounds = { -80, -36, 80, 36 },
		gateYaw = -90,
		spawnYaw = 90,
		playerSpawn = { 60, 20 },
		seed = "siege",
		theme = "orchard",
		wires = { { seg = 4, t = 0.5 } },
	},
}

return Arenas
