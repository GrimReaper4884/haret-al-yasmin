--!strict
-- The Story tab of the Play panel (STORY_PLAN §10.3, S1-C01): the nine episode cards in Config/Story
-- order (an episode without a Config/Modes entry yet is "soon": shown, not playable), the first-clear
-- gifts a player can still earn on a difficulty, and the secret unit's odds line. Pure: the callers
-- pass the configs (Story, Modes, TD, Beads) and the player's cleared difficulty.

export type Card = { id: string, number: number, mode: any?, soon: boolean }
export type Gift = { difficulty: string, traitStones: number, beads: number, unit: string? }
export type SecretOdds = { unit: string, chance: number, pity: number }

local StoryCards = {}

function StoryCards.cards(story: any, modes: { [string]: any }): { Card }
	local out: { Card } = {}
	for i, id in story.order do
		local mode = modes[id]
		local playable = mode ~= nil and mode.kind == "story"
		table.insert(out, { id = id, number = i, mode = if playable then mode else nil, soon = not playable })
	end
	return out
end

-- First-clear gifts of a mode still ahead of `cleared` (the best difficulty already cleared, or nil),
-- one entry per difficulty in TD.DIFFICULTY_ORDER: trait stones and units (TD.STORY_FIRST_CLEAR) and beads
-- (Beads.firstClear). Mirrors MatchRewards.compute / MatchRewards.beads.
function StoryCards.gifts(mode: any, td: any, beads: any, cleared: string?): { Gift }
	local out: { Gift } = {}
	if mode == nil or mode.kind ~= "story" then
		return out
	end
	local stones = td.STORY_FIRST_CLEAR and td.STORY_FIRST_CLEAR[mode.episode] or {}
	local beadGifts = beads.firstClear[mode.episode] or {}
	local clearedOrder = if cleared and td.DIFFICULTIES[cleared] then td.DIFFICULTIES[cleared].order else 0
	for _, key in td.DIFFICULTY_ORDER do
		local s = stones[key] and stones[key].traitStones or 0
		local u = stones[key] and stones[key].unit
		local b = beadGifts[key] or 0
		if td.DIFFICULTIES[key].order > clearedOrder and (s > 0 or b > 0 or u ~= nil) then
			table.insert(out, { difficulty = key, traitStones = s, beads = b, unit = u })
		end
	end
	return out
end

-- The secret-unit roll a win of `episodeId` on `difficulty` makes (TD.SECRET_DROP), or nil.
function StoryCards.secretOdds(td: any, episodeId: string, difficulty: string): SecretOdds?
	local drop = td.SECRET_DROP
	if drop == nil or drop.episode ~= episodeId then
		return nil
	end
	local chance = drop.chance[difficulty]
	if chance == nil then
		return nil
	end
	return { unit = drop.unit, chance = chance, pity = drop.pity }
end

-- The Hakawati's room tales (S1-C06): one per episode in story order, its outro readable once the
-- player has cleared that episode on any difficulty (`cleared` = profile.td.cleared). Read-only.
export type Tale = { id: string, number: number, titleKey: string, lines: { string }, unlocked: boolean }

function StoryCards.tales(story: any, cleared: { [string]: any }?): { Tale }
	local out: { Tale } = {}
	for i, id in story.order do
		local ep = story.episodes[id]
		table.insert(out, { id = id, number = i, titleKey = ep.titleKey, lines = ep.outro, unlocked = cleared ~= nil and cleared[id] ~= nil })
	end
	return out
end

-- 0.01 → "1", 0.025 → "2.5" (one decimal at most, no trailing ".0").
function StoryCards.percent(chance: number): string
	local s = string.format("%.1f", chance * 100)
	return (string.gsub(s, "%.0$", ""))
end

return StoryCards
