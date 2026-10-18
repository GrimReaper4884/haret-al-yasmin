--!strict
-- Arena looks and dressing numbers (POLISH_PLAN PV-E03). World/Arena reads them; an arena picks
-- its theme in Config/Arenas (`theme`). Colours are hex, materials are Enum.Material names, so this
-- stays pure data. Nothing here changes the road, the bounds or anything the simulation reads.

export type Theme = {
	ground: string,
	groundMaterial: string,
	field: string,
	fieldMaterial: string,
	wall: string,
	wallBand: string?, -- a basalt band along the outer wall (rival lane)
	road: string,
	kerb: string,
	gateStone: string, -- the home gate's pillars and crown
	produce: { string }, -- crate fruit colours in the field and on the kerb
	trees: boolean, -- orchard trees in the field (false: pots and low walls only)
	houses: boolean, -- a ring of house blocks outside the field wall
}

return {
	themes = {
		-- Warm country road between garden walls (Episodes 1, the olive harvest, the siege).
		orchard = {
			ground = "#9F8A5A",
			groundMaterial = "Ground",
			field = "#7F9A4A",
			fieldMaterial = "Grass",
			wall = "#E6D5B8", -- Palette.stoneLight (the orchard keeps its pre-PV-E03 colours)
			road = "#D9BF94", -- Palette.stoneWarm
			kerb = "#E6D5B8",
			gateStone = "#D9BF94",
			produce = { "#E8892B", "#A8322A" },
			trees = true,
			houses = false,
		},
		-- "The Rival Lane" (Episode 2): a paved street of the next quarter, cooler stone and plaster,
		-- house fronts all round, basalt bands.
		rival = {
			ground = "#77786F",
			groundMaterial = "Slate",
			field = "#A9A79C",
			fieldMaterial = "Pavement",
			wall = "#B9BAB2",
			wallBand = "#3D3F42",
			road = "#625D55", -- dark basalt cobbles: the road must read clearly against the paving
			kerb = "#DAD7CC",
			gateStone = "#BDB7AA",
			produce = { "#4A2357", "#5C7A3A" },
			trees = false,
			houses = true,
		},
	},

	-- House blocks outside the rival lane's wall: one every `every` studs along each edge, `depth`
	-- deep, `minH`..`maxH` tall, kept `clearStart` studs from the road's start (their gate) and
	-- `clearEnd` from its end (our gate's 80-stud wall and the rooftops behind it).
	houses = {
		every = 12,
		depth = 9,
		minH = 12,
		maxH = 22,
		clearStart = 26,
		clearEnd = 45,
		plaster = { "#C9C6BC", "#B7BCC0", "#D4CFC4", "#A9AFB4" },
		window = "#2B2A2E",
		lanternEvery = 4, -- every n-th house gets a wall lantern
	},

	-- Crates and sacks along the kerb: one every `every` studs of road, alternating sides, `inset`
	-- studs from the centreline, skipping `margin` studs at each segment end (corners) and anything
	-- that would land on another stretch of road or within `spawnClear` of the party spawn.
	kerb = { every = 15, inset = 4.7, margin = 6, spawnClear = 9, sack = "#D9C9A6" },

	-- A wire across the road with a hanging lantern: posts `inset` from the centreline, wire at
	-- `height`, lantern `drop` below it.
	wires = { inset = 5, height = 10, drop = 2.2, range = 16, brightness = 1.3, color = "#FFB060" },

	-- Climbing jasmine on the home wall beside the gate (four vines).
	jasmine = {
		offsets = { 7.5, 18 },
		width = 3,
		height = 12,
		flowers = 7,
		leaf = "#4F7A32",
		flower = "#FBF8F1",
	},

	-- Night dust haze drifting low over the road (client turns it on at Effects full only).
	haze = {
		radius = 180,
		y = 0.8,
		rate = 0.16,
		size = 8,
		lifetime = 7,
		transparency = 0.76,
		color = "#C8B79A",
		speed = 0.4,
	},
}
