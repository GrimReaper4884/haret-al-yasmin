--!strict
-- Dialogue trees per NPC (types below). The server resolves the entry node from the
-- player's quest state; the client only ever sends the index of a choice in the current node.
-- Local types only (erased at runtime) so this file stays loadable by Lune tests.

export type Action = { type: string, quest: string?, shop: string?, screen: string? } -- screen: a Hud.DIALOGUE.screens key
export type Choice = { textKey: string, action: Action?, next: string? }
export type Node = { textKey: string, choices: { Choice } }
export type Entry = { condition: { quest: string, state: string }?, node: string }
export type Tree = { entries: { Entry }, nodes: { [string]: Node } }

local Dialogue: { [string]: Tree } = {
	abu_nadim = {
		entries = {
			{ condition = { quest = "delivery_kaak", state = "none" }, node = "offer" },
			{ condition = { quest = "delivery_kaak", state = "active" }, node = "waiting" },
			{ condition = { quest = "delivery_kaak", state = "completed" }, node = "thanks" },
		},
		nodes = {
			offer = {
				textKey = "dlg.abu_nadim.offer",
				choices = {
					{
						textKey = "dlg.abu_nadim.offer.accept",
						action = { type = "acceptQuest", quest = "delivery_kaak" },
						next = "accepted",
					},
					{ textKey = "dlg.common.not_now", action = { type = "close" } },
				},
			},
			accepted = {
				textKey = "dlg.abu_nadim.accepted",
				choices = { { textKey = "dlg.abu_nadim.accepted.ok" } },
			},
			waiting = {
				textKey = "dlg.abu_nadim.waiting",
				choices = { { textKey = "dlg.common.on_my_way" } },
			},
			thanks = {
				textKey = "dlg.abu_nadim.thanks",
				choices = { { textKey = "dlg.common.goodbye" } },
			},
		},
	},

	sitt_wardeh = {
		entries = {
			{ condition = { quest = "delivery_kaak", state = "active" }, node = "delivery" },
			{ condition = { quest = "delivery_kaak", state = "completed" }, node = "after" },
			{ node = "greet" },
		},
		nodes = {
			greet = {
				textKey = "dlg.sitt_wardeh.greet",
				choices = { { textKey = "dlg.common.thank_you" } },
			},
			delivery = {
				textKey = "dlg.sitt_wardeh.delivery",
				choices = {
					{
						textKey = "dlg.sitt_wardeh.delivery.give",
						action = { type = "deliverQuest", quest = "delivery_kaak" },
						next = "delivered",
					},
					{ textKey = "dlg.common.one_moment", action = { type = "close" } },
				},
			},
			delivered = {
				textKey = "dlg.sitt_wardeh.delivered",
				choices = { { textKey = "dlg.common.thank_you" } },
			},
			after = {
				textKey = "dlg.sitt_wardeh.after",
				choices = { { textKey = "dlg.common.goodbye" } },
			},
		},
	},

	-- Season 1 · Episode 1 (docs/SEASON_1.md)
	hajj_rashid = {
		entries = {
			{ condition = { quest = "s1e1_wedding_eve", state = "completed" }, node = "after" },
			{ condition = { quest = "s1e1_wedding_eve", state = "ready" }, node = "report" },
			{ condition = { quest = "s1e1_wedding_eve", state = "active" }, node = "searching" },
			{ condition = { quest = "delivery_kaak", state = "completed" }, node = "plea" },
			{ node = "busy" },
		},
		nodes = {
			busy = {
				textKey = "dlg.hajj_rashid.busy",
				choices = { { textKey = "dlg.common.goodbye" } },
			},
			plea = {
				textKey = "dlg.hajj_rashid.plea",
				choices = {
					{ textKey = "dlg.hajj_rashid.plea.ask", next = "plea2" },
					{ textKey = "dlg.common.not_now", action = { type = "close" } },
				},
			},
			plea2 = {
				textKey = "dlg.hajj_rashid.plea2",
				choices = {
					{
						textKey = "dlg.hajj_rashid.plea2.accept",
						action = { type = "acceptQuest", quest = "s1e1_wedding_eve" },
						next = "accepted",
					},
					{ textKey = "dlg.hajj_rashid.plea2.decline", action = { type = "close" } },
				},
			},
			accepted = {
				textKey = "dlg.hajj_rashid.accepted",
				choices = { { textKey = "dlg.common.on_my_way" } },
			},
			searching = {
				textKey = "dlg.hajj_rashid.searching",
				choices = { { textKey = "dlg.common.on_my_way" } },
			},
			report = {
				textKey = "dlg.hajj_rashid.report",
				choices = {
					{
						textKey = "dlg.hajj_rashid.report.give",
						action = { type = "deliverQuest", quest = "s1e1_wedding_eve" },
						next = "reported",
					},
					{ textKey = "dlg.common.one_moment", action = { type = "close" } },
				},
			},
			reported = {
				textKey = "dlg.hajj_rashid.reported",
				choices = { { textKey = "dlg.hajj_rashid.reported.ok" } },
			},
			after = {
				textKey = "dlg.hajj_rashid.after",
				choices = { { textKey = "dlg.common.goodbye" } },
			},
		},
	},

	khalil_tailor = {
		entries = {
			{ node = "greet" },
		},
		nodes = {
			greet = {
				textKey = "dlg.khalil_tailor.greet",
				choices = {
					{
						textKey = "dlg.khalil_tailor.greet.shop",
						action = { type = "openShop", shop = "khalil_tailor" },
					},
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},

	barber = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.barber.greet",
				choices = { { textKey = "dlg.barber.greet.ok" } },
			},
		},
	},
	qahwaji = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.qahwaji.greet",
				choices = {
					{ textKey = "dlg.qahwaji.greet.hakawati", next = "hakawati" },
					{ textKey = "dlg.qahwaji.greet.ok" },
				},
			},
			-- The AFK chamber: Abu Hatem sends the player upstairs to the storyteller.
			hakawati = {
				textKey = "dlg.qahwaji.hakawati",
				choices = {
					{ textKey = "dlg.qahwaji.hakawati.go", action = { type = "afk" } },
					{ textKey = "dlg.common.not_now", action = { type = "close" } },
				},
			},
		},
	},
	hakawati = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.hakawati.greet",
				choices = { { textKey = "dlg.hakawati.greet.ok" } },
			},
		},
	},
	natour = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.natour.greet",
				choices = { { textKey = "dlg.natour.greet.ok" } },
			},
		},
	},
	-- The bigger lane's cast (LP-D02): each opens the screen that fits the character (§4.2).
	umm_hissam = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.umm_hissam.greet",
				choices = {
					{ textKey = "dlg.umm_hissam.greet.go", action = { type = "screen", screen = "units" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	midwife = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.midwife.greet",
				choices = {
					{ textKey = "dlg.midwife.greet.go", action = { type = "screen", screen = "daily" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	zaim_npc = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.zaim_npc.greet",
				choices = {
					{ textKey = "dlg.zaim_npc.greet.go", action = { type = "screen", screen = "pass" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	akeed_npc = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.akeed_npc.greet",
				choices = {
					{ textKey = "dlg.akeed_npc.greet.go", action = { type = "screen", screen = "play" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	hammam_owner = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.hammam_owner.greet",
				choices = {
					{ textKey = "dlg.hammam_owner.greet.go", action = { type = "screen", screen = "wardrobe" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	sergeant_npc = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.sergeant_npc.greet",
				choices = {
					{ textKey = "dlg.sergeant_npc.greet.go", action = { type = "screen", screen = "event" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	mukhtar_npc = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.mukhtar_npc.greet",
				choices = { { textKey = "dlg.mukhtar_npc.greet.ok" } },
			},
		},
	},
	-- Abu Ghadeb, the lane's gossip: three spiteful lines, one after another.
	balila = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.balila.greet",
				choices = { { textKey = "dlg.balila.more", next = "second" }, { textKey = "dlg.common.goodbye" } },
			},
			second = {
				textKey = "dlg.balila.second",
				choices = { { textKey = "dlg.balila.more", next = "third" }, { textKey = "dlg.common.goodbye" } },
			},
			third = {
				textKey = "dlg.balila.third",
				choices = { { textKey = "dlg.balila.enough" } },
			},
		},
	},
	-- LP-D08: Abu Marzouk opens the lane store; the sheikh greets and that is all (nothing to buy or do).
	grocer = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.grocer.greet",
				choices = {
					{ textKey = "dlg.grocer.greet.go", action = { type = "screen", screen = "store" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	-- LP-E03: Abu Brahim says his piece and opens the lane store.
	cloth_merchant = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.cloth_merchant.greet",
				choices = {
					{ textKey = "dlg.cloth_merchant.greet.go", action = { type = "screen", screen = "store" } },
					{ textKey = "dlg.common.maybe_later", action = { type = "close" } },
				},
			},
		},
	},
	sheikh = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.sheikh.greet",
				choices = { { textKey = "dlg.sheikh.greet.ok" } },
			},
		},
	},
}

return Dialogue
