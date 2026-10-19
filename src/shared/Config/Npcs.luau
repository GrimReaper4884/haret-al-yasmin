--!strict
-- NPC placement and look. Positions are { x, y, z } in studs (ground Y = 0), yaw in degrees
-- (0 = facing -Z). Colors are hex strings so this file stays free of Roblox datatypes.

export type NpcDef = {
	nameKey: string,
	roleKey: string,
	position: { number },
	yaw: number,
	skin: string,
	robe: string,
	accent: string,
	headwear: string?,
	look: string?, -- a unit or enemy id (Config/CharacterLooks): its figure in the lane (LP-D02) and its portrait (LP-C04)
	pose: Pose?, -- "stand" (default), "seated" on the seat at `position` (its Y is the seat top), "walk" along `route`
	route: { { number } }?, -- walkers: a closed loop of { x, z } (Logic/LobbyLife.route), `position` = its first point
	phase: number?, -- walkers: seconds into the shared cycle, so two walkers on one clock don't move in step
	clipsFrom: { [string]: string }?, -- clip slot -> another look id whose clip this figure borrows (same skeleton)
	zone: string?, -- Config/LaneZones id: stands in the lane only once that zone is built
	talk: boolean?, -- false = ambient (no prompt, no dialogue)
}

export type Pose = "stand" | "seated" | "walk"

local Npcs: { [string]: NpcDef } = {
	abu_nadim = {
		nameKey = "npc.abu_nadim.name",
		roleKey = "npc.abu_nadim.role",
		position = { -11, 0, 60 },
		yaw = -90, -- faces the lane (+X)
		skin = "#C68E64",
		robe = "#F1E9DA",
		accent = "#6B4423",
		headwear = "cap",
	},
	sitt_wardeh = {
		nameKey = "npc.sitt_wardeh.name",
		roleKey = "npc.sitt_wardeh.role",
		position = { 4, 0, -40 },
		yaw = 180, -- faces the entrance (+Z)
		skin = "#B97F5A",
		robe = "#2F3E6B",
		accent = "#FBF8F1",
		headwear = "scarf",
	},
	hajj_rashid = {
		nameKey = "npc.hajj_rashid.name",
		roleKey = "npc.hajj_rashid.role",
		position = { -21.5, 0, 16 },
		yaw = -90, -- faces the square (+X)
		skin = "#C08A62",
		robe = "#5E7D3A",
		accent = "#E6D5B8",
		headwear = "cap",
	},
	khalil_tailor = {
		nameKey = "npc.khalil_tailor.name",
		roleKey = "npc.khalil_tailor.role",
		position = { 11, 0, 56 },
		yaw = 90, -- faces the lane (-X)
		skin = "#D2A07A",
		robe = "#4A2E18",
		accent = "#A4302A",
		headwear = "tarboosh",
	},
	barber = {
		look = "umm_hara",
		nameKey = "npc.barber.name",
		roleKey = "npc.barber.role",
		position = { 14.5, 0.3, 36 },
		yaw = 90, -- faces the lane (-X), behind the chair
		skin = "#D2A07A",
		robe = "#FBF8F1",
		accent = "#1F1B18",
		headwear = "tarboosh",
	},
	qahwaji = {
		look = "qahwaji",
		nameKey = "npc.qahwaji.name",
		roleKey = "npc.qahwaji.role",
		position = { -27, 0.3, -13 },
		yaw = -90, -- faces the square (+X)
		skin = "#C08A62",
		robe = "#5E7D3A",
		accent = "#C9A13B",
		headwear = "tarboosh",
	},
	natour = {
		look = "natour",
		nameKey = "npc.natour.name",
		roleKey = "npc.natour.role",
		position = { 5.5, 0, 84 },
		yaw = 90, -- faces the lane (-X), by the wicket
		skin = "#B97F5A",
		robe = "#4A2E18",
		accent = "#B87333",
		headwear = "cap",
	},
	-- The bigger lane's cast (LOOK_AND_PLAY_PLAN §4.2, LP-D02): each wears the unit or enemy model of
	-- the same character. Zone NPCs wait for their zone (Config/LaneZones `built`); the positions of
	-- those are provisional until the zone's task lays the zone out.
	mukhtar_npc = {
		look = "mukhtar",
		pose = "seated",
		nameKey = "npc.mukhtar_npc.name",
		roleKey = "npc.mukhtar_npc.role",
		position = { 14.2, 1.8, 7 }, -- the square's north-east bench (World/Zones/Square; the cat has the south one)
		yaw = 90, -- faces the fountain (-X)
		skin = "#C08A62",
		robe = "#4A2E18",
		accent = "#C9A13B",
	},
	umm_hissam = {
		look = "matriarch",
		pose = "seated",
		nameKey = "npc.umm_hissam.name",
		roleKey = "npc.umm_hissam.role",
		position = { -2.4, 1.2, -49.1 }, -- on the cushions of Sitt Wardeh's liwan (World/Zones/House)
		yaw = 180, -- faces the courtyard (+Z)
		skin = "#B97F5A",
		robe = "#5A2340",
		accent = "#C9A13B",
	},
	midwife = {
		look = "qabilah",
		pose = "walk",
		clipsFrom = { walk = "beggar" }, -- a careful walk; her own clips are idle and attack only
		nameKey = "npc.midwife.name",
		roleKey = "npc.midwife.role",
		position = { 3, 0, 30 },
		route = { { 3, 30 }, { -3, 46 }, { 2, 64 }, { -2, 47 } }, -- up and down the lane
		phase = 0,
		yaw = 0,
		skin = "#B97F5A",
		robe = "#2F3E6B",
		accent = "#FBF8F1",
	},
	balila = {
		look = "khayyat",
		pose = "walk",
		clipsFrom = { walk = "drummer" }, -- a confident stroll for the lane's gossip
		nameKey = "npc.balila.name",
		roleKey = "npc.balila.role",
		position = { -9, 0, 14 },
		route = { { -9, 14 }, { -9, -4 }, { 0, -17 }, { 10, -4 }, { 9, 14 }, { 2, 26 } }, -- round the square
		phase = 11,
		yaw = 0,
		skin = "#C68E64",
		robe = "#EADFC8",
		accent = "#6B4423",
	},
	zaim_npc = {
		look = "zaim",
		pose = "seated",
		zone = "diwan",
		nameKey = "npc.zaim_npc.name",
		roleKey = "npc.zaim_npc.role",
		position = { 46, 1.2, -18 }, -- in the liwan (LP-D05 places it)
		yaw = 90, -- faces the door (-X: the diwan opens west onto the square)
		skin = "#C08A62",
		robe = "#1F1B18",
		accent = "#C9A13B",
	},
	akeed_npc = {
		look = "zaim_akbar",
		pose = "walk",
		zone = "diwan",
		clipsFrom = { walk = "abu_jawdan" }, -- a proud stride
		nameKey = "npc.akeed_npc.name",
		roleKey = "npc.akeed_npc.role",
		position = { 26, 0, -10 },
		route = { { 26, -10 }, { 17, 2 }, { 3, 30 }, { 0, 76 }, { -3, 30 }, { 17, -2 } }, -- diwan door to the gate
		phase = 0,
		yaw = 0,
		skin = "#B97F5A",
		robe = "#4A2E18",
		accent = "#A4302A",
	},
	hammam_owner = {
		look = "hammam",
		zone = "hammam",
		nameKey = "npc.hammam_owner.name",
		roleKey = "npc.hammam_owner.role",
		position = { -46.4, 0, 28.2 }, -- beside the hammam's curtained door (World/Zones/Hammam)
		yaw = 180, -- faces the court (+Z)
		skin = "#C68E64",
		robe = "#FBF8F1",
		accent = "#2E8B87",
	},
	sergeant_npc = {
		look = "abu_jawdan",
		zone = "post",
		clipsFrom = { idle = "natour" }, -- an enemy figure: it has a walk, no idle of its own
		nameKey = "npc.sergeant_npc.name",
		roleKey = "npc.sergeant_npc.role",
		position = { -27, 0, 106 }, -- at the post's desk (LP-D06 places it)
		yaw = -90, -- faces the road (+X)
		skin = "#C08A62",
		robe = "#3B4A3A",
		accent = "#C9A13B",
	},
	corporal_npc = {
		look = "corporal",
		zone = "post",
		talk = false,
		clipsFrom = { idle = "natour" },
		nameKey = "npc.corporal_npc.name",
		roleKey = "npc.corporal_npc.role",
		position = { -21, 0, 112 }, -- by the post's door (LP-D06 places it)
		yaw = -90,
		skin = "#B97F5A",
		robe = "#3B4A3A",
		accent = "#1F1B18",
	},
	fawza_roof = {
		look = "saqqa",
		pose = "seated",
		zone = "rooftop_view",
		talk = false,
		nameKey = "npc.fawza_roof.name",
		roleKey = "npc.fawza_roof.role",
		position = { -8.6, 22.3, 44 }, -- on the roof edge over the lane, legs over the wall (LP-D07 places it)
		yaw = -90, -- looks down into the lane (+X)
		skin = "#B97F5A",
		robe = "#5E7D3A",
		accent = "#FBF8F1",
	},
	-- Abu Brahim's son by the cloth shop in the souq (LP-D03): a crowd look, ambient.
	ibrahim_son = {
		zone = "souq",
		talk = false,
		nameKey = "npc.ibrahim_son.name",
		roleKey = "npc.ibrahim_son.role",
		position = { 58.8, 0, 53.6 },
		yaw = 90, -- faces across the corridor (-X)
		skin = "#C68E64",
		robe = "#EADFC8",
		accent = "#2F3E6B",
		headwear = "tarboosh",
	},
	-- The storyteller of the AFK chamber, on his dais in the Hakawati's room (Config/Afk.ORIGIN
	-- -3000, 0, 0; the dais is at local z 8..13, 1.2 high).
	hakawati = {
		nameKey = "npc.hakawati.name",
		roleKey = "npc.hakawati.role",
		position = { -3000, 1.2, 10.4 },
		yaw = 0, -- faces the listeners (-Z)
		skin = "#B5835E",
		robe = "#2F3E6B",
		accent = "#C9A13B",
		headwear = "tarboosh",
	},
}

return Npcs
