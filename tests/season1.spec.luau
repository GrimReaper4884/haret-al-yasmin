--!nocheck
-- Season 1 · Episode 1: investigation quests, clues, prerequisites, "ready" dialogue state.

return function(t)
	local QuestLogic = t.logic("QuestLogic")
	local DialogueLogic = t.logic("DialogueLogic")
	local ProfileSchema = t.logic("ProfileSchema")
	local Items = t.config("Items")
	local Quests = t.config("Quests")
	local Clues = t.config("Clues")
	local Dialogue = t.config("Dialogue")
	local Economy = t.config("Economy")

	local Q = "s1e1_wedding_eve"

	local function profile()
		return { qirsh = 0, inventory = {}, equipped = {}, quests = {} }
	end

	local function unlocked()
		local p = profile()
		p.quests.delivery_kaak = { state = "completed", startedAt = 1, completions = 1 }
		return p
	end

	t.describe("S1E1 investigation", function()
		t.it("is locked until the ka'ak delivery is done", function()
			local ok, err = QuestLogic.accept(profile(), Q, Quests, Items, 1)
			t.eq(ok, false)
			t.eq(err, "locked")
		end)

		t.it("full path: accept → 3 clues → ready → turn in pays once", function()
			local p = unlocked()
			t.truthy(QuestLogic.accept(p, Q, Quests, Items, 10))
			t.eq(QuestLogic.state(p, Q, Quests), "active")
			t.eq(next(p.inventory), nil, "investigations grant no item")

			local ok1, _, n1 = QuestLogic.collectClue(p, Q, "clue_slipper", Quests)
			t.truthy(ok1)
			t.eq(n1, 1)
			t.eq(QuestLogic.canDeliver(p, Q, Quests), false)
			t.truthy(QuestLogic.collectClue(p, Q, "clue_thread", Quests))
			t.truthy(QuestLogic.collectClue(p, Q, "clue_token", Quests))
			t.eq(QuestLogic.state(p, Q, Quests), "ready")
			t.eq(QuestLogic.state(p, Q), "active", "without config, ready reads as active")

			local ok, err, paid = QuestLogic.deliver(p, Q, Quests, Economy.MAX_QIRSH, 20)
			t.truthy(ok, err)
			t.eq(paid, 60)
			t.eq(p.qirsh, 60)
			t.eq(QuestLogic.state(p, Q, Quests), "completed")
			t.eq(QuestLogic.deliver(p, Q, Quests, Economy.MAX_QIRSH, 30), false)
			t.eq(p.qirsh, 60)
		end)

		t.it("rejects duplicate, foreign and inactive clues without side effects", function()
			local p = unlocked()
			t.eq(QuestLogic.collectClue(p, Q, "clue_slipper", Quests), false, "not accepted yet")
			QuestLogic.accept(p, Q, Quests, Items, 1)
			t.truthy(QuestLogic.collectClue(p, Q, "clue_slipper", Quests))
			local before = t.deepCopy(p)
			local ok, err = QuestLogic.collectClue(p, Q, "clue_slipper", Quests)
			t.eq(ok, false)
			t.eq(err, "already_found")
			t.eq(QuestLogic.collectClue(p, Q, "clue_unknown", Quests), false)
			t.eq(QuestLogic.collectClue(p, "delivery_kaak", "clue_slipper", Quests), false, "wrong quest kind")
			t.truthy(t.deepEq(p, before))
		end)

		t.it("cannot turn in with missing clues", function()
			local p = unlocked()
			QuestLogic.accept(p, Q, Quests, Items, 1)
			QuestLogic.collectClue(p, Q, "clue_slipper", Quests)
			local ok, err = QuestLogic.deliver(p, Q, Quests, Economy.MAX_QIRSH, 2)
			t.eq(ok, false)
			t.eq(err, "missing_clues")
			t.eq(p.qirsh, 0)
		end)

		t.it("progress survives a save/load round trip", function()
			local p = ProfileSchema.default(1, Economy.SCHEMA_VERSION)
			p.quests.delivery_kaak = { state = "completed", startedAt = 1, completions = 1 }
			QuestLogic.accept(p, Q, Quests, Items, 2)
			QuestLogic.collectClue(p, Q, "clue_thread", Quests)
			local ctx = t.schemaCtx()
			local loaded = ProfileSchema.load(t.deepCopy(p), ctx, 3)
			t.eq(loaded.quests[Q].progress.clue_thread, true)
			t.eq(QuestLogic.cluesFound(loaded, Q), 1)
		end)

		t.it("sanitize strips malformed progress", function()
			local ctx = t.schemaCtx({ maxQirsh = 100, receiptHistory = 10 })
			local p = ProfileSchema.load({
				schemaVersion = 1,
				quests = {
					a = { state = "active", startedAt = 1, completions = 0, progress = { ok = true, bad = 5, [3] = true } },
					b = { state = "active", startedAt = 1, completions = 0, progress = "nope" },
				},
			}, ctx, 1)
			t.eq(p.quests.a.progress.ok, true)
			t.eq(p.quests.a.progress.bad, nil)
			t.eq(p.quests.a.progress[3], nil)
			t.eq(p.quests.b.progress, nil)
		end)
	end)

	t.describe("Hajj Rashid dialogue", function()
		local tree = Dialogue.hajj_rashid
		t.it("follows the episode states", function()
			local p = profile()
			t.eq(DialogueLogic.entryNode(tree, p, Quests), "busy")
			p = unlocked()
			t.eq(DialogueLogic.entryNode(tree, p, Quests), "plea")
			QuestLogic.accept(p, Q, Quests, Items, 1)
			t.eq(DialogueLogic.entryNode(tree, p, Quests), "searching")
			for _, c in Quests[Q].clues do
				QuestLogic.collectClue(p, Q, c, Quests)
			end
			t.eq(DialogueLogic.entryNode(tree, p, Quests), "report")
			QuestLogic.deliver(p, Q, Quests, Economy.MAX_QIRSH, 2)
			t.eq(DialogueLogic.entryNode(tree, p, Quests), "after")
		end)
		t.it("an 'active' entry still matches a ready delivery quest", function()
			local p = profile()
			QuestLogic.accept(p, "delivery_kaak", Quests, Items, 1)
			t.eq(QuestLogic.state(p, "delivery_kaak", Quests), "ready")
			t.eq(DialogueLogic.entryNode(Dialogue.sitt_wardeh, p, Quests), "delivery")
			t.eq(DialogueLogic.entryNode(Dialogue.abu_nadim, p, Quests), "waiting")
		end)
	end)

	-- The Episode 9 story card (LP-E04, LOOK_AND_PLAY_PLAN §7.2): its outro, read on the result screen and
	-- in the Hakawati's room once cleared, says the gold comes home to Abu Brahim, in both languages.
	t.describe("Episode 9 story card", function()
		local Story = t.config("Story")
		local Modes = t.config("Modes")
		local Strings = t.config("Strings")
		local StoryCards = t.logic("StoryCards")
		t.it("the card is the ninth, and its cleared tale names Abu Brahim in en and ar", function()
			local cards = StoryCards.cards(Story, Modes)
			t.eq(cards[9].id, "ep9")
			local tale = StoryCards.tales(Story, { ep9 = "normal" })[9]
			t.eq(tale.id, "ep9")
			t.truthy(tale.unlocked)
			t.eq(#tale.lines, 3)
			local en, ar = {}, {}
			for _, key in tale.lines do
				table.insert(en, Strings.en[key])
				table.insert(ar, Strings.ar[key])
			end
			t.truthy(string.find(table.concat(en, " "), "Abu Brahim", 1, true), "English outro names him")
			t.truthy(string.find(table.concat(ar, " "), "أبو براهيم", 1, true), "Arabic outro names him")
			t.truthy(string.find(Strings.en["unit.tajir.name"], "Abu Brahim", 1, true), "the same name as his unit")
		end)
	end)

	t.describe("Clue config", function()
		t.it("every clue belongs to an investigation that lists it, and vice versa", function()
			for clueId, c in Clues do
				local q = Quests[c.quest]
				t.truthy(q and q.kind == "investigate", clueId .. " quest")
				t.truthy(table.find(q.clues, clueId), clueId .. " listed by its quest")
				t.eq(#c.position, 3, clueId .. " position")
			end
			for qid, q in Quests do
				if q.kind == "investigate" then
					t.truthy(#q.clues > 0, qid .. " has clues")
					t.truthy(q.objectiveKeys.ready, qid .. " has a ready objective")
					for _, clueId in q.clues do
						t.truthy(Clues[clueId] and Clues[clueId].quest == qid, qid .. " → " .. clueId)
					end
				end
				for _, req in q.requires or {} do
					t.truthy(Quests[req], qid .. " requires " .. req)
				end
			end
		end)
	end)
end
