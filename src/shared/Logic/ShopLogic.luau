--!strict
-- Shop and equip rules. Prices always come from the Items config, never from the caller. Pure.

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

type ShopProfile = {
	qirsh: number,
	inventory: { [string]: number },
	equipped: { [string]: string },
}
type ItemDef = { kind: string, price: number?, slot: string?, stackMax: number }
type ShopDef = { items: { string } }

local ShopLogic = {}

function ShopLogic.sells(shop: ShopDef, itemId: string): boolean
	return table.find(shop.items, itemId) ~= nil
end

function ShopLogic.canPurchase(
	profile: ShopProfile,
	shop: ShopDef?,
	itemId: string,
	items: { [string]: ItemDef }
): (boolean, string?)
	if not shop then
		return false, "no_shop"
	end
	local def = items[itemId]
	if not def or not ShopLogic.sells(shop, itemId) then
		return false, "not_sold_here"
	end
	local price = def.price
	if type(price) ~= "number" or price < 0 or math.floor(price) ~= price then
		return false, "not_for_sale"
	end
	if def.kind == "cosmetic" and Inventory.has(profile, itemId, 1) then
		return false, "already_owned"
	end
	local okAdd, errAdd = Inventory.canAdd(profile, itemId, 1, items)
	if not okAdd then
		return false, errAdd
	end
	if not Wallet.canAfford(profile, price) then
		return false, "insufficient_funds"
	end
	return true, nil
end

-- Returns ok, err, pricePaid.
function ShopLogic.purchase(
	profile: ShopProfile,
	shop: ShopDef?,
	itemId: string,
	items: { [string]: ItemDef }
): (boolean, string?, number?)
	local ok, err = ShopLogic.canPurchase(profile, shop, itemId, items)
	if not ok then
		return false, err, nil
	end
	local price = items[itemId].price :: number
	Wallet.spend(profile, price)
	Inventory.add(profile, itemId, 1, items)
	return true, nil, price
end

-- wear = true puts the item on (replacing whatever is in its slot); false takes it off.
function ShopLogic.setWorn(
	profile: ShopProfile,
	itemId: string,
	wear: boolean,
	items: { [string]: ItemDef }
): (boolean, string?)
	local def = items[itemId]
	if not def or def.kind ~= "cosmetic" or def.slot == nil then
		return false, "not_cosmetic"
	end
	local slot = def.slot :: string
	if not wear then
		if profile.equipped[slot] ~= itemId then
			return false, "not_worn"
		end
		profile.equipped[slot] = nil
		return true, nil
	end
	if not Inventory.has(profile, itemId, 1) then
		return false, "not_owned"
	end
	profile.equipped[slot] = itemId
	return true, nil
end

return ShopLogic
