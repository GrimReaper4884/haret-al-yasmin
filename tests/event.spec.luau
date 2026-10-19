--!nocheck
-- Limited-time events: running window, match currency, the shop (server-side rules), sanitising.

return function(t)
	local EventLogic = t.logic("EventLogic")
	local ProfileSchema = t.logic("ProfileSchema")
	local MatchRewards = t.logic("MatchRewards")
	local Events = t.config("Events")
	local Modes = t.config("Modes")
	local Waves = t.config("Waves")
	local Items = t.config("Items")
	local Units = t.config("Units")
	local Traits = t.config("Traits")
	local TD = t.config("TD")
	local Economy = t.config("Economy")

	local def = Events.olive_harvest
	local during = def.startsAt + 3600
	local function profile()
		local ctx = t.schemaCtx()
		return ProfileSchema.default(during, ctx.schemaVersion, ctx)
	end
	local function grantCtx()
		return {
			maxQirsh = Economy.MAX_QIRSH,
			maxLira = TD.MAX_LIRA,
			maxStones = TD.MAX_TRAIT_STONES,
			items = Items,
			units = Units,
			traits = Traits,
			rng = function()
				return 0.5
			end,
			now = during,
		}
	end

	t.describe("EventLogic", function()
		t.it("config is consistent: mode, waves, shop", function()
			for id, e in Events do
				local mode = Modes[e.modeId]
				t.truthy(mode, id .. " mode")
				t.eq(mode.kind, "event")
				t.eq(mode.event, id)
				t.truthy(Waves.events[id], id .. " waves")
				t.eq(Waves.events[id].waves, mode.waves)
				t.truthy(e.endsAt > e.startsAt)
				for _, s in e.shop do
					t.truthy(s.cost > 0 and s.stock > 0, s.key)
					if s.reward.item then
						t.truthy(Items[s.reward.item], s.reward.item)
					end
				end
			end
		end)

		t.it("runs only inside its window", function()
			t.eq(EventLogic.isActive(def, def.startsAt - 1), false)
			t.truthy(EventLogic.isActive(def, def.startsAt))
			t.eq(EventLogic.isActive(def, def.endsAt), false)
			t.eq(EventLogic.forMode(Events, "ev_olive", during), "olive_harvest")
			t.eq(EventLogic.forMode(Events, "ev_olive", def.endsAt + 1), nil)
			t.eq(EventLogic.forMode(Events, "ep1", during), nil)
		end)

		t.it("a match pays currency per wave plus a win bonus, capped", function()
			t.eq(EventLogic.matchCurrency(def, false, 4), 4 * def.perWave)
			t.eq(EventLogic.matchCurrency(def, true, 15), 15 * def.perWave + def.winBonus)
			local p = profile()
			t.eq(EventLogic.addCurrency(p, "olive_harvest", def, 10), 10)
			t.eq(EventLogic.addCurrency(p, "olive_harvest", def, -5), 0)
			t.eq(EventLogic.addCurrency(p, "olive_harvest", def, 0 / 0), 0)
			t.eq(EventLogic.addCurrency(p, "olive_harvest", def, 1e12), def.maxCurrency - 10)
		end)

		t.it("the shop checks event, item, stock and currency, then grants", function()
			local p = profile()
			local ok, err = EventLogic.buy(p, Events, "olive_harvest", "lira_120", during, grantCtx())
			t.eq(err, "not_enough")
			EventLogic.addCurrency(p, "olive_harvest", def, 1000)
			ok, err = EventLogic.buy(p, Events, "olive_harvest", "nope", during, grantCtx())
			t.eq(err, "unknown_item")
			ok, err = EventLogic.buy(p, Events, "spring", "lira_120", during, grantCtx())
			t.eq(err, "unknown_event")
			ok, err = EventLogic.buy(p, Events, "olive_harvest", "lira_120", def.endsAt + 5, grantCtx())
			t.eq(err, "event_over")
			local lira = p.lira
			local granted
			ok, err, granted = EventLogic.buy(p, Events, "olive_harvest", "lira_120", during, grantCtx())
			t.truthy(ok, err)
			t.eq(p.lira, lira + 120)
			t.eq(granted.lira, 120)
			t.eq(p.events.olive_harvest.currency, 1000 - 30)
			t.eq(p.events.olive_harvest.bought.lira_120, 1)
			-- The shawl has stock 1.
			t.truthy(EventLogic.buy(p, Events, "olive_harvest", "shawl", during, grantCtx()))
			ok, err = EventLogic.buy(p, Events, "olive_harvest", "shawl", during, grantCtx())
			t.eq(err, "sold_out")
		end)

		t.it("event rewards and profile sanitising", function()
			local r = MatchRewards.compute("ev_olive", Modes.ev_olive, "normal", { won = true, wavesCleared = 15, totalWaves = 15 }, profile(), false, TD, function()
				return 0.9
			end)
			t.eq(r.lira, Modes.ev_olive.rewards.lira)
			t.eq(r.firstClear, false)
			local clean = EventLogic.sanitize({ olive_harvest = { currency = -5, bought = { shawl = 1, bad = "x" } }, [5] = {}, junk = 3 })
			t.eq(clean.olive_harvest.currency, 0)
			t.eq(clean.olive_harvest.bought.shawl, 1)
			t.eq(clean.olive_harvest.bought.bad, nil)
			t.eq(clean.junk, nil)
			t.deepEq(EventLogic.sanitize(nil), {})
		end)

		-- Lantern Nights (LP-D12, owner D-122): the Ramadan event that turns the musaharati on.
		t.it("Lantern Nights: its window, its villains, a shop with no Robux, an event-only lantern", function()
			local r = Events.ramadan
			t.truthy(r, "the event id the musaharati checks")
			t.eq(r.startsAt, 1801958400, "2027-02-07 00:00 UTC")
			t.eq(r.endsAt, 1804723200, "2027-03-11 00:00 UTC")
			t.truthy(r.startsAt >= Events.olive_harvest.endsAt, "one event at a time (the event arch shows the first)")
			t.eq(EventLogic.forMode(Events, "ev_ramadan", r.startsAt + 3600), "ramadan")
			t.eq(EventLogic.forMode(Events, "ev_ramadan", r.endsAt), nil)
			local w = Waves.events.ramadan
			t.eq(w.bosses[8], "rival_zaim", "Abu al-Nahr at wave 8")
			t.eq(w.bosses[15], "abu_shatour", "Abu Shatour at wave 15")
			for _, e in r.shop do
				for k in e.reward do
					t.truthy(k == "lira" or k == "qirsh" or k == "traitStones" or k == "item", e.key .. " pays only game rewards")
				end
				t.eq(e.product, nil, e.key .. " is never a Robux product")
			end
			local fanous = Items.fanous_brass
			t.eq(fanous.kind, "cosmetic")
			t.eq(fanous.slot, "waist")
			t.eq(fanous.price, nil, "not sold for qirsh")
			t.eq(fanous.product, nil, "not sold for Robux")
		end)
	end)
end
