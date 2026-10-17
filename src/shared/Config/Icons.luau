--!strict
-- Icon registry (POLISH_PLAN PV-C02). Every icon name the UI draws is listed here with the Roblox
-- image id of its painted version. id 0 = not uploaded yet: client UI/Icons falls back to its
-- primitive drawer of the same name (tests/icons.spec.luau checks one exists), the same pattern as
-- CharacterLooks[id].model. Ids come from tools/upload_manifest.json (tools/upload_asset.py) or a
-- Creator Hub upload; `tint` recolours a white-on-alpha image (ImageColor3), otherwise the image
-- keeps its painted colours. Pure data.

export type Icon = { id: number, tint: string? }

local Icons = {}

Icons.images = {
	-- Menu rail (LobbyMenuController: "ui_" .. key) and HUD buttons
	ui_play = { id = 0 },
	ui_event = { id = 0 },
	ui_units = { id = 0 },
	ui_summon = { id = 0 },
	ui_pass = { id = 0 },
	ui_daily = { id = 0 },
	ui_codes = { id = 0 },
	ui_afk = { id = 0 },
	ui_settings = { id = 0 },
	ui_music = { id = 0 },
	ui_music_off = { id = 0 },

	-- Currencies and reward kinds (PV-C03)
	lira = { id = 0 },
	qirsh = { id = 0 },
	cash = { id = 0 },
	stone = { id = 0 },
	stones_3 = { id = 0 },
	xp = { id = 0 },
	pass = { id = 0 },
	ticket = { id = 0 },
	lira_stack = { id = 0 },
	qirsh_pouch = { id = 0 },
	coins = { id = 0 },

	-- Enemy health-bar markers (PV-A04)
	shield = { id = 0 },
	eye = { id = 0 },

	-- Wardrobe items (Items[].icon; tinted by Items[].iconColor while primitive)
	basket = { id = 0 },
	tarboosh = { id = 0 },
	cap = { id = 0 },
	hatta = { id = 0 },
	vest = { id = 0 },
	robe = { id = 0 },
	trousers = { id = 0 },
	sash = { id = 0 },
	cloak = { id = 0 },
} :: { [string]: Icon }

-- Reward table key (SeasonPass, Daily, Events, Codes rewards) → icon name. `item` uses the item's
-- own icon and `unit` the unit portrait (PV-C05); `matchCash` is match cash.
Icons.reward = {
	lira = "lira",
	qirsh = "qirsh",
	traitStones = "stone",
	xp = "xp",
	matchCash = "cash",
	item = "@item",
	unit = "@unit",
	allUnits = "@unit",
} :: { [string]: string }

-- Developer product kind (Config/Products) → store card icon.
Icons.product = {
	lira = "lira_stack",
	qirsh = "qirsh_pouch",
	stones = "stones_3",
	item = "@item",
	passPremium = "pass",
	passSkip = "pass",
	bundle = "lira_stack",
} :: { [string]: string }

return Icons
