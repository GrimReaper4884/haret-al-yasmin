--!strict
-- Inventory rules. Items are counted per id; stack limits come from the Items config. Pure.

type InvProfile = { inventory: { [string]: number } }
type ItemsConfig = { [string]: { stackMax: number } }

local Inventory = {}

local function isPositiveInt(n: any): boolean
	return type(n) == "number" and n == n and n > 0 and n ~= math.huge and math.floor(n) == n
end

function Inventory.count(profile: InvProfile, itemId: string): number
	return profile.inventory[itemId] or 0
end

function Inventory.has(profile: InvProfile, itemId: string, n: number?): boolean
	return Inventory.count(profile, itemId) >= (n or 1)
end

function Inventory.canAdd(profile: InvProfile, itemId: string, n: number, items: ItemsConfig): (boolean, string?)
	local def = items[itemId]
	if not def then
		return false, "unknown_item"
	end
	if not isPositiveInt(n) then
		return false, "invalid_amount"
	end
	if Inventory.count(profile, itemId) + n > def.stackMax then
		return false, "stack_full"
	end
	return true, nil
end

function Inventory.add(profile: InvProfile, itemId: string, n: number, items: ItemsConfig): (boolean, string?)
	local ok, err = Inventory.canAdd(profile, itemId, n, items)
	if not ok then
		return false, err
	end
	profile.inventory[itemId] = Inventory.count(profile, itemId) + n
	return true, nil
end

function Inventory.remove(profile: InvProfile, itemId: string, n: number): (boolean, string?)
	if not isPositiveInt(n) then
		return false, "invalid_amount"
	end
	local have = Inventory.count(profile, itemId)
	if have < n then
		return false, "not_enough"
	end
	local left = have - n
	if left > 0 then
		profile.inventory[itemId] = left
	else
		profile.inventory[itemId] = nil
	end
	return true, nil
end

return Inventory
