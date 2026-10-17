# Data Schema

*Status: living document · Last updated 2026-10-17 · Current schema version: **2***

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
2. **Autosave** every 120 s for every loaded player (it always runs, because it refreshes the lock): `UpdateAsync` checks that the lock is
   still ours. If it is not, the save is aborted and the player is kicked (another server owns them).
3. **Release:** the save on `PlayerRemoving` or `BindToClose` writes the data and sets `lock = nil`.
4. **Retries:** every DataStore call retries 5 times with backoff (1, 2, 4, 8 s, capped). A load that fails
   for good kicks the player and is never saved.

## 6. Budget

Per player per session: 1 load + 1 save every 2 minutes + 1 release. Well within
`60 + numPlayers × 10` requests per minute.

## 7. Data that is *not* stored

- Chat or any free text from players.
- Dialogue progress mid-conversation (sessions are transient).
- Position (players always spawn at the gate in the slice).

## 8. Studio and mock mode

`DataStoreAdapter.create` uses an in-memory mock when the place is unpublished (`PlaceId == 0`) or
Studio API access is off. The HUD then shows "Test mode: progress will not be saved." The mock supports
`failNext(n)` for testing retries. `DataService.debug.reload(player)` saves, releases and reloads a profile,
which exercises the full persistence round trip inside one Studio session. Note that `game.JobId` is
empty in Studio, so session locks cannot tell two Studio sessions apart; test lock contention on a
published **test** experience.

## Schema v2 (tower-defense update, 2026-10-16)

`SCHEMA_VERSION = 2`. Migration 1 -> 2 is the identity; `ProfileSchema.sanitize` fills the new fields:

| Field | Shape | Notes |
|-------|-------|-------|
| `lira` | integer 0..10,000,000 | summon currency |
| `welcomeLira` | `true` once paid | the one-time `TD.STARTER_LIRA` gift (500) was added to `lira`; sanitize pays it to any profile without the flag |
| `traitStones` | integer 0..100,000 | trait rerolls |
| `units` | `{ [unitId]: { copies, trait, at } }` | unknown ids and traits are dropped; the starter unit (`TD.STARTER_UNIT`) is always present |
| `loadout` | `{ unitId }` | owned, unique, de-duplicated; defaults to the starter |
| `summons` | `{ total, sinceLegendary, sinceMythic }` | pity counters |
| `pass` | `{ season, xp, premium, claimedFree{tier->true}, claimedPremium }` | reset when `season ~= SeasonPass.season` |
| `codes` | `{ [CODE]: at }` | redeemed codes |
| `bundles` | `{ [productNameKey]: at }` | one-time bundles |
| `daily` | `{ streak, lastDay }` | UTC day index |
| `afk` | `{ day, lira, carry, cups, tales, seconds }` | The Hakawati's room (AFK chamber): UTC day and lira paid that day (cap), seconds toward the next cup, lifetime cups / tales / seconds. Filled by `AfkLogic.sanitize`; see docs/AFK_CHAMBER.md §5 |
| `td` | `{ matches, wins, kills, cleared{modeId->difficulty}, bestInfinite }` | unlocks and stats |
| `ledger` | `{ Entry }`, newest last, ≤ `Economy.LEDGER_SIZE` (200) | audit ring buffer, see §9 |

Tier keys inside `claimedFree`/`claimedPremium` are strings ("1".."50") so the DataStore JSON stays an
object. All new tables use string keys only. In Studio, a failed load no longer kicks (flag
`KICK_IN_STUDIO` in DataService) and the mock store seeds 5,000 lira and 5 trait stones.

## 9. Audit ledger (BUILD_PLAN P2-15, 2026-10-17)

Every change to `lira`, `qirsh` or `traitStones` is recorded **inside the mutation that made it**.
`DataService.mutate(player, fn, meta)` runs `fn` through `Logic/Ledger.mutate`: it snapshots the three
balances, runs `fn`, and when `fn` returns `true` and a balance moved it appends one entry to
`profile.ledger` in the same step (so the entry is saved with the grant or not at all, and `fn` still
never yields). Services never write entries by hand; they only name the mutation:

```lua
type Meta = { src: string, key: string?, seed: number? }
type Entry = {
	at: number,        -- os.time()
	src: string,       -- see the table below (≤ 64 chars)
	lira: number?,     -- signed delta; absent when that currency did not move
	qirsh: number?,
	stones: number?,
	key: string?,      -- idempotency key: never recorded twice
	seed: number?,     -- RNG seed of the rolls this mutation made
}
```

| `src` | Where | `key` | `seed` |
|---|---|---|---|
| `receipt:<productKey>` | `MonetizationService.processReceipt` | `receipt:<PurchaseId>` | |
| `code:<CODE>` | `MetaService.redeemCode` | `code:<CODE>` | |
| `summon_x1` / `summon_x10` | `MetaService.summon` | | seed of the `Random` that drove every rarity, unit and trait roll of the pull |
| `reroll:<unitId>` | `MetaService.rerollTrait` | | seed of the reroll (nudge included) |
| `pass:free` / `pass:premium` | `MetaService.claimPass` | | |
| `daily` | `MetaService.claimDaily` | | |
| `event:<eventId>` | `MetaService.eventBuy` | | |
| `match:<modeId>` | `MatchService.rewardPlayer` | | |
| `afk` | `AfkService` payouts | | |
| `shop` | `ShopService.purchase` | | |
| `quest:<questId>` | `QuestService.deliver` | | |
| `debug` | `DebugService` (Studio only) | | |
| `unknown` | any mutation that moved a currency without a `meta` (warned in Studio) | | |

Rules:

1. **Idempotency.** A mutation whose `key` is already in the ledger writes no second entry. In practice the
   logic refuses first (`grantReceipt` answers `"already"` without touching balances; `CodesLogic.redeem`
   returns `already_redeemed`), so the ledger check is a second line of defence. Specs: `tests/ledger.spec.luau`.
2. **Replay.** A summon or reroll can be reproduced from its entry: `Random.new(entry.seed)` fed to
   `SummonLogic.summon` / `UnitLogic.rerollTrait` with the same profile state yields the same units.
3. **Ring buffer.** `Ledger.sanitize` keeps the newest `Economy.LEDGER_SIZE` well-formed entries on load;
   `commit` trims after every append. 200 entries × ~7 fields stays far under the 4 MB DataStore value limit.
4. **Analytics.** Each entry also emits one `AnalyticsService:LogEconomyEvent` per currency moved
   (`Analytics.ledger`): currency `Lira` / `Qirsh` / `TraitStones`, Source or Sink by sign, balance after
   the mutation, transaction type from the source prefix (`receipt:` → IAP, `summon` / `reroll` / `shop` /
   `event:` → Shop, `daily` → TimedReward, otherwise Gameplay), `src` as the SKU. The hand-written
   `Analytics.source` / `sink` calls (which labelled lira summons as Qirsh) were removed.
5. `DataService.LedgerEntry` fires `(player, entry)` after the mutation; `DataService.ledger(player)` returns
   the live list read-only (used by `HaretDebug:Invoke("ledger")`).
