--!strict
-- Season Story 1 "The Night Guard" (docs/STORY_PLAN.md §5): the Hakawati's words for each of the
-- nine episodes. Pure data: every value is a key into Config/Strings (EN + AR), checked by
-- tests/config.spec. intro/outro are three lines each (Play panel card and result screen); boss
-- maps an enemy id to the line the Hakawati says when that boss arrives in this episode; moments
-- are scripted beats (Episode 8's ally turn); mechanics are what the episode introduces, drawn as
-- icons on its Play panel card (keys of Config/Icons.mechanics and Strings "mech.<key>"; checked
-- against the episode's enemies and arena by tests/storycards.spec).
--
-- The text names roles ("the thief", "the sergeant"), never a character name: names follow the
-- one-letter-off table in STORY_PLAN §3 once the owner approves it (S1-N01).

export type Episode = {
	titleKey: string,
	intro: { string },
	outro: { string },
	boss: { [string]: string },
	moments: { [string]: string }?,
	mechanics: { string },
}

local function lines(prefix: string): { string }
	return { prefix .. ".1", prefix .. ".2", prefix .. ".3" }
end

-- One line per boss, shared by every episode the boss appears in.
local function bosses(ids: { string }): { [string]: string }
	local out = {}
	for _, id in ids do
		out[id] = "story.boss." .. id
	end
	return out
end

local function episode(id: string, mechanics: { string }, bossIds: { string }, moments: { [string]: string }?): Episode
	return {
		titleKey = "story." .. id .. ".title",
		intro = lines("story." .. id .. ".intro"),
		outro = lines("story." .. id .. ".outro"),
		boss = bosses(bossIds),
		moments = moments,
		mechanics = mechanics,
	}
end

local episodes: { [string]: Episode } = {
	ep1 = episode("ep1", { "stealth" }, { "sergeant", "chief_thief" }),
	ep2 = episode("ep2", { "armor", "fast" }, { "sergeant", "chief_thief", "rival_zaim" }),
	ep3 = episode("ep3", { "sapper" }, { "sergeant", "chief_thief", "rival_zaim", "colonel" }),
	ep4 = episode("ep4", { "swarm", "aura" }, { "corporal", "sergeant", "abu_jawdan" }),
	ep5 = episode("ep5", { "burn", "shield" }, { "sergeant", "abu_shatour", "rival_zaim" }),
	ep6 = episode("ep6", { "disguised", "teleport" }, { "corporal", "abu_jawdan", "sergeant", "lateef", "spy" }),
	ep7 = episode("ep7", { "sabotage", "summon" }, { "corporal", "sergeant", "abu_jawdan", "colonel" }),
	ep8 = episode(
		"ep8",
		{ "two_paths", "split", "heal" },
		{ "fakhr", "abu_zira", "chief_thief", "rival_zaim", "rival_zaim_enraged" },
		{ ally_turn = "story.moment.ally_turn" }
	),
	ep9 = episode("ep9", { "ally", "swarm", "stealth" }, { "abu_shatour", "lateef", "abu_zira", "fakhr", "rival_zaim", "colonel" }),
}

return {
	titleKey = "story.season.title",
	order = { "ep1", "ep2", "ep3", "ep4", "ep5", "ep6", "ep7", "ep8", "ep9" },
	episodes = episodes,
}
