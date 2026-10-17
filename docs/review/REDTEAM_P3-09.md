# Red-team pass (BUILD_PLAN P3-09)

Date: 2026-10-17 · branch `phase/0` · Studio place not open (Phase 2 is owner-gated), so this pass is a
**code read of every remote handler plus pure specs** (`tests/redteam.spec.luau`, 40 cases, in
`lune run tests/run`). The Studio-side fuzzer (`RemoteFuzz.luau`, 1,000 random calls per remote from a
Client context, profile checksum) and the two-session lock test need the place open and **Test → Clients
and Servers** (owner); they are listed under *Open* at the end.

Every handler was asked the same questions: what if it fires 1,000×/s; NaN / ±inf / 1e308 / 2^53 /
negative / fractional numbers; non-string ids; 65+ character or NUL / Arabic strings; ids not in Config;
actions out of phase (placing before a match, claiming a tier twice, redeeming a code mid-match);
spending more than owned; acting on another player's tower or party; replaying a receipt or code.

Verdicts: **pass** = refused with no state change (spec or code read says which); **fixed** = a real hole
closed in this pass; **open** = needs the owner or Studio; **design** = behaves as designed but worth a
conscious decision.

## Transport (every remote)

| Layer | Attacks | Verdict | Evidence |
|---|---|---|---|
| `RemoteGuard.event/func` (`src/server/Services/RemoteGuard.luau`) | 1,000 calls/s; handler errors; return values | pass | Token bucket per player per remote: DEFAULT 8 burst / 4 per s, STRICT 3 / 1. Over the limit → `rate_limited` (func) or dropped (event) plus one `notify.slow_down` toast to the caller only. Handlers run in `pcall`; an error is warned and answered `{ ok = false, err = "error" }`, never the message. Buckets are forgotten on leave (a rejoin gets a fresh burst, bounded by Roblox's join rate). Spec: *Red team: RateLimiter* (burst exact, 1 s and 60 s floods, rewound clock). |
| `RateLimiter.allow` with a non-finite clock | NaN / ±inf `now` | **fixed** `f15a69d` | A NaN `now` refilled the bucket on every call (`math.max(0, NaN)`), i.e. fail-open. Only `os.clock()` reaches it so it was not exploitable, but the guard now denies any non-finite clock without creating a bucket. |
| Throttle toast | 1,000 throttled calls/s | design | Each throttled call fires one small event back to the attacker only; server cost is one `FireClient` of a 2-field table. Not worth a second bucket. |
| `Net.serverSetup` | pre-existing `Remotes` folder; `DebugCommand` in production | pass | The server destroys any existing `Remotes` folder and recreates every remote. `DebugCommand` exists everywhere but `DebugService.start` returns before connecting it outside Studio, so production calls are dropped. |

## MatchService (`PlaceTower`, `UpgradeTower`, `SellTower`, `SetTargeting`, `UseAbility`, `VoteSkip`, `SetSpeed`, `LeaveMatch`)

| Handler | Attacks | Verdict | Evidence |
|---|---|---|---|
| `PlaceTower(unitId, x, z)` DEFAULT | NaN / ±inf / 1e308 / strings / tables for x, z; 65-char and foreign `unitId`; unit owned but not in loadout; before a match; after won/lost; cash = cost − 1; 1,000 placements; path, bounds, spacing | pass | `Validate.isIdentifier` + `isFiniteNumber` first; unit must be in `Units`, owned **and** in `profile.loadout`; `towerContext` refuses when not in a match or `match.ended`. A finite but huge x (1e308) overflows `Vector3` (float32) to ±inf/NaN in `ArenaService.toLocal`; `TdTowers.canPlace` re-checks finiteness after the transform, then bounds, path clearance, spacing, `TOWER_CAP`, `maxPlaced`, cash. Spec: *hostile coordinates*, *out of phase*, *1,000 placements stop at the caps*, *cost − 1*. |
| `UpgradeTower(towerId)` DEFAULT | another player's tower; NaN / string / table / 0 / negative / 2^53 ids; past max level; cash short | pass | `TdTowers.find` needs a number id and `t.owner == key`; `max_level`, `cannot_afford` leave cash untouched. Spec: *another player's tower*, *hostile tower ids*, *past the top level*. |
| `SellTower(towerId)` DEFAULT | sell twice; sell another's; sell after the match | pass | Second sell → `not_yours` (tower gone), refund paid once. After `won`/`lost` the service's `match.ended` check refuses (the pure `sell` itself has no phase check; the service is the guard). Spec: *selling twice refunds once*. |
| `SetTargeting(towerId, mode)` DEFAULT | mode outside `{first,last,strong,close}`, wrong case, table; another's tower | pass | Enum membership in `TdTowers.setTargeting`; the event to clients is only queued on success. Spec: *targeting accepts only the four modes*. |
| `UseAbility(towerId)` DEFAULT | non-integer id; another's tower; before cooldown; after the match | pass | `Validate.isPositiveInteger` then owner, ability, cooldown, phase. Spec: *an ultimate cannot be queued after the match*. |
| `VoteSkip` STRICT | vote twice; vote during a wave; vote after the match | pass | `castSkipVote`: phase must be `prep`, one vote per player, votes reset on `waveStart`. Solo players get `SKIP_BONUS` every skipped countdown: designed (`TD.SKIP_BONUS`). |
| `SetSpeed(speed)` STRICT | non-host; 0 / NaN / 1.5 / 2^53; above the pass speed | pass | Host only, `isPositiveInteger`, `≤ FREE_SPEED` or `PASS_SPEED` with the `fast` perk; otherwise a toast and no change. |
| `LeaveMatch` STRICT | leave at wave 0 and re-queue (farming); leave twice; last player leaves from the result screen | pass + **fixed** `6d6b054` | A quit pays the loss share × waves/total: zero at wave 0 in every mode (spec *leaving at wave 0 pays nothing*), never a first-clear bonus or stone. Second leave is a no-op (`byPlayer` cleared). **Fixed:** when the last player pressed Back on the result screen, `removePlayer` destroyed the match and `finish()`'s delayed cleanup destroyed it again 12 s later, freeing an arena slot that a new party could already hold (two matches in one arena). `destroyMatch` is now idempotent. |

## MetaService (`Summon`, `SetLoadout`, `RerollTrait`, `ClaimPass`, `RedeemCode`, `ClaimDaily`, `EventBuy`)

| Handler | Attacks | Verdict | Evidence |
|---|---|---|---|
| `Summon(n)` STRICT | n ∈ {0, 2, 11, −1, NaN, inf, "10", table}; lira < cost; 1,000 pulls on a budget; negative n (negative cost) | pass | `n ~= 1 and n ~= 10` in the handler and again in `SummonLogic.summon` before the lira check; cost comes from `TD`, VIP discount from the server perk; pity and odds covered by `meta.spec` (1,000,000-pull sims). Spec: *n must be exactly 1 or 10*, *1,000 pulls on a budget*. Restricted regions can still spend lira they already hold: correct (the policy restricts paying Robux for random items, `MonetizationLogic.fundsRandomItems`). |
| `SetLoadout(list)` DEFAULT | > slots; duplicates; unowned / unknown / non-string / 65-char entries; nil holes; hash-only table; 7 slots without the pass; **changing the loadout during a match** | pass + **fixed** `70f07e0` | `UnitLogic.setLoadout` validates whole-list and writes nothing on refusal; slot count comes from the server's perk flag. A hash-only table reads as an empty loadout (harmless). **Fixed:** the handler accepted a new loadout mid-match while `PlaceTower` reads the loadout live, so a client could rotate through every owned unit and make the Extra Slot pass worthless. Now refused with `in_match` while the match runs (the result screen is open again). Spec: *loadouts over the slot count…*, *a slot count from a perk the player lacks*. |
| `RerollTrait(unitId)` STRICT | unowned unit; 0 stones; 1,000 taps with 3 stones; foreign id | pass | `isIdentifier` + `Units[unitId]`; `UnitLogic.rerollTrait` checks ownership and `traitStones ≥ cost` before writing. Seed logged to the ledger. Spec: *1,000 reroll taps with three stones*. |
| `ClaimPass(tier, track)` DEFAULT | tier 0 / −1 / 1.5 / NaN / inf / 2^53 / #tiers+1 / "1"; track "free2" / "Premium" / table; tier above level; premium without premium; 1,000 claims of one tier; level skip past the season | pass | `isPositiveInteger` + track enum in the handler; `PassLogic.canClaim` bounds the tier to `1..#tiers`, level-gates, premium-gates and keys claims by `tostring(tier)`. Spec: *hostile tiers and tracks*, *claiming above the level… twice*, *a level skip never passes the last tier*. |
| `RedeemCode(code)` STRICT | 1,000 replays in every case / spacing; 33–10,000-char, NUL, Arabic, pattern chars; expired; `onlyUserIds` as a stranger; match-cash code via the profile path; match-cash outside a match; code mid-match | pass | `isShortString(40)` then `normalize` (≤ 32 `[%w_]`, upper-cased, whitespace stripped) so every variant maps to one `profile.codes` key; expired and foreign-user codes answer like a typo. Normal codes redeemed mid-match only touch the profile (no match state). `MONEY50K` is owner-locked and repeatable by design. Spec: *RedeemCode* ×4, including *every published code has an expiry or an owner list*. |
| `ClaimDaily` STRICT | 1,000 claims in a day; last second of the day; next day | pass | Keyed by UTC day from `os.time()`. Spec: *ClaimDaily*. |
| `EventBuy(eventId, key)` STRICT | hostile ids / keys; before and after the window; 1,000 buys of each limited item; cost − 1 currency; NaN / negative / inf match currency | pass | `isIdentifier` + `isShortString(40)`; `EventLogic.buy` checks event, window, shop key, stock and currency; `addCurrency` rejects NaN / ≤ 0 and caps at `maxCurrency`. Spec: *EventBuy* ×4. |

## ShopService, DialogueService, QuestService, PlayerStateService, AfkService, Matchmaking

| Handler | Attacks | Verdict | Evidence |
|---|---|---|---|
| `ShopPurchase(itemId)` STRICT | hostile ids; no shop session; out of range; shop that does not sell it; Robux-only cosmetic with qirsh; 1,000 buys of a cosmetic | pass | `isIdentifier`; session + `NpcService.inRange`; `ShopLogic.purchase` takes the price from `Items` (never the client), refuses `price == nil`, owned cosmetics, full stacks and short funds. Spec: *ShopPurchase and SetWorn* ×3. |
| `SetWorn(itemId, wear)` STRICT | unowned; unwear something not worn; non-boolean | pass | Spec: same. No currency moves, so no ledger meta is needed. |
| `DialogueChoose(index)` DEFAULT | 0 / −1 / 1.5 / NaN / inf / 1e9 / string / table index; stale node; out of range | pass | Session is server-set (`ProximityPrompt`); `DialogueLogic.choice` needs an integer that indexes the current node's choices; range checked before any action; quest ids come from the choice's config. Spec: *dialogue: hostile choice indices*. |
| `QuestService.accept/deliver` | only reachable through `DialogueChoose` | pass | Giver/target NPC checked against `Quests`; `QuestLogic` state machine (accept twice, deliver without accepting) covered by `logic.spec`. |
| `SetLanguage(lang)` STRICT; `SetSetting(key, value)` DEFAULT | hostile keys (`__index`, `language`, 65-char) and values (NaN, strings for bools, enum outside) | pass | `lang` enumerated inline; `Settings.accept` is a closed table of enum/bool defs. Spec: *settings: hostile keys and values*. |
| `AfkEnter(reason)` / `AfkLeave` / `AfkHop` STRICT | reason "hop" / "debug" / table; enter while in a match; hop spam | pass | Reason enum excludes `hop` and `debug` (server-only); `enter` refuses without a profile, in a match, or without a live character and leaves any party; `hop` has a 10-minute server cooldown. Sitting time is server-measured (`insideRoom` on the server, 5 s per tick cap); payouts go through `AfkLogic.accrue` (daily lira cap, `afk.spec`). |
| `PartyCreate` / `PartyJoin` / `PartyReplay` / `PartyStart` / `QueueSetDifficulty` / `QueueLeave` STRICT | mode / difficulty not in Config; party id NaN / huge; join a launched party; fifth member; double join; non-host start or difficulty change; locked mode / difficulty; while in a match or the AFK room | pass | Identifiers checked against `Modes` and `TD.DIFFICULTIES`; `isPositiveInteger` party ids index a live table; `PartyLogic` caps at `MAX_PLAYERS`, rejects duplicates and non-host starts; `MatchRewards.canPlay` gates unlocks. Spec: *parties*, *unlock gates*. |
| Party difficulty piggy-back | a member who has only unlocked Normal joins a Nightmare party | design | `join` checks the mode only ("everyone plays the host's difficulty"), so the member earns Nightmare rewards and, on a win, `MatchRewards.record` marks Nightmare cleared for them. Carry is a co-op feature; the owner should decide whether unlocks should require having cleared the previous difficulty yourself. |

## MonetizationService (`RequestProduct`, `RequestPass`, `ProcessReceipt`)

| Handler | Attacks | Verdict | Evidence |
|---|---|---|---|
| `RequestProduct(key)` STRICT | unknown key; product with id 0; restricted region asking for lira / stones / premium / skips / a lira bundle; owned item; 1,000 prompts/s | pass + **fixed** `f15a69d` | Server opens the prompt only after `MonetizationLogic.canPrompt`; the prompt rate is the STRICT bucket. **Fixed:** `canPrompt` accepted a NaN or infinite `productId` (`NaN <= 0` is false). The id comes from `Config/Products`, never the client, so it was latent; it now requires a positive finite integer. Spec: *prompts: unknown keys, unpublished ids and restricted regions*. |
| `RequestPass(key)` STRICT | unknown key; pass id 0 | pass | Prompt only for a published pass; Roblox refuses prompting an owned pass. Perks are granted by `PromptGamePassPurchaseFinished` (server callback) and re-checked on join. |
| `ProcessReceipt` (Roblox callback, not a remote) | 1,000 replays of one `PurchaseId`; empty / numeric / table receipt id; unknown product; NaN / inf / negative / fractional amounts; player left or profile not loaded | pass | `grantReceipt` records `profile.receipts[PurchaseId]` in the same mutation as the grant; replays answer `already` with no balance change and no second ledger line (ledger key `receipt:<PurchaseId>`). Any failure, including a failed `saveNow`, answers `NotProcessedYet` so Roblox retries. Spec: *1,000 replays of one receipt*, *hostile receipt ids…*; `ledger.spec` *a replayed Robux receipt produces exactly one entry*. |

## DataService.mutate and Logic/Ledger

| Path | Attacks | Verdict | Evidence |
|---|---|---|---|
| `DataService.mutate` | mutate before load / after release; a Logic function that errors mid-way; 1,000 mutations | pass (noted) | Refuses with `not_loaded` unless the entry is loaded and not released; every write runs through `Ledger.mutate`. A mutation that **errors after writing** leaves the partial write in the live profile (the service `pcall` only stops the error reaching the client) and the autosave persists it. No shipped Logic module writes before validating, and `Grants.apply` ignores hostile amounts instead of erroring; keep it that way. Spec: *a mutation that errors mid-way leaves no ledger line*. |
| `Ledger.commit` | hostile `meta` (NaN src, table src, NaN seed, numeric key); replayed key with a real balance change; 1,000 mutations; hostile stored entries | pass (noted) | `src` falls back to `unknown`, seeds must be finite, the ring never exceeds `LEDGER_SIZE`, `sanitize` drops malformed entries and trims text to 64. **Note:** the ledger's key dedupe is an audit convenience, not the guard: a replayed key with a changed balance is *not* recorded, so a double grant would be invisible here. The guards are `profile.receipts` and `profile.codes`, both specced. Spec: *Grants and the audit ledger* ×5. |
| `Grants.apply` | NaN / −inf / negative / fractional / string / table amounts; 1e308 and 2^53; unknown item or unit | pass | Positive finite integers only; caps at `MAX_LIRA`, `MAX_QIRSH`, `MAX_TRAIT_STONES`. Spec: *hostile reward amounts*. |
| Session lock (`DataService.tryLoad` / `save`) | second server loads the same profile; stale lock | pass by code read, **open** in Studio | A lock held by another `JobId` younger than `LOCK_STALE_SECONDS` (600 s) refuses the load; after `LOAD_LOCK_RETRIES × LOAD_LOCK_WAIT` (30 s) the player is kicked with `kick.session_locked` and the entry is marked released, so nothing is ever saved over data that failed to load. `save` re-reads the lock inside `store:update` and refuses (`lost`, kick) when another job owns it. The live two-client test is the owner's (Test → Clients and Servers). |
| `DebugCommand` / `HaretDebug` | any player in Studio grants lira, places, teleports | pass | Studio only: `DebugService.start` returns before creating the hook or connecting the remote when `RunService:IsStudio()` is false. |

## Fixes in this pass

| Commit | Change | Spec |
|---|---|---|
| `f15a69d` | `MonetizationLogic.canPrompt` requires a positive finite integer product id; `RateLimiter.allow` denies a non-finite clock | `monetization.spec` canPrompt case; `redteam.spec` *the clock is the server's* |
| `70f07e0` | `MetaService.setLoadout` answers `in_match` while the player's match is running | server glue (no pure seam); `luau-lsp` strict |
| `6d6b054` | `MatchService.destroyMatch` is idempotent, so an early Back from the result screen cannot double-release an arena slot | server glue; `luau-lsp` strict |
| `da09112` | `tests/redteam.spec.luau` (40 cases) registered in `tests/run.luau` | `lune run tests/run`: 227 passed |

## Open (needs the owner or the Studio place)

1. **Studio fuzz run** (`RemoteFuzz.luau` from BUILD_PLAN P3-09): 1,000 random calls per remote from a Client context with a profile checksum before and after, plus the rate-limit toasts. Needs the place open; the pure specs above cover every guard the fuzzer would hit, so the run is confirmation.
2. **Two-session lock test**: Test → Clients and Servers, two clients on one account is not possible; the owner can join the TEST place from a second device while a Studio server holds the lock and should be kicked with the "session locked" message within 30 s.
3. **Design decision: party difficulty piggy-back** (table above). No code change made.
4. **Design note: `SetLoadout` during the result screen** is still allowed (the match has ended); placing is impossible then, so there is no exposure.
