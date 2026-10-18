--!strict
-- Where the imported Meshy props (ReplicatedStorage.PropModels, docs/CHARACTER_PIPELINE.md) are
-- placed. Server/World/PropDressing reads this; a prop whose model is missing is skipped, so the
-- primitive world always stands on its own.
--
-- Each placement: `prop` (model name), `height` (studs the model is scaled to), `yaw` (degrees,
-- 0 = the model's front faces -Z of its frame), `solid` (players collide with it).
-- Lobby placements use world coordinates `at = { x, z }` (ground level). Arena placements use
-- arena-local coordinates, or `anchor = "start"` to sit at the first road point facing along the
-- road (the enemies' entrance), with `at` as an offset in that frame: -Z runs down the road,
-- +Z back out of the arena.

export type Placement = {
	prop: string,
	at: { number },
	height: number,
	yaw: number?,
	solid: boolean?,
	anchor: ("start" | "origin")?,
}

local Placements: { lobby: { Placement }, arenas: { [string]: { Placement } } } = {
	lobby = {
		-- No free-standing lantern posts in Jasmine Lane: the lane is only 16 studs wide and players
		-- reported the posts standing in the market. The lane uses wall lanterns (Zones/Lane facades).
		-- Abu Hatem's coffee-house corner, square west by the coffee house
		{ prop = "coffee_house", at = { -21, -8 }, height = 7, yaw = 90, solid = true },
	},
	arenas = {
		orchard = {
			-- The rival lane's gate the attackers march out of
			{ prop = "gate", anchor = "start", at = { 0, 4 }, height = 20, solid = true },
			-- Lanterns at the road's corners, set back from the kerb
			{ prop = "lantern_post", at = { -58, 18 }, height = 9 },
			{ prop = "lantern_post", at = { -22, 6 }, height = 9 },
			{ prop = "lantern_post", at = { 6, -24 }, height = 9 },
			{ prop = "lantern_post", at = { 18, 26 }, height = 9 },
			{ prop = "lantern_post", at = { 44, 26 }, height = 9 },
			-- The home lane's life behind the defenders
			{ prop = "barber_shop", at = { -10, 26 }, height = 10, solid = true }, -- front (-Z) toward the road
			{ prop = "coffee_house", at = { -44, -36 }, height = 7, yaw = -139, solid = true }, -- faces the road corner (-28,-18)
			{ prop = "bread_oven", at = { 66, 4 }, height = 7, yaw = 90, solid = true },
			{ prop = "fountain", at = { 18, -36 }, height = 4, solid = true },
		},
		-- The Rival Lane: their gate at the road's start (ours, the primitive one, stands at the end:
		-- it is what the attackers hit), lantern posts at the corners, the rival quarter's fountain.
		rival_lane = {
			{ prop = "gate", anchor = "start", at = { 0, 4 }, height = 20, solid = true },
			{ prop = "lantern_post", at = { -58, 18 }, height = 9 },
			{ prop = "lantern_post", at = { -22, 6 }, height = 9 },
			{ prop = "lantern_post", at = { 6, -24 }, height = 9 },
			{ prop = "lantern_post", at = { 44, 26 }, height = 9 },
			{ prop = "fountain", at = { -44, -36 }, height = 4, solid = true }, -- the south-west corner, off the best tower ground
		},
		siege = {
			{ prop = "gate", anchor = "start", at = { 0, 4 }, height = 20, solid = true },
			{ prop = "lantern_post", at = { -46, 30 }, height = 9 },
			{ prop = "lantern_post", at = { -6, -28 }, height = 9 },
			{ prop = "lantern_post", at = { 30, 28 }, height = 9 },
		},
	},
}

return Placements
