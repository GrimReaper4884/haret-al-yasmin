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
}

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
}

return Npcs
