--!strict
-- Limited-time events. Pure data. An event runs between `startsAt` and `endsAt` (UTC epoch
-- seconds): its mode appears under Play → Event, its corner in the square opens, and its own
-- currency (earned only in its mode) buys from its shop. Currency and purchases are kept per event
-- in profile.events and checked on the server (Logic/EventLogic). No Robux anywhere in an event.
--
-- To run a new event: add it here with its mode (Config/Modes, kind = "event"), its waves
-- (Config/Waves.events) and strings, then deploy.

export type ShopEntry = {
	key: string, -- stable id (purchase counts are stored under it)
	cost: number, -- event currency
	stock: number, -- purchases per player per event
	reward: { lira: number?, qirsh: number?, traitStones: number?, item: string?, unit: string? },
	nameKey: string,
}

export type EventDef = {
	nameKey: string,
	descKey: string,
	currencyKey: string, -- "{n} olives"
	startsAt: number,
	endsAt: number,
	modeId: string,
	perWave: number, -- currency per wave held in the event mode
	winBonus: number, -- extra currency for holding every wave
	maxCurrency: number,
	shop: { ShopEntry },
}

local Events: { [string]: EventDef } = {
	-- Autumn olive harvest in the orchards outside the quarter (2026-10-16 → 2026-11-30 UTC).
	olive_harvest = {
		nameKey = "event.olive_harvest.name",
		descKey = "event.olive_harvest.desc",
		currencyKey = "event.olive_harvest.currency",
		startsAt = 1792108800,
		endsAt = 1795996800,
		modeId = "ev_olive",
		perWave = 3,
		winBonus = 25,
		maxCurrency = 100000,
		shop = {
			{ key = "qirsh_400", cost = 15, stock = 10, reward = { qirsh = 400 }, nameKey = "event.shop.qirsh_400" },
			{ key = "lira_120", cost = 30, stock = 10, reward = { lira = 120 }, nameKey = "event.shop.lira_120" },
			{ key = "stone_1", cost = 45, stock = 5, reward = { traitStones = 1 }, nameKey = "event.shop.stone_1" },
			{ key = "shawl", cost = 160, stock = 1, reward = { item = "shawl_embroidered" }, nameKey = "event.shop.shawl" },
		},
	},
}

return Events
