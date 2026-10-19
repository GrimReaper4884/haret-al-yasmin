--!nocheck
-- Profile rollback (BUILD_PLAN P4-05, Logic/Restore): the right version, an exact restore, receipts kept,
-- a held session refused.

return function(t)
	local Restore = _G.LogicRequire("Restore")
	local STALE = 600

	local function record(lira, ledger, receipts, lock)
		return { data = { lira = lira, qirsh = 100, traitStones = 2, units = { walad = { copies = 1 } }, ledger = ledger, receipts = receipts or {} }, lock = lock, savedAt = 1 }
	end

	t.describe("Rollback", function()
		t.it("picks the newest live version at or before the moment", function()
			local versions = {
				{ version = "a", created = 1000, deleted = false },
				{ version = "b", created = 2000, deleted = false },
				{ version = "c", created = 3000, deleted = true },
				{ version = "d", created = 4000, deleted = false },
			}
			t.eq(Restore.pickVersion(versions, 2500).version, "b")
			t.eq(Restore.pickVersion(versions, 3500).version, "b", "a deleted version is skipped")
			t.eq(Restore.pickVersion(versions, 4000).version, "d")
			t.eq(Restore.pickVersion(versions, 999), nil, "nothing that old")
		end)

		t.it("restores the version exactly when nothing was paid for since", function()
			local e1 = { at = 10, src = "daily", lira = 30 }
			local old = record(130, { e1 })
			local current = record(5130, { e1, { at = 20, src = "match:ep1", lira = 80 }, { at = 30, src = "summon_x10", lira = -500, seed = 7 } })
			current.data.units.zaim = { copies = 1 }
			local plan, err = Restore.plan(old, current, 1000, STALE)
			t.truthy(plan, tostring(err))
			t.truthy(t.deepEq(plan.record.data, old.data), "the data is the version's, field for field")
			t.eq(plan.record.lock, nil, "the lock is cleared")
			t.eq(#plan.lost, 2)
			t.eq(plan.net.lira, -420, "80 earned and 500 spent are undone")
			t.eq(#plan.replayed, 0)
			t.eq(old.data.lira, 130, "the version itself is untouched")
		end)

		t.it("keeps every receipt paid after the version: currency, ledger entry and receipt id", function()
			local e1 = { at = 10, src = "daily", lira = 30 }
			local paid = { at = 25, src = "receipt:lira_300", lira = 300, key = "receipt:ABC" }
			local old = record(130, { e1 })
			local current = record(530, { e1, { at = 20, src = "match:ep1", lira = 100 }, paid }, { ABC = 25 })
			local plan = Restore.plan(old, current, 1000, STALE)
			t.eq(plan.record.data.lira, 430, "130 + the 300 paid for")
			t.eq(#plan.replayed, 1)
			t.eq(plan.record.data.receipts.ABC, 25, "the purchase id stays, so the receipt is never granted twice")
			t.eq(plan.record.data.ledger[#plan.record.data.ledger].key, "receipt:ABC")
			t.eq(#plan.lost, 1)
			t.eq(plan.net.lira, 100)
		end)

		t.it("refuses while a server holds the player, allows a stale lock or none", function()
			local old = record(1, {})
			t.eq(select(2, Restore.plan(old, record(2, {}, nil, { jobId = "x", at = 900 }), 1000, STALE)), "locked")
			t.truthy(Restore.plan(old, record(2, {}, nil, { jobId = "x", at = 100 }), 1000, STALE), "stale lock")
			t.truthy(Restore.plan(old, nil, 1000, STALE), "no current record")
			t.eq(select(2, Restore.plan({ lock = {} }, nil, 1000, STALE)), "no_data")
		end)
	end)
end
