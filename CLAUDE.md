# CLAUDE.md: Haret Al-Yasmin

Co-op tower defense for Roblox set in **Haret Al-Yasmin (حارة الياسمين, "Jasmine Lane")**, an original walled
lane of a late-Ottoman Levantine city. The lane is the lobby (errands, wardrobe, coffee house, the Hakawati's
AFK room); parties of 1–4 step on a portal and defend the lane gate against night thieves, gendarmes,
bandits and rival-lane thugs. A server-authoritative pure simulation (`Logic/TdSim`) sits under a collection
meta (lira summons with published odds and pity, traits and trait stones, stars, the "Lane Diary" season
pass, codes, dailies). The experience is **already public** on the TEST place and has Discord testers.

| File | Purpose |
|---|---|
| `docs/BUILD_PLAN.md` | Your work queue: phases, tasks, acceptance criteria, kickoff prompts |
| `docs/POLISH_PLAN.md` | Phase V look-and-feel queue: Meshy enemies, effects, icon set, covers, loading screen, world dressing |
| `docs/GAME_DESIGN.md`, `docs/TOWER_DEFENSE.md`, `docs/MONETIZATION.md`, `docs/AFK_CHAMBER.md` | Design and every number. Config wins at runtime; change doc and `src/shared/Config` in one commit |
| `docs/SYSTEMS_ARCHITECTURE.md`, `docs/DATA_SCHEMA.md` | Service boundaries, remotes, persistence |
| `docs/DECISIONS.md` | Dated log of every TUNE change and design deviation |
| `docs/TOOLS.md` | The MCP tool surface as observed on this machine. It wins over this file |
| `docs/CHARACTER_PIPELINE.md`, `tools/meshy`, `tools/anim` | Meshy → GLB → Studio importer → `.rbxm`; baked bone clips |
| `docs/RELEASE_CHECKLIST.md`, `docs/COPYRIGHT_REGISTER.md` | Owner-only steps, live-settings log, IP register |
| `docs/TEST_REPORT_SLICE.md` | Evidence from every Studio and device run so far |
| `reports/…blueprint.md` | Genre research (anime TD economics, policy). Background only: its design kit was **not** adopted (DECISIONS D-001) |

You run on the owner's **Windows 11** machine. Roblox Studio is open on **"Haret Al-Yasmin (TEST)"**
(placeId 120389740593436) with "Enable Studio as MCP server" on, Blender 5.2 runs the Blender Lab MCP
extension, and `rojo serve` is connected to Studio.

## Session start (every session)
1. `git status`. Other Claude sessions often edit this same checkout: **never** `git stash`, `checkout`,
   `reset` or reformat whole files here (DECISIONS D-005). Check `ListAgents` and message a session whose
   files overlap yours. Read BUILD_PLAN statuses and DECISIONS.
2. Call `list_roblox_studios` and pass its `studio_id` to **every** Studio call. Confirm the name contains
   "Haret Al-Yasmin (TEST)". `get_studio_state` must say `Edit`.
3. `rojo serve` must be running (port 34872; start it in the background if not) and the Rojo plugin shows
   Connected. You can't click Connect yourself: ask the owner. Verify sync with `script_grep`.
4. Blender only when needed: `get_blendfile_summary_path_info` responds. Save the .blend before geometry changes.

## Source of truth
| What | Owner | How to change it |
|---|---|---|
| Luau: `src/server` → `ServerScriptService.Server`, `src/client` → `StarterPlayer.StarterPlayerScripts.Client`, `src/shared` → `ReplicatedStorage.Shared` | **Rojo + git** | Edit files on disk; Rojo syncs |
| Approved models: `assets/production/CharacterModels/*.rbxm` → `ReplicatedStorage.CharacterModels`, `PropModels` likewise | git (binary) | Export from Studio to `.rbxm`; register in COPYRIGHT_REGISTER |
| Lighting, Workspace streaming, SoundService, Players | `default.project.json` | code |
| The world (lane, arenas, props) | built at runtime by `server/World/*` and `WorldService.build()` | code; nothing map-related is Studio-owned |
| Product and pass IDs | `src/shared/Config/Products.luau` (all `0` until the owner creates them) | owner creates, agent pastes |
| Clip and model IDs | `src/shared/Config/CharacterLooks.luau` | code |

- **Never** `multi_edit` (or otherwise write) any script through MCP; Rojo overwrites it and git never sees it.
  Never create Script, LocalScript or ModuleScript instances through MCP. For one-off probes use
  `execute_luau`, which leaves no instance. `script_read` / `script_grep` are for confirming sync only.
- Nothing in this project is Studio-owned, so the place rarely needs saving; publishing is the owner's.

## MCP tools (names verified on this machine, see `docs/TOOLS.md`)
**Roblox_Studio** (every call takes `studio_id`; `datamodel_type` is `Edit`, `Server` or `Client`):
- `list_roblox_studios`, `get_studio_state`: session start and before every playtest.
- `search_game_tree`, `inspect_instance`: live instances (synced folders, imported models, built world).
- `script_read`, `script_grep`, `script_search`: read-only sync checks.
- `execute_luau` (Edit / Server / Client): probes, measurements, server-side test hooks
  (`game.ServerStorage.HaretDebug:Invoke(cmd, ...)`: `state`, `reload`, `grant`, `place`, `lira`, `cash`,
  `tp`, `failNext`), firing remotes from the Client context for validation tests. Studio freezes until the code
  yields: chunk heavy loops with `task.wait()`.
- `start_stop_play`, `get_console_output`, `screen_capture` (optional camera position/target): the playtest loop.
- `user_keyboard_input` (Client): drive the Studio-only harness keys (`DebugKeysController`: `1`–`6` screens,
  `7`/`8` summon ×1/×10, `9` teleport to the Episode 1 portal, `0` square, `M` create and start an Episode 1
  Normal party at once, `L` fill the loadout from owned units, `N`/`Y` AFK room enter-leave / fast-forward, `X`
  close; in a match `P` place at your feet, `B` place at the next road-side debug spot, `U` upgrade, `J` sell,
  `K` skip, `T` 2× speed, `C` +5000 cash, `G` gate to 1 HP, `H` leave). Verified through MCP on 2026-10-17 after
  one `user_mouse_input` click on the viewport. Grant units first with `HaretDebug:Invoke("grant", "id,id,…")`.
- `execute_luau` runs in a separate VM from the game (like the command bar): `require` gives you a fresh copy of a
  module, so talk to the live server through `ServerStorage.HaretDebug` and to the live client through instances.
  A camera you set from `execute_luau` is reset by Studio; use `screen_capture` with `camera_position` and
  `look_at_position` instead (works during Play).
- `character_navigation` (Client), `user_mouse_input` (Client): try, but don't depend on them.
- `search_asset`, `insert_asset` (numeric id), `upload_image` (HTTP URLs), `store_image` (local png → image URI).
- `generate_mesh`, `generate_texture`, `generate_material`, `generate_procedural_model`, `segment_mesh`,
  `wait_job_finished`: quick props and blockouts; log AI-generated results in COPYRIGHT_REGISTER.
- `subagent` (explore / screen_capture / unit_test), `skill` (rbx-debug, rbx-device-simulator-lua,
  rbx-docs-search, rbx-perf-profiling, rbx-scene-analysis, rbx-unit-test), `http_get` (Roblox docs only).
- There is no multi-client playtest tool: ask the owner for Test → Clients and Servers.

**blender** (official Blender Lab server; `mcp-for-blender` names do not exist here):
- `get_blendfile_summary_path_info` (is Blender up, is the file saved), `get_objects_summary`,
  `get_object_detail_summary`: state checks.
- `execute_blender_code` (live) / `execute_blender_code_for_cli` (`blender --background <file>`): assign a dict
  to `result`. Break big jobs into steps.
- `get_screenshot_of_area_as_image` (`VIEW_3D`), `render_thumbnail_to_path`, `render_viewport_to_path`: look
  before every export.
- `get_python_api_docs`, `search_api_docs`, `search_manual_docs`: bundled bpy docs; use instead of guessing.
- Character and prop meshes come from **Meshy** (`tools/meshy/meshy.py`, key in `MESHY_API_KEY`), not Blender.
  Blender is for headless previews (`tools/anim/preview.py`), inspection and the occasional fix-up.

## Verify loop (every task)
1. Write or modify code **and** its test in `tests/*.spec.luau` (pure modules only; Roblox globals are banned in
   `Logic/*` and pure `Config/*`). Numbers come from `src/shared/Config`, never inline literals.
2. `tools/check.ps1` (or `tools/check.sh`): selene clean, `lune run tests/run` green, `luau-lsp analyze` strict
   clean, `rojo build` OK. StyLua is advisory on this repo (D-005); don't reformat files you didn't change.
3. Confirm sync: `script_grep` for a string you just added. If stale, check `rojo serve` and the plugin.
4. Playtest: `start_stop_play` (start) → `get_console_output` shows `[HaretAlYasmin] server ready`, no errors or
   warnings from our code (the `PERSISTENCE DISABLED` line is expected only on the mock store) → drive with the
   harness keys and `execute_luau` (Server/Client) → `screen_capture` and actually look → `start_stop_play` (stop).
5. Balance questions: `lune run tests/balance` (auto-battler over every mode × difficulty × loadout).
6. Fix and repeat until **every** Accept line of the task holds. Don't mark a task done on partial evidence.
7. Commit (format below), tick the task in BUILD_PLAN, log TUNE changes and deviations in DECISIONS.

## Hard rules
- **Server-authoritative.** Clients send intents only (place/upgrade/sell tower, targeting, vote, speed, summon,
  loadout, reroll, claim, redeem, product key). Never damage, enemy state, cash, rewards, prices or rolls.
- **Validate every remote** through `RemoteGuard.wrap` (type checks, finite numbers, identifier strings ≤ 64,
  enum membership against Config, ownership, affordability, phase, range, token-bucket rate limit). Reject and
  log. Ask: what if this fires 1,000×/s?
- **Odds = RNG config.** `TD.ODDS` (Rare 75.5 / Epic 20 / Legendary 4 / Mythic 0.5 %), pity 50 / 400 and
  `Config/Traits` weights feed both the roll and the Rates screens. Never type odds into UI.
- **PolicyService.** `ArePaidRandomItemsRestricted` read on join (failure = restricted). Restricted players never
  see or buy anything that funds lira or trait stones (`MonetizationLogic.fundsRandomItems`).
- **Never hard-code Robux prices.** `Products.luau` `robux` fields are display hints; the real price comes from
  `MarketplaceService:GetProductInfo`. Every product id stays `0` until the owner creates it.
- **IP (owner's decision, COPYRIGHT_REGISTER C-201).** Names and roles are inspired by the classic Damascus hara
  dramas and were chosen by the owner. Never the series' title in any title/tag/description, never actor
  likenesses or photos in prompts, never its music or recordings. New names go in `Config/Strings` and get a
  register row; when unsure, ask.
- **Luau strict.** `--!strict` on line 1; exported types; no `any` without a justifying comment.
- **Tests with Lune.** `tests/run.luau` is the runner; every `Logic/*` module and every validator has specs.
  Mandatory: odds sum, pity bounds, placement rejections, receipt idempotency, schema migration, balance targets.
- **Data.** `DataService.mutate(player, fn)` is the only write path; session locks; receipts recorded in the same
  mutation as the grant; profiles that failed to load are never saved.
- **Dev code** (`DebugService`, `DebugKeysController`, `DebugOverlayController`) is a no-op outside Studio.
- **No secrets in git.** `MESHY_API_KEY`, `ROBLOX_OPEN_CLOUD_KEY`, `ROBLOX_CREATOR_ID`, Discord tokens live in
  env vars or `tools/discord` local files only. Never print them.
- **Shared checkout.** No whole-file reformat, no stash/checkout/reset, no history rewrite, no push unless asked.

## Asset rules
- **Budgets:** ≤ 20,000 tris per MeshPart (Roblox cap). Characters 3–6k, bosses ≤ 12k, props ≤ 2k; one
  base-colour map, 1024² (512² for enemies); ≤ 25 unique character meshes in a match.
- **Pipeline:** `python tools/meshy/meshy.py make <id>` (concept image first, judge it, then mesh, rig, clips) →
  import the **GLB** in Studio (Rig Type Custom, Upload on) → Save to File `assets/production/CharacterModels/<Name>.rbxm`
  → `CharacterLooks[id].model` → `python tools/anim/fetch.py` + `bake.py` for signature clips → register row.
  Never import Meshy FBX clips (rotated 90°).
- **Naming:** ids are lower_snake archetypes (`natour`, `qahwaji`); model files are PascalCase display names.
- **Provenance:** every production asset has a COPYRIGHT_REGISTER row (tool, prompt, date, status Approved).
  Nothing under `assets/unapproved` may be referenced from `src/`.

## Commits
- One task per commit, on the current phase branch (`phase/<n>`, cut from `feat/vertical-slice`; ask before
  merging anywhere).
- Subject: `P0-03: fix type errors and add check scripts` (task ID + imperative, ≤ 72 chars).
- Body: what changed, then `Verified:` with the evidence (test counts, key console lines, what the screenshot showed).
- Never commit secrets, `Packages/`, `build/`, place binaries, or a red test suite.

## Picking the next task
Open `docs/BUILD_PLAN.md` and take the first `[ ]` task whose deps are all `[x]`. Mark it `[~]`, do it, then
mark it `[x] <hash>`. If you're blocked after 3 honest attempts, mark it `[!] <reason / what you need>` and
take the next unblocked task. Design work (new units, bosses, modes, worlds) goes into a design-doc appendix and
gets one owner review before you build it.

## Stop and ask (never decide alone)
- Robux: prices, creating developer products, passes or subscriptions; Ads Manager spend.
- Publishing a place version, restarting servers, changing experience or place settings, the maturity
  questionnaire, audience/age settings.
- Legal: IP clearance of a name or asset, contributor contracts, interpreting paid-random-item, PolicyService or
  trading rules, the series-title trademark question.
- API keys and credentials; installing MCP servers or Studio plugins; spending Meshy credits beyond a task's stated budget.
- Deleting or overwriting Studio content you didn't create; anything needing a human click (Rojo Connect, Player
  Emulator, Clip Editor publish, importer dialogs, multi-client test).

Batch these into one precise request, keep working on unblocked tasks, and stop when only "needs you" items remain.
