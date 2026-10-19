--!strict
-- Lobby life numbers (POLISH_PLAN PV-E02). Client only: LobbyLifeController draws everything here
-- locally, so the server builds nothing extra and simulates nothing. Every piece is gated by the
-- Effects setting (Logic/LobbyLife.tier) and stops beyond `radius` studs from the camera.
-- Positions are lobby world coordinates (docs/WORLD_MAP.md: the lane runs along Z from the gate at
-- z ≈ 92 to the fountain square at the origin). Pure data.

return {
	radius = 120, -- studs from the camera; farther pieces hold still / switch off

	-- The lane clock (LP-D09, LOOK_AND_PLAY_PLAN §4.3): a 12-minute day on the server's clock, so every
	-- player sees the same light; phases in minutes, each fading in from the last over `fade` s.
	-- The looks are Config/Lighting `lane[phase]`.
	CLOCK = {
		cycle = 720,
		fade = 25,
		phases = {
			{ id = "dawn", from = 0, to = 1 },
			{ id = "day", from = 1, to = 8 },
			{ id = "evening", from = 8, to = 10 },
			{ id = "night", from = 10, to = 12 },
		},
	},

	-- The lane's beats (LP-D10, LOOK_AND_PLAY_PLAN §4.3), on the lane clock. Seconds throughout.
	beats = {
		-- Abu Hares swings the gate leaves half shut at night (a gap stays: the road outside is still
		-- open to players) and open again at dawn, when a rooster calls.
		gate = { swing = 6, nightAngle = 50 },
		-- Corporal Houri and two gendarmes march from the gate round the fountain and back.
		patrol = {
			phases = { "day" },
			every = 240,
			offset = 90,
			length = 56,
			speed = 4.2,
			gap = 2.2, -- seconds between marchers
			route = { { 0, 84 }, { 1, 30 }, { -9, 14 }, { -10, -4 }, { 0, -16 }, { 10, -4 }, { 9, 14 }, { 1, 30 } },
		},
		-- Two neighbours quarrel before the liwan; the za'im raises his hand; they shake on it.
		dispute = {
			phases = { "day" },
			every = 300,
			offset = 200,
			length = 26,
			at = { 42.5, -15 }, -- between the pool and the liwan
			lines = { "beat.dispute.1", "beat.dispute.2", "beat.dispute.3", "beat.dispute.4" },
			lineSeconds = 6,
			fundRange = 20, -- studs: the cosmetic "lane fund" toast for players this close
		},
		-- The coffee house in the evening: six neighbours on the benches, the Hakawati on his stool
		-- telling one of his tales (three lines over 90 s; a different tale each evening).
		coffee = {
			phase = "evening",
			tales = { "antar", "baybars", "hilali", "zir", "sayf" },
			lineAt = { 10, 40, 70 },
			lineSeconds = 14,
			hakawati = { -29.4, -13, 90 }, -- x, z, yaw: on a stool facing the west bench
			seats = { { -36.3, -14.5, -90 }, { -36.3, -10.5, -90 }, { -36.3, -6.5, -90 }, { -33, -24.4, 180 }, { -29.5, -24.4, 180 }, { -26.5, -24.4, 180 } },
		},
		-- The 'arada (LP-D11): every third evening a wedding procession of six sword-and-shield dancers
		-- (the `arada` unit's model, its dance as the idle) leaves the diwan, crosses the square and goes
		-- up the lane to the gate; rice falls from the rooftops over the lane (Lane life "full" only).
		-- Its drum loop is cue `arada_drums` (silent until supplied).
		arada = {
			phase = "evening",
			everyEvenings = 3,
			from = 20,
			length = 75,
			speed = 2.6,
			gap = 1.6, -- seconds between ranks
			route = { { 31, -13.5 }, { 20, -13.5 }, { 10, -4 }, { 9, 14 }, { 1, 30 }, { 0, 82 } },
			rice = { { -6, 18, 40 }, { 6, 18, 52 }, { -6, 18, 66 } }, -- x, y, z: emitters along the roofs' edges
		},
		-- The musaharati (LP-D11): in the night of a running event with this id only (Config/Events) a
		-- drummer walks the lane calling the neighbours to their suhoor.
		musaharati = {
			event = "ramadan",
			phase = "night",
			from = 10,
			length = 100,
			speed = 2.4,
			route = { { 0, 82 }, { 1, 30 }, { -9, 14 }, { 0, -2 } },
			calls = { "beat.musaharati.1", "beat.musaharati.2" },
			callEvery = 12,
			callSeconds = 6,
		},
		-- The night watch: Abu Hares calls twice; Al-Adashari slips up the souq to Abu Brahim's
		-- shutter and is gone.
		watch = {
			phase = "night",
			calls = { { at = 4, key = "beat.watch.1" }, { at = 64, key = "beat.watch.2" } },
			callSeconds = 8,
			cameo = { from = 30, length = 20, route = { { 56, 43.6 }, { 57.4, 48.2 } }, speed = 1.6 },
		},
	},

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
	-- Fawza calls down from her roof (LP-D07): a line every `every` s for `show` s, waving her broom
	-- for the first `wave` s; lines take turns (Strings `roof.fawza.*`).
	rooftop = {
		npc = "fawza_roof",
		every = 90,
		show = 7,
		offset = 20,
		wave = 1.5,
		lines = { "roof.fawza.1", "roof.fawza.2", "roof.fawza.3", "roof.fawza.4" },
	},
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
