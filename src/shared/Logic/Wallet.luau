--!strict
-- Currency rules (qirsh). Pure: operates on a profile table, validates before writing.

type WalletProfile = { qirsh: number }

local Wallet = {}

local function isAmount(n: any): boolean
	return type(n) == "number" and n == n and n >= 0 and n ~= math.huge and math.floor(n) == n
end

function Wallet.balance(profile: WalletProfile): number
	return profile.qirsh
end

function Wallet.canAfford(profile: WalletProfile, amount: number): boolean
	return isAmount(amount) and profile.qirsh >= amount
end

-- Adds qirsh, clamped to maxBalance. Returns the amount actually added.
function Wallet.add(profile: WalletProfile, amount: number, maxBalance: number): (boolean, string?, number?)
	if not isAmount(amount) then
		return false, "invalid_amount", nil
	end
	local before = profile.qirsh
	profile.qirsh = math.min(before + amount, maxBalance)
	return true, nil, profile.qirsh - before
end

function Wallet.spend(profile: WalletProfile, amount: number): (boolean, string?)
	if not isAmount(amount) then
		return false, "invalid_amount"
	end
	if profile.qirsh < amount then
		return false, "insufficient_funds"
	end
	profile.qirsh -= amount
	return true, nil
end

return Wallet
