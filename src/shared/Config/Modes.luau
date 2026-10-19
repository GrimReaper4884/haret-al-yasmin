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
	-- Season Story 1, Episodes 4–6 (STORY_PLAN §5, S1-S04). Portals are only the Studio debug teleport.
	ep4 = {
		kind = "story",
		episode = "ep4",
		arena = "saha",
		nameKey = "mode.ep4.name",
		descKey = "mode.ep4.desc",
		order = 5,
		requires = "ep3",
		portal = { -19, -18 },
		portalYaw = -90,
	},
	ep5 = {
		kind = "story",
		episode = "ep5",
		arena = "warehouse",
		nameKey = "mode.ep5.name",
		descKey = "mode.ep5.desc",
		order = 6,
		requires = "ep4",
		portal = { 19, -18 },
		portalYaw = 90,
	},
	ep6 = {
		kind = "story",
		episode = "ep6",
		arena = "saha",
		nameKey = "mode.ep6.name",
		descKey = "mode.ep6.desc",
		order = 7,
		requires = "ep5",
		portal = { -19, 12 },
		portalYaw = -90,
	},
	ep7 = {
		kind = "story",
		episode = "ep7",
		arena = "post_road",
		nameKey = "mode.ep7.name",
		descKey = "mode.ep7.desc",
		order = 8,
		requires = "ep6",
		portal = { -19, 16 },
		portalYaw = -90,
	},
	ep8 = {
		kind = "story",
		episode = "ep8",
		arena = "twin_gates",
		twinRoads = true, -- both gates spawn (S1-M05)
		nameKey = "mode.ep8.name",
		descKey = "mode.ep8.desc",
		order = 9,
		requires = "ep7",
		portal = { -19, 20 },
		portalYaw = -90,
	},
	ep9 = {
		kind = "story",
		episode = "ep9",
		arena = "twin_gates",
		twinRoads = true,
		nameKey = "mode.ep9.name",
		descKey = "mode.ep9.desc",
		order = 10,
		requires = "ep8",
		portal = { -19, 24 },
		portalYaw = -90,
	},
	-- Event: the olive harvest raid (Config/Events.olive_harvest). Normal only.
	ev_olive = {
		kind = "event",
		event = "olive_harvest",
		arena = "olive_press", -- the Blender-kit map (S1-M03, D-055); was the generic orchard
		nameKey = "mode.ev_olive.name",
		descKey = "mode.ev_olive.desc",
		order = 12,
		waves = 15,
		rewards = { lira = 60, qirsh = 120, xp = 100 },
		rewardKey = "event.olive_harvest.rewards",
		portal = { 19, 8 },
		portalYaw = 90,
	},
	-- Lantern Nights (LP-D12): the rival lane at night, Abu al-Nahr at wave 8 and Abu Shatour at 15.
	ev_ramadan = {
		kind = "event",
		event = "ramadan",
		arena = "rival_lane", -- Abu al-Nahr's own lane by night (ep2's map; the twin-road square was too hard for an event)
		nameKey = "mode.ev_ramadan.name",
		descKey = "mode.ev_ramadan.desc",
		order = 13,
		waves = 15,
		rewards = { lira = 60, qirsh = 120, xp = 100 },
		rewardKey = "event.ramadan.rewards",
		portal = { 19, 8 }, -- the event arch (only one event runs at a time)
		portalYaw = 90,
	},
	infinite = {
		kind = "infinite",
		arena = "siege",
		nameKey = "mode.infinite.name",
		descKey = "mode.infinite.desc",
		order = 11, -- after the story episodes
		requires = "ep1",
		portal = { 19, -8 },
		portalYaw = 90,
	},
}

return Modes
