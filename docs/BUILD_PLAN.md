# Haret Al-Yasmin: Build Plan

The task-by-task execution plan for the coding agent (Claude in Claude Code on the owner's Windows machine, with
Roblox Studio's built-in MCP server and the Blender Lab MCP). Rewritten 2026-10-17 for the code that exists on
`feat/vertical-slice` (DECISIONS D-001); the original research kit is in `reports/` for background.

- Standing rules: [`CLAUDE.md`](../CLAUDE.md). Tool names: [`docs/TOOLS.md`](TOOLS.md).
- Design and numbers: [`GAME_DESIGN.md`](GAME_DESIGN.md), [`TOWER_DEFENSE.md`](TOWER_DEFENSE.md),
  [`MONETIZATION.md`](MONETIZATION.md), [`AFK_CHAMBER.md`](AFK_CHAMBER.md), `src/shared/Config/`.
- Decisions: [`DECISIONS.md`](DECISIONS.md). Owner-only steps: [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md).

**Where we are (2026-10-17).** The game is playable end to end and **public** on the TEST experience (place
120389740593436, version 71) with Discord testers: lane lobby, Season 1 Episode 1 errands, wardrobe and shop,
summons with published odds and pity, traits and stars, the Lane Diary season pass, codes, dailies, the
Hakawati's AFK room, three story episodes plus Endless on three difficulties for parties of 1–4, 16 defenders
and 11 attackers (21 imported Meshy characters with baked signature animations, 6 props), server-authoritative
match simulation, PolicyService gating, idempotent receipts (product ids still `0`), analytics events, 147 Lune
specs and an auto-battler balance harness. Phases 1–2 below are therefore mostly ticked with the commits that
built them; the open work is monetization ids (owner), performance and device gates, audio, remaining enemy
models, red-teaming, onboarding measurement, and live ops.

| Phase | Weeks | Exit criteria |
|---|---|---|
| 0 Foundations | now | The agent edits code, playtests and reads the console via Studio MCP; the check script is green; one imported asset is verified in Studio; TOOLS and DECISIONS exist |
| 1 Core prototype | done except perf | Match loop proven; 400 enemies stable on an emulated phone; blind testers choose to replay |
| 2 Meta systems and monetization | 1–4 | Product ids live on the TEST experience and the Studio purchase script passes; Player Emulator passes in 5 regulated markets; odds sims green; onboarding join → wave 1 measured |
| 3 Content alpha | 5–10 | Every attacker has a real model; audio in; Episode 4 or a new arena; Auto Play; red-team pass clean; closed test of 100–300 |
| 4 Beta / soft launch | 11–14 | Production build excludes dev code; thumbnails and icon; backups drilled; D1/D7 trending up before scaling ads |
| 5 Launch | 15–16 | Launch audit passes; stable through launch weekend; Update 1 ~80% built |
| 6 Live ops | then | Each update ships a banner, an event currency, a mode and codes |

## How to use this file

- **Statuses:** `[ ]` todo, `[~]` in progress, `[x]` done (append the short commit hash), `[!]` blocked (append the
  reason and what is needed from the owner).
- **Picking work:** take the first `[ ]` task whose dependencies are all `[x]`. One task at a time. Commit at the end
  of each task.
- **Task fields:** **Goal** · **Create** (files) · **Tools** (MCP tools; "code" means Rojo-synced files) · **Accept**
  (criteria you verify yourself via tests, console, screenshots) · **Deps**.
- **STOP** marks a step that needs a human decision or click (CLAUDE.md "Stop and ask"). Prepare everything first,
  then ask once with a precise list.
- Each "Accept" assumes the CLAUDE.md verify loop: `tools/check.ps1` green, playtest console free of errors from our code.

---

## Phase 0: Foundations (verification of what exists)

### Manual setup by the owner (U0): all done 2026-10-17

| Step | State |
|---|---|
| U0-1 Studio, TEST place published, **Studio Access to API Services on** | done (RELEASE_CHECKLIST §B2.5, §E) |
| U0-2 Studio as MCP server | done (`list_roblox_studios` returns the TEST place) |
| U0-3 Git | done (`.gitattributes` marks `.rbxm`/`.png` binary; no LFS yet) |
| U0-4 Rokit toolchain: rojo 7.7.1, selene 0.32.0, StyLua 2.6.0, luau-lsp 1.70.1, lune 0.11.0, wally 0.3.2 | done |
| U0-5 Wally | `wally.toml` present with no dependencies (D-003) |
| U0-6 Jest-Lua | not used (D-003) |
| U0-7 uv 0.13.1, Blender 5.2 with the Blender Lab MCP extension | done |
| U0-8 Claude Code 2.1.302 | done |
| U0-9 MCP servers (`Roblox_Studio`, `blender` at user scope; `discord-feedback` project scope) | done |
| U0-10 `MAX_MCP_OUTPUT_TOKENS=50000`, `ROBLOX_OPEN_CLOUD_KEY`, `ROBLOX_CREATOR_ID` at user level | done (restart Claude Code to inherit) |
| U0-11 `rojo serve` + Rojo plugin Connected | done |
| U0-12 Legal: contributor contracts, IP stance | owner (D-007; register C-201) |

### Agent tasks

- [x] 7b0c66d **P0-01 Tool inventory** · deps: U0-11
  - **Goal:** Record the real MCP tool surface of this machine and fix every name in CLAUDE.md that differs.
  - **Create:** `docs/TOOLS.md`.
  - **Tools:** `claude mcp list`, tool schemas, `list_roblox_studios`, `get_studio_state`, `get_blendfile_summary_path_info`, `get_objects_summary`.
  - **Accept:** TOOLS.md lists both servers with required params and limits; `list_roblox_studios` returns the TEST place; every differing name is noted and CLAUDE.md uses the real names.

- [x] 51bd1cb **P0-02 Rojo round-trip and playtest loop** · deps: P0-01
  - **Goal:** Prove live sync plus the playtest/console loop through MCP (earlier runs used computer use).
  - **Tools:** Bash (`rojo serve` already up on 34872), `search_game_tree`, `script_grep`, `start_stop_play`, `get_console_output`, `screen_capture`.
  - **Accept:**
    - `ServerScriptService.Server.Main`, `ReplicatedStorage.Shared.Logic.TdSim` and `ReplicatedStorage.CharacterModels` exist in Studio.
    - A nonce comment added to `Main.server.luau` appears via `script_grep` within seconds, then is reverted; nothing is committed for it.
    - During a playtest the console shows `[HaretAlYasmin] server ready`, no `PERSISTENCE DISABLED` (API access on), and no errors or warnings from our code; a screenshot shows the lane.

- [x] 47106ad **P0-03 Lint, type and test baseline** · deps: P0-02
  - **Goal:** Zero-error baseline and one repeatable command.
  - **Create:** `tools/check.ps1`, `tools/check.sh` (selene, `lune run tests/run`, sourcemap + `luau-lsp analyze` strict, `rojo build`; StyLua advisory per D-005), `.styluaignore` for generated clips.
  - **Fix:** the 3 type errors at HEAD (`BoneAnim.clipsFor` narrowing; `RigAnimController` passing `speedMul` as `dt` and omitting `smooth`, D-011) and the unused `RunService` in `DataService`.
  - **Accept:** `tools/check.ps1` prints `CHECK OK`; selene 0 errors 0 warnings; luau-lsp 0 errors; 147+ specs pass; a playtest shows imported enemies walking smoothly (the `dt` bug is visible as a jittering walk).

- [x] 0c7a951 **P0-04 Test harness proof** · deps: P0-02
  - **Goal:** Prove the Lune harness catches a broken number.
  - **Tools:** Bash.
  - **Accept:** `lune run tests/run` is green; changing `TD.ODDS.rare` so the odds no longer sum to 1 (or `PITY_LEGENDARY`) makes at least one spec fail; the change is reverted. `lune run tests/balance` runs the 96-cell matrix and matches `TOWER_DEFENSE.md` §5 on the asserted cells. Convention: specs stay in `tests/*.spec.luau`, registered in `tests/run.luau`.

- [x] 0c7a951 **P0-05 Place layout check** · deps: P0-02
  - **Goal:** Confirm nothing in the place is Studio-owned and the runtime world matches the project file.
  - **Tools:** `search_game_tree` (Edit and Server), `inspect_instance`, `execute_luau`, `screen_capture`.
  - **Accept:** In Edit the DataModel holds only the Rojo-synced folders, `Lighting` and service properties from `default.project.json` (ClockTime 15.2, StreamingEnabled) and a baseplate/spawn; during a playtest `Workspace` contains the lane zones, `Crowd`, portals and (after a queue) `Arenas`. Any Studio-owned leftovers are listed for the owner (STOP before deleting anything).

- [x] 0c7a951 **P0-06 Blender and preview toolkit** · deps: P0-01
  - **Goal:** The Blender side of the pipeline works from MCP and headlessly.
  - **Tools:** `get_blendfile_summary_path_info`, `execute_blender_code`, `get_screenshot_of_area_as_image`, `render_thumbnail_to_path`; Bash for `tools/anim/preview.py`.
  - **Accept:** `execute_blender_code` returns the Blender version and the tri count of the default cube; `render_thumbnail_to_path` writes a PNG that is actually looked at; `blender -b --factory-startup -P tools/anim/preview.py -- <an existing clip .glb> out.png 8 front` renders a sheet of an existing character clip.

- [x] 0c7a951 **P0-07 Asset credentials and upload path** · deps: P0-06, U0-10
  - **Goal:** Confirm the Open Cloud key works and decide the upload route.
  - **Accept:** a read-only Open Cloud call (key introspection or an Assets API read) succeeds without printing the key; `docs/CHARACTER_PIPELINE.md` names the current route (Studio importer, GLB) and D-004 records that `tools/upload_asset.py` is deferred to P3-02. If the key is missing: STOP and ask for U0-10.

- [x] 0c7a951 **P0-08 Imported asset round trip** · deps: P0-05, P0-07
  - **Goal:** One real asset verified end to end in Studio.
  - **Tools:** `search_game_tree`, `inspect_instance`, `execute_luau`, `screen_capture`.
  - **Accept:** `ReplicatedStorage.CharacterModels.AbuHatem` (or any production model) exists with Bones and no Script descendants; its bounding size is the archetype height ±5 % after `RigBuilder` scaling in a match; a playtest screenshot shows the imported model placed and animating with its hand prop.

- [x] 5fbe57a **P0-09 Decision log** · deps: none
  - **Create:** `docs/DECISIONS.md` seeded with D-001…D-011 (codebase choice, tool names, Lune, Meshy pipeline, StyLua advisory, one place, IP stance, growth axes, branching, AFK cap, the P0-03 fix).
  - **Accept:** the file exists; from now on every TUNE change and design deviation gets a dated line.

**Phase 0 exit:** P0-01..P0-09 are `[x]`. Report the evidence (check output, console lines, screenshot description, asset check) and wait for the owner.

---

## Phase 1: Core prototype (built 2026-10-15 → 10-17; verify the open items)

- [x] **P1-01 Net and remote guard** · `src/shared/Net.luau`, `RemoteGuard` (type checks, identifiers ≤ 64, token bucket), `Logic/RateLimiter`, `Logic/Validate` · cb853b6
- [x] **P1-02 Lane world** · `WorldService`, `World/Kit`, `Props`, `Zones/*`, streaming · cb853b6, 1b8b60f
- [x] **P1-03 Path and match data** · `Logic/Path` (polyline, distance), `Config/Arenas`, `Config/Modes` · 2b0b800
- [x] **P1-04 Server enemy simulation** · `Logic/TdSim` 20 Hz pure step (stealth, armor, slows, stuns, stun-chain cap), `tests/td.spec.luau` · 2b0b800, 658e4e5
- [x] **P1-05 Replication and renderer** · `MatchEvents` batches, `EnemyPositions` UnreliableRemoteEvent at 10 Hz, `EnemyRenderController` interpolation · 2b0b800, 026da45
- [x] **P1-06 Match economy** · start cash, wave bonus, skip bonus, sell refund, party scaling (`TD.PARTY_*`, `tests/party.spec.luau`) · 2b0b800, 658e4e5
- [x] **P1-07 Waves and modes** · `Logic/WaveLogic`, `Config/Waves`, episodes 1–3 + Endless, difficulties, bosses every 10 · 2b0b800
- [x] **P1-08 Placement rules and tower service** · `Logic/TdTowers` (bounds, road clearance, spacing, caps, cash), `MatchService` remotes · 2b0b800
- [x] **P1-09 Placement controller and match HUD** · `PlacementController`, `MatchController`, `MatchCameraController`, TD-style UI pass · 2b0b800, 658e4e5
- [x] **P1-10 Targeting, damage, abilities** · first/last/strongest/closest, splash, shabriyeh and sweep abilities, support auras, farm, gate repair · 2b0b800
- [x] **P1-11 Roster** · 16 defenders in `Config/Units` (7 Rare, 3 Epic, 3 Legendary, 2 Mythic, 1 Secret), 11 attackers in `Config/Enemies` · 2b0b800
- [x] **P1-12 Dev tools and bot** · `DebugService` (`HaretDebug` hooks), `DebugKeysController`, `DebugOverlayController`, `tests/autobattle.luau`, `tests/balance.luau` · 2b0b800, 658e4e5
- [x] **P1-13 Balance pass** · targets asserted in `tests/td.spec.luau` "Balance"; results in `TOWER_DEFENSE.md` §5 · 658e4e5
- [x] **P1-14 Characters and props** · Meshy pipeline, 21 `.rbxm` characters, 6 props, `CharacterLooks`, `PropPlacements` · 658e4e5
- [x] **P1-15 Signature animations** · baked bone clips, `BoneAnim`, `ThrowFx`, `HandProps` · 7f57080, f46109a
- [x] **P1-16 Tester bug pass** · summons, stealth, clicks, frozen enemies, T-poses, wall climbing · 026da45
- [ ] **P1-17 Co-op verification (multi-client)** · deps: P0-02 · STOP
  - **Tools:** no multi-client MCP tool (TOOLS.md): ask the owner to start **Test → Clients and Servers** with 2 players.
  - **Accept:** with 2 clients: both get their own start cash and wave bonus; kill cash goes to the killing tower's owner; the skip vote needs both; a client that leaves mid-match pays the loss share and the match continues; no cross-talk in dialogue or shop sessions. Record in `TEST_REPORT_SLICE.md`.
- [ ] **P1-18 Performance gate** · deps: P0-03
  - **Goal:** The worst realistic match: a party of 4 at Endless wave 60+ (≥ 150 live attackers) with 80 towers.
  - **Tools:** `execute_luau` Server (`os.clock` around `TdSim.step` and the `MatchEvents` batch) and Client (average frame time over 5 s from `RunService.RenderStepped`); `skill` `rbx-device-simulator-lua` for a mid-range phone; `skill` `rbx-perf-profiling` if the budget is missed.
  - **Accept:** server step ≤ 4 ms average and ≤ 8 ms p95 per match; client ≥ 30 FPS on the emulated phone; `EnemyPositions` packet ≤ 900 bytes; numbers logged in DECISIONS. If device emulation can't be driven from MCP, STOP and ask the owner to run the Device Emulator.
- [ ] **P1-19 Prototype playtest report** · deps: P1-16 · STOP
  - **Goal:** Turn the Discord tester feedback (`tools/discord`, `docs/community`) into a dated report with replay intent.
  - **Create:** `docs/playtests/P1.md` (what testers did, bugs, 6 questions, a replay-intent table).
  - **Accept:** the owner confirms the summary; new issues become tasks here.

---

## Phase 2: Meta systems and monetization (vertical slice gate)

- [x] **P2-01 Place roles** · one place, arenas in-server · D-006 (revisit if servers of 30 with 6 arenas miss P1-18)
- [x] **P2-02 Persistence** · `DataService` session locks, autosave, `BindToClose`, versioned schema (`Logic/ProfileSchema` v2 migration), mock store fallback · cb853b6, 2b0b800
- [x] **P2-03 Summons and pity** · `Logic/SummonLogic`, `TD.ODDS`, pity 50 / 400, featured share, hourly banners, `tests/meta.spec.luau` · 2b0b800
- [x] **P2-04 Odds disclosure** · summon Rates screen and the Units → Rates trait panel generated from config · 2b0b800, 658e4e5
- [x] **P2-05 PolicyService gating** · restricted players can't fund lira or stones (`MonetizationLogic.fundsRandomItems`); failure = restricted · bf5c3d1, 658e4e5
- [x] **P2-06 Traits and stars** · `Config/Traits`, `UnitLogic.rerollTrait`/`rerollOdds`, stars from copies · 2b0b800
- [x] **P2-07 Loadout and units UI** · 6 slots (+1 pass), `UnitsController`, `UnitCard`, `SummonSequence` · 2b0b800, 658e4e5
- [x] **P2-08 Match rewards and unlocks** · `Logic/MatchRewards` (lira/qirsh/XP, first clear ×2, loss share, Endless tiers), episode and difficulty unlocks · 2b0b800
- [x] **P2-09 Season pass, codes, dailies** · `PassLogic`, `CodesLogic`, `DailyLogic`, UTC resets · 2b0b800
- [x] **P2-10 Monetization plumbing** · `Products.luau` keys → ids, server-opened prompts, idempotent `ProcessReceipt`, fallbacks, pass perks · bf5c3d1, 658e4e5
- [x] **P2-11 AFK chamber** · the Hakawati's room, `AfkLogic`, daily cap (D-010) · 8986c62
- [ ] **P2-12 Odds and pity simulation specs** · deps: P0-04
  - **Create:** in `tests/meta.spec.luau`: a 1,000,000-pull simulation with pity disabled matching `TD.ODDS` per rarity within 4σ; with pity enabled, no gap longer than 50 (Legendary+) or 400 (Mythic); trait reroll odds per current trait sum to 1 within 1e-9. Keep the sim under 10 s in Lune (seeded RNG).
  - **Accept:** specs green; counts and σ printed in the commit body.
- [ ] **P2-13 Product ids and Studio purchase script** · deps: P2-10 · STOP
  - **Goal:** The owner creates the 15 developer products and 4 passes at the planned tiers (RELEASE_CHECKLIST §B2.2–B2.3) and sends the ids; the agent pastes them into `Products.luau` and runs §B2.7 in Studio.
  - **Accept:** every §B2.7 row passes or is recorded with the Output log; `lune run tests/run` green; §D register filled.
- [ ] **P2-14 Player Emulator policy check** · deps: P2-13 · STOP
  - **Goal:** Add a Studio-only override attribute to force `ArePaidRandomItemsRestricted` both ways; screenshots of the restricted store and summon screens; then the owner checks the Player Emulator for Australia, Belgium, the Netherlands, the UK and Brazil.
  - **Accept:** specs for both paths; owner reports pass/fail per market.
- [ ] **P2-15 Audit log and ledger** · deps: P2-02
  - **Goal:** Every lira/qirsh/stone grant and spend writes an audit entry (source, amount, idempotency key) inside the same `mutate`; a per-player ring buffer in the profile plus analytics economy events.
  - **Accept:** specs: a replayed receipt or code produces no second entry; the summon and reroll entries carry the roll seed; `DATA_SCHEMA.md` updated.
- [ ] **P2-16 Onboarding funnel measurement** · deps: P2-02
  - **Goal:** Funnel events join → first prompt → first summon → portal → wave 1 → wave 5 → first clear, with timestamps; a Studio-only report of join → wave 1 time.
  - **Accept:** in Studio with the harness the steps complete in ≤ 60 s; the live median comes from the Creator Dashboard after the next publish (owner reads it; STOP to ask).
- [ ] **P2-17 Match VFX pass** · deps: P1-15
  - **Goal:** Hits, deaths (petal/ash poof, no blood), shabriyeh and sweep impacts, boss telegraphs, gate hit; all client-side from `MatchEvents`, pooled, capped per frame.
  - **Accept:** screenshots of each effect; client frame time still within P1-18.
- [ ] **P2-18 Vertical slice gate** · deps: P2-12..P2-17 · STOP
  - **Accept:** P2-12 sims green; §B2.7 purchase script passed; Player Emulator 5/5; join → wave 1 median ≤ 60 s on 10 live joins; the owner signs off.

---

## Phase 3: Content alpha

- [ ] **P3-01 Remaining attacker models** · deps: P0-08
  - **Goal:** Meshy models for bandit, thug, rider, sapper, the Sergeant and the Commandant (budget ≈ 47 credits each; STOP for the total before spending), with walk and hit clips baked.
  - **Accept:** tri budgets pass; all 11 attackers imported; `TEST_REPORT_SLICE.md` screenshot of the lineup in a match.
- [ ] **P3-02 Open Cloud upload tool (optional)** · deps: P0-07
  - **Create:** `tools/upload_asset.py` (`uv run`, standard library, multipart POST to `https://apis.roblox.com/assets/v1/assets` with `x-api-key` from the env, `creationContext.creator.userId` from `ROBLOX_CREATOR_ID`, polls the operation, prints `rbxassetid://`, `--dry-run`, never prints the key).
  - **Accept:** dry-run output; one image or audio asset uploaded and its id used from Config. Skip if the importer route stays sufficient (note in DECISIONS).
- [ ] **P3-03 Audio** · deps: P2-17 · STOP
  - **Goal:** Original cues per `AUDIO_BIBLE.md` and `AUDIO_COMMISSION.md` (owner commissions or approves Creator Store audio); ids into `Config/Audio`; bands change at the wave thresholds.
  - **Accept:** every cue id non-zero or deliberately silent; music band changes logged in a playtest; register rows for every track.
- [ ] **P3-04 Episode 4 or second arena** · deps: P2-18
  - **Goal:** Design first (a one-page appendix in `TOWER_DEFENSE.md` with pacing: a new attacker every 5–8 waves, a 2× spike, a mid-boss, an exam wave, an untimed finale), owner review (STOP), then `Config/Arenas`, `Config/Waves`, props.
  - **Accept:** the auto-battler clears it on Normal with the tier `TOWER_DEFENSE.md` §5 predicts and loses without stealth detection; balance cells added to the asserted set.
- [ ] **P3-05 Trials or Bounty mode** · deps: P2-18
  - **Goal:** One scarce-currency mode (modifiers on an existing episode, or a daily boss with a 5-minute limit) paying trait stones; caps per day; UTC rotation.
  - **Accept:** specs per modifier and cap; a playtest of two modifiers.
- [ ] **P3-06 Auto Play and layout codes** · deps: P1-12
  - **Goal:** Promote the auto-battler planner to a player feature: pick an anchor, it places and upgrades the loadout, never fires abilities; export/import layouts as compact base64 validated server-side like any placement.
  - **Accept:** specs: malformed code rejected; Auto Play clears Episode 1 Normal with re6up.
- [ ] **P3-07 Analytics review** · deps: P2-16
  - **Goal:** Economy source/sink events per currency, progression, mode starts and clears; verify method names with `http_get` docs.
  - **Accept:** events visible in Studio output; the owner confirms the dashboard after a live test (STOP).
- [ ] **P3-08 Mobile UI pass** · deps: P2-17
  - **Goal:** Touch targets ≥ 44 px, safe areas, portrait-proof modals, touch placement.
  - **Accept:** screenshots at phone and tablet via `rbx-device-simulator-lua`; a real-device run (owner, STOP) for touch placement.
- [ ] **P3-09 Red-team pass** · deps: P2-15
  - **Create:** `src/server/Services/RemoteFuzz.luau` (Studio only): every remote, 1,000 fuzzed calls each from a Client context (random types, NaN/inf, huge strings, other players' ids, replayed receipts and codes).
  - **Accept:** 0 state changes from invalid calls (profile checksum unchanged), rate limits trip; a two-session lock test refuses the second session; findings in `docs/security/redteam-P3.md`.
- [ ] **P3-10 Arabic and cultural review** · deps: none · STOP
  - **Goal:** Native-speaker review of `Config/Strings` (`docs/review/ARABIC_STRINGS_REVIEW.md`) and of depictions; fixes applied.
- [ ] **P3-11 Closed test** · deps: P3-01..P3-09 · STOP
  - **Goal:** The owner invites 100–300 testers via Discord; the agent prepares the build checklist, known-issues post and telemetry queries.
  - **Accept:** the owner reports; issues become tasks.

---

## Phase 4: Beta / soft launch

- [ ] **P4-01 Production build project** · deps: P3-11
  - **Create:** `build.project.json`: the same tree with `globIgnorePaths` for `**/Debug*`, `**/RemoteFuzz*`; tests are already outside `src`.
  - **Accept:** `rojo build build.project.json -o build/prod.rbxl` succeeds and a script scan of the output finds no Debug or RemoteFuzz instances; `DebugService`/`DebugKeysController` stay Studio-gated regardless.
- [x] **P4-02 Maturity questionnaire** · Mild, paid random items declared · RELEASE_CHECKLIST §B2.4 (2026-10-16)
- [ ] **P4-03 Thumbnails and icon** · deps: P3-01
  - **Goal:** 5 thumbnails at 1920×1080 (staged `screen_capture` with set cameras or Blender renders) and a 512×512 icon in the original style, no series imagery, no text-heavy layouts.
  - **Accept:** files in `assets/marketing/`; STOP for the owner to upload.
- [ ] **P4-04 Mobile performance pass** · deps: P1-18, P3-01
  - **Goal:** LOD (animation off beyond 220 studs already; health bars off beyond 80), part and texture budgets, instance counts per arena.
  - **Accept:** P1-18 numbers re-measured and logged.
- [ ] **P4-05 Backups and rollback drill** · deps: P2-15
  - **Create:** `src/server/Services/RestoreService.luau` (restore a profile version by timestamp via DataStore versions; replay the audit log) and `docs/ops/rollback.md`.
  - **Accept:** a drill on a test account restores state exactly.
- [ ] **P4-06 Error telemetry** · deps: P3-07
  - **Goal:** Hook `LogService.MessageOut` on the server, count errors by message hash, flush as analytics custom events every 60 s.
  - **Accept:** a forced error appears in the counts.
- [ ] **P4-07 Rewarded video** · deps: P2-13 · STOP (needs 2,000+ monthly uniques and a developer product)
- [ ] **P4-08 Subscription "Lane Club"** · deps: P2-13 · STOP (owner creates; daily lira + stones to the paid balance)
- [ ] **P4-09 Ads and Discord plan** · deps: P4-03 · STOP (agent drafts copy, code-drop schedule and launch codes; owner runs a small Ads Manager test)
- [ ] **P4-10 Onboarding iteration** · deps: P4-06
  - **Goal:** Fix the largest funnel drop each week, one change at a time, logged in DECISIONS.
  - **Accept:** bounce < 60 s and D1/D7 trending up week over week; STOP before scaling ads.

---

## Phase 5: Launch

- [ ] **P5-01 Launch audit** · deps: P4-*
  - **Create:** `docs/LAUNCH_AUDIT.md` with pass/fail evidence: all specs and sims green; Player Emulator 5/5; no hard-coded prices (`grep -rni robux src` finds only display hints and comments); COPYRIGHT_REGISTER complete and Approved, title trademark search done; remote fuzz clean; backups drilled; production build excludes dev code; questionnaire current.
  - **Accept:** every line passes or carries an owner-approved waiver.
- [ ] **P5-02 Update 1 at ~80 %** · deps: P3-* · on branch `update/1`.
- [ ] **P5-03 Publish** · deps: P5-01 · STOP (owner publishes the production build, sets title, description, genre; agent provides the text; restart outdated servers afterwards).
- [ ] **P5-04 Launch-weekend watch** · deps: P5-03 · every 2 hours: error telemetry, economy anomalies (lira/stone source spikes, duplicate receipt alerts); hotfixes on `hotfix/*` with tests; STOP for the owner to publish.
- [ ] **P5-05 Milestone codes** · deps: P5-03 · pre-written like/favourite milestone codes with expiry; activated on the owner's go.

---

## Phase 6: Live ops

### Update template (every update)
Each update ships: a new banner (featured or limited unit), an event currency and event shop, one mode or arena,
2–4 codes, a title tag (`[UPD n]`), balance notes in `docs/patch-notes/U<n>.md`, and a Part 2 two weeks later.
Before shipping: re-run the P5-01 lines for odds, policy, prices and licenses; every new power axis declares a
cap in DECISIONS (D-008).

- [ ] **P6-U1-01 Nightmare+ remixes** · remixed episodes at a fourth difficulty after clearing Nightmare; exclusive drops.
- [ ] **P6-U1-02 New arena** · pipeline P3-04.
- [ ] **P6-U1-03 Update 1 Mythic and event** · design → owner name review → Config → model.
- [ ] **P6-U1-04 Ship U1 and Part 2** · STOP (publish)
- [ ] **P6-U2 Leaderboards and Endless seasons** · OrderedDataStore weekly boards; rate-limited writes.
- [ ] **P6-U3 Raid: The Khan** · multi-stage co-op raid with its own sigils and shop.
- [ ] **P6-U4 Trading** · Lv gate, server escrow, traits and stars reset on trade, limited units untradeable, `IsPaidItemTradingAllowed` gate; STOP for legal review before shipping.
- [ ] **P6-U5 Fair-play arena** · traits disabled; score attack.

---

## Asset pipeline reference

| Asset | Tris (hard cap 20,000 per MeshPart) | Texture | Route |
|---|---|---|---|
| Defender / attacker | 3,000–6,000 (bosses ≤ 12,000) | 1024² (enemies 512²) | Meshy concept → mesh → rig → GLB import → `.rbxm`; clips baked |
| Prop | ≤ 2,000 | 1024² | Meshy mesh → GLB import → `.rbxm` → `PropPlacements` |
| VFX sprite | – | 256–512² PNG with alpha | `upload_image` (HTTP URL) or Studio import |
| Marketing | – | 1920×1080, 512×512 | `screen_capture` with set cameras, Blender renders |

Every production asset: a COPYRIGHT_REGISTER row (tool, prompt, date, Approved); nothing from `assets/unapproved` is referenced from `src/`.

---

## Kickoff prompts

**Phase 0**
> Read CLAUDE.md, docs/TOOLS.md, docs/DECISIONS.md and docs/BUILD_PLAN.md. Continue Phase 0 from the first unticked task with the verify loop, committing after each task on `phase/0` and ticking it here. Stop and ask for anything on the Stop-and-ask list. When the Phase 0 exit criteria are met, give me the evidence and wait.

**Phase 1 (open items)**
> Phase 0 is done. Do P1-18 (performance gate) with the verify loop, then prepare P1-17 and P1-19 and ask me once for the clicks and the Discord summary review.

**Phase 2**
> Start Phase 2 from the first unticked task. Before P2-13, list exactly what I must create in the Creator Dashboard (RELEASE_CHECKLIST §B2) and wait for the ids. Never create or price products yourself. Stop at P2-14 for my Player Emulator check and at P2-18 for the gate review.

**Phase 3**
> Start Phase 3. For every new attacker, mode or arena, first add a design appendix with original names and a one-line IP check, then pause once for my review before building. Tell me the Meshy credit budget before spending it. Run the red-team pass (P3-09) before asking me to start the closed test.

**Long autonomous session (prepend to any phase prompt)**
> You may work autonomously for this session. Rules: (1) `git status` first; never stash, checkout, reset or reformat whole files in this checkout; message overlapping sessions. (2) One BUILD_PLAN task at a time; commit after every task with the evidence; tick it. (3) Checkpoint every 3 tasks or 60 minutes: a 5-line status (done, evidence, next, blockers, needs-you). (4) After 3 failed attempts mark `[!]` and move on. (5) Never: spend or price Robux, create products, publish or change place settings, submit questionnaires, make legal or IP calls, handle keys, delete Studio content you didn't create, push, rewrite history, or write scripts through MCP. (6) Stop when the phase exit criteria are met or only "needs you" items remain, and summarize.
