--!strict
-- What a finished match pays (lira, qirsh, pass XP, trait stones) and the progression it unlocks.
-- Pure; rng() → [0, 1) for the trait stone drop.

local MatchRewards = {}

export type Outcome = { won: boolean, wavesCleared: number, totalWaves: number? }
export type Reward = { lira: number, qirsh: number, xp: number, traitStones: number, firstClear: boolean, unit: string? }

local function infiniteLira(waves: number, td: any): number
	local lira = 0
	local tiers = waves // 10
	for i = 1, tiers do
		local base = td.INFINITE_TIER_LIRA[math.min(i, #td.INFINITE_TIER_LIRA)]
		if i > #td.INFINITE_TIER_LIRA then
			base += td.INFINITE_TIER_LIRA_LATE * (i - #td.INFINITE_TIER_LIRA)
		end
		lira += base
	end
	return lira
end

-- mode: Config/Modes entry; difficulty: key; profile.td.cleared is read for first-clear bonuses.
function MatchRewards.compute(modeId: string, mode: any, difficulty: string, outcome: Outcome, profile: any, vip: boolean, td: any, rng: () -> number): Reward
	local diff = td.DIFFICULTIES[difficulty] or td.DIFFICULTIES.normal
	local lira, qirsh, xp = 0, 0, 0
	local firstClear = false
	if mode.kind == "story" then
		local base = td.STORY_REWARDS[mode.episode]
		local share = if outcome.won then 1 else td.LOSS_SHARE * (outcome.wavesCleared / math.max(1, outcome.totalWaves or 1))
		lira = base.lira * diff.reward * share
		qirsh = base.qirsh * diff.reward * share
		xp = base.xp * share
		if outcome.won then
			local cleared = profile.td.cleared[modeId]
			local clearedOrder = if cleared then td.DIFFICULTIES[cleared].order else 0
			if diff.order > clearedOrder then
				firstClear = true
				lira *= 2
				xp *= 2
			end
		end
	elseif mode.kind == "event" and mode.rewards then
		local share = if outcome.won then 1 else td.LOSS_SHARE * (outcome.wavesCleared / math.max(1, outcome.totalWaves or 1))
		lira = mode.rewards.lira * share
		qirsh = mode.rewards.qirsh * share
		xp = mode.rewards.xp * share
	else
		lira = infiniteLira(outcome.wavesCleared, td) * diff.reward
		qirsh = td.INFINITE_QIRSH_PER_WAVE * outcome.wavesCleared * diff.reward
		xp = td.INFINITE_XP_PER_WAVE * outcome.wavesCleared
	end
	if vip then
		lira *= 1 + td.VIP_LIRA_BONUS
	end
	local stones = 0
	if outcome.won and mode.kind == "story" and diff.order >= 2 and rng() < td.TRAIT_STONE_DROP then
		stones = 1
	end
	-- First-clear gifts (TD.STORY_FIRST_CLEAR): for each difficulty this clear reaches for the first time.
	local gifts = firstClear and td.STORY_FIRST_CLEAR and td.STORY_FIRST_CLEAR[mode.episode]
	local unit: string? = nil
	if gifts then
		local cleared = profile.td.cleared[modeId]
		local clearedOrder = if cleared then td.DIFFICULTIES[cleared].order else 0
		for key, gift in gifts do
			local need = td.DIFFICULTIES[key].order
			if clearedOrder < need and diff.order >= need then
				stones += gift.traitStones or 0
				unit = gift.unit or unit
			end
		end
	end
	return {
		lira = math.floor(lira + 0.5),
		qirsh = math.floor(qirsh + 0.5),
		xp = math.floor(xp + 0.5),
		traitStones = stones,
		firstClear = firstClear,
		unit = unit,
	}
end

-- Beads a finished match earns (Config/Beads, S1-S11). Call inside the reward's DataService.mutate,
-- BEFORE MatchRewards.record (it reads the old first-clear state) so the grant and the daily counter
-- land in the same mutation as the rest of the reward. today = the UTC day number. Returns the
-- number of beads to grant (the daily counter in profile.td is updated here).
function MatchRewards.beads(profile: any, modeId: string, mode: any, difficulty: string, outcome: Outcome, beads: any, td: any, today: number): number
	if not outcome.won or mode.kind ~= "story" then
		return 0
	end
	local diff = td.DIFFICULTIES[difficulty]
	if not diff then
		return 0
	end
	local n = 0
	local gifts = beads.firstClear[mode.episode]
	if gifts then
		local cleared = profile.td.cleared[modeId]
		local clearedOrder = if cleared then td.DIFFICULTIES[cleared].order else 0
		for key, count in gifts do
			local need = td.DIFFICULTIES[key].order
			if clearedOrder < need and diff.order >= need then
				n += count
			end
		end
	end
	if beads.winDrops[mode.episode] and diff.order >= 2 then
		local t = profile.td
		if t.beadDay ~= today then
			t.beadDay = today
			t.beadDayCount = 0
		end
		if (t.beadDayCount or 0) < beads.perDay then
			t.beadDayCount = (t.beadDayCount or 0) + 1
			n += 1
		end
	end
	return n
end

-- The secret unit roll (TD.SECRET_DROP, S1-S12). Call inside the reward's DataService.mutate,
-- BEFORE MatchRewards.record (the Nightmare guarantee reads the old clear). Updates
-- profile.td.secretPity; returns the unit id to grant, or nil. rng() → [0, 1).
function MatchRewards.secretDrop(profile: any, modeId: string, mode: any, difficulty: string, outcome: Outcome, drop: any, td: any, rng: () -> number): string?
	if not drop or not outcome.won or mode.kind ~= "story" or mode.episode ~= drop.episode then
		return nil
	end
	local t = profile.td
	local chance = drop.chance[difficulty] or 0
	local cleared = t.cleared[modeId]
	local clearedOrder = if cleared then td.DIFFICULTIES[cleared].order else 0
	local firstNightmare = difficulty == "nightmare" and clearedOrder < td.DIFFICULTIES.nightmare.order
	local pity = (t.secretPity or 0) + 1
	if firstNightmare or pity >= drop.pity or rng() < chance then
		t.secretPity = 0
		return drop.unit
	end
	t.secretPity = pity
	return nil
end

-- Records the outcome in profile.td (stats and unlocks). Call inside DataService.mutate.
function MatchRewards.record(profile: any, modeId: string, mode: any, difficulty: string, outcome: Outcome, kills: number, td: any)
	local t = profile.td
	t.matches += 1
	t.kills += kills
	if outcome.won then
		t.wins += 1
		if mode.kind == "story" then
			local cleared = t.cleared[modeId]
			local clearedOrder = if cleared then td.DIFFICULTIES[cleared].order else 0
			if td.DIFFICULTIES[difficulty].order > clearedOrder then
				t.cleared[modeId] = difficulty
			end
		end
	end
	if mode.kind == "infinite" and outcome.wavesCleared > t.bestInfinite then
		t.bestInfinite = outcome.wavesCleared
	end
end

-- Whether a mode/difficulty is open to this profile.
-- The result screen's cash curve (Theme v2, LP-C06). `totals` holds the player's running total of
-- cash earned (cash + spent) at the end of each wave, in order; the curve is what each wave added
-- (never negative; the first wave counts from `start`, the match's starting cash).
function MatchRewards.cashCurve(totals: { number }, start: number): { number }
	local out = {}
	local prev = start
	for _, v in totals do
		table.insert(out, math.max(0, v - prev))
		prev = math.max(prev, v)
	end
	return out
end

-- Points of a sparkline in a w × h box (y grows down): one point per value, evenly spaced, the
-- highest value at the top, zero at the bottom. One value draws a flat line across; none, nothing.
function MatchRewards.sparkline(values: { number }, w: number, h: number): { { number } }
	local n = #values
	if n == 0 then
		return {}
	end
	local top = 0
	for _, v in values do
		top = math.max(top, v)
	end
	local pts = {}
	for i, v in values do
		local x = if n == 1 then 0 else (i - 1) / (n - 1) * w
		local y = if top <= 0 then h else h - v / top * h
		table.insert(pts, { x, y })
	end
	if n == 1 then
		table.insert(pts, { w, pts[1][2] })
	end
	return pts
end

function MatchRewards.canPlay(profile: any, modeId: string, modes: { [string]: any }, difficulty: string, td: any): (boolean, string?)
	local mode = modes[modeId]
	if not mode then
		return false, "unknown_mode"
	end
	local diff = td.DIFFICULTIES[difficulty]
	if not diff then
		return false, "bad_difficulty"
	end
	if mode.requires and not profile.td.cleared[mode.requires] then
		return false, "locked_mode"
	end
	if diff.order > 1 and mode.kind == "story" then
		local cleared = profile.td.cleared[modeId]
		local clearedOrder = if cleared then td.DIFFICULTIES[cleared].order else 0
		if clearedOrder < diff.order - 1 then
			return false, "locked_difficulty"
		end
	end
	return true, nil
end

return MatchRewards
