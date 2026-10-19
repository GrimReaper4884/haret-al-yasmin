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
	abu_baseer = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.abu_baseer.greet",
				choices = { { textKey = "dlg.abu_baseer.greet.ok" } },
			},
		},
	},

	sitt_wardeh = {
		entries = { { node = "greet" } },
		nodes = {
			greet = {
				textKey = "dlg.sitt_wardeh.greet",
				choices = { { textKey = "dlg.common.thank_you" } },
			},
		},
	},

	hajj_rashid = {
		entries = { { node = "busy" } },
		nodes = {
			busy = {
				textKey = "dlg.hajj_rashid.busy",
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
				choices = { { textKey = "dlg.common.goodbye" } },
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
