--!nocheck
-- Robux grants (idempotent receipts), pass grants, prompt validation, catalogue integrity.

local fs = require("@lune/fs")

return function(t)
	local MonetizationLogic = t.logic("MonetizationLogic")
	local ShopLogic = t.logic("ShopLogic")
	local Items = t.config("Items")
	local Shops = t.config("Shops")
	local Products = t.config("Products")
	local Strings = t.config("Strings")

	local MAX = 1000000

	local function profile()
		return { qirsh = 0, inventory = {}, equipped = {}, quests = {}, receipts = {} }
	end

	t.describe("MonetizationLogic.grantReceipt", function()
		local pouch = { kind = "qirsh", amount = 100 }
		local gold = { kind = "item", item = "tarboosh_gold", fallbackQirsh = 300 }

		t.it("grants a qirsh pack once per receipt", function()
			local p = profile()
			local ok, _, r = MonetizationLogic.grantReceipt(p, "R1", pouch, Items, MAX, 5)
			t.truthy(ok)
			t.eq(r, "granted")
			t.eq(p.qirsh, 100)
			local ok2, _, r2 = MonetizationLogic.grantReceipt(p, "R1", pouch, Items, MAX, 6)
			t.truthy(ok2, "a re-sent receipt is acknowledged")
			t.eq(r2, "already")
			t.eq(p.qirsh, 100, "but not paid twice")
			MonetizationLogic.grantReceipt(p, "R2", pouch, Items, MAX, 7)
			t.eq(p.qirsh, 200, "a new receipt pays again")
		end)

		t.it("grants an item, falls back to qirsh if already owned", function()
			local p = profile()
			t.truthy(MonetizationLogic.grantReceipt(p, "A", gold, Items, MAX, 1))
			t.eq(p.inventory.tarboosh_gold, 1)
			local _, _, r = MonetizationLogic.grantReceipt(p, "B", gold, Items, MAX, 2)
			t.eq(r, "fallback")
			t.eq(p.inventory.tarboosh_gold, 1)
			t.eq(p.qirsh, 300)
		end)

		t.it("rejects bad input without recording the receipt", function()
			local p = profile()
			t.eq(MonetizationLogic.grantReceipt(p, "", pouch, Items, MAX, 1), false)
			t.eq(MonetizationLogic.grantReceipt(p, "X", nil, Items, MAX, 1), false)
			t.eq(MonetizationLogic.grantReceipt(p, "Y", { kind = "qirsh", amount = -5 }, Items, MAX, 1), false)
			t.eq(MonetizationLogic.grantReceipt(p, "Z", { kind = "item", item = "nope" }, Items, MAX, 1), false)
			t.eq(next(p.receipts), nil)
			t.eq(p.qirsh, 0)
		end)

		t.it("clamps to the wallet maximum", function()
			local p = profile()
			p.qirsh = MAX - 10
			MonetizationLogic.grantReceipt(p, "C", pouch, Items, MAX, 1)
			t.eq(p.qirsh, MAX)
		end)
	end)

	t.describe("Prompts and passes", function()
		t.it("canPrompt requires a live id and refuses owned items", function()
			local p = profile()
			local gold = { kind = "item", item = "tarboosh_gold" }
			t.eq(MonetizationLogic.canPrompt(p, gold, 0), false, "id 0 = not created yet")
			t.truthy(MonetizationLogic.canPrompt(p, gold, 123))
			p.inventory.tarboosh_gold = 1
			local ok, err = MonetizationLogic.canPrompt(p, gold, 123)
			t.eq(ok, false)
			t.eq(err, "already_owned")
		end)
		t.it("pass items are granted once", function()
			local p = profile()
			local changed, granted = MonetizationLogic.grantPassItems(p, { "tarboosh_gold", "shawl_embroidered" }, Items)
			t.truthy(changed)
			t.eq(#granted, 2)
			local changed2 = MonetizationLogic.grantPassItems(p, { "tarboosh_gold", "shawl_embroidered" }, Items)
			t.eq(changed2, false)
		end)
		t.it("Robux-only items cannot be bought with qirsh", function()
			local p = profile()
			p.qirsh = 999999
			local ok, err = ShopLogic.purchase(p, Shops.khalil_tailor, "tarboosh_gold", Items)
			t.eq(ok, false)
			t.eq(err, "not_for_sale")
		end)
	end)

	t.describe("Catalogue integrity", function()
		local visualsSource = fs.readFile("src/shared/Config/CosmeticVisuals.luau")

		t.it("every cosmetic has a slot, exactly one price kind, strings and visuals", function()
			for id, def in Items do
				if def.kind == "cosmetic" then
					t.truthy(def.slot, id .. " slot")
					t.truthy((def.price ~= nil) ~= (def.product ~= nil), id .. " has price XOR product")
					t.truthy(string.find(visualsSource, "\n\t" .. id .. " = ", 1, true), id .. " has visuals")
					if def.product then
						local prod = Products.devProducts[def.product]
						t.truthy(prod and prod.kind == "item" and prod.item == id, id .. " product link")
					end
				end
			end
		end)
		t.it("products and passes are well formed", function()
			for key, p in Products.devProducts do
				t.truthy(type(p.productId) == "number" and p.productId >= 0, key .. " id")
				t.truthy(Strings.en[p.nameKey] and Strings.ar[p.nameKey], key .. " name strings")
				if p.kind == "qirsh" then
					t.truthy(p.amount and p.amount > 0, key .. " amount")
				else
					t.truthy(Items[p.item] and Items[p.item].product == key, key .. " item back-link")
				end
			end
			for _, key in Products.storeOrder do
				t.truthy(Products.devProducts[key], "store order " .. key)
			end
			for key, pass in Products.gamePasses do
				for _, itemId in pass.items do
					t.truthy(Items[itemId] and Items[itemId].kind == "cosmetic", key .. " → " .. itemId)
				end
				t.truthy(Strings.en[pass.descKey] and Strings.ar[pass.descKey], key .. " strings")
			end
		end)
		t.it("every shop item exists", function()
			for sid, shop in Shops do
				for _, itemId in shop.items do
					t.truthy(Items[itemId], sid .. " sells " .. itemId)
				end
			end
		end)
	end)
end
