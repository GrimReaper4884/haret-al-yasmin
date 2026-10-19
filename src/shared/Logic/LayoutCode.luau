--!strict
-- Layout codes (BUILD_PLAN P3-06): a tower layout as a short text a player can copy, share and paste back.
-- Pure. "HY1-" + base64url (no padding) of: version byte, arena id (length byte + ASCII), tower count, then
-- per tower its loadout slot (1 byte) and arena-local x and z in half studs (signed 16-bit each).
--
-- A code carries no unit ids, levels or cash: the slot is read against the importer's own loadout, and every
-- tower is placed through the normal server placement rules (cash, spacing, path, bounds), so a code can
-- never do more than its importer could do by hand. `decode` refuses anything malformed (P3-06 accept).

local LayoutCode = {}

LayoutCode.PREFIX = "HY1-"
LayoutCode.VERSION = 1
LayoutCode.MAX_LEN = 256 -- characters, prefix included (20 towers on the longest arena id fit in ~170)

export type Entry = { slot: number, x: number, z: number }
export type Layout = { arena: string, entries: { Entry } }

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local DECODE: { [number]: number } = {}
for i = 1, #ALPHABET do
	DECODE[string.byte(ALPHABET, i)] = i - 1
end

local function b64encode(bytes: { number }): string
	local out = {}
	for i = 1, #bytes, 3 do
		local a, b, c = bytes[i], bytes[i + 1], bytes[i + 2]
		local n = a * 65536 + (b or 0) * 256 + (c or 0)
		local chars = 2 + (if b then 1 else 0) + (if c then 1 else 0)
		for k = 1, chars do
			local v = bit32.band(bit32.rshift(n, 18 - 6 * (k - 1)), 63)
			table.insert(out, string.sub(ALPHABET, v + 1, v + 1))
		end
	end
	return table.concat(out)
end

local function b64decode(s: string): { number }?
	if #s % 4 == 1 then
		return nil
	end
	local bytes = {}
	for i = 1, #s, 4 do
		local n, chars = 0, 0
		for k = 0, 3 do
			local ch = string.byte(s, i + k)
			if ch then
				local v = DECODE[ch]
				if v == nil then
					return nil
				end
				n = n * 64 + v
				chars += 1
			else
				n *= 64
			end
		end
		table.insert(bytes, bit32.band(bit32.rshift(n, 16), 255))
		if chars >= 3 then
			table.insert(bytes, bit32.band(bit32.rshift(n, 8), 255))
		end
		if chars == 4 then
			table.insert(bytes, bit32.band(n, 255))
		end
	end
	return bytes
end

local function int16(v: number): (number, number)
	local u = if v < 0 then v + 65536 else v
	return bit32.rshift(u, 8), bit32.band(u, 255)
end

-- arenaId: a Config/Arenas key; entries in placement order. Coordinates round to half studs.
function LayoutCode.encode(arenaId: string, entries: { Entry }): string
	local bytes = { LayoutCode.VERSION, #arenaId }
	for i = 1, #arenaId do
		table.insert(bytes, string.byte(arenaId, i))
	end
	table.insert(bytes, #entries)
	for _, e in entries do
		table.insert(bytes, e.slot)
		local xh, xl = int16(math.floor(e.x * 2 + 0.5))
		local zh, zl = int16(math.floor(e.z * 2 + 0.5))
		table.insert(bytes, xh)
		table.insert(bytes, xl)
		table.insert(bytes, zh)
		table.insert(bytes, zl)
	end
	return LayoutCode.PREFIX .. b64encode(bytes)
end

-- limits: { arenas = Config/Arenas, maxSlots = the most loadout slots anyone has, towerCap = TD.TOWER_CAP }.
-- Returns the layout, or nil and why: "bad_code" (not a code at all), "bad_version", "unknown_arena",
-- "too_many", "bad_slot", "out_of_bounds".
function LayoutCode.decode(code: any, limits: { arenas: any, maxSlots: number, towerCap: number }): (Layout?, string?)
	if type(code) ~= "string" or #code > LayoutCode.MAX_LEN or string.sub(code, 1, #LayoutCode.PREFIX) ~= LayoutCode.PREFIX then
		return nil, "bad_code"
	end
	local bytes = b64decode(string.sub(code, #LayoutCode.PREFIX + 1))
	if not bytes or #bytes < 3 then
		return nil, "bad_code"
	end
	if bytes[1] ~= LayoutCode.VERSION then
		return nil, "bad_version"
	end
	local idLen = bytes[2]
	if idLen < 1 or idLen > 64 or #bytes < 3 + idLen then
		return nil, "bad_code"
	end
	local chars = {}
	for i = 3, 2 + idLen do
		local b = bytes[i]
		-- identifiers only: lower-case letters, digits and underscores
		if not ((b >= 97 and b <= 122) or (b >= 48 and b <= 57) or b == 95) then
			return nil, "bad_code"
		end
		table.insert(chars, string.char(b))
	end
	local arenaId = table.concat(chars)
	local arena = limits.arenas[arenaId]
	if not arena then
		return nil, "unknown_arena"
	end
	local n = bytes[3 + idLen]
	if n > limits.towerCap then
		return nil, "too_many"
	end
	if #bytes ~= 3 + idLen + n * 5 then
		return nil, "bad_code"
	end
	local entries: { Entry } = {}
	local bnd = arena.bounds
	for i = 0, n - 1 do
		local at = 4 + idLen + i * 5
		local slot = bytes[at]
		if slot < 1 or slot > limits.maxSlots then
			return nil, "bad_slot"
		end
		local xu = bytes[at + 1] * 256 + bytes[at + 2]
		local zu = bytes[at + 3] * 256 + bytes[at + 4]
		local x = (if xu >= 32768 then xu - 65536 else xu) / 2
		local z = (if zu >= 32768 then zu - 65536 else zu) / 2
		if x < bnd[1] or x > bnd[3] or z < bnd[2] or z > bnd[4] then
			return nil, "out_of_bounds"
		end
		table.insert(entries, { slot = slot, x = x, z = z })
	end
	return { arena = arenaId, entries = entries }, nil
end

-- A layout read against a loadout: the plan (unit ids) and its fixed spots, skipping slots the loadout
-- leaves empty.
function LayoutCode.toPlan(layout: Layout, loadout: { string }): ({ string }, { { x: number, z: number } })
	local plan, spots = {}, {}
	for _, e in layout.entries do
		local unitId = loadout[e.slot]
		if unitId then
			table.insert(plan, unitId)
			table.insert(spots, { x = e.x, z = e.z })
		end
	end
	return plan, spots
end

return LayoutCode
