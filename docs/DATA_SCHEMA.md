# Data Schema

*Status: living document · Last updated 2026-10-15 · Current schema version: **1***

## 1. Store layout

| Item | Value |
|------|-------|
| DataStore | `PlayerData_v1` (from `Economy.DATASTORE_NAME`) |
| Key | `u_<UserId>` |
| Value | `StoredRecord` (below) |
| UserIds | Attached to every `SetAsync`/`UpdateAsync` write (helps with GDPR "right to erasure" requests) |

```lua
type StoredRecord = {
	data: Profile,
	lock: { jobId: string, at: number }?, -- os.time() of the last refresh; nil when released
	savedAt: number,
}
```

## 2. Profile (v1)

```lua
type Profile = {
	schemaVersion: number,                 -- 1
	qirsh: number,                         -- integer, 0 .. Economy.MAX_QIRSH
	inventory: { [string]: number },       -- itemId → count (>0); removed keys mean 0
	equipped: { head: string? },           -- slot → itemId (must be owned)
	quests: { [string]: QuestRecord },
	settings: { language: string? },       -- "en" | "ar" | nil (= follow the Roblox locale)
	stats: { firstJoin: number, lastJoin: number, sessions: number },
	receipts: { [string]: number },        -- RESERVED: Robux PurchaseId → os.time(); idempotent ProcessReceipt
}

type QuestRecord = {
	state: "active" | "completed",
	startedAt: number,
	completedAt: number?,
	completions: number,                   -- for repeatable quests
}
```

### Defaults

```lua
{ schemaVersion = 1, qirsh = 0, inventory = {}, equipped = {}, quests = {},
  settings = {}, stats = { firstJoin = now, lastJoin = now, sessions = 0 }, receipts = {} }
```

## 3. Invariants (enforced by `Logic/ProfileSchema.sanitize` on load and by the logic modules on write)

1. `qirsh` is a finite non-negative integer ≤ `MAX_QIRSH`.
2. Inventory counts are positive integers ≤ the item's `stackMax`. Unknown item ids are **kept** (never
   deleted), so that a rolled-back config cannot wipe player items. They are hidden in the UI.
3. `equipped[slot]` refers to an owned cosmetic of that slot; otherwise it is cleared.
4. Quest records have a valid state; unknown quest ids are kept.
5. `receipts` keeps the last 100 entries at most (oldest are pruned).

## 4. Versioning and migration

- `ProfileSchema.migrate(data)` runs on load, applying the steps `1 → 2 → …` in order. Each step is a pure
  function, unit-tested with a fixture of the previous version.
- If a profile's `schemaVersion` is **newer** than the server knows (an old server during a rolling update), the
  server **refuses to load it** and kicks the player with a "the game was updated, please rejoin" message.
  The data is never downgraded.

## 5. Session locking

1. **Load:** `UpdateAsync`. If the record has a lock from another `JobId` refreshed less than
   `LOCK_STALE_SECONDS` (600 s) ago, return without writing and retry after 6 s, up to 5 times. Otherwise
   take the lock (ours, `at = now`) and return the data.
2. **Autosave** every 120 s when dirty, and always refreshing the lock: `UpdateAsync` checks that the lock is
   still ours. If it is not, the save is aborted and the player is kicked (another server owns them).
3. **Release:** the save on `PlayerRemoving` or `BindToClose` writes the data and sets `lock = nil`.
4. **Retries:** every DataStore call retries 5 times with backoff (1, 2, 4, 8 s, capped). A load that fails
   for good kicks the player and is never saved.

## 6. Budget

Per player per session: 1 load + about 1 save per 2 minutes + 1 release. Well within
`60 + numPlayers × 10` requests per minute.

## 7. Data that is *not* stored

- Chat or any free text from players.
- Dialogue progress mid-conversation (sessions are transient).
- Position (players always spawn at the gate in the slice).
