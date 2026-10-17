--!strict
-- Icon registry (POLISH_PLAN PV-C02). Every icon name the UI draws is listed here with the Roblox
-- image id of its painted version. id 0 = not uploaded yet: client UI/Icons falls back to its
-- primitive drawer of the same name (tests/icons.spec.luau checks one exists), the same pattern as
-- CharacterLooks[id].model. Ids come from tools/upload_manifest.json (tools/upload_asset.py) or a
-- Creator Hub upload; `tint` recolours a white-on-alpha image (ImageColor3), otherwise the image
-- keeps its painted colours; `recolor` makes a white image take the caller's colour (Icons.draw colorHex).
-- Pure data.

export type Icon = { id: number, tint: string?, recolor: boolean? }

local Icons = {}

Icons.images = {
	-- Menu rail (LobbyMenuController: "ui_" .. key) and HUD buttons
	ui_play = { id = 119124942337695 },
	ui_event = { id = 81866345377315 },
	ui_units = { id = 93072318807029 },
	ui_summon = { id = 139894468545667 },
	ui_pass = { id = 100612098218612 },
	ui_daily = { id = 79760059433884 },
	ui_codes = { id = 129498450392895 },
	ui_afk = { id = 73616718849628 },
	ui_settings = { id = 126392875254573 },
	ui_music = { id = 0 },
	ui_music_off = { id = 0 },
	ui_shop = { id = 91398480705014 },

	-- Match actions and defender roles (PV-C04)
	act_upgrade = { id = 118839200965690 },
	act_sell = { id = 136960612732395 },
	act_target = { id = 130728713809801 },
	act_speed = { id = 115153852782730 },
	act_skip = { id = 84586717628744 },
	act_leave = { id = 79507462286688 },
	role_melee = { id = 123022930977561 },
	role_ranged = { id = 120445918635830 },
	role_splash = { id = 102067809885629 },
	role_support = { id = 93302330771605 },
	role_healer = { id = 138499908268330 },
	role_farm = { id = 123072503034014 },
	-- A white gem tinted per rarity (Theme.rarityColor) for card corners
	gem = { id = 112303897320983, recolor = true },

	-- Currencies and reward kinds (PV-C03)
	lira = { id = 91594568838206 },
	qirsh = { id = 140599145045126 },
	cash = { id = 129410440388323 },
	stone = { id = 121079621002145 },
	stones_3 = { id = 80815170078106 },
	xp = { id = 87817934165202 },
	pass = { id = 111255187450298 },
	ticket = { id = 113199979121197 },
	lira_stack = { id = 93445954754265 },
	qirsh_pouch = { id = 82947809330849 },
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
