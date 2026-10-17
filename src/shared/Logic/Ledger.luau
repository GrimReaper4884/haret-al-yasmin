--!strict
-- Audit ledger: every lira / qirsh / trait-stone change a profile mutation makes is recorded in a
-- per-player ring buffer (profile.ledger) inside the same mutation, with its source, an
-- idempotency key (receipt or code) and the roll seed for summons and rerolls. Pure.
--
-- DataService.mutate runs every profile write through Ledger.mutate, so a service never writes an
-- entry by hand: it only names the source (and key / seed) of the mutation.

export type Meta = {
	src: string, -- "summon_x10", "receipt:lira_small", "code:WELCOME", "match", "shop", "debug"…
	key: string?, -- idempotency key: the same key is never recorded twice
	seed: number?, -- RNG seed of the rolls this mutation made (summons, trait rerolls)
}

export type Entry = {
	at: number,
	src: string,
	lira: number?, -- signed delta; absent when unchanged
	qirsh: number?,
	stones: number?,
	key: string?,
	seed: number?,
}

export type Balances = { lira: number, qirsh: number, stones: number }

local Ledger = {}

Ledger.UNKNOWN_SOURCE = "unknown"

local function isFinite(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function num(v: any): number
	return if isFinite(v) then v else 0
end

function Ledger.snapshot(profile: any): Balances
	return { lira = num(profile.lira), qirsh = num(profile.qirsh), stones = num(profile.traitStones) }
end

function Ledger.hasKey(profile: any, key: string): boolean
	local list = profile.ledger
	if type(list) ~= "table" then
		return false
	end
	for _, e in ipairs(list) do
		if e.key == key then
			return true
		end
	end
	return false
end

-- Records the balance changes since `before`. Returns the entry, or nil when nothing moved or the
-- idempotency key was already recorded (a replayed receipt or code never gets a second line).
function Ledger.commit(profile: any, before: Balances, meta: Meta?, now: number, maxEntries: number): Entry?
	local after = Ledger.snapshot(profile)
	local dLira, dQirsh, dStones = after.lira - before.lira, after.qirsh - before.qirsh, after.stones - before.stones
	if dLira == 0 and dQirsh == 0 and dStones == 0 then
		return nil
	end
	local key = if meta then meta.key else nil
	if key and Ledger.hasKey(profile, key) then
		return nil
	end
	local entry: Entry = {
		at = now,
		src = if meta and type(meta.src) == "string" and #meta.src > 0 then meta.src else Ledger.UNKNOWN_SOURCE,
		lira = if dLira ~= 0 then dLira else nil,
		qirsh = if dQirsh ~= 0 then dQirsh else nil,
		stones = if dStones ~= 0 then dStones else nil,
		key = key,
		seed = if meta and isFinite(meta.seed) then meta.seed else nil,
	}
	local list = profile.ledger
	if type(list) ~= "table" then
		list = {}
		profile.ledger = list
	end
	table.insert(list, entry)
	while #list > maxEntries do
		table.remove(list, 1)
	end
	return entry
end

-- Runs fn(profile) and, when it returns true, records the balance changes it made. Returns the
-- entry (or nil) followed by everything fn returned.
function Ledger.mutate(profile: any, fn: (any) -> (boolean, ...any), meta: Meta?, now: number, maxEntries: number): (Entry?, boolean, ...any)
	local before = Ledger.snapshot(profile)
	local results = table.pack(fn(profile))
	local entry: Entry? = nil
	if results[1] == true then
		entry = Ledger.commit(profile, before, meta, now, maxEntries)
	end
	return entry, table.unpack(results, 1, results.n)
end

-- Keeps only well-formed entries, newest `maxEntries`.
function Ledger.sanitize(raw: any, maxEntries: number): { Entry }
	local out: { Entry } = {}
	if type(raw) ~= "table" then
		return out
	end
	for _, e in ipairs(raw) do
		if type(e) == "table" and isFinite(e.at) and type(e.src) == "string" then
			local lira, qirsh, stones = num(e.lira), num(e.qirsh), num(e.stones)
			if lira ~= 0 or qirsh ~= 0 or stones ~= 0 then
				table.insert(out, {
					at = e.at,
					src = string.sub(e.src, 1, 64),
					lira = if lira ~= 0 then lira else nil,
					qirsh = if qirsh ~= 0 then qirsh else nil,
					stones = if stones ~= 0 then stones else nil,
					key = if type(e.key) == "string" then string.sub(e.key, 1, 64) else nil,
					seed = if isFinite(e.seed) then e.seed else nil,
				})
			end
		end
	end
	while #out > maxEntries do
		table.remove(out, 1)
	end
	return out
end

return Ledger
