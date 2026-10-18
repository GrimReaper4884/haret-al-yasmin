--!nocheck
-- The level-7 chooser and the bead slots (Logic/UpgradeView, S1-C04): the panel offers the right step,
-- prices and sell basis match what the server charges (TdTowers), and bead slots read the profile.

return function(t)
	local UpgradeView = t.logic("UpgradeView")
	local UnitLogic = t.logic("UnitLogic")
	local TdTowers = t.logic("TdTowers")
	local Units = t.config("Units")
	local Traits = t.config("Traits")
	local Beads = t.config("Beads")
	local TD = t.config("TD")
	local Strings = t.config("Strings")

	local function inEveryLanguage(key, where)
		for _, lang in Strings.languages do
			t.truthy(
				Strings[lang][key] ~= nil,
				"missing string '" .. key .. "' (" .. lang .. ") for " .. where
			)
		end
	end

	t.describe("UpgradeView", function()
		t.it("levels, then the signature choice at the last level, then done", function()
			local q = Units.qabaday
			local last = #q.levels
			t.eq(UpgradeView.step(q, 1, nil), "level")
			t.eq(UpgradeView.step(q, last - 1, nil), "level")
			t.eq(UpgradeView.step(q, last, nil), "choose")
			t.eq(UpgradeView.step(q, last + 1, "a"), "max")
			t.eq(
				UpgradeView.step(Units.walad, #Units.walad.levels, nil),
				"max",
				"no signature: max at the last level"
			)
		end)

		t.it("every signature path has a price and both names and effects in EN and AR", function()
			local n = 0
			for id, def in Units do
				if def.signature then
					n += 1
					for _, p in { "a", "b" } do
						local sig = def.signature[p]
						t.truthy(sig, id .. " path " .. p)
						t.eq(UpgradeView.signatureCost(def, p, nil, UnitLogic.costFor), sig.cost)
						inEveryLanguage("unit." .. id .. ".sig." .. sig.key .. ".name", id)
						inEveryLanguage("unit." .. id .. ".sig." .. sig.key .. ".desc", id)
					end
				end
			end
			t.truthy(n >= 8, "the eight Epic+ banner units have signatures")
			t.eq(UpgradeView.signatureCost(Units.walad, "a", nil, UnitLogic.costFor), nil)
		end)

		t.it(
			"the sell basis matches what the server put into the tower, signature and miser included",
			function()
				local q = Units.qabaday
				local miser = Traits.traits.miser
				for _, trait in { nil, miser } do
					local rules = {
						starBonus = TD.STAR_BONUS,
						traitCaps = Traits.caps,
						maxPlaced = 99,
						maxTowers = 99,
						sellRefund = TD.SELL_REFUND,
					}
					local state = {
						towers = {},
						players = { p = { cash = 1e9, spent = 0, placed = {} } },
						nextId = 1,
						phase = "prep",
						time = 0,
					}
					local tower = {
						id = 1,
						owner = "p",
						unitId = "qabaday",
						level = 1,
						x = 0,
						z = 0,
						stars = 0,
						trait = trait,
						invested = UnitLogic.costFor(q.levels[1].cost, trait),
						stats = UnitLogic.stats(q, 1, 0, trait, TD.STAR_BONUS, Traits.caps),
					}
					table.insert(state.towers, tower)
					for _ = 2, #q.levels do
						t.truthy(TdTowers.upgrade(state, "p", 1, q, rules), "level up")
					end
					t.eq(
						tower.invested,
						UpgradeView.invested(q, tower.level, nil, trait, UnitLogic.costFor),
						"levels"
					)
					t.truthy(TdTowers.upgrade(state, "p", 1, q, rules, "b"), "signature")
					t.eq(tower.path, "b")
					t.eq(
						tower.invested,
						UpgradeView.invested(q, tower.level, "b", trait, UnitLogic.costFor),
						"with the signature"
					)
				end
			end
		)

		t.it(
			"bead slots read the profile; choices are the unit's kinds with the current one marked",
			function()
				local empty = UpgradeView.beadSlots({ copies = 0 }, Beads.slots, Beads.kinds)
				t.eq(#empty, Beads.slots)
				for _, s in empty do
					t.eq(s.kind, nil)
				end
				local some =
					UpgradeView.beadSlots({ beads = { "range", "", "nonsense" } }, Beads.slots, Beads.kinds)
				t.eq(some[1].kind, "range")
				t.eq(some[2].kind, nil)
				t.eq(some[3].kind, nil, "an unknown kind reads as empty")
				local allowed = UnitLogic.beadKinds(Units.qabaday, Beads)
				local choices = UpgradeView.beadChoices(allowed, "range")
				t.eq(#choices, #allowed)
				local marked = 0
				for _, c in choices do
					if c.current then
						marked += 1
						t.eq(c.kind, "range")
					end
				end
				t.eq(marked, 1)
			end
		)

		t.it("the chooser's and the bead picker's strings exist in EN and AR", function()
			for _, key in
				{
					"match.sig_pick",
					"match.sig_confirm",
					"match.sig_cost",
					"match.err.bad_path",
					"units.beads_title",
					"units.bead_empty",
					"units.bead_pick",
					"units.err.no_beads",
					"units.err.same_bead",
				}
			do
				inEveryLanguage(key, "S1-C04")
			end
			for kind in Beads.kinds do
				inEveryLanguage("bead." .. kind .. ".name", "bead " .. kind)
			end
		end)
	end)
end
