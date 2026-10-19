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
	requiresClear: string?, -- a mode id: each client shows the figure only once its player has cleared it (S1-A08)
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
		position = { 50.7, 1.2, -15 }, -- in the middle of the liwan's back bench (World/Zones/Diwan)
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
		position = { 43.5, 0, -9.5 },
		-- from the liwan through the diwan's portal and the square, up the lane to the gate and back
		route = { { 43.5, -9.5 }, { 31, -12.4 }, { 20, -13.5 }, { 10, -4 }, { 3, 30 }, { 0, 76 }, { -3, 30 }, { 10, -6 }, { 20, -13.5 }, { 31, -12.4 } },
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
		position = { -31, 0, 109 }, -- in the post's yard, before its door (World/Zones/Post)
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
		position = { -24.5, 0, 113.5 }, -- in the post's yard (World/Zones/Post)
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
		position = { -8.6, 22.3, 44 }, -- on WestB's roof edge over the lane, legs over the wall (World/Zones/Rooftops)
		yaw = -90, -- looks down into the lane (+X)
		skin = "#B97F5A",
		robe = "#5E7D3A",
		accent = "#FBF8F1",
	},
	-- LP-D13 (owner approved 2026-10-19, D-122): the za'im's two elders on the liwan's back bench either side of
	-- him, the lane's notables in their unit figures (no new names); ambient: the za'im takes the prompt.
	elder_baker = {
		look = "farran",
		pose = "seated",
		zone = "diwan",
		talk = false,
		nameKey = "npc.elder_baker.name",
		roleKey = "npc.elder_baker.role",
		position = { 50.7, 1.2, -18.6 }, -- the back bench (World/Zones/Diwan), south of the za'im
		yaw = 90, -- faces the door (-X)
		skin = "#C08A62",
		robe = "#EADFC8",
		accent = "#6B4423",
	},
	elder_smith = {
		look = "haddad",
		pose = "seated",
		zone = "diwan",
		talk = false,
		nameKey = "npc.elder_smith.name",
		roleKey = "npc.elder_smith.role",
		position = { 50.7, 1.2, -11.4 }, -- the back bench, north of the za'im
		yaw = 90,
		skin = "#B97F5A",
		robe = "#3B4A3A",
		accent = "#1F1B18",
	},
	-- Eido the bath attendant by the towel bench in the hammam's court (LP-D13): a crowd look, ambient.
	hammam_worker = {
		zone = "hammam",
		talk = false,
		nameKey = "npc.hammam_worker.name",
		roleKey = "npc.hammam_worker.role",
		position = { -46.6, 0, 34.6 }, -- beside the bench of folded towels (World/Zones/Hammam)
		yaw = 0, -- faces the bath-house (-Z)
		skin = "#C68E64",
		robe = "#FBF8F1",
		accent = "#A4302A",
		headwear = "cap",
	},
	-- LP-D08: the four Meshy looks of their own (Config/CharacterLooks "lane NPCs").
	feryal_roof = {
		look = "feryal",
		pose = "seated",
		zone = "rooftop_view",
		talk = false,
		nameKey = "npc.feryal_roof.name",
		roleKey = "npc.feryal_roof.role",
		position = { 10.6, 23.6, 80 }, -- on the stool on EastA's roof (World/Zones/Rooftops; seat top = roof + 1.4)
		yaw = 90, -- looks down into the lane (-X)
		skin = "#B97F5A",
		robe = "#2E6B6B",
		accent = "#C9A13B",
	},
	grocer = {
		look = "grocer",
		zone = "souq",
		nameKey = "npc.grocer.name",
		roleKey = "npc.grocer.role",
		position = { 49, 0, 74.4 }, -- behind his crates in the niche (World/Zones/Souq `grocer`)
		yaw = 0, -- faces the corridor (-Z)
		skin = "#C68E64",
		robe = "#5E7D3A",
		accent = "#FBF8F1",
	},
	sheikh = {
		look = "sheikh",
		pose = "seated",
		zone = "mosque_court",
		nameKey = "npc.sheikh.name",
		roleKey = "npc.sheikh.role",
		position = { 47.1, 1.4, 14.4 }, -- on the stone bench beside the mosque door (World/Zones/MosqueCourt)
		yaw = 90, -- faces the court (-X)
		skin = "#C08A62",
		robe = "#EADFC8",
		accent = "#4A3426",
	},
	-- Abu Brahim the Cloth Merchant before his counter in the souq (LP-E03): his unit's figure; his
	-- prompt opens the lane store with his line (the unit's lore, in his own words).
	cloth_merchant = {
		look = "tajir",
		zone = "souq",
		nameKey = "npc.cloth_merchant.name",
		roleKey = "npc.cloth_merchant.role",
		position = { 59, 0, 48.6 }, -- before his counter (World/Zones/Souq `clothShop`, counter x 60.1..61)
		yaw = 90, -- faces the corridor (-X)
		skin = "#C68E64",
		robe = "#E9DFC6",
		accent = "#2F5A3A",
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
		look = "hakawati", -- his Meshy figure (LP-D08); the coffee-house evening seats the same figure
		nameKey = "npc.hakawati.name",
		roleKey = "npc.hakawati.role",
		position = { -3000, 1.2, 10.4 },
		yaw = 0, -- faces the listeners (-Z)
		skin = "#B5835E",
		robe = "#2F3E6B",
		accent = "#C9A13B",
		headwear = "tarboosh",
	},
	-- S1-A08: after Episode 9 the Night Guard keeps the lane gate by his old pickle cart (STORY_PLAN §7.6).
	adashari_guard = {
		nameKey = "npc.adashari_guard.name",
		roleKey = "npc.adashari_guard.role",
		position = { -3.6, 0, 82.4 },
		yaw = 200, -- by the cart's shafts, looking down the lane
		skin = "#B98A62",
		robe = "#2E2A26",
		accent = "#8C6A3E",
		look = "adashari",
		talk = false,
		requiresClear = "ep9",
	},
}

return Npcs
