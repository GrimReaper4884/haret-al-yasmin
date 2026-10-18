# Systems Architecture

*Status: living document · Last updated 2026-10-16*

## 1. Principles

1. **The server is authoritative.** The client sends *intent* only ("I chose option 2", "I want to buy
   item X"). Prices, rewards, ownership, quest state and positions are always read and validated on the
   server.
2. **Content is configuration.** Items, quests, NPCs, dialogue, shops and strings are plain Luau tables in
   `src/shared/Config`. Adding a quest should not require new code.
3. **Pure logic, thin services.** Rules such as affording, granting, quest transitions and dialogue
   resolution live in dependency-free modules (`src/shared/Logic`). They take a profile and config tables
   and return a result. Roblox services wrap them with I/O (DataStores, remotes and instances). This keeps
   the rules unit-testable outside Studio with Lune.
4. **Small modules.** No file over ~400 lines, and one responsibility per module.
5. **Mobile first.** UI in offset px for a landscape phone's safe area under one UIScale (`UI/Device` +
   `Logic/HudLayout`, docs/MOBILE_HUD_PLAN.md), ProximityPrompts for interaction, low part counts.

## 2. Source layout (Rojo)

```
default.project.json
src/
  shared/      → ReplicatedStorage.Shared
    Config/    Items, Quests, Npcs, Dialogue, Shops, Economy, Strings (pure data, export their own types)
               TD, Units, Enemies, Waves, Arenas, Modes, Banners, Traits, SeasonPass, Codes, Daily, Audio
                Palette, CosmeticVisuals (use Roblox datatypes; not loaded by Lune)
    Logic/     ProfileSchema, Wallet, Inventory, QuestLogic, ShopLogic, DialogueLogic, RateLimiter, Validate
               Path, WaveLogic, TdSim, TdTowers, UnitLogic, SummonLogic, PassLogic, CodesLogic, DailyLogic,
               MatchRewards, Grants, MonetizationLogic
    Util/      Signal, Locale, CosmeticBuilder, RigBuilder (primitive figures for units/enemies/previews)
    Net.luau   remote names and access
  server/      → ServerScriptService.Server
    Main.server.luau        bootstrap: init → start every service in order
    Services/
      DataStoreAdapter      real DataStore or in-memory mock (Studio without API access)
      DataService           load, session lock, autosave, release, mutate()
      PlayerStateService    pushes state snapshots to the owning client
      RemoteGuard           rate limiting and argument validation for every client→server remote
      AnalyticsService      AnalyticsService wrapper (funnels, economy)
      WorldService          builds the slice map from primitives
      NpcService            spawns NPC rigs and ProximityPrompts
      DialogueService       server-side dialogue sessions
      QuestService          quest accept/deliver built on QuestLogic
      ShopService           shop sessions, purchase, equip
      AvatarService         attaches equipped cosmetics to characters
      MonetizationService     Robux prompts/receipts, pass perks, PolicyService (paid random items)
      ArenaService            arena slots at x >= 3000, builds arenas and tower models
      MatchService            match lifecycle, Heartbeat loop over TdSim, tower remotes, rewards
      MatchmakingService      portal pads, parties, countdown, difficulty vote
      MetaService             summons, loadout, traits, season pass, codes, daily
      CrowdService            ambient neighbours with pathfinding
      DebugService            Studio-only: HaretDebug hook, log mirror, test seeds
    World/                    Kit, Props, Props2 (gate, signs, coffee house, barber), Facade, Arena, Zones/*
  client/      → StarterPlayer.StarterPlayerScripts.Client
    Main.client.luau        bootstrap
    Controllers/            State, Locale, Hud, Dialogue, Shop, NpcLabel, Toast, Wardrobe, Clue, Audio,
                            LobbyMenu, Summon, Units, Pass, Codes, Daily, Queue, Match, Placement,
                            EnemyRender, MatchFx, MatchCamera, DebugOverlay*, DebugKeys* (*Studio only)
    UI/                     Root (ScreenGui + UIScale), Theme, Icons, Create, Modal, UnitCard, ItemPreview,
                            RewardText
tests/                      Lune unit tests for src/shared/Logic (not synced into the place)
```

## 3. Service boundaries

| Service | Owns | May call | Never does |
|---------|------|----------|------------|
| DataService | Profiles in memory, DataStore I/O, locks | DataStoreAdapter | Game rules |
| QuestService | Quest transitions | DataService.mutate, QuestLogic, Analytics | Touch UI |
| ShopService | Open-shop sessions, purchases, equip | DataService.mutate, ShopLogic, AvatarService | Trust client price |
| DialogueService | Per-player dialogue session (npc, node) | DialogueLogic, QuestService, ShopService | Accept a node id from the client |
| PlayerStateService | Snapshot serialization | DataService | Mutate data |
| AvatarService | Cosmetic instances on characters | — | Check ownership itself (callers pass a validated profile) |

Every mutation goes through `DataService.mutate(player, fn)`. `fn` runs synchronously against the live
profile and must not yield. Because Luau runs one thread at a time, each mutation is atomic with respect
to all other server code: there is no window in which two purchases can both see the old balance. If `fn`
returns `false`, mutate assumes nothing was changed, so logic modules validate first and write second.

## 4. Networking

Remotes are created by the server in `ReplicatedStorage.Remotes`. Names are defined once, in
`src/shared/Net.luau`.

| Remote | Kind | Direction | Payload | Server validation |
|--------|------|-----------|---------|-------------------|
| `StateSync` | RemoteEvent | S→C | snapshot | — |
| `DialogueShow` | RemoteEvent | S→C | `{npcId, nodeId, textKey, choices[]}` | — |
| `DialogueHide` | RemoteEvent | S→C | — | — |
| `DialogueChoose` | RemoteEvent | C→S | `choiceIndex: number` | integer, in range for the *server's* current node, player within range of the NPC, rate-limited |
| `DialogueClose` | RemoteEvent | C→S | — | rate-limited |
| `ShopShow` | RemoteEvent | S→C | `shopId` | — |
| `ShopClose` | RemoteEvent | C→S | — | rate-limited |
| `ShopPurchase` | RemoteFunction | C→S | `itemId: string` | string ≤ 64 chars, shop session open, in range, item sold by that shop, price from config, rate-limited |
| `SetWorn` | RemoteFunction | C→S | `itemId: string, wear: boolean` | identifier, boolean, owned cosmetic, rate-limited |
| `SetLanguage` | RemoteEvent | C→S | `"en"`/`"ar"` | whitelist, rate-limited |
| `Notify` | RemoteEvent | S→C | `{key, args}` | — |
| `QueueState` / `QueueLeave` / `QueueSetDifficulty` | RemoteEvent | S→C / C→S | party snapshot; —; difficulty | host only for difficulty; unlock checked |
| `MatchStart` / `MatchState` / `MatchEvents` / `MatchEnd` | RemoteEvent | S→C | match info; HUD snapshot; batched sim events; result + rewards | — |
| `EnemyPositions` | UnreliableRemoteEvent | S→C | packed `{id, dist, hp%}` triples at 10 Hz | — |
| `PlaceTower` / `UpgradeTower` / `SellTower` | RemoteFunction | C→S | unitId, x, z / towerId / towerId | in match, in loadout and owned, bounds, road clearance, spacing, caps, cash (TdTowers) |
| `SetTargeting` / `VoteSkip` / `SetSpeed` / `LeaveMatch` | RemoteEvent | C→S | towerId, mode / — / 1–3 / — | own tower; prep phase; host and pass for 3x |
| `Summon` | RemoteFunction | C→S | 1 or 10 | lira, odds and pity on the server (SummonLogic) |
| `SetLoadout` / `RerollTrait` | RemoteFunction | C→S | `{unitIds}` / unitId | owned, unique, slot count (pass); trait stones |
| `ClaimPass` / `RedeemCode` / `ClaimDaily` | RemoteFunction | C→S | tier, track / code / — | level reached, premium flag; expiry, once; UTC day |
| `DebugCommand` | RemoteEvent | C→S | cmd, arg | Studio only (no listener in production) |
| `ClientProfile` | RemoteEvent | C→S | "desktop" \| "touch-phone" \| "touch-tablet" | STRICT; first valid report per session kept on the player state (not the profile) and logged as `ui_device` (MOBILE_HUD_PLAN MH-17) |
| `PlaceCancelled` | RemoteEvent | C→S | — | 2 burst / 2 per s; counted per match, logged as `place_outcome_cancelled` with `placed` / `invalid` when the match ends for the player |

Dialogue is started by the server-side `ProximityPrompt.Triggered` event, so the client never names the
NPC it is talking to.

## 5. Security rules (checklist for every feature)

- [ ] Every client→server handler is wrapped by `RemoteGuard.wrap` (type checks plus a token-bucket rate limit).
- [ ] Never read a price, reward, item count or ownership flag from a client payload.
- [ ] Distance checks: dialogue choices and purchases need the player's HumanoidRootPart within
      `Economy.INTERACT_RANGE` (14 studs) of the NPC.
- [ ] Reward and state change happen in the same `mutate` call, so a duplicate request finds the quest
      already completed and gets nothing.
- [ ] Profiles that failed to load are **never saved**; the player is kicked with a friendly message
      instead of playing on blank data.
- [ ] A save checks that the session lock is still ours before writing.
- [ ] Integers only for currency; reject NaN and infinity; clamp to `Economy.MAX_QIRSH`.
- [ ] Client UI state is cosmetic only and safe to tamper with.

## 6. Persistence

See `DATA_SCHEMA.md`. Summary: one key per user (`u_<UserId>`) in the DataStore `PlayerData_v1`, with
session locking stored next to the data and refreshed on every autosave (every 120 s, always, so the lock stays fresh). The final
save releases the lock on leave and on `BindToClose`. Writes retry with exponential backoff. The schema is
versioned and migrated on load.

When the place has no DataStore access (unpublished Studio place, or API access disabled), the adapter falls
back to an in-memory mock and logs `PERSISTENCE DISABLED (mock store)`. Nothing persists in that mode.

## 7. Client architecture

- `StateController` keeps the last snapshot and fires `Changed`.
- `LocaleController` resolves strings for the current language. Its initial value comes from the snapshot
  (saved preference) or `LocalizationService.RobloxLocaleId`.
- UI controllers subscribe to state and locale changes and re-render. UI is built in code from `Theme`
  tokens. This is a deliberate choice for the slice (diffable in Git). Larger screens may move to Studio-
  authored ScreenGuis later.

## 8. Testing strategy

| Layer | Tool | What |
|-------|------|------|
| Static | `selene src` | Lints, global usage |
| Static | `luau-lsp analyze` (strict) with a Rojo sourcemap and Roblox definitions | Type errors |
| Unit | `lune run tests/run` | All `Logic/*` and config integrity (every quest, item, shop and dialogue reference resolves) |
| Integration | Studio Play (server + client), via Studio MCP or computer use; server inspection through `ServerStorage.HaretDebug` (the command bar is a separate VM) | Prompt → dialogue → accept → deliver → reward → buy → equip, plus remote abuse attempts |
| Persistence | Studio with API access on a **test** experience, or a published test place | Leave/rejoin, double join, forced save failure |
| Device | Studio device emulator (phone, tablet) and a real phone before release | Layout, safe areas, touch targets, frame rate |

StyLua formats code. It is pinned in `rokit.toml`, but Windows Application Control currently blocks the
binary on the dev machine (see known issues in the milestone report).

## 8b. Shared world (many players, one lane)

- Every server hosts one shared lane; all players see each other, each other's cosmetics and the same NPCs.
  Recommended **max players: 30** per server (set at publish; it's a live setting and needs approval). Roblox
  opens new servers automatically when one fills up.
- **Per-player state** (quests, clues, dialogue sessions, shop sessions, wallet) is isolated server-side.
  Two players can run the same episode side by side without interfering.
- **Streaming** is enabled (`Workspace.StreamingEnabled`, min radius 96, target 320) so the map can grow. NPCs
  and clue spots are `ModelStreamingMode = Persistent` because client UI depends on them.
- **No player-to-player collisions** (`PlayerCollisionService`, collision group "Players") so crowds can't block
  doors, counters or the gate.
- Planned shared systems: community goals and votes (Episode 5, MemoryStore), live events, paid private servers.

## 8c. Match simulation

`Logic/TdSim` is a pure fixed-step simulation (20 Hz): enemies advance along a `Logic/Path` polyline,
defenders pick targets (first/last/strongest/closest) within range, apply damage/splash/slow/stun and
abilities, the gate loses HP when an enemy reaches the end, and waves end when the queue is empty and
nothing is alive. `MatchService` steps every live match on Heartbeat (at most 6 ticks per frame, dropping
time if the server falls behind), batches the step's events into one `MatchEvents` payload per frame, and
streams positions at 10 Hz over an UnreliableRemoteEvent. Enemies exist on the client only as rendered rigs
(`EnemyRenderController`) that interpolate toward the last reported distance; defenders are server models
(`ArenaService.buildTower`) so every client sees them. Arenas live at x >= 3000 (600 studs apart, up to 6)
and are destroyed when a match ends.

## 9. Pure-module convention

`src/shared/Logic/*` and the pure `Config` modules must not use Roblox globals (`game`, `Instance`,
`Vector3`, `task`, …). Logic modules that depend on siblings resolve them with a local `sibling()`
helper: in Roblox it requires `script.Parent[name]`; in Lune the test runner installs
`_G.LogicRequire`. That is the only `_G` use in the codebase, and it is allow-listed for Selene inline.

## 10. Commands

```bash
rokit install                        # toolchain pinned in rokit.toml
lune run tests/run                   # unit tests
selene src                           # lint
rojo sourcemap -o sourcemap.json && luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json --definitions=types/globalTypes.d.luau src
rojo serve                           # live sync into Studio (Rojo plugin)
rojo build -o build/HaretAlYasmin.rbxl
```
