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
	ui_music = { id = 116428282368219 },
	ui_music_off = { id = 118573460190934 },
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
	coins = { id = 119537322287101 },

	-- Difficulty ribbons (PV-C06), by TD.DIFFICULTY_ORDER key
	diff_normal = { id = 84262010666406 },
	diff_hard = { id = 126028072998521 },
	diff_nightmare = { id = 119398560683518 },

	-- Enemy health-bar markers (PV-A04)
	shield = { id = 80380706316361 },
	eye = { id = 114096895353976 },

	-- Wardrobe items (Items[].icon): pale painted pieces recoloured by Items[].iconColor
	basket = { id = 132706876306427 },
	tarboosh = { id = 82053544513629, recolor = true },
	cap = { id = 127837332858213, recolor = true },
	hatta = { id = 138327566793330, recolor = true },
	vest = { id = 112033811845338, recolor = true },
	robe = { id = 139723744408376, recolor = true },
	trousers = { id = 133519985927952, recolor = true },
	sash = { id = 134035941908098, recolor = true },
	cloak = { id = 70826930774461, recolor = true },
} :: { [string]: Icon }

-- Mode banners (PV-C06): Config/Modes key → 512×288 painted banner (Play panel cards, result screen).
Icons.modes = {
	ep1 = { id = 98610965293669 },
	ep2 = { id = 70959689012811 },
	ep3 = { id = 93089947848285 },
	ev_olive = { id = 119222103493381 },
	infinite = { id = 108697701587533 },
} :: { [string]: Icon }

-- Character portraits (PV-C05): unit or enemy id → 128² head-and-shoulders image, rendered from the
-- figure by tools/icons/portrait_render.luau + portraits.py. `model` is the CharacterLooks model it was
-- rendered from ("" = the primitive figure); UnitCard shows it only while that still matches, so a newly
-- imported model falls back to its live viewport until the portrait is re-rendered.
export type Portrait = { id: number, model: string }
Icons.portraits = {
	-- Defenders
	walad = { id = 137506377504428, model = "LaneBoy" },
	natour = { id = 93314435304199, model = "AbuFares" },
	farran = { id = 136063904564645, model = "AbuBashir" },
	saqqa = { id = 97661723924568, model = "Fawzia" },
	hallaq = { id = 78904073713642, model = "Issam" },
	khayyat = { id = 93177367730945, model = "AbuGhalib" },
	qahwaji = { id = 133770563324554, model = "AbuHatem" },
	qabaday = { id = 138798466079086, model = "Motaz" },
	haddad = { id = 80513823020473, model = "AbuKhater" },
	mukhtar = { id = 71493269450072, model = "AbuBadr" },
	zaim = { id = 70842411073565, model = "AbuSaleh" },
	pahlawan = { id = 139062433898050, model = "Strongman" },
	umm_hara = { id = 95850884167044, model = "AbuIssam" },
	arada = { id = 112960454245872, model = "Arada" },
	zaim_akbar = { id = 139294337065178, model = "AbuShehab" },
	-- Attackers
	gendarme = { id = 115451910060448, model = "Gendarme" },
	corporal_minion = { id = 115451910060448, model = "Gendarme" }, -- same mesh as the gendarme (S1-S05)
	thief = { id = 102539531902290, model = "Thief" },
	bandit = { id = 120949810630957, model = "Bandit" },
	thug = { id = 135478284152010, model = "Thug" },
	rider = { id = 101117813202159, model = "Rider" },
	sapper = { id = 101949803501935, model = "Sapper" },
	spy = { id = 117876863565509, model = "Nims" },
	sergeant = { id = 73566511528622, model = "Sergeant" },
	chief_thief = { id = 131496373841818, model = "Idaashari" },
	rival_zaim = { id = 93232597039986, model = "AbuNar" },
	rival_zaim_enraged = { id = 93232597039986, model = "AbuNar" }, -- same mesh as Abu al-Nahr (S1-S08)
	colonel = { id = 106285960688999, model = "Commandant" },
} :: { [string]: Portrait }

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
