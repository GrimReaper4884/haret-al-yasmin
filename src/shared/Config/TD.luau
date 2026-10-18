--!strict
-- Tower-defense tunables (docs/TOWER_DEFENSE.md). Pure data: loaded by Lune tests.
-- Every number here is a balance knob; nothing in the client is trusted for any of them.
-- Genre reference numbers: docs/research/ROBLOX_TOWER_DEFENSE_GENRE.md.

return {
	-- Match
	START_CASH = 600, -- per player, at the start of a match
	WAVE_BONUS_BASE = 110, -- cash to every player when a wave is cleared …
	WAVE_BONUS_PER_WAVE = 20, -- … plus this per wave number
	SKIP_BONUS = 60, -- extra cash to everyone when all players vote to skip the countdown
	PREP_SECONDS = 15, -- before wave 1
	STUN_CHAIN_MAX = 6, -- seconds a chain of stuns can hold an enemy (stun-locks end) …
	STUN_IMMUNITY = 3, -- … then it ignores stuns for this long (an enemy walks at least a third of the time)
	-- Burning gate (torchbearers, Enemies[id].burn; STORY_PLAN §5.2 ep5): each stack costs the gate
	-- BURN_DAMAGE HP every BURN_TICK seconds for BURN_SECONDS after the newest stack, at most
	-- BURN_MAX_STACKS; dousing defenders (Units[id].douse) take stacks off; a cleared wave puts it out.
	BURN_MAX_STACKS = 5,
	BURN_TICK = 2,
	BURN_DAMAGE = 1,
	BURN_SECONDS = 20,
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
	-- Party scaling, indexed by players in the match (1..MAX_PLAYERS). Every player gets their own
	-- start cash and wave bonus (× PARTY_CASH) and builds their own defence, so regular enemies get
	-- PARTY_HP × their HP; bosses meet every defender on the road and get the milder PARTY_BOSS_HP.
	-- Tuned with `lune run tests/balance --party N` (docs/TOWER_DEFENSE.md §5).
	PARTY_HP = { 1, 1.65, 2.3, 3.0 },
	PARTY_BOSS_HP = { 1, 1.35, 1.65, 2.1 },
	PARTY_CASH = { 1, 1, 1, 1 },

	-- Placement
	LOADOUT_SLOTS = 6, -- +1 with the Extra Slot pass
	TOWER_CAP = 20, -- per player
	TOWER_SPACING = 2.6, -- studs between towers
	PATH_HALF_WIDTH = 3.2, -- towers must stay this far from the path centreline
	SELL_REFUND = 0.6, -- fraction of cash invested returned on sell
	-- Supports stack (LP-A02): a defender's damage is 1 + Σ(buff − 1) over every other support covering
	-- it (one player's copies of the same unit count once), capped here at +80 %: the highest cap that
	-- keeps the balance ladder (1.9 lets a party of 4 Legendaries win Episode 1 Nightmare), and never
	-- below one support's own best (Loud 1.8). Hastes multiply the attack cooldown and are floored
	-- here. TOWER_DEFENSE.md §4.4, DECISIONS D-092.
	BUFF_CAP = 1.8,
	HASTE_FLOOR = 0.7,

	-- Difficulty: enemy HP multiplier; growth = multiplier on the per-wave HP growth of story
	-- episodes (the opening waves stay playable with starter cash, the late waves bite); endless =
	-- the same for Endless Night (its curve is already quadratic); boss = extra boss HP; speed
	-- multiplier; reward = kill cash and lira multiplier; gate HP. Tuned with `lune run tests/balance`
	-- (results in docs/TOWER_DEFENSE.md §5).
	DIFFICULTIES = {
		normal = { hp = 1.0, growth = 1.0, endless = 1.0, boss = 1.0, speed = 1.0, reward = 1.0, gate = 100, order = 1 },
		hard = { hp = 1.25, growth = 1.7, endless = 1.25, boss = 1.0, speed = 1.05, reward = 1.6, gate = 60, order = 2 },
		nightmare = { hp = 1.0, growth = 4.5, endless = 1.6, boss = 1.8, speed = 1.1, reward = 2.4, gate = 35, order = 3 },
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
	STARTER_LIRA = 500, -- one-time welcome gift (one ×10 summon); also reaches players who joined before it existed
	STAR_COPIES = { 1, 2, 4, 7, 11 }, -- extra copies needed for star 1..5 (cumulative)
	STAR_BONUS = 0.05, -- +5% damage per star
	MAX_LIRA = 10000000,
	MAX_TRAIT_STONES = 100000,
	TRAIT_REROLL_COST = 1, -- trait stones (either slot)
	TRAIT2_STARS = 3, -- stars a unit needs before its second trait slot opens (traits v2)

	-- Rewards (base; × difficulty.reward; × 2 on first clear of a story episode)
	STORY_REWARDS = {
		ep1 = { lira = 80, qirsh = 120, xp = 120 },
		ep2 = { lira = 140, qirsh = 180, xp = 180 },
		ep3 = { lira = 240, qirsh = 260, xp = 260 },
		-- Season Story 1 (STORY_PLAN §5.4)
		ep4 = { lira = 300, qirsh = 300, xp = 320 },
		ep5 = { lira = 360, qirsh = 340, xp = 380 },
		ep6 = { lira = 420, qirsh = 380, xp = 440 },
		ep7 = { lira = 480, qirsh = 420, xp = 500 },
		ep8 = { lira = 560, qirsh = 480, xp = 580 },
		ep9 = { lira = 650, qirsh = 540, xp = 680 },
	},
	-- One-off gifts for the first clear of an episode at (or above) a difficulty, on top of the reward:
	-- trait stones and/or a unit (a copy already owned stars it). Beads are in Config/Beads.firstClear.
	STORY_FIRST_CLEAR = {
		ep4 = { normal = { traitStones = 1 } },
		ep6 = { normal = { unit = "qabilah" } }, -- Umm Baki the midwife, the story gift (S1-A03)
	},
	LOSS_SHARE = 0.25, -- a lost match still pays this share (scaled by waves reached)
	-- Infinite: lira per 10-wave tier (100, 230, 390, +30 per tier to wave 50, then +5)
	INFINITE_TIER_LIRA = { 100, 230, 390, 420, 450 },
	INFINITE_TIER_LIRA_LATE = 5, -- added per tier after wave 50
	INFINITE_QIRSH_PER_WAVE = 8,
	INFINITE_XP_PER_WAVE = 3,
	TRAIT_STONE_DROP = 0.15, -- chance of 1 trait stone on a story win (Hard+)
	-- The secret unit (STORY_PLAN §7.6, owner 2026-10-18, D-048): every win of `episode` rolls it at
	-- `chance[difficulty]`; after `pity` wins without it the next win guarantees it; the first
	-- Nightmare clear of the episode always gives it. Not a paid random item (no Robux buys a roll);
	-- the odds are shown on the episode card anyway.
	SECRET_DROP = {
		unit = "adashari",
		episode = "ep9",
		chance = { normal = 0.01, hard = 0.025, nightmare = 0.06 },
		pity = 40,
	},
	VIP_LIRA_BONUS = 0.25,
}
