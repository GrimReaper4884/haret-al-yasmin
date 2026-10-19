--!strict
-- Profile rollback (BUILD_PLAN P4-05, docs/ops/rollback.md). Pure. RestoreService lists a key's DataStore
-- versions and reads one; this module decides what to write back:
--   * pickVersion: the newest live (not deleted) version created at or before a moment;
--   * plan: the restored record = that version's profile, the session lock cleared, plus every Robux receipt
--     the player paid for after that version (ledger entries with src "receipt:…"): their currency, their
--     ledger entry and their receipt id are carried over, so a rollback never takes back a purchase. Everything
--     else after the version (matches, summons, codes, dailies…) is reported as lost. A record whose session
--     lock is fresh (a server holds the player) is refused: the player must be out of the game.
--
-- A record is DataService's { data = profile, lock = { jobId, at }?, savedAt }.

local Restore = {}

export type Version = { version: string, created: number, deleted: boolean } -- created: unix ms
export type Entry = { at: number, src: string, lira: number?, qirsh: number?, stones: number?, key: string?, seed: number? }
export type Plan = {
	record: any, -- what to write
	lost: { Entry }, -- ledger entries after the version that the rollback undoes
	replayed: { Entry }, -- receipts carried over
	net: { lira: number, qirsh: number, stones: number }, -- currency the rollback takes back (lost minus replayed)
}

local BALANCE = { lira = "lira", qirsh = "qirsh", stones = "traitStones" }

local function clone(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = clone(x)
	end
	return out
end

local function signature(e: any): string
	return string.format("%s|%s|%s|%s|%s|%s|%s", tostring(e.at), tostring(e.src), tostring(e.lira), tostring(e.qirsh), tostring(e.stones), tostring(e.key), tostring(e.seed))
end

function Restore.pickVersion(versions: { Version }, atMs: number): Version?
	local best: Version? = nil
	for _, v in versions do
		if not v.deleted and v.created <= atMs and (best == nil or v.created > best.created) then
			best = v
		end
	end
	return best
end

-- old: the version's record; current: the record now (nil if none); now: os.time(); lockStale: Economy.LOCK_STALE_SECONDS.
function Restore.plan(old: any, current: any, now: number, lockStale: number): (Plan?, string?)
	if type(old) ~= "table" or type(old.data) ~= "table" then
		return nil, "no_data"
	end
	if type(current) == "table" and type(current.lock) == "table" and type(current.lock.at) == "number" and now - current.lock.at < lockStale then
		return nil, "locked"
	end
	local data = clone(old.data)
	data.ledger = data.ledger or {}
	local had: { [string]: boolean } = {}
	for _, e in data.ledger do
		had[signature(e)] = true
	end
	local lost, replayed = {}, {}
	local net = { lira = 0, qirsh = 0, stones = 0 }
	local curData = if type(current) == "table" and type(current.data) == "table" then current.data else nil
	for _, e in (if curData and curData.ledger then curData.ledger else {}) do
		if not had[signature(e)] then
			if type(e.src) == "string" and string.sub(e.src, 1, 8) == "receipt:" then
				table.insert(replayed, clone(e))
				for field, balance in BALANCE do
					local d = e[field]
					if type(d) == "number" then
						data[balance] = (data[balance] or 0) + d
					end
				end
				table.insert(data.ledger, clone(e))
				local purchaseId = if type(e.key) == "string" then string.match(e.key, "^receipt:(.+)$") else nil
				if purchaseId and curData and type(curData.receipts) == "table" and curData.receipts[purchaseId] ~= nil then
					data.receipts = data.receipts or {}
					data.receipts[purchaseId] = curData.receipts[purchaseId]
				end
			else
				table.insert(lost, clone(e))
				for field in BALANCE do
					local d = e[field]
					if type(d) == "number" then
						net[field] += d
					end
				end
			end
		end
	end
	local record = { data = data, lock = nil, savedAt = now }
	return { record = record, lost = lost, replayed = replayed, net = net }, nil
end

return Restore
