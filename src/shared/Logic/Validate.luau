--!strict
-- Argument validation helpers for untrusted (client) input and stored data. Pure.

local Validate = {}

function Validate.isFiniteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function Validate.isInteger(v: any): boolean
	return Validate.isFiniteNumber(v) and math.floor(v) == v
end

function Validate.isNonNegativeInteger(v: any): boolean
	return Validate.isInteger(v) and v >= 0
end

function Validate.isPositiveInteger(v: any): boolean
	return Validate.isInteger(v) and v > 0
end

function Validate.isShortString(v: any, maxLen: number?): boolean
	return type(v) == "string" and #v > 0 and #v <= (maxLen or 64)
end

function Validate.isIdentifier(v: any): boolean
	return Validate.isShortString(v, 64) and string.match(v, "^[%w_]+$") ~= nil
end

return Validate
