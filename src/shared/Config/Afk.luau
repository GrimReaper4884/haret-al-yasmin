--!strict
-- The AFK chamber: the Hakawati's room upstairs in the coffee house (docs/AFK_CHAMBER.md). Pure
-- data: loaded by Lune tests. Every number is a balance knob; the server owns the clock.
--
-- While a player sits in the room the storyteller pours a cup of tea every CUP_SECONDS and pays
-- CUP; every CUPS_PER_TALE cups he finishes a tale and pays TALE on top. The pay is ×(1 + bonuses)
-- for VIP and Roblox Premium, and so is the day's lira cap (DAILY_CAP_LIRA per UTC day): VIP really
-- is "2× AFK", but overnight AFK can't outpace playing. Once the day's lira are in, the cups keep
-- paying a little qirsh (OVERFLOW) so staying is never worth nothing. Progress toward the next cup
-- lives in the profile (`afk.carry`), so a disconnect or the anti-idle hop never loses time.
--
-- Genre reference (docs/AFK_CHAMBER.md §1): their Time Chamber pays about
-- 15 % of an active hour's premium currency, uncapped; ours pays ~12 % of an active hour and caps
-- the day because our lira economy is far tighter (250–400 lira a day for an active free player).

export type Reward = { lira: number?, qirsh: number?, xp: number?, traitStones: number? }

return {
	ORIGIN = { -3000, 0, 0 }, -- room centre (x, y, z); far from the lane and the arenas (x >= 3000)
	CUP_SECONDS = 300, -- one cup of tea every 5 minutes
	CUP = { lira = 5, qirsh = 10, xp = 15 } :: Reward,
	CUPS_PER_TALE = 6, -- a tale every 30 minutes
	TALE = { lira = 10, qirsh = 20, xp = 40 } :: Reward, -- base: 80 lira / 160 qirsh / 260 XP an hour
	TALE_STONE_CHANCE = 0.05, -- a trait stone on one finished tale in twenty (before the cap)
	DAILY_CAP_LIRA = 240, -- lira per UTC day from the room at ×1 (3 hours); scales with the bonus
	OVERFLOW = { qirsh = 3 } :: Reward, -- per cup once the day's lira are in (also scaled)
	-- Bonuses add up: VIP alone ×2, Premium alone ×1.5, both ×2.5.
	VIP_BONUS = 1,
	PREMIUM_BONUS = 0.5,
	MAX_SESSION_SECONDS = 12 * 3600, -- a single visit longer than this ends
	FLUSH_SECONDS = 30, -- the server writes sitting time to the profile at least this often

	-- Roblox disconnects a player after 20 minutes without input. While inside, the client watches
	-- Player.Idled and past IDLE_HOP_SECONDS asks the server to move it to a fresh server of this
	-- place, where it walks straight back into the room (TeleportData { afk = true }).
	IDLE_HOP_SECONDS = 15 * 60,
	HOP_COOLDOWN = 10 * 60, -- per player, server-side
	-- Lobby players idle this long are walked up to the room (setting "autoAfk", on by default).
	AUTO_ENTER_IDLE_SECONDS = 5 * 60,

	-- The tales the storyteller tells, in order (the folk epics of the coffee houses, plus one of
	-- the lane's own; Strings "afk.tale.<id>" and "afk.line.<id>.1..LINES"). Cycles.
	TALES = { "antar", "baybars", "hilali", "zir", "sayf", "lane" },
	LINES = 3, -- storyteller lines per tale (shown in turn above his chair)
	LINE_SECONDS = 14,
	-- Where players come back out: in the coffee house, facing the square.
	RETURN = { -33, 0, -20.5 },
}
