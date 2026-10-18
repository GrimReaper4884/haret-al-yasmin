--!strict
-- How each defender / attacker is dressed beyond the basic colours in Units / Enemies `visual`:
-- body build, outfit cut, facial hair, cloak. Read by Util/RigBuilder.
--
-- `model` names an imported character under ReplicatedStorage.CharacterModels (see
-- docs/CHARACTER_PIPELINE.md). When that model exists it replaces the primitive figure; when it
-- does not, the primitive figure is built from the rest of this table, so a missing or
-- not-yet-approved asset never breaks a match.
--
-- Imported Meshy models + published clip ids come from assets/unapproved/characters/anim_ids.json
-- (docs/CHARACTER_PIPELINE.md); the primitive fields below stay as the fallback figure.
-- Most defenders now carry the lane drama's main characters (owner's decision, COPYRIGHT_REGISTER
-- C-201); the comment on each row names who. Faces stay stylized cartoons: never an actor likeness.

export type Build = "kid" | "slim" | "normal" | "stout" | "broad" | "giant"
export type Outfit = "qumbaz" | "sherwal" | "abaya" | "uniform" | "apron" | "bisht" | "vest"
export type Beard = "none" | "stubble" | "short" | "full" | "long"
export type Moustache = "none" | "thin" | "thick" | "handlebar"

export type Look = {
	build: Build?,
	outfit: Outfit?,
	beard: Beard?,
	moustache: Moustache?,
	hair: string?, -- facial hair / brows colour (hex)
	cloak: string?, -- over-cloak colour for bisht / abaya (hex)
	apron: string?, -- apron colour (hex)
	model: string?, -- imported model name, if one has been approved
	modelYaw: number?, -- degrees to turn an imported model that does not already face -Z (GLB imports do)
	anims: { idle: number?, attack: number?, walk: number? }?, -- published animation asset ids
	clips: string?, -- baked clip set (Anim/Clips/<id>) when it is not this id's own: a re-skin on another figure's mesh
}

local DARK = "#1F1B18"
local GREY = "#8C8079"
local WHITE = "#E9E4DA"

local Looks: { [string]: Look } = {
	------------------------------------------------------------------ defenders
	walad = {
		build = "kid",
		outfit = "sherwal",
		beard = "none",
		moustache = "none",
		model = "LaneBoy",
		anims = { idle = 112157925514712, attack = 107319959392835 },
	},
	natour = {
		build = "normal",
		outfit = "qumbaz",
		beard = "short",
		moustache = "thick",
		hair = GREY,
		cloak = "#4A2E18",
		model = "AbuFares",
		anims = { idle = 90495332802964, attack = 98400283326592 },
	}, -- Abu Hares the watchman
	farran = {
		build = "stout",
		outfit = "apron",
		beard = "stubble",
		moustache = "thick",
		hair = DARK,
		apron = "#FBF8F1",
		model = "AbuBashir",
		anims = { idle = 104394597256841, attack = 84495088331540 },
	}, -- Abu Baseer the baker
	saqqa = {
		build = "normal",
		outfit = "abaya",
		beard = "none",
		moustache = "none",
		cloak = "#7A3B5C",
		model = "Fawzia",
		-- v2 model (no fused broom; the broom is an Anim/HandProps prop): the published clips were
		-- made for the v1 rig, so only the baked clips (Anim/Clips/saqqa) apply.
	}, -- Fawza
	-- Hissam, Abu Hissam's son and apprentice
	hallaq = {
		build = "slim",
		outfit = "apron",
		beard = "stubble",
		moustache = "thin",
		hair = DARK,
		apron = "#FBF8F1",
		model = "Issam",
		anims = { idle = 134713688366558, attack = 128007614982036 },
	},
	khayyat = {
		build = "stout",
		outfit = "vest",
		beard = "stubble",
		moustache = "thick",
		hair = GREY,
		model = "AbuGhalib",
		anims = { idle = 103539550283275, attack = 124855699529232 },
	}, -- Abu Ghadeb
	qahwaji = {
		build = "stout",
		outfit = "apron",
		beard = "stubble",
		moustache = "thick",
		hair = DARK,
		apron = "#C9A13B",
		model = "AbuHatem",
		anims = { idle = 99420630175988, attack = 137357629317314 },
	}, -- Abu Hazem
	qabaday = {
		build = "broad",
		outfit = "vest",
		beard = "stubble",
		moustache = "handlebar",
		hair = DARK,
		model = "Motaz",
		anims = { idle = 100329174869234, attack = 72491953659647 },
	}, -- Mo'ez
	haddad = {
		build = "broad",
		outfit = "apron",
		beard = "full",
		moustache = "thick",
		hair = DARK,
		apron = "#3D3A38",
		model = "AbuKhater",
		anims = { idle = 79270488835196, attack = 108770696471593 },
	}, -- Abu Shater
	mukhtar = {
		build = "slim",
		outfit = "qumbaz",
		beard = "none",
		moustache = "thick",
		hair = DARK,
		model = "AbuBadr",
		anims = { idle = 118604731409520, attack = 87931164204170 },
	}, -- Abu Bader
	zaim = {
		build = "broad",
		outfit = "bisht",
		beard = "full",
		moustache = "thick",
		hair = WHITE,
		cloak = DARK,
		model = "AbuSaleh",
		anims = { idle = 130775978082816, attack = 111473861813662 },
	}, -- Za'im Abu Faleh
	pahlawan = {
		build = "giant",
		outfit = "sherwal",
		beard = "stubble",
		moustache = "handlebar",
		hair = DARK,
		model = "Strongman",
		anims = { idle = 76414942150002, attack = 80908186732109 },
	},
	-- Abu Hissam, the barber and hakim of the lane: Meshy character (COPYRIGHT_REGISTER C-200)
	umm_hara = {
		build = "slim",
		outfit = "apron",
		beard = "none",
		moustache = "handlebar",
		hair = DARK,
		apron = "#FBF8F1",
		model = "AbuIssam",
		anims = { idle = 106025561358804, attack = 140700990361989 },
	},
	arada = {
		build = "broad",
		outfit = "sherwal",
		beard = "short",
		moustache = "handlebar",
		hair = DARK,
		model = "Arada",
		anims = { idle = 91839698856951, attack = 91462204733625 },
	},
	zaim_akbar = {
		build = "broad",
		outfit = "vest",
		beard = "full",
		moustache = "thick",
		hair = DARK,
		model = "AbuShehab",
		anims = { idle = 106622979715660, attack = 134238214440993 },
	}, -- Al-'Akeed Abu Shehan
	qitt = { model = "Cat" },
	-- Al-Adashari, the night guard (S1-S12): primitive until his Meshy model (S1-A05).
	adashari = { build = "slim", outfit = "qumbaz", beard = "stubble", moustache = "thin", hair = DARK, apron = "#1F1B18" },

	------------------------------------------------------------------ attackers
	gendarme = {
		build = "slim",
		outfit = "uniform",
		beard = "none",
		moustache = "thin",
		hair = DARK,
		model = "Gendarme",
		anims = { walk = 127807283756558 },
	},
	thief = {
		build = "slim",
		outfit = "sherwal",
		beard = "stubble",
		moustache = "thin",
		hair = DARK,
		model = "Thief",
		anims = { walk = 138865475842481 },
	},
	bandit = {
		build = "broad",
		outfit = "qumbaz",
		beard = "full",
		moustache = "thick",
		hair = DARK,
		cloak = "#4A3B30",
		model = "Bandit",
	},
	thug = { build = "stout", outfit = "vest", beard = "stubble", moustache = "thick", hair = DARK, model = "Thug" },
	rider = { build = "normal", outfit = "uniform", beard = "none", moustache = "handlebar", hair = DARK, model = "Rider" },
	sapper = { build = "stout", outfit = "uniform", beard = "short", moustache = "thick", hair = DARK, model = "Sapper" },
	spy = {
		build = "slim",
		outfit = "qumbaz",
		beard = "none",
		moustache = "thin",
		hair = DARK,
		cloak = "#EADFC8",
		model = "Nims",
		anims = { walk = 118280743752950 },
	},
	sergeant = { build = "broad", outfit = "uniform", beard = "none", moustache = "handlebar", hair = DARK, model = "Sergeant" },
	chief_thief = {
		build = "broad",
		outfit = "qumbaz",
		beard = "short",
		moustache = "handlebar",
		hair = DARK,
		cloak = DARK,
		model = "Idaashari",
		anims = { walk = 120072524188528 },
	},
	rival_zaim = {
		build = "broad",
		outfit = "bisht",
		beard = "full",
		moustache = "thick",
		hair = DARK,
		cloak = "#3E5B3A",
		model = "AbuNar",
		anims = { walk = 100088303835625 },
	},
	colonel = { build = "giant", outfit = "uniform", beard = "none", moustache = "handlebar", hair = GREY, model = "Commandant" },

	-- Season Story 1, batch 1 (S1-S03 config, S1-A02 Meshy models; register C-242..C-251).
	pickpocket = { build = "kid", outfit = "sherwal", beard = "none", moustache = "none", hair = DARK, model = "Pickpocket" },
	drummer = { build = "stout", outfit = "qumbaz", beard = "stubble", moustache = "thick", hair = DARK, model = "Drummer" },
	torchbearer = { build = "slim", outfit = "vest", beard = "stubble", moustache = "thin", hair = DARK, model = "Torchbearer" },
	porter = { build = "broad", outfit = "vest", beard = "short", moustache = "thick", hair = DARK, model = "Porter" },
	disguised = { build = "normal", outfit = "qumbaz", beard = "short", moustache = "thin", hair = DARK, cloak = "#D9C9A8", model = "Disguised" },
	beggar = { build = "slim", outfit = "abaya", beard = "stubble", moustache = "none", hair = GREY, cloak = "#6E6A64", model = "Beggar" },
	corporal = { build = "slim", outfit = "uniform", beard = "none", moustache = "thin", hair = DARK, model = "Corporal" },
	abu_jawdan = { build = "stout", outfit = "uniform", beard = "none", moustache = "handlebar", hair = DARK, model = "AbuJawdan" },
	abu_shatour = { build = "broad", outfit = "vest", beard = "stubble", moustache = "thick", hair = DARK, model = "AbuShatour" },
	lateef = { build = "slim", outfit = "abaya", beard = "stubble", moustache = "thin", hair = DARK, cloak = "#6E6A64", model = "Lateef" },
	-- Season Story 1, batch 2 (S1-S08): primitive figures until S1-A04.
	rifleman = { build = "slim", outfit = "uniform", beard = "none", moustache = "thin", hair = DARK },
	cart = { build = "giant", outfit = "vest", beard = "none", moustache = "none", hair = GREY },
	hakim_rival = { build = "slim", outfit = "abaya", beard = "short", moustache = "thin", hair = GREY, cloak = "#2A211B" },
	snake = { build = "kid", outfit = "vest", beard = "none", moustache = "none", hair = DARK },
	brute = { build = "giant", outfit = "vest", beard = "stubble", moustache = "thick", hair = DARK },
	fakhr = { build = "giant", outfit = "vest", beard = "stubble", moustache = "thick", hair = DARK },
	abu_zira = { build = "slim", outfit = "sherwal", beard = "none", moustache = "handlebar", hair = DARK },
	-- The enraged 'akeed re-uses Abu al-Nahr's mesh and clips (no new mesh, STORY_PLAN §6.2); the red
	-- tint is client work (S1-C03).
	rival_zaim_enraged = {
		build = "broad",
		outfit = "bisht",
		beard = "full",
		moustache = "thick",
		hair = DARK,
		cloak = "#3E5B3A",
		model = "AbuNar",
		clips = "rival_zaim",
		anims = { walk = 100088303835625 },
	},
	-- Abu Jawdan's escort (S1-S05): the gendarme's mesh and clips (no new mesh, STORY_PLAN §6.2).
	corporal_minion = {
		build = "slim",
		outfit = "uniform",
		beard = "none",
		moustache = "thin",
		hair = DARK,
		model = "Gendarme",
		clips = "gendarme",
		anims = { walk = 127807283756558 },
	},
}

return Looks
