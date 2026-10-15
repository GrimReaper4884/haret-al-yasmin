--!strict
-- Tower-defense tunables (docs/TOWER_DEFENSE.md). Pure data: loaded by Lune tests.
-- Every number here is a balance knob; nothing in the client is trusted for any of them.
-- Genre reference numbers: docs/research/ROBLOX_TOWER_DEFENSE_GENRE.md.

return {
	-- Match
	START_CASH = 500, -- per player, at the start of a match
	WAVE_BONUS_BASE = 90, -- cash to every player when a wave is cleared …
	WAVE_BONUS_PER_WAVE = 20, -- … plus this per wave number
	SKIP_BONUS = 60, -- extra cash to everyone when all players vote to skip the countdown
	PREP_SECONDS = 15, -- before wave 1
	BETWEEN_WAVES = 9, -- countdown between waves
	TICK = 1 / 20, -- simulation step (seconds of game time)
	POSITION_RATE = 0.1, -- seconds between enemy position broadcasts
	FREE_SPEED = 2, -- fastest speed without a pass
	PASS_SPEED = 3, -- with the Fast Mode pass
	MAX_PLAYERS = 4,
	MAX_MATCHES = 6, -- arenas per server
	RESULT_SECONDS = 12, -- how long the result screen stays before returning to the lane
	QUEUE_SECONDS = 25, -- portal countdown once the first player steps in
	QUEUE_FULL_SECONDS = 5, -- countdown once the party is full

	-- Placement
	LOADOUT_SLOTS = 6, -- +1 with the Extra Slot pass
	TOWER_CAP = 20, -- per player
	TOWER_SPACING = 2.6, -- studs between towers
	PATH_HALF_WIDTH = 3.2, -- towers must stay this far from the path centreline
	SELL_REFUND = 0.6, -- fraction of cash invested returned on sell

	-- Difficulty: enemy HP / speed multipliers, reward multiplier, gate HP
	DIFFICULTIES = {
		normal = { hp = 1.0, speed = 1.0, reward = 1.0, gate = 100, order = 1 },
		hard = { hp = 1.6, speed = 1.08, reward = 1.6, gate = 60, order = 2 },
		nightmare = { hp = 2.6, speed = 1.15, reward = 2.4, gate = 35, order = 3 },
	},
	DIFFICULTY_ORDER = { "normal", "hard", "nightmare" },

	-- Summons (lira). Odds are displayed before every purchase (paid random items policy).
	SUMMON_COST = 50,
	SUMMON_TEN_COST = 500,
	VIP_SUMMON_DISCOUNT = 0.2, -- VIP pays 40 per pull
	ODDS = { rare = 0.755, epic = 0.20, legendary = 0.04, mythic = 0.005 },
	RARITY_ORDER = { "rare", "epic", "legendary", "mythic", "secret" },
	PITY_LEGENDARY = 50, -- a Legendary or better at least every N summons (counter resets on hit)
	PITY_MYTHIC = 400,
	FEATURED_SHARE = 0.5, -- share of a rarity roll that goes to the banner's featured unit
	BANNER_ROTATION = 3600, -- seconds per banner

	-- Collection
	STARTER_UNIT = "walad", -- every new player owns this
	STAR_COPIES = { 1, 2, 4, 7, 11 }, -- extra copies needed for star 1..5 (cumulative)
	STAR_BONUS = 0.05, -- +5% damage per star
	MAX_LIRA = 10000000,
	MAX_TRAIT_STONES = 100000,
	TRAIT_REROLL_COST = 1, -- trait stones

	-- Rewards (base; × difficulty.reward; × 2 on first clear of a story episode)
	STORY_REWARDS = {
		ep1 = { lira = 80, qirsh = 120, xp = 120 },
		ep2 = { lira = 140, qirsh = 180, xp = 180 },
		ep3 = { lira = 240, qirsh = 260, xp = 260 },
	},
	LOSS_SHARE = 0.25, -- a lost match still pays this share (scaled by waves reached)
	-- Infinite: lira per 10-wave tier (100, 230, 390, +30 per tier to wave 50, then +5)
	INFINITE_TIER_LIRA = { 100, 230, 390, 420, 450 },
	INFINITE_TIER_LIRA_LATE = 5, -- added per tier after wave 50
	INFINITE_QIRSH_PER_WAVE = 8,
	INFINITE_XP_PER_WAVE = 3,
	TRAIT_STONE_DROP = 0.15, -- chance of 1 trait stone on a story win (Hard+)
	VIP_LIRA_BONUS = 0.25,
}
