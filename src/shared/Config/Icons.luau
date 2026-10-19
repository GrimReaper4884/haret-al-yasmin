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
	-- Touch HUD (MOBILE_HUD_PLAN MH-04): primitives until a painted pair is approved
	ui_menu = { id = 0 },
	ui_view = { id = 0 },
	ui_more = { id = 0 },
	ui_lock = { id = 0 }, -- a locked speed chip (LP-A03)
	ui_defenders = { id = 0 }, -- the Defenders panel's rail button: three fezzes (LP-B02)

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

	-- Story mechanics on the Play panel (S1-C01, Icons.mechanics); primitive drawers until painted
	mech_armor = { id = 0 },
	mech_fast = { id = 0 },
	mech_sapper = { id = 0 },
	mech_swarm = { id = 0 },
	mech_drum = { id = 0 },
	mech_roads = { id = 0 },
	mech_burn = { id = 0 },
	mech_disguise = { id = 0 },
	mech_teleport = { id = 0 },
	mech_sabotage = { id = 0 },
	mech_summon = { id = 0 },
	mech_split = { id = 0 },
	mech_heal = { id = 0 },
	mech_ally = { id = 0 },
	-- A shabriyeh bead (Config/Beads), until a painted one exists
	bead = { id = 0 },
	bead_range = { id = 0 },
	bead_cooldown = { id = 0 },
	bead_cash = { id = 0 },
	bead_heal = { id = 0 },
	bead_buff = { id = 0 },

	-- Wardrobe items (Items[].icon): pale painted pieces recoloured by Items[].iconColor
	basket = { id = 132706876306427 },
	tarboosh = { id = 82053544513629, recolor = true },
	cap = { id = 127837332858213, recolor = true },
	hatta = { id = 138327566793330, recolor = true },
	vest = { id = 112033811845338, recolor = true },
	robe = { id = 139723744408376, recolor = true },
	trousers = { id = 133519985927952, recolor = true },
	sash = { id = 134035941908098, recolor = true },
	fanous = { id = 90786801080402 }, -- LP-D12: the Lantern Nights brass fanous (full colour, not tinted)
	cloak = { id = 70826930774461, recolor = true },
} :: { [string]: Icon }

-- Mode banners (PV-C06): Config/Modes key → 512×288 painted banner (Play panel cards, result screen).
Icons.modes = {
	ep1 = { id = 98610965293669 },
	ep2 = { id = 70959689012811 },
	ep3 = { id = 93089947848285 },
	ev_olive = { id = 119222103493381 },
	ev_ramadan = { id = 77282830122368 }, -- LP-D12 Lantern Nights
	infinite = { id = 108697701587533 },
} :: { [string]: Icon }

-- Bead kinds (Config/Beads.kinds) → their icon on the Units screen (S1-C04).
Icons.beads = {
	range = "bead_range",
	cooldown = "bead_cooldown",
	cash = "bead_cash",
	heal = "bead_heal",
	buff = "bead_buff",
} :: { [string]: string }

-- Story mechanics (Config/Story.episodes[id].mechanics) → the icon drawn for each on the Play panel.
Icons.mechanics = {
	stealth = "eye",
	armor = "mech_armor",
	fast = "mech_fast",
	sapper = "mech_sapper",
	swarm = "mech_swarm",
	aura = "mech_drum",
	two_paths = "mech_roads",
	burn = "mech_burn",
	shield = "shield",
	disguised = "mech_disguise",
	teleport = "mech_teleport",
	sabotage = "mech_sabotage",
	summon = "mech_summon",
	split = "mech_split",
	heal = "mech_heal",
	ally = "mech_ally",
} :: { [string]: string }

-- Character portraits (PV-C05): unit or enemy id → 128² head-and-shoulders image, rendered from the
-- figure by tools/icons/portrait_render.luau + portraits.py. `model` is the CharacterLooks model it was
-- rendered from ("" = the primitive figure); UnitCard shows it only while that still matches, so a newly
-- imported model falls back to its live viewport until the portrait is re-rendered.
export type Portrait = { id: number, model: string }
Icons.portraits = {
	-- Defenders
	walad = { id = 137506377504428, model = "LaneBoy" },
	natour = { id = 93314435304199, model = "AbuFares" },
	qabilah = { id = 134168283413116, model = "UmmBaki" },
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
	-- Season Story 1 (S1-A05, S1-A07)
	adashari = { id = 129480120172448, model = "Adashari" },
	hammam = { id = 94554642685040, model = "AbuBasim" },
	hummus = { id = 134954871256848, model = "AbuSamih" },
	iskafi = { id = 108276284703172, model = "AbuHamoud" },
	matriarch = { id = 136188622806631, model = "SudaKhanum" },
	tajir = { id = 126484283642738, model = "AbuBrahim" }, -- LP-E03
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
	-- Season Story 1, batch 1 (S1-A02)
	pickpocket = { id = 104937576576070, model = "Pickpocket" },
	drummer = { id = 135608077051671, model = "Drummer" },
	torchbearer = { id = 104828458020182, model = "Torchbearer" },
	porter = { id = 115073087355888, model = "Porter" },
	disguised = { id = 73390391883285, model = "Disguised" },
	beggar = { id = 82706323206891, model = "Beggar" },
	corporal = { id = 135092251624966, model = "Corporal" },
	abu_jawdan = { id = 99981072657403, model = "AbuJawdan" },
	abu_shatour = { id = 104141919130883, model = "AbuShatour" },
	lateef = { id = 100259993440842, model = "Lateef" },
	-- Season Story 1, batch 2 (S1-A04)
	rifleman = { id = 82824029232245, model = "Rifleman" },
	cart = { id = 115383986277883, model = "DonkeyCart" },
	hakim_rival = { id = 99400540596434, model = "HakimRival" },
	snake = { id = 95632074308862, model = "GraveSnake" },
	brute = { id = 92274296106421, model = "Brute" },
	fakhr = { id = 124184204799611, model = "Fakhr" },
	abu_zira = { id = 93274551501564, model = "AbuZira" },
} :: { [string]: Portrait }

-- Reward table key (SeasonPass, Daily, Events, Codes rewards) → icon name. `item` uses the item's
-- own icon and `unit` the unit portrait (PV-C05); `matchCash` is match cash.
Icons.reward = {
	lira = "lira",
	qirsh = "qirsh",
	traitStones = "stone",
	beads = "bead",
	xp = "xp",
	matchCash = "cash",
	item = "@item",
	unit = "@unit",
	allUnits = "@unit",
} :: { [string]: string }

-- Theme v2 chrome (LP-C01, LOOK_AND_PLAY_PLAN §5.2): 9-slice images for panels, header bands and
-- buttons. `slice` is the SliceCenter rect {x0, y0, x1, y1} in image pixels, `size` the image size.
-- id 0 = not uploaded yet: Theme.chrome leaves the drawn style (stroke, gradient) in place.
Icons.chrome = {
	panel = { id = 0, size = { 128, 128 }, slice = { 40, 40, 88, 88 } }, -- paper on wood, corner ornaments
	header = { id = 0, size = { 256, 48 }, slice = { 24, 8, 232, 40 } }, -- ablaq band (basalt / cream)
	button = { id = 0, size = { 96, 64 }, slice = { 24, 20, 72, 44 } }, -- carved wood, brass bevel
	primary = { id = 0, size = { 96, 64 }, slice = { 24, 20, 72, 44 } }, -- gold leaf
} :: { [string]: { id: number, size: { number }, slice: { number } } }

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
