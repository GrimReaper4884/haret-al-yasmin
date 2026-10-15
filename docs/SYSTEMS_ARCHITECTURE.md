# Systems Architecture

*Status: living document · Last updated 2026-10-15*

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
5. **Mobile first.** UI in Scale units, ProximityPrompts for interaction, low part counts.

## 2. Source layout (Rojo)

```
default.project.json
src/
  shared/      → ReplicatedStorage.Shared
    Config/    Items, Quests, Npcs, Dialogue, Shops, Economy, Strings (pure data, export their own types)
                Palette, CosmeticVisuals (use Roblox datatypes; not loaded by Lune)
    Logic/     ProfileSchema, Wallet, Inventory, QuestLogic, ShopLogic, DialogueLogic, RateLimiter, Validate
    Util/      Signal, Locale
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
      DebugService          Studio-only BindableFunction (ServerStorage.HaretDebug) for command-bar tests
  client/      → StarterPlayer.StarterPlayerScripts.Client
    Main.client.luau        bootstrap
    Controllers/            State, Locale, Hud, Dialogue, Shop, NpcLabel, Toast
    UI/                     Root (ScreenGui + UIScale), Theme, Icons, Create (instance builder)
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
