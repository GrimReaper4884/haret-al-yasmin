--!strict
-- The bigger lane (LOOK_AND_PLAY_PLAN §4.1, LP-D00). The slice's six zones stay where they are; the
-- new zones grow outward around them, each one `Model` with ModelStreamingMode Atomic built by
-- `server/World/Zones/<module>` once its task lands (`built = true`). Bounds are { x0, z0, x1, z1 } in
-- studs (lobby space, ground Y = 0); `budget` is the zone's part cap. Pure data.

export type Zone = {
	id: string,
	module: string, -- server/World/Zones/<module>.luau
	bounds: { number },
	budget: number,
	built: boolean, -- false until the zone's LP-D task ships (WorldService skips it)
	task: string,
}

local LaneZones = {}

-- Every part of the lobby map (the old 6,000 budget stays the figure for what streams in at once:
-- the gate end and the square end never fully co-stream on a phone, StreamingEnabled is on).
LaneZones.PART_BUDGET = 9000
LaneZones.STREAM_BUDGET = 6000
LaneZones.ZONE_MAX = 1200 -- no single new zone above this

-- What the slice already occupies (WORLD_MAP "Zones in the slice" plus the coffee house and the
-- buildings either side of the lane): the new zones must not overlap these.
LaneZones.existing = {
	{ id = "gate", bounds = { -8, 84, 8, 94 } },
	{ id = "lane", bounds = { -24, 24, 24, 84 } },
	{ id = "square", bounds = { -22, -24, 22, 24 } },
	{ id = "coffee_house", bounds = { -40, -26, -24, 0 } },
	{ id = "wardeh_house", bounds = { -16, -58, 16, -26 } },
} :: { { id: string, bounds: { number } } }

LaneZones.zones = {
	{ id = "souq", module = "Souq", bounds = { 24, 40, 64, 76 }, budget = 1000, built = true, task = "LP-D03" }, -- + its passage under EastA
	{ id = "hammam", module = "Hammam", bounds = { -62, 0, -24, 40 }, budget = 700, built = true, task = "LP-D04" }, -- + its passage under WestB
	{ id = "diwan", module = "Diwan", bounds = { 24, -28, 54, -2 }, budget = 900, built = true, task = "LP-D05" }, -- with SquareSE made shallow
	{ id = "mosque_court", module = "MosqueCourt", bounds = { 24, -2, 50, 26 }, budget = 500, built = true, task = "LP-D05" }, -- with SquareNE made shallow
	{ id = "post", module = "Post", bounds = { -40, 96, -16, 120 }, budget = 600, built = false, task = "LP-D06" },
	{ id = "orchard_road", module = "OrchardRoad", bounds = { -16, 96, 40, 150 }, budget = 1000, built = false, task = "LP-D06" },
	{ id = "rooftop_view", module = "Rooftops", bounds = { -24, 24, 24, 84 }, budget = 150, built = false, task = "LP-D07" },
} :: { Zone }

-- Zones that sit above another area (no collision, no floor): they may overlap it.
LaneZones.overhead = { rooftop_view = true } :: { [string]: boolean }

return LaneZones
