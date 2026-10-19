--!strict
-- Profile rollback (BUILD_PLAN P4-05, docs/ops/rollback.md). Studio only: the owner opens the place in Studio
-- (API access on, so it reaches the live data stores) and runs it through HaretDebug, dry first:
--   D:Invoke("restore", "<userId> <unix seconds>")          -- what a rollback to that moment would do
--   D:Invoke("restore", "<userId> <unix seconds> apply")    -- do it (the player must be out of the game)
--   RestoreService.drillBegin() / .drillFinish(key, atMs)    -- the drill, on the separate "HaretDrill" store
-- Logic/Restore decides the record (receipts after the version are kept); this module only lists, reads and
-- writes through UpdateAsync, which re-checks the session lock at write time.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Restore = require(Shared.Logic.Restore)

local RestoreService = {}

RestoreService.DRILL_STORE = "HaretDrill"
local MAX_VERSIONS = 200

-- Live and deleted versions of a key, oldest first (at most MAX_VERSIONS).
function RestoreService.versions(store: DataStore, key: string): { Restore.Version }
	local out: { Restore.Version } = {}
	local pages = store:ListVersionsAsync(key, Enum.SortDirection.Ascending)
	while #out < MAX_VERSIONS do
		for _, info in pages:GetCurrentPage() do
			table.insert(out, { version = info.Version, created = info.CreatedTime, deleted = info.IsDeleted })
		end
		if pages.IsFinished then
			break
		end
		pages:AdvanceToNextPageAsync()
	end
	return out
end

-- Rolls `key` back to its newest version at or before `atMs`. Dry unless `apply`. Returns a report.
function RestoreService.run(store: DataStore, key: string, atMs: number, apply: boolean): { [string]: any }
	if not RunService:IsStudio() then
		return { ok = false, err = "studio_only" }
	end
	local version = Restore.pickVersion(RestoreService.versions(store, key), atMs)
	if not version then
		return { ok = false, err = "no_version" }
	end
	local old = store:GetVersionAsync(key, version.version)
	local current = store:GetAsync(key)
	local plan, err = Restore.plan(old, current, os.time(), Economy.LOCK_STALE_SECONDS)
	if not plan then
		return { ok = false, err = err, version = version.version }
	end
	local report: { [string]: any } = {
		ok = true,
		version = version.version,
		created = version.created,
		lost = #plan.lost,
		replayed = #plan.replayed,
		net = plan.net,
		applied = false,
	}
	if apply then
		local refused: string? = nil
		store:UpdateAsync(key, function(now: any)
			-- the lock is checked again against the record as it is at write time
			local fresh, why = Restore.plan(old, now, os.time(), Economy.LOCK_STALE_SECONDS)
			if not fresh then
				refused = why
				return nil
			end
			return fresh.record
		end)
		report.applied = refused == nil
		report.err = refused
	end
	return report
end

-- Restore for a live profile key (Economy.KEY_PREFIX .. userId) in the profile store.
function RestoreService.restoreUser(userId: number, atSeconds: number, apply: boolean): { [string]: any }
	local store = DataStoreService:GetDataStore(Economy.DATASTORE_NAME)
	return RestoreService.run(store, Economy.KEY_PREFIX .. tostring(userId), atSeconds * 1000, apply)
end

local function deepEq(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not deepEq(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- The drill (P4-05 accept), on its own store, in two steps because Roblox keeps one version of a key per
-- time window (two writes seconds apart leave a single version: measured 2026-10-19, D-130):
--   drillBegin: write version A (a daily claimed) to a fresh key; note the key and the moment.
--   drillFinish (an hour or more later): write B (a match, a summon and a paid receipt since), roll the key
--   back to that moment and check it now holds A's profile plus the receipt, field for field.
local function drillRecords()
	local e1 = { at = 1, src = "daily", lira = 30 }
	local a = { data = { lira = 130, qirsh = 100, traitStones = 2, units = { walad = { copies = 1 } }, ledger = { e1 }, receipts = {} }, savedAt = 1 }
	local paid = { at = 3, src = "receipt:lira_300", lira = 300, key = "receipt:DRILL" }
	local b = {
		data = {
			lira = 130 + 80 - 500 + 300,
			qirsh = 220,
			traitStones = 2,
			units = { walad = { copies = 1 }, zaim = { copies = 1 } },
			ledger = { e1, { at = 2, src = "match:ep1", lira = 80, qirsh = 120 }, { at = 2.5, src = "summon_x10", lira = -500, seed = 9 }, paid },
			receipts = { DRILL = 3 },
		},
		savedAt = 2,
	}
	local expected = table.clone(a.data)
	expected.lira = 130 + 300
	expected.ledger = { e1, paid }
	expected.receipts = { DRILL = 3 }
	return a, b, expected
end

function RestoreService.drillBegin(): { [string]: any }
	if not RunService:IsStudio() then
		return { ok = false, err = "studio_only" }
	end
	local store = DataStoreService:GetDataStore(RestoreService.DRILL_STORE)
	local key = "drill_" .. HttpService:GenerateGUID(false)
	local a = drillRecords()
	local version = store:SetAsync(key, a)
	task.wait(1)
	return { ok = true, key = key, at = DateTime.now().UnixTimestampMillis, version = version }
end

function RestoreService.drillFinish(key: string, atMs: number): { [string]: any }
	if not RunService:IsStudio() then
		return { ok = false, err = "studio_only" }
	end
	local store = DataStoreService:GetDataStore(RestoreService.DRILL_STORE)
	local _, b, expected = drillRecords()
	store:SetAsync(key, b)
	local versions = RestoreService.versions(store, key)
	local report = RestoreService.run(store, key, atMs, true)
	local now = store:GetAsync(key)
	report.key = key
	report.versionsListed = #versions
	report.exact = type(now) == "table" and deepEq(now.data, expected) and now.lock == nil
	report.lira = if type(now) == "table" and type(now.data) == "table" then now.data.lira else nil
	return report
end

return RestoreService
