--!nocheck
-- ProfileSchema: defaults, sanitisation, versioning (docs/DATA_SCHEMA.md §3–4).

return function(t)
	local ProfileSchema = t.logic("ProfileSchema")
	local Items = t.config("Items")
	local Economy = t.config("Economy")

	local ctx = {
		schemaVersion = Economy.SCHEMA_VERSION,
		maxQirsh = Economy.MAX_QIRSH,
		receiptHistory = 3,
		items = Items,
	}

	t.describe("ProfileSchema.load", function()
		t.it("creates defaults for new players", function()
			local p, err = ProfileSchema.load(nil, ctx, 1000)
			t.eq(err, nil)
			t.eq(p.qirsh, 0)
			t.eq(p.schemaVersion, Economy.SCHEMA_VERSION)
			t.eq(p.stats.firstJoin, 1000)
		end)
		t.it("round-trips a valid profile unchanged", function()
			local p = ProfileSchema.default(5, ctx.schemaVersion)
			p.qirsh = 10
			p.inventory.tarboosh_red = 1
			p.equipped.head = "tarboosh_red"
			p.quests.delivery_kaak = { state = "completed", startedAt = 1, completedAt = 2, completions = 1 }
			p.settings.language = "ar"
			local copy = t.deepCopy(p)
			local loaded = ProfileSchema.load(copy, ctx, 99)
			t.truthy(t.deepEq(loaded, p))
		end)
		t.it("refuses data from a newer schema", function()
			local p, err = ProfileSchema.load({ schemaVersion = 999 }, ctx, 1)
			t.eq(p, nil)
			t.eq(err, "newer_schema")
		end)
		t.it("refuses non-table data", function()
			local _, err = ProfileSchema.load("garbage", ctx, 1)
			t.eq(err, "corrupt")
		end)
		t.it("repairs invalid currency", function()
			for _, case in { { -5, 0 }, { 0 / 0, 0 }, { math.huge, 0 }, { 12.7, 12 }, { 5e9, Economy.MAX_QIRSH } } do
				local p = ProfileSchema.load({ schemaVersion = 1, qirsh = case[1] }, ctx, 1)
				t.eq(p.qirsh, case[2], "qirsh " .. tostring(case[1]))
			end
		end)
		t.it("keeps unknown items but drops invalid counts and clamps stacks", function()
			local p = ProfileSchema.load({
				schemaVersion = 1,
				inventory = { future_item = 3, basket_kaak = 7, tarboosh_red = 0, broken = "x" },
			}, ctx, 1)
			t.eq(p.inventory.future_item, 3)
			t.eq(p.inventory.basket_kaak, 1)
			t.eq(p.inventory.tarboosh_red, nil)
			t.eq(p.inventory.broken, nil)
		end)
		t.it("unequips items that are not owned or in the wrong slot", function()
			local p = ProfileSchema.load({ schemaVersion = 1, inventory = {}, equipped = { head = "tarboosh_red" } }, ctx, 1)
			t.eq(p.equipped.head, nil)
			local p2 = ProfileSchema.load({ schemaVersion = 1, inventory = { tarboosh_red = 1 }, equipped = { feet = "tarboosh_red" } }, ctx, 1)
			t.eq(p2.equipped.feet, nil)
		end)
		t.it("drops malformed quest records but keeps unknown valid ones", function()
			local p = ProfileSchema.load({
				schemaVersion = 1,
				quests = {
					future_quest = { state = "active", startedAt = 1, completions = 0 },
					bad = { state = "weird" },
					worse = 5,
				},
			}, ctx, 1)
			t.truthy(p.quests.future_quest)
			t.eq(p.quests.bad, nil)
			t.eq(p.quests.worse, nil)
		end)
		t.it("keeps only the newest receipts", function()
			local p = ProfileSchema.load({ schemaVersion = 1, receipts = { a = 1, b = 5, c = 3, d = 4 } }, ctx, 1)
			t.eq(p.receipts.a, nil)
			t.eq(p.receipts.b, 5)
			t.eq(p.receipts.c, 3)
			t.eq(p.receipts.d, 4)
		end)
		t.it("rejects unsupported languages", function()
			local p = ProfileSchema.load({ schemaVersion = 1, settings = { language = "xx" } }, ctx, 1)
			t.eq(p.settings.language, nil)
		end)
		t.it("beginSession bumps counters", function()
			local p = ProfileSchema.default(1, 1)
			ProfileSchema.beginSession(p, 50)
			t.eq(p.stats.sessions, 1)
			t.eq(p.stats.lastJoin, 50)
		end)
	end)
end
