--!nocheck
-- The Play panel Story tab (Logic/StoryCards, S1-C01): nine cards in story order, "soon" for the
-- episodes not built yet, mechanic icons that match what each episode really spawns, first-clear
-- gifts, and the secret unit's odds line read from TD.SECRET_DROP.

return function(t)
	local StoryCards = t.logic("StoryCards")
	local Story = t.config("Story")
	local Modes = t.config("Modes")
	local Waves = t.config("Waves")
	local Enemies = t.config("Enemies")
	local Arenas = t.config("Arenas")
	local Icons = t.config("Icons")
	local Strings = t.config("Strings")
	local TD = t.config("TD")
	local Beads = t.config("Beads")
	local Units = t.config("Units")
	local PartyLogic = t.logic("PartyLogic")

	local function inEveryLanguage(key, where)
		for _, lang in Strings.languages do
			t.truthy(
				Strings[lang][key] ~= nil,
				"missing string '" .. key .. "' (" .. lang .. ") for " .. where
			)
		end
	end

	-- What each mechanic key means in the data: true when the episode (its enemies, arena, script) has it.
	local function anyEnemy(ids, pred)
		for _, id in ids do
			if pred(Enemies[id]) then
				return true
			end
		end
		return false
	end
	local PRESENT = {
		stealth = function(ids)
			return anyEnemy(ids, function(e)
				return e.stealth == true
			end)
		end,
		armor = function(ids)
			return anyEnemy(ids, function(e)
				return (e.armor or 0) >= 0.2
			end)
		end,
		fast = function(ids)
			return anyEnemy(ids, function(e)
				return e.speed >= 6.5 and not e.swarm
			end)
		end,
		sapper = function(ids)
			return anyEnemy(ids, function(e)
				return not e.boss and e.gateDamage >= 8
			end)
		end,
		swarm = function(ids)
			return anyEnemy(ids, function(e)
				return e.swarm == true
			end)
		end,
		aura = function(ids)
			return anyEnemy(ids, function(e)
				return e.aura ~= nil
			end)
		end,
		burn = function(ids)
			return anyEnemy(ids, function(e)
				return (e.burn or 0) > 0
			end)
		end,
		shield = function(ids)
			return anyEnemy(ids, function(e)
				return e.shield ~= nil
			end)
		end,
		disguised = function(ids)
			return anyEnemy(ids, function(e)
				return e.disguised == true
			end)
		end,
		teleport = function(ids)
			return anyEnemy(ids, function(e)
				return e.teleport ~= nil
			end)
		end,
		sabotage = function(ids)
			return anyEnemy(ids, function(e)
				return e.sabotage ~= nil
			end)
		end,
		summon = function(ids)
			return anyEnemy(ids, function(e)
				return e.summon ~= nil
			end)
		end,
		split = function(ids)
			return anyEnemy(ids, function(e)
				return e.split ~= nil
			end)
		end,
		heal = function(ids)
			return anyEnemy(ids, function(e)
				return e.healAura ~= nil
			end)
		end,
		two_paths = function(_ids, mode)
			-- Both roads walked: the arena has two and the mode sends enemies down both (Modes.twinRoads, S1-M05).
			local arena = Arenas[mode.arena]
			return mode.twinRoads == true and arena.paths ~= nil and #arena.paths >= 2
		end,
		ally = function(_ids, mode)
			for _, beat in Waves.episodes[mode.episode].script or {} do
				if beat.kind == "ally" or beat.kind == "ally_turn" then
					return true
				end
			end
			return false
		end,
	}

	t.describe("StoryCards", function()
		t.it("nine cards in Config/Story order; only episodes with a story mode are playable", function()
			local cards = StoryCards.cards(Story, Modes)
			t.eq(#cards, 9)
			for i, c in cards do
				t.eq(c.id, Story.order[i])
				t.eq(c.number, i)
				local m = Modes[c.id]
				t.eq(c.soon, not (m ~= nil and m.kind == "story"), c.id .. " soon")
				t.eq(c.mode, if c.soon then nil else m)
			end
			t.eq(cards[1].soon, false, "Episode 1 is always playable")
			local fake = table.clone(Modes)
			fake.ep9 = nil
			t.eq(StoryCards.cards(Story, fake)[9].soon, true)
		end)

		t.it("every episode lists 1–3 known mechanics, each with an icon and EN + AR names", function()
			for _, id in Story.order do
				local list = Story.episodes[id].mechanics
				t.truthy(#list >= 1 and #list <= 3, id .. " has 1–3 mechanics")
				for _, key in list do
					t.truthy(PRESENT[key], id .. ": unknown mechanic " .. key)
					local icon = Icons.mechanics[key]
					t.truthy(
						icon and Icons.images[icon],
						id .. ": mechanic " .. key .. " has an icon in Config/Icons"
					)
					inEveryLanguage("mech." .. key, id)
				end
			end
			for key in Icons.mechanics do
				t.truthy(PRESENT[key], "Icons.mechanics." .. key .. " is a known mechanic")
			end
		end)

		t.it("the built episodes really have the mechanics their card shows", function()
			for _, id in Story.order do
				local mode = Modes[id]
				if mode and mode.kind == "story" then
					local pool, bosses = PartyLogic.enemiesOf(mode, Waves)
					local all = table.clone(pool)
					for _, b in bosses do
						table.insert(all, b)
					end
					for _, key in Story.episodes[id].mechanics do
						t.truthy(
							PRESENT[key](all, mode),
							id .. " shows '" .. key .. "' but its waves/arena don't have it"
						)
					end
				end
			end
		end)

		t.it("first-clear gifts: what is still ahead of the cleared difficulty", function()
			local function sum(list, field)
				local n = 0
				for _, g in list do
					n += g[field]
				end
				return n
			end
			-- Episode 4: one trait stone on the first Normal clear (TD.STORY_FIRST_CLEAR).
			local ep4 = StoryCards.gifts(Modes.ep4, TD, Beads, nil)
			t.eq(#ep4, 1)
			t.eq(ep4[1].difficulty, "normal")
			t.eq(ep4[1].traitStones, TD.STORY_FIRST_CLEAR.ep4.normal.traitStones)
			t.eq(#StoryCards.gifts(Modes.ep4, TD, Beads, "normal"), 0, "earned once")
			-- Episode 5: a bead on the first Hard clear (Beads.firstClear), still ahead after Normal.
			local ep5 = StoryCards.gifts(Modes.ep5, TD, Beads, "normal")
			t.eq(sum(ep5, "beads"), Beads.firstClear.ep5.hard)
			t.eq(ep5[1].difficulty, "hard")
			t.eq(#StoryCards.gifts(Modes.ep5, TD, Beads, "nightmare"), 0)
			-- Episode 6: Umm Baki on the first Normal clear (S1-A03).
			local ep6 = StoryCards.gifts(Modes.ep6, TD, Beads, nil)
			t.eq(ep6[1].difficulty, "normal")
			t.eq(ep6[1].unit, "qabilah")
			t.eq(#StoryCards.gifts(Modes.ep6, TD, Beads, "normal"), 0, "Umm Baki is given once")
			t.eq(#StoryCards.gifts(Modes.ep1, TD, Beads, nil), 0, "Episode 1 has no gift")
			t.eq(#StoryCards.gifts(Modes.infinite, TD, Beads, nil), 0, "not a story mode")
			t.eq(#StoryCards.gifts(nil, TD, Beads, nil), 0, "an episode not built yet")
		end)

		t.it("the secret odds line comes from TD.SECRET_DROP, on its episode only", function()
			local drop = TD.SECRET_DROP
			t.truthy(Units[drop.unit], "the secret unit exists")
			for _, d in TD.DIFFICULTY_ORDER do
				local o = StoryCards.secretOdds(TD, drop.episode, d)
				t.truthy(o, d .. " has odds")
				t.eq(o.chance, drop.chance[d])
				t.eq(o.pity, drop.pity)
				t.eq(o.unit, drop.unit)
			end
			t.eq(StoryCards.secretOdds(TD, "ep4", "normal"), nil)
			t.eq(StoryCards.secretOdds(TD, drop.episode, "bogus"), nil)
			t.eq(StoryCards.percent(0.01), "1")
			t.eq(StoryCards.percent(0.025), "2.5")
			t.eq(StoryCards.percent(0.06), "6")
			t.eq(StoryCards.percent(0.5), "50")
		end)

		t.it("the Hakawati's tales: nine outros in order, unlocked by a clear on any difficulty (S1-C06)", function()
			local none = StoryCards.tales(Story, nil)
			t.eq(#none, 9)
			for i, tale in none do
				t.eq(tale.id, Story.order[i])
				t.eq(tale.number, i)
				t.eq(tale.unlocked, false)
				t.eq(#tale.lines, 3)
			end
			local some = StoryCards.tales(Story, { ep1 = "normal", ep3 = "nightmare" })
			t.eq(some[1].unlocked, true)
			t.eq(some[2].unlocked, false)
			t.eq(some[3].unlocked, true)
			t.eq(some[1].lines, Story.episodes.ep1.outro)
		end)

		t.it("the pickle cart has three lines and its names in EN and AR (S1-C06)", function()
			local cart = Story.cart
			t.eq(#cart.lines, 3)
			for _, key in cart.lines do
				inEveryLanguage(key, "pickle cart")
			end
			inEveryLanguage(cart.nameKey, "pickle cart")
			inEveryLanguage(cart.promptKey, "pickle cart")
			t.truthy(cart.lineSeconds >= 2 and cart.lineSeconds <= 8, "time to read a line")
			t.truthy(cart.reach > 4 and cart.reach <= 16, "a walk-up reach")
			for _, key in { "afk.tales", "afk.tales_title", "afk.tale_locked" } do
				inEveryLanguage(key, "tales list")
			end
		end)

		t.it("the Story tab's strings exist in EN and AR", function()
			for _, key in
				{
					"play.soon",
					"play.soon_name",
					"play.hakawati",
					"play.secret",
					"play.secret_pity",
					"play.first_gift",
					"play.mechanics",
				}
			do
				inEveryLanguage(key, "PlayController")
			end
		end)
	end)

	t.describe("The lane after Episode 9 (S1-A08)", function()
		t.it("the pickle cart stands inside the gate, in the lane", function()
			local LaneZones = t.config("LaneZones")
			local at = Story.cart.at
			t.truthy(type(at) == "table" and #at == 2)
			t.truthy(at[1] > -8 and at[1] < 8, "inside the lane's 16 studs")
			local gate
			for _, r in LaneZones.existing do
				if r.id == "gate" then
					gate = r
				end
			end
			t.truthy(gate, "the gate rectangle")
			t.truthy(at[2] < gate.bounds[2] and at[2] > gate.bounds[2] - 10, "on the lane side, within 10 studs of the gate")
		end)
		t.it("every story-gated NPC names a real mode and has strings", function()
			local Npcs = t.config("Npcs")
			local Strings = t.config("Strings")
			local n = 0
			for id, def in Npcs do
				if def.requiresClear then
					n += 1
					t.truthy(Modes[def.requiresClear], id .. " gate is a mode")
					t.eq(def.talk, false, id .. " is ambient")
					for _, lang in { "en", "ar" } do
						t.truthy(Strings[lang][def.nameKey] and Strings[lang][def.roleKey], id .. " strings in " .. lang)
					end
				end
			end
			t.truthy(Npcs.adashari_guard and Npcs.adashari_guard.requiresClear == "ep9", "Al-Adashari waits for Episode 9")
			t.truthy(n >= 1)
		end)
	end)
end
