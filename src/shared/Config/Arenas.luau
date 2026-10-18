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
	paths: { { { number } } }?, -- twin gates: every road (merging before the gate); `path` is the first (S1-S07)
	allySpot: { number }?, -- x, z where a story ally stands (Waves.episodes[id].script, S1-S07)
	kit: string?, -- Config/ArenaLayouts/<kit>: hara kit modules placed by server/World/KitLayout (S1-M03)
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
	-- BEGIN GENERATED olive_press (tools/blender/export_layout.py from assets/blender/arenas/olive_press.blend)
	olive_press = {
		nameKey = "arena.olive_press.name",
		path = { { -70, 30 }, { -30, 30 }, { -30, -10 }, { 12, -10 }, { 12, 24 }, { 48, 24 }, { 48, -20 } },
		bounds = { -80, -40, 80, 36 },
		gateYaw = 180,
		spawnYaw = 90,
		playerSpawn = { 30, -32 },
		seed = "olive_press",
		theme = "orchard_kit",
		kit = "olive_press", -- server/World/KitLayout places Config/ArenaLayouts/olive_press
	},
	-- END GENERATED olive_press
	-- BEGIN GENERATED saha (tools/blender/export_layout.py from assets/blender/arenas/saha.blend)
	saha = {
		nameKey = "arena.saha.name",
		path = { { -62, 30 }, { -34, 30 }, { -34, 6 }, { -6, 6 }, { 22, 6 }, { 22, 28 }, { 54, 28 }, { 54, -30 } },
		paths = { { { -62, 30 }, { -34, 30 }, { -34, 6 }, { -6, 6 }, { 22, 6 }, { 22, 28 }, { 54, 28 }, { 54, -30 } }, { { -62, -30 }, { -40, -30 }, { -40, -14 }, { -6, -14 }, { -6, 6 }, { 22, 6 }, { 22, 28 }, { 54, 28 }, { 54, -30 } } },
		bounds = { -72, -40, 70, 36 },
		gateYaw = 180,
		spawnYaw = 90,
		playerSpawn = { 40, -34 },
		seed = "saha",
		theme = "rival",
		allySpot = { 48, -26 },
		kit = "saha", -- server/World/KitLayout places Config/ArenaLayouts/saha
	},
	-- END GENERATED saha
	-- BEGIN GENERATED warehouse (tools/blender/export_layout.py from assets/blender/arenas/warehouse.blend)
	warehouse = {
		nameKey = "arena.warehouse.name",
		path = { { -70, -30 }, { -70, 20 }, { -40, 20 }, { -40, -14 }, { -6, -14 }, { -6, 14 }, { 20, 14 }, { 20, -24 }, { 44, -24 }, { 44, 26 } },
		bounds = { -80, -36, 66, 32 },
		gateYaw = 0,
		spawnYaw = 0,
		playerSpawn = { 58, -28 },
		seed = "warehouse",
		theme = "orchard",
		kit = "warehouse", -- server/World/KitLayout places Config/ArenaLayouts/warehouse
	},
	-- END GENERATED warehouse
	-- BEGIN GENERATED post_road (tools/blender/export_layout.py from assets/blender/arenas/post_road.blend)
	post_road = {
		nameKey = "arena.post_road.name",
		path = { { -70, -24 }, { 30, -24 }, { 30, 4 }, { -30, 4 }, { -30, 26 }, { 66, 26 } },
		bounds = { -80, -36, 76, 36 },
		gateYaw = 90,
		spawnYaw = 90,
		playerSpawn = { 52, -20 },
		seed = "post_road",
		theme = "orchard",
		allySpot = { 44, 12 },
		kit = "post_road", -- server/World/KitLayout places Config/ArenaLayouts/post_road
	},
	-- END GENERATED post_road
	-- BEGIN GENERATED twin_gates (tools/blender/export_layout.py from assets/blender/arenas/twin_gates.blend)
	twin_gates = {
		nameKey = "arena.twin_gates.name",
		path = { { -74, 20 }, { -30, 20 }, { -30, 0 }, { 0, 0 }, { 30, 0 }, { 30, 24 }, { 64, 24 }, { 64, -30 } },
		paths = { { { -74, 20 }, { -30, 20 }, { -30, 0 }, { 0, 0 }, { 30, 0 }, { 30, 24 }, { 64, 24 }, { 64, -30 } }, { { -74, -20 }, { -40, -20 }, { -40, -32 }, { 0, -32 }, { 0, 0 }, { 30, 0 }, { 30, 24 }, { 64, 24 }, { 64, -30 } } },
		bounds = { -80, -40, 72, 36 },
		gateYaw = 180,
		spawnYaw = 90,
		playerSpawn = { 46, -12 },
		seed = "twin_gates",
		theme = "rival",
		allySpot = { 14, 10 },
		kit = "twin_gates", -- server/World/KitLayout places Config/ArenaLayouts/twin_gates
	},
	-- END GENERATED twin_gates
}

return Arenas
