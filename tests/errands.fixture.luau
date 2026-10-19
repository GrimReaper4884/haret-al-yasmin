--!nocheck
-- The two errands the lane shipped with (removed from Config on 2026-10-19, DECISIONS D-132), kept as
-- fixtures so the dormant quest engine (Logic/QuestLogic, Logic/DialogueLogic) stays covered: a delivery
-- (the baker's ka'ak to the neighbour) and an investigation behind it (three clues).

local Quests = {
	delivery_kaak = {
		kind = "delivery",
		titleKey = "quest.delivery_kaak.title",
		objectiveKeys = { active = "quest.delivery_kaak.obj_active", completed = "quest.delivery_kaak.obj_completed" },
		giver = "baker",
		target = "neighbour",
		item = "basket_kaak",
		reward = { qirsh = 50 },
		repeatable = false,
	},
	s1e1_wedding_eve = {
		kind = "investigate",
		episode = 1,
		titleKey = "quest.s1e1.title",
		objectiveKeys = { active = "quest.s1e1.obj_active", ready = "quest.s1e1.obj_ready", completed = "quest.s1e1.obj_completed" },
		giver = "merchant",
		target = "merchant",
		clues = { "clue_slipper", "clue_thread", "clue_token" },
		requires = { "delivery_kaak" },
		reward = { qirsh = 60 },
		repeatable = false,
	},
}

local Dialogue = {
	baker = {
		entries = {
			{ condition = { quest = "delivery_kaak", state = "none" }, node = "offer" },
			{ condition = { quest = "delivery_kaak", state = "active" }, node = "waiting" },
			{ condition = { quest = "delivery_kaak", state = "completed" }, node = "thanks" },
		},
		nodes = {
			offer = {
				textKey = "offer",
				choices = {
					{ textKey = "accept", action = { type = "acceptQuest", quest = "delivery_kaak" }, next = "accepted" },
					{ textKey = "not_now", action = { type = "close" } },
				},
			},
			accepted = { textKey = "accepted", choices = { { textKey = "ok" } } },
			waiting = { textKey = "waiting", choices = { { textKey = "ok" } } },
			thanks = { textKey = "thanks", choices = { { textKey = "ok" } } },
		},
	},
	neighbour = {
		entries = {
			{ condition = { quest = "delivery_kaak", state = "active" }, node = "delivery" },
			{ node = "greet" },
		},
		nodes = {
			greet = { textKey = "greet", choices = { { textKey = "ok" } } },
			delivery = {
				textKey = "delivery",
				choices = { { textKey = "give", action = { type = "deliverQuest", quest = "delivery_kaak" } } },
			},
		},
	},
	merchant = {
		entries = {
			{ condition = { quest = "s1e1_wedding_eve", state = "completed" }, node = "after" },
			{ condition = { quest = "s1e1_wedding_eve", state = "ready" }, node = "report" },
			{ condition = { quest = "s1e1_wedding_eve", state = "active" }, node = "searching" },
			{ condition = { quest = "delivery_kaak", state = "completed" }, node = "plea" },
			{ node = "busy" },
		},
		nodes = {
			busy = { textKey = "busy", choices = { { textKey = "ok" } } },
			plea = { textKey = "plea", choices = { { textKey = "ok" } } },
			searching = { textKey = "searching", choices = { { textKey = "ok" } } },
			report = { textKey = "report", choices = { { textKey = "ok" } } },
			after = { textKey = "after", choices = { { textKey = "ok" } } },
		},
	},
}

return { Quests = Quests, Dialogue = Dialogue }
