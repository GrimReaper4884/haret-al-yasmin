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

	local Units = t.config("Units")
	local Traits = t.config("Traits")
	local SeasonPass = t.config("SeasonPass")
	local TD = t.config("TD")

	local function profile()
		return {
			qirsh = 0,
			lira = 0,
			traitStones = 0,
			inventory = {},
			equipped = {},
			quests = {},
			receipts = {},
			units = {},
			bundles = {},
			pass = { season = "s1", xp = 0, premium = false, claimedFree = {}, claimedPremium = {} },
		}
	end

	local function ctx(now)
		return {
			items = Items,
			units = Units,
			traits = Traits,
			rng = function()
				return 0
			end,
			now = now or 1,
			maxQirsh = MAX,
			maxLira = TD.MAX_LIRA,
			maxStones = TD.MAX_TRAIT_STONES,
			passTiers = SeasonPass.tiers,
		}
	end

	t.describe("MonetizationLogic.grantReceipt", function()
		local pouch = { kind = "qirsh", amount = 100 }
		local gold = { kind = "item", item = "tarboosh_gold", fallbackQirsh = 300 }

		t.it("grants a qirsh pack once per receipt", function()
			local p = profile()
			local ok, _, r = MonetizationLogic.grantReceipt(p, "R1", pouch, ctx(5))
			t.truthy(ok)
			t.eq(r, "granted")
			t.eq(p.qirsh, 100)
			local ok2, _, r2 = MonetizationLogic.grantReceipt(p, "R1", pouch, ctx(6))
			t.truthy(ok2, "a re-sent receipt is acknowledged")
			t.eq(r2, "already")
			t.eq(p.qirsh, 100, "but not paid twice")
			MonetizationLogic.grantReceipt(p, "R2", pouch, ctx(7))
			t.eq(p.qirsh, 200, "a new receipt pays again")
		end)

		t.it("grants an item, falls back to qirsh if already owned", function()
			local p = profile()
			t.truthy(MonetizationLogic.grantReceipt(p, "A", gold, ctx(1)))
			t.eq(p.inventory.tarboosh_gold, 1)
			local _, _, r = MonetizationLogic.grantReceipt(p, "B", gold, ctx(2))
			t.eq(r, "fallback")
			t.eq(p.inventory.tarboosh_gold, 1)
			t.eq(p.qirsh, 300)
		end)

		t.it("rejects bad input without recording the receipt", function()
			local p = profile()
			t.eq(MonetizationLogic.grantReceipt(p, "", pouch, ctx(1)), false)
			t.eq(MonetizationLogic.grantReceipt(p, "X", nil, ctx(1)), false)
			t.eq(MonetizationLogic.grantReceipt(p, "Y", { kind = "qirsh", amount = -5 }, ctx(1)), false)
			t.eq(MonetizationLogic.grantReceipt(p, "Z", { kind = "item", item = "nope" }, ctx(1)), false)
			t.eq(next(p.receipts), nil)
			t.eq(p.qirsh, 0)
		end)

		t.it("clamps to the wallet maximum", function()
			local p = profile()
			p.qirsh = MAX - 10
			MonetizationLogic.grantReceipt(p, "C", pouch, ctx(1))
			t.eq(p.qirsh, MAX)
		end)
	end)

	t.describe("New product kinds", function()
		t.it("lira, stones, premium pass, level skip and the starter bundle", function()
			local p = profile()
			t.truthy(MonetizationLogic.grantReceipt(p, "L1", Products.devProducts.lira_100, ctx(1)))
			t.eq(p.lira, 100)
			t.truthy(MonetizationLogic.grantReceipt(p, "S1", Products.devProducts.stones_3, ctx(1)))
			t.eq(p.traitStones, 3)
			local _, _, r = MonetizationLogic.grantReceipt(p, "P1", Products.devProducts.pass_premium_s1, ctx(1))
			t.eq(r, "granted")
			t.truthy(p.pass.premium)
			_, _, r = MonetizationLogic.grantReceipt(p, "P2", Products.devProducts.pass_premium_s1, ctx(1))
			t.eq(r, "fallback", "second premium purchase pays lira instead")
			t.eq(p.lira, 900)
			t.truthy(MonetizationLogic.grantReceipt(p, "K1", Products.devProducts.pass_skip_10, ctx(1)))
			t.truthy(p.pass.xp >= 1000)
			_, _, r = MonetizationLogic.grantReceipt(p, "B1", Products.devProducts.starter_pack, ctx(1))
			t.eq(r, "granted")
			t.truthy(p.units.qabaday)
			t.eq(p.inventory.tarboosh_red, 1)
			t.eq(p.lira, 1200)
			_, _, r = MonetizationLogic.grantReceipt(p, "B2", Products.devProducts.starter_pack, ctx(1))
			t.eq(r, "fallback", "the bundle is one-time")
			t.eq(p.lira, 1500)
			local ok, err = MonetizationLogic.canPrompt(p, Products.devProducts.starter_pack, 5)
			t.eq(ok, false)
			t.eq(err, "already_owned")
			ok, err = MonetizationLogic.canPrompt(p, Products.devProducts.lira_100, 5, true)
			t.eq(err, "restricted", "no lira sales where paid random items are restricted")
			t.truthy(MonetizationLogic.canPrompt(p, Products.devProducts.lira_100, 5, false))
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
		t.it("restricted regions can't buy anything that funds paid random items", function()
			local p = profile()
			local d = Products.devProducts
			for _, key in { "lira_100", "lira_4000", "stones_3", "stones_10", "starter_pack", "pass_premium_s1", "pass_skip_10" } do
				local ok, err = MonetizationLogic.canPrompt(p, d[key], 5, true)
				t.eq(ok, false, key .. " restricted")
				t.eq(err, "restricted", key)
				t.truthy(MonetizationLogic.canPrompt(p, d[key], 5, false), key .. " allowed elsewhere")
			end
			for _, key in { "qirsh_pouch", "qirsh_chest", "item_tarboosh_gold", "item_qumbaz_wedding" } do
				t.truthy(MonetizationLogic.canPrompt(p, d[key], 5, true), key .. " is not random-item currency")
			end
			-- Every product that can pay lira or trait stones is gated (catalogue-wide).
			for key, prod in d do
				local paysRandom = prod.kind == "lira" or prod.kind == "stones" or prod.fallbackLira ~= nil
					or (prod.bundle ~= nil and ((prod.bundle.lira or 0) > 0 or (prod.bundle.traitStones or 0) > 0))
				if paysRandom then
					t.truthy(MonetizationLogic.fundsRandomItems(prod), key .. " is gated")
				end
			end
		end)
		t.it("fallback payout matches what grantReceipt pays (and the toast)", function()
			local d = Products.devProducts
			local cur, n = MonetizationLogic.fallbackPayout(d.item_tarboosh_gold)
			t.eq(cur, "qirsh")
			t.eq(n, 300)
			cur, n = MonetizationLogic.fallbackPayout(d.pass_premium_s1)
			t.eq(cur, "lira")
			t.eq(n, 800)
			cur, n = MonetizationLogic.fallbackPayout(d.starter_pack)
			t.eq(cur, "lira")
			t.eq(n, 300)
			local p = profile()
			p.inventory.qumbaz_wedding = 1
			local _, _, r = MonetizationLogic.grantReceipt(p, "Q1", d.item_qumbaz_wedding, ctx(1))
			t.eq(r, "fallback")
			t.eq(p.qirsh, 500)
			t.eq(p.lira, 0, "an item fallback never pays lira")
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
				if p.kind == "qirsh" or p.kind == "lira" or p.kind == "stones" or p.kind == "passSkip" then
					t.truthy(p.amount and p.amount > 0, key .. " amount")
				elseif p.kind == "item" then
					t.truthy(Items[p.item] and Items[p.item].product == key, key .. " item back-link")
				elseif p.kind == "passPremium" then
					t.truthy(p.season == SeasonPass.season, key .. " season")
					t.truthy(p.fallbackLira, key .. " fallback")
				elseif p.kind == "bundle" then
					t.truthy(type(p.bundle) == "table", key .. " bundle")
					t.truthy(not p.bundle.unit or Units[p.bundle.unit], key .. " bundle unit")
					t.truthy(not p.bundle.item or Items[p.bundle.item], key .. " bundle item")
				else
					t.truthy(false, key .. " unknown kind " .. tostring(p.kind))
				end
				if p.descKey then
					t.truthy(Strings.en[p.descKey] and Strings.ar[p.descKey], key .. " desc strings")
				end
			end
			for _, list in { Products.storeOrder, Products.liraOrder, Products.extrasOrder } do
				for _, key in list do
					t.truthy(Products.devProducts[key], "store order " .. key)
				end
			end
			for _, key in Products.passOrder do
				t.truthy(Products.gamePasses[key], "pass order " .. key)
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
