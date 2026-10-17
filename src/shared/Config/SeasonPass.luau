--!strict
-- Season pass ("Lane Diary"). Pure data. 50 levels; the free track pays everyone, the premium
-- track (game pass `season_pass`) doubles the lira and adds trait stones, a cosmetic and the
-- season's exclusive unit at level 50. XP comes from matches, dailies and quests (Logic/PassLogic).

export type Reward = { lira: number?, qirsh: number?, traitStones: number?, item: string?, unit: string? }
export type Tier = { xp: number, free: Reward, premium: Reward }

local LEVELS = 50

local tiers: { Tier } = {}
for level = 1, LEVELS do
	local free: Reward = {}
	local premium: Reward = {}
	if level % 10 == 0 then
		free.lira = 120
		premium.lira = 240
		premium.traitStones = 2
	elseif level % 5 == 0 then
		free.lira = 60
		premium.lira = 120
		premium.traitStones = 1
	elseif level % 2 == 0 then
		free.lira = 25
		premium.lira = 50
	else
		free.qirsh = 60
		premium.qirsh = 120
		premium.lira = 20
	end
	if level == 15 then
		premium.item = "shawl_embroidered"
	elseif level == 30 then
		premium.item = "tarboosh_gold"
	elseif level == 50 then
		free.lira = 300
		premium.lira = 600
		premium.unit = "zaim_akbar"
	end
	tiers[level] = { xp = 100 + 10 * (level - 1), free = free, premium = premium }
end

return {
	season = "s1",
	nameKey = "pass.season.s1.name",
	-- 2026-11-30 00:00 UTC. Nothing happens automatically at the end: the owner ships season 2.
	endsAt = 1764460800,
	levels = LEVELS,
	tiers = tiers,
	XP_PER_LEVEL_SKIP = 1, -- product `pass_skip_10` grants 10 levels
}
