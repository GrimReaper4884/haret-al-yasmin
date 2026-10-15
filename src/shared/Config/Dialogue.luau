--!strict
-- Dialogue trees per NPC (types below). The server resolves the entry node from the
-- player's quest state; the client only ever sends the index of a choice in the current node.
-- Local types only (erased at runtime) so this file stays loadable by Lune tests.

export type Action = { type: string, quest: string?, shop: string? }
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
				choices = { { textKey = "dlg.qahwaji.greet.ok" } },
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
}

return Dialogue
