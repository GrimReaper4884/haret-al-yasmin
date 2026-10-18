--!strict
-- Playable modes and their lobby portals. Pure data. Unlocks are checked server-side from
-- profile.td.cleared (episode → difficulty cleared).

export type ModeDef = {
	kind: "story" | "infinite" | "event",
	episode: string?, -- key in Config/Waves.episodes
	event: string?, -- key in Config/Events and Config/Waves.events (kind = "event")
	waves: number?, -- event modes: number of waves (shown in the Play panel)
	rewards: { lira: number, qirsh: number, xp: number }?, -- event modes: a win (losses pay a share)
	rewardKey: string?, -- event modes: the rewards line in the Play panel
	arena: string, -- key in Config/Arenas
	nameKey: string,
	descKey: string,
	order: number,
	requires: string?, -- mode that must be cleared on Normal first
	portal: { number }, -- x, z in the lobby square (debug teleport; play starts at the Play arch)
	portalYaw: number,
}

local Modes: { [string]: ModeDef } = {
	ep1 = {
		kind = "story",
		episode = "ep1",
		arena = "orchard",
		nameKey = "mode.ep1.name",
		descKey = "mode.ep1.desc",
		order = 1,
		portal = { -19, 2 },
		portalYaw = -90,
	},
	ep2 = {
		kind = "story",
		episode = "ep2",
		arena = "rival_lane",
		nameKey = "mode.ep2.name",
		descKey = "mode.ep2.desc",
		order = 2,
		requires = "ep1",
		portal = { -19, -8 },
		portalYaw = -90,
	},
	ep3 = {
		kind = "story",
		episode = "ep3",
		arena = "siege",
		nameKey = "mode.ep3.name",
		descKey = "mode.ep3.desc",
		order = 3,
		requires = "ep2",
		portal = { 19, 2 },
		portalYaw = 90,
	},
	-- Event: the olive harvest raid (Config/Events.olive_harvest). Normal only.
	ev_olive = {
		kind = "event",
		event = "olive_harvest",
		arena = "orchard",
		nameKey = "mode.ev_olive.name",
		descKey = "mode.ev_olive.desc",
		order = 10,
		waves = 15,
		rewards = { lira = 60, qirsh = 120, xp = 100 },
		rewardKey = "event.olive_harvest.rewards",
		portal = { 19, 8 },
		portalYaw = 90,
	},
	infinite = {
		kind = "infinite",
		arena = "siege",
		nameKey = "mode.infinite.name",
		descKey = "mode.infinite.desc",
		order = 4,
		requires = "ep1",
		portal = { 19, -8 },
		portalYaw = 90,
	},
}

return Modes
