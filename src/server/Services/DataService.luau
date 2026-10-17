--!strict
-- Owns player profiles: session-locked load, autosave, release, and the single mutation entry
-- point (DataService.mutate). See docs/DATA_SCHEMA.md for the locking protocol.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Items = require(Shared.Config.Items)
local Units = require(Shared.Config.Units)
local Traits = require(Shared.Config.Traits)
local SeasonPass = require(Shared.Config.SeasonPass)
local TD = require(Shared.Config.TD)
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local Ledger = require(Shared.Logic.Ledger)
local Locale = require(Shared.Util.Locale)
local Signal = require(Shared.Util.Signal)
local DataStoreAdapter = require(script.Parent.DataStoreAdapter)
local Analytics = require(script.Parent.AnalyticsService)

type Entry = {
	profile: any?,
	loaded: boolean,
	released: boolean, -- final save done (or must never be saved)
	saving: boolean,
	version: number, -- bumped on every successful mutation
	savedVersion: number,
}

local DataService = {}

DataService.ProfileLoaded = Signal.new()
DataService.ProfileChanged = Signal.new()
DataService.LedgerEntry = Signal.new() -- (player, Ledger.Entry) after a mutation moved a currency

local store: DataStoreAdapter.Store
local entries: { [Player]: Entry } = {}
local shuttingDown = false

local schemaCtx: ProfileSchema.Context = {
	schemaVersion = Economy.SCHEMA_VERSION,
	maxQirsh = Economy.MAX_QIRSH,
	maxLira = TD.MAX_LIRA,
	maxStones = TD.MAX_TRAIT_STONES,
	receiptHistory = Economy.RECEIPT_HISTORY,
	ledgerSize = Economy.LEDGER_SIZE,
	items = Items :: any,
	units = Units :: any,
	traits = Traits.traits :: any,
	starterUnit = TD.STARTER_UNIT,
	starterLira = TD.STARTER_LIRA,
	season = SeasonPass.season,
}

local function keyFor(player: Player): string
	return Economy.KEY_PREFIX .. tostring(player.UserId)
end

local function kick(player: Player, key: string)
	if player.Parent then
		player:Kick(Locale.get("en", key) .. "\n" .. Locale.get("ar", key))
	end
end

-- Runs fn with exponential backoff. Returns ok, lastError.
local function withRetries(label: string, fn: () -> ()): (boolean, string?)
	local delay = 1
	local lastErr: string? = nil
	for attempt = 1, Economy.STORE_RETRIES do
		local ok, err = pcall(fn :: () -> any)
		if ok then
			return true, nil
		end
		local message = tostring(err)
		lastErr = message
		warn(string.format("[DataService] %s failed (attempt %d/%d): %s", label, attempt, Economy.STORE_RETRIES, message))
		if attempt < Economy.STORE_RETRIES then
			task.wait(delay)
			delay = math.min(delay * 2, 8)
		end
	end
	return false, lastErr
end

-- Attempts to load and lock. Returns profile or nil plus a reason
-- ("locked" | "newer_schema" | "corrupt" | "store_error").
local function tryLoad(player: Player): (any?, string?)
	local key = keyFor(player)
	local loaded: any = nil
	local reason: string? = nil

	local ok = withRetries("load " .. key, function()
		loaded, reason = nil, nil
		store:update(key, function(record: any)
			local now = os.time()
			local rec = if type(record) == "table" then record else {}
			local lock = rec.lock
			if
				type(lock) == "table"
				and lock.jobId ~= game.JobId
				and type(lock.at) == "number"
				and now - lock.at < Economy.LOCK_STALE_SECONDS
			then
				reason = "locked"
				return nil
			end
			if record ~= nil and type(record) ~= "table" then
				reason = "corrupt"
				return nil
			end
			local profile, err = ProfileSchema.load(rec.data, schemaCtx, now)
			if not profile then
				reason = err
				return nil
			end
			ProfileSchema.beginSession(profile, now)
			loaded = profile
			return {
				data = ProfileSchema.clone(profile),
				lock = { jobId = game.JobId, at = now },
				savedAt = now,
			},
				{ player.UserId }
		end)
	end)
	if not ok then
		return nil, "store_error"
	end
	return loaded, reason
end

-- Returns true when the data was written (lock still ours).
local function save(player: Player, release: boolean): boolean
	local entry = entries[player]
	if not entry or not entry.loaded or entry.released then
		return false
	end
	while entry.saving do
		task.wait(0.1)
	end
	if entry.released then
		return false
	end
	if release then
		entry.released = true -- no further saves after the final one starts
	end
	entry.saving = true

	local key = keyFor(player)
	local snapshot = ProfileSchema.clone(entry.profile)
	local snapshotVersion = entry.version
	local lost = false

	local ok = withRetries("save " .. key, function()
		lost = false
		store:update(key, function(record: any)
			local lock = if type(record) == "table" then record.lock else nil
			if type(lock) ~= "table" or lock.jobId ~= game.JobId then
				lost = true
				return nil
			end
			local now = os.time()
			return {
				data = snapshot,
				lock = if release then nil else { jobId = game.JobId, at = now },
				savedAt = now,
			},
				{ player.UserId }
		end)
	end)
	entry.saving = false

	if lost then
		warn("[DataService] session lock lost for " .. key .. "; not saving")
		entry.released = true
		kick(player, "kick.session_lost")
	elseif ok then
		entry.savedVersion = math.max(entry.savedVersion, snapshotVersion)
	else
		warn("[DataService] giving up saving " .. key .. " after retries")
	end
	return ok and not lost
end

local function onPlayerAdded(player: Player)
	local entry: Entry = { profile = nil, loaded = false, released = false, saving = false, version = 0, savedVersion = 0 }
	entries[player] = entry

	local profile, reason = nil, nil
	for attempt = 1, Economy.LOAD_LOCK_RETRIES do
		profile, reason = tryLoad(player)
		if reason ~= "locked" or not player.Parent then
			break
		end
		if attempt < Economy.LOAD_LOCK_RETRIES then
			task.wait(Economy.LOAD_LOCK_WAIT)
		end
	end

	if not profile then
		entry.released = true -- never save over data we failed to read
		warn("[DataService] load failed for " .. player.Name .. ": " .. tostring(reason))
		local kickKey = if reason == "locked"
			then "kick.session_locked"
			elseif reason == "newer_schema" then "kick.newer_schema"
			else "kick.load_failed"
		kick(player, kickKey)
		return
	end

	entry.profile = profile
	entry.loaded = true

	if not player.Parent then
		-- Left while loading: release the lock we just took.
		save(player, true)
		entries[player] = nil
		return
	end
	DataService.ProfileLoaded:Fire(player, profile)
end

local beforeRelease: { (Player) -> () } = {}

local function runBeforeRelease(player: Player)
	for _, fn in beforeRelease do
		local ok, err = pcall(function()
			fn(player)
		end)
		if not ok then
			warn("[DataService] beforeRelease hook failed: " .. tostring(err))
		end
	end
end

local function onPlayerRemoving(player: Player)
	local entry = entries[player]
	if not entry then
		return
	end
	runBeforeRelease(player)
	save(player, true)
	entries[player] = nil
end

------------------------------------------------------------------------------------------
-- Public API

function DataService.init()
	store = DataStoreAdapter.create(Economy.DATASTORE_NAME)
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	-- Autosave: always runs (it also refreshes the session lock).
	task.spawn(function()
		while not shuttingDown do
			task.wait(Economy.AUTOSAVE_INTERVAL)
			for player in entries do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		shuttingDown = true
		local pending = 0
		for player in entries do
			pending += 1
			task.spawn(function()
				runBeforeRelease(player)
				save(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

-- Registers a function that runs (without yielding) just before a player's final save, so
-- services can write in-memory progress into the profile (e.g. AFK sitting time).
function DataService.beforeRelease(fn: (Player) -> ())
	table.insert(beforeRelease, fn)
end

function DataService.isPersistent(): boolean
	return store ~= nil and not store.isMock
end

-- Read-only access. Do not modify the returned table; use mutate.
function DataService.getProfile(player: Player): any?
	local entry = entries[player]
	if entry and entry.loaded and not entry.released then
		return entry.profile
	end
	return nil
end

-- Applies fn to the live profile. fn MUST NOT yield and must only write when it returns true
-- (all Logic modules validate first, then write). Returns whatever fn returns.
-- `meta` names the mutation for the audit ledger (Logic/Ledger): any lira / qirsh / trait-stone
-- change fn makes is recorded in profile.ledger inside this same mutation, with meta.key as the
-- idempotency key and meta.seed as the roll seed. Mutations that move a currency without a meta
-- are recorded as "unknown" (and warned about in Studio) so the audit stays complete.
function DataService.mutate(player: Player, fn: (profile: any) -> (boolean, ...any), meta: Ledger.Meta?): (boolean, ...any)
	local entry = entries[player]
	if not entry or not entry.loaded or entry.released then
		return false, "not_loaded"
	end
	local results = table.pack(Ledger.mutate(entry.profile, fn, meta, os.time(), Economy.LEDGER_SIZE))
	local ledgerEntry = results[1] :: Ledger.Entry?
	if results[2] == true then
		entry.version += 1
		DataService.ProfileChanged:Fire(player)
		if ledgerEntry then
			if ledgerEntry.src == Ledger.UNKNOWN_SOURCE and RunService:IsStudio() then
				warn("[DataService] currency changed without a ledger source: " .. debug.traceback("", 2))
			end
			Analytics.ledger(player, ledgerEntry, entry.profile)
			DataService.LedgerEntry:Fire(player, ledgerEntry)
		end
	end
	return table.unpack(results, 2, results.n)
end

-- The audit trail (newest last). Read-only.
function DataService.ledger(player: Player): { Ledger.Entry }
	local profile = DataService.getProfile(player)
	return if profile and type(profile.ledger) == "table" then profile.ledger else {}
end

-- Saves immediately (keeps the session). Used after Robux grants so a receipt is only
-- acknowledged once the grant is durable.
function DataService.saveNow(player: Player): boolean
	return save(player, false)
end

------------------------------------------------------------------------------------------
-- Test hooks (used from Studio via MCP / command bar; harmless in production).

DataService.debug = {}

function DataService.debug.store(): DataStoreAdapter.Store
	return store
end

-- Saves + releases, then loads again from the store: exercises the full persistence round trip.
function DataService.debug.reload(player: Player): (boolean, string?)
	local entry = entries[player]
	if not entry or not entry.loaded then
		return false, "not_loaded"
	end
	save(player, true)
	entries[player] = nil
	onPlayerAdded(player)
	return DataService.getProfile(player) ~= nil, nil
end

function DataService.debug.saveNow(player: Player)
	save(player, false)
end

function DataService.debug.isDirty(player: Player): boolean
	local entry = entries[player]
	return entry ~= nil and entry.version > entry.savedVersion
end

return DataService
