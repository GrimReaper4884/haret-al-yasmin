--!strict
-- Robux grant rules. Pure. Every grant is keyed by the Roblox PurchaseId and recorded in
-- profile.receipts in the same mutation, so a receipt that Roblox re-sends (it retries until we
-- answer PurchaseGranted) is granted exactly once.

local function sibling(name: string): any
	-- selene: allow(global_usage) -- test hook installed by tests/run.luau (Lune)
	local testRequire = (_G :: any).LogicRequire
	if testRequire then
		return testRequire(name)
	end
	local dynamicRequire: any = require -- name is dynamic; resolved at runtime
	return dynamicRequire((script :: any).Parent[name])
end

local Wallet = sibling("Wallet")
local Inventory = sibling("Inventory")

type Profile = {
	qirsh: number,
	inventory: { [string]: number },
	receipts: { [string]: number },
}
type DevProduct = { kind: string, amount: number?, item: string?, fallbackQirsh: number? }

export type GrantResult = "granted" | "already" | "fallback"

local MonetizationLogic = {}

-- Returns ok, err, result. result "already" means this receipt was granted before.
function MonetizationLogic.grantReceipt(
	profile: Profile,
	receiptId: string,
	product: DevProduct?,
	items: { [string]: any },
	maxQirsh: number,
	now: number
): (boolean, string?, GrantResult?)
	if type(receiptId) ~= "string" or receiptId == "" then
		return false, "bad_receipt", nil
	end
	if profile.receipts[receiptId] then
		return true, nil, "already"
	end
	if not product then
		return false, "unknown_product", nil
	end

	local result: GrantResult = "granted"
	if product.kind == "qirsh" then
		local amount = product.amount
		if type(amount) ~= "number" or amount <= 0 or math.floor(amount) ~= amount then
			return false, "bad_product", nil
		end
		Wallet.add(profile, amount, maxQirsh)
	elseif product.kind == "item" then
		local itemId = product.item
		if type(itemId) ~= "string" or items[itemId] == nil then
			return false, "bad_product", nil
		end
		if Inventory.has(profile, itemId, 1) then
			-- Bought twice in a race: never take Robux for nothing.
			Wallet.add(profile, product.fallbackQirsh or 0, maxQirsh)
			result = "fallback"
		else
			local ok, err = Inventory.add(profile, itemId, 1, items)
			if not ok then
				return false, err, nil
			end
		end
	else
		return false, "bad_product", nil
	end

	profile.receipts[receiptId] = now
	return true, nil, result
end

-- Grants pass items not yet owned. Returns ok (true if anything changed), list of granted ids.
function MonetizationLogic.grantPassItems(profile: Profile, passItems: { string }, items: { [string]: any }): (boolean, { string })
	local granted = {}
	for _, itemId in passItems do
		if items[itemId] and not Inventory.has(profile, itemId, 1) then
			if Inventory.add(profile, itemId, 1, items) then
				table.insert(granted, itemId)
			end
		end
	end
	return #granted > 0, granted
end

-- Whether the server may open a Robux prompt for this product for this player right now.
function MonetizationLogic.canPrompt(profile: Profile, product: DevProduct?, productId: number?): (boolean, string?)
	if not product then
		return false, "unknown_product"
	end
	if type(productId) ~= "number" or productId <= 0 then
		return false, "not_available"
	end
	if product.kind == "item" and product.item and Inventory.has(profile, product.item, 1) then
		return false, "already_owned"
	end
	return true, nil
end

return MonetizationLogic
