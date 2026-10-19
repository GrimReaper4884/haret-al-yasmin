--!strict
-- Lobby life numbers (POLISH_PLAN PV-E02). Client only: LobbyLifeController draws everything here
-- locally, so the server builds nothing extra and simulates nothing. Every piece is gated by the
-- Effects setting (Logic/LobbyLife.tier) and stops beyond `radius` studs from the camera.
-- Positions are lobby world coordinates (docs/WORLD_MAP.md: the lane runs along Z from the gate at
-- z ≈ 92 to the fountain square at the origin). Pure data.

return {
	radius = 120, -- studs from the camera; farther pieces hold still / switch off

	-- The lane's cast (LP-D02, Config/Npcs): walkers stroll their route at `walkSpeed` and stand
	-- `pause` s at each point; the server moves them `serverHz` times a second (prompt range) and each
	-- client draws them smoothly on the same clock. A seated figure bends `thigh` / `knee` degrees at
	-- the hip and knee bones over its idle clip, its hip bone `lift` studs above the seat (`drop` ×
	-- its height when a figure has no hip bone).
	npcs = {
		walkSpeed = 3.6,
		pause = 4,
		serverHz = 10,
		sit = { thigh = -90, knee = 90, lift = 0.35, drop = 0.3 },
	},
	hz = 30, -- animation updates per second
	staticHz = 2, -- how often far-away vines are hidden / shown again

	-- The existing washing lines (World/Props.laundry): each cloth swings on the rope.
	laundry = { amp = 9, hz = 0.32 }, -- degrees, swings per second

	-- One flock of six birds circling above the square.
	birds = {
		count = 6,
		center = { 0, 6 }, -- x, z
		radius = 30,
		height = 34,
		bob = 1.4, -- studs up and down
		speed = 0.16, -- radians per second around the circle
		spacing = 0.13, -- radians between birds
		spread = 2.2, -- studs: birds fly on slightly different circles
		flapHz = 2.6,
		flap = 28, -- degrees of roll while flapping
		size = { 1.2, 0.14, 0.55 },
		color = "#2B2622",
	},

	-- The square's fountain (World/Zones/Square): a little spray from the spout and a ripple where
	-- each of the four streams meets the basin.
	fountain = {
		at = { 0, 0 }, -- x, z
		spout = { 0, 7.1, 0 },
		rate = 6,
		color = "#D6F1FF",
		ripples = {
			count = 4,
			ring = 3.4,
			y = 1.72,
			from = 0.6,
			to = 3.2,
			period = 1.7,
			transparency = 0.45,
			color = "#E6F7FF",
		},
	},

	-- Abu Hatem's corner: steam from the samovar in the coffee house (World/Zones/Extras).
	steam = { at = { -35.5, 4.25, -3 }, rate = 4 },
	-- The hammam's roof vent (World/Zones/Hammam, LP-D04), once that zone is built.
	hammamSteam = { at = { -58, 19.6, 6 }, rate = 6 },

	-- Abu Nadim's oven (World/Zones/Shops): passing by it makes the fire flare and puffs flour.
	oven = {
		mouth = { -12.2, 2.4, 60 },
		puff = { -10.6, 4.6, 60 }, -- the flour rises over the bread counter in front of the mouth
		trigger = 9, -- studs from the oven mouth (the local player only)
		cooldown = 6, -- seconds between puffs
		boost = 1.9, -- the oven light's brightness multiplier at the flare
		flare = 1.6, -- seconds for the flare to settle back
		dust = 10, -- particles
		dustColor = "#F3EBDD",
	},

	-- Cats (World/Props.cat) turn to face the nearest player within `reach`.
	cat = { reach = 24, turnSpeed = 140 }, -- studs, degrees per second

	-- Climbing jasmine on six walls. Each vine is found by casting a ray from a point in the open
	-- lane/square (`from`, x y z) in direction `dir` (x z) at most `reach` studs; it grows from
	-- the ground up to `height` where the ray hits a wall.
	vines = {
		reach = 14,
		width = 2.6,
		flowers = 8,
		leaf = "#4F7A32",
		leafDark = "#3B5E26",
		flower = "#FBF8F1",
		spots = {
			{ from = { 0, 5, 41 }, dir = { -1, 0 }, height = 13 },
			{ from = { 0, 5, 74 }, dir = { 1, 0 }, height = 12 },
			{ from = { 0, 5, 81 }, dir = { -1, 0 }, height = 14 },
			{ from = { 0, 5, 67 }, dir = { 1, 0 }, height = 11 },
			{ from = { -12, 5, 16 }, dir = { -1, 0 }, height = 13 },
			{ from = { 12, 5, -18 }, dir = { 1, 0 }, height = 12 },
		},
	},
}
