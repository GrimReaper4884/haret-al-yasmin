# Haret Al Yasmin: Build Plan

The task-by-task execution plan for the coding agent (Claude Fable 5.1 in Claude Code, on the user's Windows or macOS machine, with Roblox Studio's built-in MCP server and Blender MCP).

- Standing rules: [`CLAUDE.md`](../CLAUDE.md).
- Numbers: [`docs/GAME_DESIGN.md`](GAME_DESIGN.md) (GDD) and `src/shared/Config/`.
- Research: [`reports/Roblox tower defense game blueprint.md`](../reports/Roblox%20tower%20defense%20game%20blueprint.md).

**Schedule:** about 26 weeks to launch, then a 3–4-week live-ops cadence. It assumes a 2–4 person team with the agent carrying most of the scripting, testing and asset preparation.

| Phase | Weeks | Exit criteria |
|---|---|---|
| 0 Foundations | 1–2 | The agent edits code, playtests and reads the console via Studio MCP; one asset goes Blender → Open Cloud → Studio |
| 1 Core prototype | 3–8 | 400 enemies stable on emulated mobile; the bot clears W1 Act 3; blind playtesters choose to replay |
| 2 Vertical slice (meta systems) | 9–14 | Player Emulator passes in 5 regulated markets; 1M-pull sim matches tables; W1 Acts 1–6 complete |
| 3 Content alpha | 15–20 | W1–W4 × 6 acts N/NM, all launch modes, 30 units, BP S1; closed test of 100–300; red-team pass clean |
| 4 Beta / soft launch | 21–24 | Bounce and D1/D7 trending up week over week; onboarding fixed before scaling ads |
| 5 Launch | 25–26 | Stable through launch weekend; Update 1 ~80% built |
| 6 Live ops | month 7+ | Each update ships a banner, an event currency, a mode and codes |

## How to use this file

- **Statuses:** `[ ]` todo, `[~]` in progress, `[x]` done (append the short commit hash), `[!]` blocked (append the reason and what is needed from the user).
- **Picking work:** take the first `[ ]` task whose dependencies are all `[x]`. Work one task at a time. Commit at the end of each task.
- **Task fields:** **Goal** · **Create** (files/instances) · **Tools** (MCP tools; "code" means Rojo-synced files) · **Accept** (criteria you verify yourself via tests, console, screenshots) · **Deps**.
- **STOP** marks a step that needs a human decision or click (see CLAUDE.md "Stop and ask"). Prepare everything first, then ask once with a precise list.
- Each "Accept" assumes the CLAUDE.md verify loop: StyLua/selene clean, Jest specs green, playtest console free of errors from our code.

---

## Phase 0: Foundations (weeks 1–2)

### Manual setup by the user (U0)

The repo's `.mcp.json` uses the **macOS** Studio command. Windows users follow U0-9 to override it locally.

**U0-1 Roblox Studio**
1. Install Studio from <https://create.roblox.com> (Dashboard → Create → download Studio) and update it to the latest version.
2. Create a **Baseplate** place.
3. Publish it with **File → Publish to Roblox** as a private experience named "Haret Al Yasmin [DEV]".
4. Open **Game Settings → Security** and turn on **Enable Studio Access to API Services** (needed for DataStores/ProfileStore in Studio). Leave "Allow HTTP Requests" off; the built-in MCP doesn't need it.

**U0-2 Enable the Studio MCP server.** In Studio, open **Assistant → … → Manage MCP Servers** and turn on **Enable Studio as MCP server**. A green indicator shows the number of connected clients.

**U0-3 Git** (plus optional Git LFS for `.blend`/`.fbx`/place files)
- macOS: `xcode-select --install` (or `brew install git git-lfs`)
- Windows (PowerShell): `winget install --id Git.Git -e` and optionally `winget install --id GitHub.GitLFS -e`
- Optional, both platforms: `git lfs install` then `git lfs track "*.blend" "*.fbx" "*.rbxl"`. Commit the resulting `.gitattributes` change.

**U0-4 Rokit and the toolchain** (commands from the Rokit README; verify there if they fail)
- macOS: `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`
- Windows (PowerShell): `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`
- Restart the terminal, then in the repo root:
  ```
  rokit install            # rojo, wally, selene, stylua from rokit.toml (approve the trust prompts)
  rojo --version; wally --version; selene --version; stylua --version
  rojo plugin install      # installs the Rojo plugin into Studio
  ```
- Aftman users: an equivalent `aftman.toml` would list the same four tools. Rokit is the maintained successor, so only `rokit.toml` is provided.

**U0-5 Wally packages.** Run `wally install` in the repo root. Rojo's `$path` for `Packages`/`DevPackages` is optional, so the project builds even before this step.

**U0-6 Jest-Lua prerequisite.** Jest-Lua runs only inside Roblox. If the test runner (P0-04) errors because `debug.loadmodule` / `loadmodule` is unavailable, follow the jsdotlua/jest-lua README: it documents enabling a Studio FFlag (`FFlagEnableLoadModule`) in Studio's `ClientSettings/ClientAppSettings.json`. **Unverified for current Studio builds.** Studio updates can reset this file.

**U0-7 uv, Blender and the Blender MCP addon**
- uv (do **not** `pip install uv`):
  - macOS: `curl -LsSf https://astral.sh/uv/install.sh | sh` (or `brew install uv`)
  - Windows: `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`
- Blender 3.0+ (4.x LTS recommended):
  - macOS: `brew install --cask blender`
  - Windows: `winget install --id BlenderFoundation.Blender -e`
  - or download from blender.org
- Addon: `uvx mcp-for-blender install-addon`. Then in Blender: **Edit → Preferences → Add-ons**, enable **Interface: MCP for Blender**; in the viewport press **N**, open the **MCP for Blender** tab and click **Start MCP Server** (listens on localhost:9876, no auth). `uvx mcp-for-blender setup` is the automatic alternative.
- Optional: API keys for `generate_3d` providers (Hyper3D Rodin, Hunyuan3D, Tripo) or Sketchfab/Poly Pizza go in the addon preferences or `BLENDERMCP_*` environment variables, per the addon README. Never in the repo.

**U0-8 Claude Code ≥ v2.1.257** (required for Fable 5.1)
- macOS: `curl -fsSL https://claude.ai/install.sh | bash` (or `npm install -g @anthropic-ai/claude-code`)
- Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex` (or npm)
- Check with `claude --version`; upgrade with `claude update`.

**U0-9 MCP servers.** `.mcp.json` at the repo root defines `Roblox_Studio` (macOS command) and `blender` (`uvx mcp-for-blender`, telemetry off).
- **macOS:** nothing to do. Approve both project servers when Claude Code asks.
- **Windows:** add a local-scope server with the same name. Local scope takes precedence over project scope; you may also reject the project's `Roblox_Studio` when prompted. From cmd.exe or PowerShell:
  ```
  claude mcp add --scope local --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
  ```
  (`cmd.exe /c` expands `%LOCALAPPDATA%` itself, so this works from PowerShell too.) The equivalent JSON entry is `"Roblox_Studio": {"command": "cmd.exe", "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]}`.
- **Both:** if you used Studio's **quick connect** for Claude Code, it may already have added a user-scope `Roblox_Studio`. Run `claude mcp list` and keep exactly one working entry (`claude mcp remove <name> -s <scope>` for extras). Verify with `claude mcp get Roblox_Studio`.

**U0-10 Environment variables**
- Screenshots and Blender renders exceed the default 25K-token MCP output cap, so raise it:
  - macOS (zsh): `echo 'export MAX_MCP_OUTPUT_TOKENS=50000' >> ~/.zshrc && echo 'export DISABLE_TELEMETRY=true' >> ~/.zshrc && source ~/.zshrc`
  - Windows: `setx MAX_MCP_OUTPUT_TOKENS 50000` and `setx DISABLE_TELEMETRY true`, then open a new terminal.
- Open Cloud asset uploads (needed by P0-07):
  1. On create.roblox.com → **Open Cloud → API Keys**, create a key with **Assets API: read + write**, restricted to your IP and to this experience's creator.
  2. Set `ROBLOX_OPEN_CLOUD_KEY` and `ROBLOX_CREATOR_ID` (your numeric user ID, or set `ROBLOX_GROUP_ID` instead for a group) with `export` / `setx`. Never commit them.

**U0-11 First launch**
1. Terminal 1, in the repo: `rojo serve` (port 34872). In Studio: **Plugins → Rojo → Connect**.
2. Terminal 2: `claude`, approve the MCP servers, run `/model fable`, then `/mcp` and confirm `Roblox_Studio` and `blender` are connected.
3. If Fable usage shows a usage-credit consent prompt, approve it before leaving any long run unattended; unattended prompts expire after about 5 minutes and the turn ends.
4. Optional, to cut permission prompts in long sessions: add allow rules for `mcp__Roblox_Studio` and `mcp__blender` and your lint/test commands in `.claude/settings.json` (your decision; see CLAUDE.md).

**U0-12 Legal (user only).** Sign contributor contracts with IP assignment and a revenue share before anyone else commits. Approve the IP rules in GDD §2.

### Agent tasks

- [ ] **P0-01 Tool inventory** · deps: U0-11
  - **Goal:** Record the real MCP tool surface of this machine. The Studio tool list in CLAUDE.md comes from Roblox docs and has not been verified against your build.
  - **Create:** `docs/TOOLS.md` (every Studio and Blender tool: name, required params such as `studio_id` and `datamodel_type`, and observed limits such as output size or timeouts).
  - **Tools:** `/mcp` tool list, `list_roblox_studios`, `get_studio_state`, `get_scene_info`, `get_addon_status`.
  - **Accept:** `docs/TOOLS.md` lists both servers. `list_roblox_studios` returns the DEV place. Any name that differs from CLAUDE.md is noted, and CLAUDE.md is updated in the same commit.

- [ ] **P0-02 Rojo round-trip** · deps: P0-01, U0-5
  - **Goal:** Prove Rojo sync plus the playtest/console loop.
  - **Tools:** Bash (`rojo serve` in the background if not already running), `search_game_tree`, `script_read`, `start_stop_play`, `get_console_output`.
  - **Accept:**
    - `ServerScriptService.Main` and `ReplicatedStorage.Shared.Config.Validate` exist.
    - During a playtest the console shows `[HY] Config OK` and `[HY] Client boot` and no errors.
    - Temporarily add a nonce print to `Main.server.luau`, confirm it appears via `script_read` and in a playtest, then revert. Nothing is committed for the nonce.

- [ ] **P0-03 Lint, format and type baseline** · deps: P0-02
  - **Goal:** Zero-warning baseline and a repeatable command.
  - **Create:**
    - `tools/check.sh` and `tools/check.ps1`: run `stylua --check src`, `selene src` and, if installed, `luau-lsp analyze`.
    - Optional: add `JohnnyMorganz/luau-lsp` with `rokit add`; `rojo sourcemap default.project.json -o sourcemap.json`; then `luau-lsp analyze --sourcemap=sourcemap.json --definitions=<roblox globalTypes.d.luau> src`. Verify the flags with `luau-lsp --help`.
  - **Accept:** the check script exits 0 on the current tree. selene's `roblox` std downloads on first run.

- [ ] **P0-04 Jest-Lua harness** · deps: P0-02
  - **Create:**
    - `src/server/Tests/TestRunner.luau` (ModuleScript exposing `run(): {passed, failed, summary}` via Jest `runCLI`, projects = ReplicatedStorage.Shared and ServerScriptService).
    - `src/server/Tests/jest.config.luau` (`testMatch = {"**/*.spec"}`).
    - `src/shared/Config/Validate.spec.luau`: `Validate.run()` returns `{}`; each rarity table, the trait table and both stat-grade columns sum to 1,000,000; trait pity equals `round(1.2 × 1e6 / ppm)`.
  - **Tools:** `execute_luau` (Edit): `return require(game.ServerScriptService.Tests.TestRunner).run()`; `get_console_output`.
  - **Accept:** at least 1 suite and 0 failures. Breaking one number makes the spec fail; restore it afterwards. Convention from here on: specs are `*.spec.luau` next to the code they test.

- [ ] **P0-05 Studio-owned place layout** · deps: P0-02
  - **Create:** `tools/studio/setup_place.luau` (idempotent; run via `execute_luau` Edit):
    - Folders: `Workspace.Map`, `ReplicatedStorage.Assets/{Units,Enemies,Props,VFX}`, `ServerStorage.Maps`.
    - Night lighting: ClockTime 20.5, `Lighting.Technology` Future, an Atmosphere instance.
    - The CollectionService tag names used by code: `Ground`, `Hill`, `Path`.
  - **Tools:** `execute_luau` (Edit), `search_game_tree`, `screen_capture`.
  - **Accept:** the folders exist; a second run creates no duplicates; the screenshot shows night lighting. Ask the user to save the place (STOP: one-line request).

- [ ] **P0-06 Blender export toolkit** · deps: P0-01
  - **Create:** `tools/blender/hy_export.py`, loaded with `exec(open(path).read())` inside `execute_blender_code`, with functions:
    - `tri_count(obj)` (evaluated mesh)
    - `assert_budget(obj, max_tris)`
    - `limit_weights(obj, 4)` (`bpy.ops.object.vertex_group_limit_total(limit=4)`)
    - `apply_transforms(obj)`
    - `export_fbx(objs, path, anim=False)` with: `apply_scale_options='FBX_SCALE_UNITS'`, `add_leaf_bones=False`, `bake_anim=anim`, `path_mode='COPY'`, `embed_textures=True`, `use_selection=True`, `mesh_smooth_type='FACE'`
    - `export_glb(objs, path)`
    - The script sets the scene to Unit System None.
  - **Accept:** on a test cube the export writes `assets/export/test_cube.fbx`, prints the tri count, and fails loudly over budget.

- [ ] **P0-07 Asset upload path** · deps: P0-06, U0-10
  - **Create:** `tools/upload_asset.py`, standard-library Python run with `uv run tools/upload_asset.py <file> <displayName> <assetType>`:
    - POSTs a multipart request to `https://apis.roblox.com/assets/v1/assets` with header `x-api-key: $ROBLOX_OPEN_CLOUD_KEY`; a `request` JSON part (assetType, displayName, description, `creationContext.creator.userId` or `groupId`); and a `fileContent` part (≤ 20 MB).
    - Polls `GET /assets/v1/operations/{id}` and prints `rbxassetid://<id>`.
    - Never prints the key.
  - **Accept:** a dry-run mode prints the request without sending. If the env vars are missing: **STOP** and ask the user for U0-10. Fallback: the user imports via Studio's 3D Importer (Scale Unit = Stud, "Insert Using Scene Position" on).

- [ ] **P0-08 Blender → Open Cloud → Studio round trip** · deps: P0-05, P0-07
  - **Goal:** One real asset end to end.
  - **Create:**
    - `assets/blender/props/HY_Prop_TestLantern.blend` (≈1.5k tris, one UV set, 512² PNG baked color map).
    - Exported FBX.
    - `src/shared/Config/AssetIds.luau` (name → `rbxassetid://` map; `--!strict`; the single place for asset IDs).
    - `assets/LICENSES.md` (header plus a first row: "self-made").
  - **Tools:** `execute_blender_code`, `look`, Bash (upload), `insert_asset`, `search_game_tree`, `inspect_instance`, `screen_capture`.
  - **Accept:**
    - A MeshPart model sits in `ReplicatedStorage.Assets.Props` with no Script descendants.
    - Its bounding size matches the Blender dimensions in studs within ±5%.
    - The texture is visible in the screenshot.

- [ ] **P0-09 Decision log** · deps: none
  - **Create:** `docs/DECISIONS.md`, seeded with the decisions in this plan:
    - macOS `.mcp.json`
    - ProfileStore vendored vs. Wally (pending P2-02)
    - UI library choice (pending P1-09)
    - World 1 master-template approach
    - The prototype implements all 10 archetypes (the W1 template needs them by wave 20)
  - **Accept:** the file exists. From now on every TUNE change and design deviation gets a dated line here.

**Phase 0 exit:** P0-01..P0-09 are `[x]`. Report the evidence (console lines, screenshot description, asset ID) and wait for the user.

---

## Phase 1: Core prototype (weeks 3–8)

One place (Dev role), World 1, Acts 1–3 playable, 8 prototype units, all 10 archetypes, Wilt Matron, 1–4 player co-op rules. Code goes under `src/server/Services`, `src/shared/Sim`, `src/shared/Net`, `src/client/Controllers` and `src/client/UI`.

- [ ] **P1-01 Net and utility foundations** · deps: P0-04
  - **Create:**
    - `src/shared/Util/TokenBucket.luau`
    - `src/shared/Sim/Rng.luau` (wraps `Random`; seed and draw counter; `pickPpm(weights)` for integer ppm tables)
    - `src/shared/Net/Remotes.luau` (remote names plus argument schemas)
    - `src/server/Net/RemoteServer.luau` (creates remotes under `ReplicatedStorage.Remotes` at runtime; middleware for schema checks — type, finite numbers, string ≤ 64 chars, enum membership — plus a per-player token bucket and `[HY][Reject] <remote> <player> <reason>` logs)
    - Specs for each.
  - **Accept:**
    - Specs green.
    - `pickPpm` over 100,000 draws lands within 4σ for each bucket.
    - The schema rejects NaN, ±inf, wrong types, 10 KB strings and unknown enum values.

- [ ] **P1-02 World 1 blockout (Studio-owned, scripted)** · deps: P0-05
  - **Create:** `tools/studio/build_w1_blockout.luau`, run via `execute_luau` Edit. It builds in `Workspace.Map.W1`:
    - A path of 330–400 studs, 6 studs wide, with 2 U-turns. Waypoint parts are `Waypoints/001..` (invisible, anchored).
    - Path tiles tagged `Path`; ground pads tagged `Ground` beside the path.
    - Three Hill plateaus at least 6 studs high, tagged `Hill`, at the U-turns.
    - A Wilt spawn portal and the Garden Gate.
  - **Tools:** `execute_luau`, `screen_capture` (top-down camera), `search_game_tree`.
  - **Accept:** `execute_luau` reports a path length within 330–400 studs, at least 20 `Ground` and at least 3 `Hill` parts; the top-down screenshot shows a readable lane. STOP: ask the user to save the place.

- [ ] **P1-03 Map data and PathMath** · deps: P1-01, P1-02
  - **Create:**
    - `src/shared/Maps/W1_LanternMarket.luau` (waypoints exported by an `execute_luau` dump, pathWidth, spawn, gate, plus a `botLayout` list of placements for P1-15)
    - `src/shared/Sim/PathMath.luau` (cumulative length table, `positionAt(d)`, `totalLength`, `distanceToPath(point)`)
    - Specs.
  - **Accept:** specs: `positionAt(0)` is the spawn and `positionAt(total)` the gate, positions are monotonic, and known-point distances are correct within 0.01. Exported waypoints match the blockout.

- [ ] **P1-04 Server enemy simulation** · deps: P1-03
  - **Create:**
    - `src/server/Services/EnemySim.luau`: data records `{id, typeId, wave, hp, maxHp, shield, plates, distance, speed, slows, stunUntil, flags}`, a 10 Hz fixed step, leaks → Gate HP, death → bounty event, query `inRange(pos, radius)` over path-distance buckets.
    - `src/server/Services/EnemySim.spec.luau`.
  - **Accept (specs):**
    - spawn HP = `EnemyConfig.computeHp`;
    - leaks subtract `leakDamage`;
    - Ironbound takes 0 damage until 3 Breaker plates are stripped;
    - Warded shields absorb first, with Breakers at 3×;
    - Fortified doubles shields on Nightmare;
    - bosses convert stuns into a 20% slow.
  - **Accept (playtest):** a dev spawn of 50 Wisps leaks at pathLength / 6 s ±5%.

- [ ] **P1-05 Replication and client renderer** · deps: P1-04
  - **Create:**
    - `src/shared/Net/EnemyPackets.luau`: reliable spawn/death/hp/speed events; UnreliableRemoteEvent corrections packed with `buffer`, ≤ 900 bytes per packet, with a sequence number.
    - `src/client/Controllers/EnemyRenderer.luau`: pooled models from `ReplicatedStorage.Assets.Enemies`, falling back to colored parts; position from PathMath at `workspace:GetServerTimeNow()`; `BulkMoveTo`; boss/elite health bars.
  - **Accept:**
    - Packet round-trip spec green, with max packet size asserted.
    - In a playtest, client vs. server position drift is ≤ 1 stud, measured via `execute_luau` in Server and Client contexts at the same server time.
    - The screenshot shows enemies on the path.

- [ ] **P1-06 Match economy** · deps: P1-01
  - **Create:** `src/server/Services/MatchEconomy.luau` plus a spec, implementing:
    - 600 starting Cash;
    - kill bounty split evenly;
    - wave bonus `(250 + 40w) / party`;
    - Merchant income paid to the owner;
    - spend/refund (60%);
    - the reconnect window (90 s) and AFK flag (120 s).
  - **Accept:** specs for party sizes 1–4: totals per wave are equal regardless of party size, and an AFK player abstains from votes.

- [ ] **P1-07 WaveDirector** · deps: P1-04, P1-06
  - **Create:** `src/server/Services/WaveDirector.luau` plus a spec, covering:
    - WaveConfig acts and the finale override;
    - the timer `min(75, 30 + n)`;
    - untimed, unskippable finales;
    - vote skip (opens at 10 s; all-but-one);
    - the next-wave preview payload;
    - victory/defeat.
  - **Accept:**
    - Specs: Act 1 wave 15 is the finale; Act 6 wave 30 is the finale; vote thresholds hold for 1–4 players.
    - A playtest with the dev auto-kill flag logs waves 1..15 with enemy totals 8, 12, 14, 20, 16, 14, 16, 32, 12, 11, 18, 22, 16, 18, 9, then `[HY][Match] Victory`.

- [ ] **P1-08 Placement rules and TowerService** · deps: P1-03, P1-06
  - **Create:**
    - `src/shared/Sim/PlacementRules.luau` (pure validator: surface tag vs. unit placement, path clearance, spacing, per-unit and per-player caps, Crown placement limit, cash)
    - `src/server/Services/TowerService.luau` (place / upgrade incl. U4 branch choice / sell / targeting mode)
    - Specs.
  - **Accept:**
    - Specs cover every rejection reason.
    - A Client-context `execute_luau` that fires the place remote with NaN position, a Hill unit on Ground, an off-map position, another player's unit ID and insufficient cash → each one rejected with a logged reason and unchanged state. A valid placement is accepted.

- [ ] **P1-09 Placement controller and match HUD** · deps: P1-07, P1-08
  - **Goal:** Pick and add the UI library first: Vide or Fusion. Confirm the Wally package name and version on wally.run, update `wally.toml`, and log the choice in DECISIONS.
  - **Create:**
    - `src/client/Controllers/PlacementController.luau` (hotbar of 6 slots; ghost model with range ring; green/red validity; upgrade/sell panel with A/B branch choice; targeting toggle)
    - `src/client/UI/MatchHud.luau` (Cash, wave, timer, Gate HP, skip vote with counter, 1×/2× speed, next-wave preview strip with attribute icons)
  - **Tools:** `user_mouse_input`, `user_keyboard_input`, `screen_capture`.
  - **Accept:** simulated input places Tarek on a Ground pad and upgrades him to U1. The screenshot shows the unit, the range ring and reduced Cash; the console is clean.

- [ ] **P1-10 Targeting and damage** · deps: P1-04, P1-08
  - **Create:**
    - `src/shared/Sim/Targeting.luau` (First/Last/Strongest/Closest; patterns Single/Circle/Cone/Line/Nova/Zone; flyer rules; Veiled detection from Lantern auras)
    - `src/shared/Sim/DamageCalc.luau` (the GDD §7.3 formula, caps from UnitConfig)
    - `src/server/Services/CombatService.luau` (10 Hz; server-side hits; VFX events to clients)
    - Specs.
  - **Accept:**
    - Specs: Veiled can't be a primary target without detection, but splash hits it; Half/Full/None flyer rules; Herald auras don't stack; discounts capped at 25%; crit chance capped at 75%; damage-taken capped at 40%.
    - Perf: 400 enemies × 40 units averages ≤ 2 ms per targeting step (`os.clock`, Server context).

- [ ] **P1-11 Prototype units** · deps: P1-10
  - **Goal:** Data-driven behavior for spice_caravan, tarek, rima, hadi, nadia, bassam, layla and qamar, including forks, auras, Merchant income, Lantern detection from U2, Breaker plates and shields, and Warden slow/stun.
  - **Create:** `src/server/Units/UnitRuntime.luau` plus per-mechanic modules.
  - **Accept:** a spec computes damage/SPA/range at every level and branch from UnitConfig and checks they apply in a sim run (DPS within 1% of damage/SPA). The screenshot shows each unit placed.

- [ ] **P1-12 Ability framework** · deps: P1-11
  - **Create:** `src/server/Services/AbilityService.luau` (server cooldowns; validated `UseAbility` remote) plus a client ability button. Implement Layla's *Nightwind Snare* and Qamar's *Rally*.
  - **Accept:** firing the remote 20 times in 1 s results in exactly 1 activation per cooldown. Snare stuns non-bosses for 3 s and slows bosses 20%; the screenshot shows the VFX placeholder.

- [ ] **P1-13 Enemy behaviors** · deps: P1-10
  - **Goal:** Hive split, Mender regen/heal (after 3 s unhit), Hexer stun (r15, 3 s every 10 s; Calm Air immunity), Lantern-Eater snuff, Thornback shed at 50%.
  - **Accept:** a spec for each behavior, plus a playtest wave 18 log line showing 3 Hives → 12 Couriers.

- [ ] **P1-14 Wilt Matron** · deps: P1-13
  - **Goal:** Phases at 66% and 33%; summons; a 15% shield; pulses with a telegraph (a server event carries the windup; the client draws the ring); untimed finale; boss bar with phase markers.
  - **Accept:**
    - Dev-damaging the Matron to 65% and then 32% logs phase entries with the correct summon counts (6 Wisp + 2 Brute; 4 Veiled + 2 Mender).
    - Units inside 18 studs are stunned 3 s after a 2 s windup.
    - The screenshot shows the telegraph ring.

- [ ] **P1-15 Dev tools and bot player (Studio only)** · deps: P1-12, P1-14
  - **Create:**
    - `src/server/Dev/DevCommands.luau` (spawn, setCash, godGate, skipToWave, timeScale, autoKill)
    - `src/server/Dev/BotPlayer.luau` (places and upgrades the `botLayout` from the map module on a schedule; never uses actives)
    - Both return immediately unless `RunService:IsStudio()`.
  - **Accept:** at timeScale 3:
    1. The bot clears W1 **Act 3** Normal (20 waves) with the reference loadout (Tarek ×3, Rima ×2, Old Hadi ×1, Nadia ×2, Bassam ×1, Spice Caravan ×3) with Gate HP ≥ 50.
    2. Without Old Hadi it loses at least 15 Gate HP to Veiled by wave 8.
    3. Without Bassam, Ironbound leaks at wave 17.

    Runs 2 and 3 prove the attribute checks. Record the results in the commit.

- [ ] **P1-16 Co-op verification** · deps: P1-15
  - **Goal:** 2–4 player rules end to end.
  - **Tools:** check `docs/TOOLS.md` for whether `start_stop_play` supports multi-client. If not, STOP and ask the user to start **Test → Clients and Servers** with 2 players (or to approve installing the optional third-party `Chrrxs/robloxstudio-mcp` fork, which has `multiplayer_playtest`).
  - **Accept:** with 2 clients:
    - both receive equal kill and wave Cash;
    - Merchant income goes only to its owner;
    - vote skip needs 1 of 2 votes with one player AFK;
    - a client killed with `Players:Kick` in a test rejoins within 90 s and keeps their units (or the unit test covers this when a rejoin isn't possible in Studio).

- [ ] **P1-17 Blender: World 1 map kit, pass 1** · deps: P0-08, P1-02
  - **Goal:** Modular kit:
    - path straight/corner/U-turn tiles, ground pad, hill plateau
    - souq stall, lantern post, awning, archway, crates, jasmine vine
    - Garden Gate (≤ 8k tris) and spawn portal
    - every other piece ≤ 2k tris
    - one 1024² trim-sheet texture
  - **Create:** `assets/blender/maps/W1_kit.blend`, exports, `tools/studio/build_w1_art.luau` (replaces blockout visuals and **keeps the tags and waypoints**), `AssetIds.luau` entries.
  - **Accept:** a beauty screenshot plus a top-down screenshot; the P1-02 tag counts are unchanged; the P1-03 waypoint export is identical.

- [ ] **P1-18 Blender: enemy models** · deps: P0-08
  - **Goal:**
    - 10 archetypes at 1.5–4k tris and 3 bosses at ≤ 12k tris
    - 512² textures (bosses 1024²)
    - static meshes with a pivot at the feet
    - client-side procedural motion (bob, sway, wing flap via CFrame); rigs come in P2-19
  - **Accept:** Blender prints tri counts within budget for every model; a Studio screenshot shows the lineup; `EnemyRenderer` uses the real models.

- [ ] **P1-19 Blender: prototype unit models** · deps: P0-08
  - **Goal:** 8 prototype units at 3–8k tris and 1024², static pose, original designs per GDD §2. Each has a front/side `look` sheet before export.
  - **Accept:** tri budgets pass; the Studio screenshot of all 8 placed on the map reads clearly from the default camera.

- [ ] **P1-20 Performance gate** · deps: P1-15, P1-18
  - **Goal:** 400 enemies plus 40 units.
  - **Tools:** `execute_luau` (Server: EnemySim step time via `os.clock`; Client: average frame time over 5 s from `RunService.RenderStepped`), the `skill` tool for device simulation if available.
  - **Accept:**
    - Server sim step ≤ 4 ms average and ≤ 8 ms p95.
    - Client ≥ 30 FPS with device emulation for a mid-range phone; if the MCP can't emulate a device, STOP and ask the user to check with Studio's Device Emulator.
    - Every unreliable packet ≤ 900 bytes.
    - Log the numbers in DECISIONS.

- [ ] **P1-21 Prototype playtest** · deps: P1-16, P1-20 · STOP
  - **Goal:** The user runs a blind playtest with 3–5 people.
  - **Create:** `docs/playtests/P1.md` (test script, 6 questions, a table for replay intent).
  - **Accept:** the user reports results. Exit when testers choose to replay. File fixes as new tasks.

---

## Phase 2: Vertical slice: meta systems (weeks 9–14)

- [ ] **P2-01 Place roles** · deps: P1-21 · STOP
  - **Goal:** The user adds a Match place to the same universe (Asset Manager → Places) and gives both place IDs.
  - **Create:** `src/shared/Config/PlaceConfig.luau` (`{Lobby = id, Match = id}`; role `"Dev"` whenever `RunService:IsStudio()` with a Studio-only override attribute); `src/server/Bootstrap.luau` starts the services for the role. Dev runs lobby and match services together.
  - **Accept:** in Studio the Dev role boots both service sets; a spec covers role resolution.

- [ ] **P2-02 Player data (ProfileStore)** · deps: P2-01
  - **Goal:** Resolve the wally.toml TODO: vendor `src/server/Vendor/ProfileStore.luau` with its license header (log it in LICENSES and DECISIONS) unless a verified Wally package exists.
  - **Create:** `src/server/Services/PlayerData.luau` and `src/shared/Types/ProfileSchema.luau` (v1). The schema holds:
    - versioned currencies with **paid/earned** splits for Gems, Trait Seeds and Cores;
    - GUID unit records: unitId, level, xp, bloom, trait, per-trait pity, grades, potentialTakedowns, takedowns, evolved, shiny, paidOrigin, locked;
    - pity groups, account level/XP, quests, receipts (bounded), codesRedeemed, settings and tutorialDone.

    Migrations are pure functions.
  - **Accept:** specs: v0→v1 migration; a duplicate GUID is detected and refused; the 300-unit cap is enforced. In Studio, data persists across two playtests (API access on), and a second session for the same user is refused while the lock is held.

- [ ] **P2-03 Ledger and audit log** · deps: P2-02
  - **Create:** `src/server/Services/Ledger.luau`, the single path for every grant and spend. It takes an idempotency key, keeps paid/earned balances and the earned-first spend order, and records `paidOrigin`. Plus `src/server/Services/AuditLog.luau` (batched DataStore writes within budget: `300 + 20 × CCU` writes/min).
  - **Accept:** specs: a repeated idempotency key is a no-op; a restricted-mode spend uses earned balances only; overdrafts are impossible.

- [ ] **P2-04 Lobby blockout** · deps: P0-05
  - **Create:** `tools/studio/build_lobby.luau` (the Courtyard and every station from GDD §4) and `src/server/Services/LobbyStations.luau` (ProximityPrompts, created by code, open the UIs).
  - **Accept:** the screenshot shows all stations; each prompt opens its placeholder UI with simulated input.

- [ ] **P2-05 Matchmaking and teleport** · deps: P2-01, P2-04
  - **Create:** `src/server/Services/Matchmaking.luau`:
    - pads form parties of 1–4;
    - MemoryStore hash-map ticket `{mode, world, act, difficulty, userIds}` with a 300 s TTL;
    - `TeleportAsync(matchPlaceId, players, TeleportOptions{ShouldReserveServer = true})` with **only the ticket ID** in teleport data;
    - 3 retries on `TeleportInitFailed`.

    On the match server: `MatchBoot.luau` reads the ticket, validates it against the Config allowlist and the expected user IDs, and kicks mismatches.
  - **Accept:** specs: ticket validation and allowlist. Live test: STOP — the user publishes and plays a 2-person queue in the live client; the agent supplies the checklist.

- [ ] **P2-06 Match results** · deps: P2-05, P2-03
  - **Goal:** Server-computed rewards per GDD §15.2 (first clear, repeat, Nightmare ×1.5, defeat 50%) granted through the Ledger. Create the remaining economy numbers as `src/shared/Config/EconomyConfig.luau`, mirroring GDD §15–16.
  - **Accept:** specs reproduce the GDD reward table for Acts 1 and 6.

- [ ] **P2-07 SummonService** · deps: P2-03
  - **Goal:** RNG from SummonConfig:
    - pity counters and groups; the Slot-10 table; featured 50/50 and its guarantee;
    - 4-hour rotation keyed by the UTC window; Moon Sigils and the spark purchase; shiny with level gate and Shiny Charm;
    - Tutorial banner; audit log entries.
  - **Accept (specs):**
    - pity triggers exactly on pulls 40 and 300;
    - counters reset per the rules;
    - the guarantee follows a lost 50/50;
    - level gates hold;
    - restricted players can't spend paid Gems.

- [ ] **P2-08 Odds tables and View Odds UI** · deps: P2-07
  - **Create:** `src/shared/Sim/OddsTable.luau` (per-unit split with largest-remainder at 1 ppm; Slot-10, shiny, interpolated stat-grade and trait tables) and `src/client/UI/OddsPanel.luau` (labeled "View Odds" button; shown before purchase; live pity counters, guarantee state, Sigils).
  - **Accept (specs):**
    - every generated table sums to exactly 1,000,000 ppm for every banner/rotation/state combination;
    - the 1,000,000-pull sim with pity disabled matches each rarity rate within 4σ;
    - with pity enabled, no gap exceeds 40/300.
    - Screenshot of the panel.

- [ ] **P2-09 PolicyService gating** · deps: P2-07, P2-08
  - **Goal:** `GetPolicyInfoForPlayerAsync` on join (pcall, 3 retries, treat as restricted on failure) with the restricted-path behavior from GDD §20.3/4. Add a Studio-only override attribute to force each path.
  - **Accept:**
    - Specs for both paths.
    - Screenshots of the restricted summon UI (earned-only balance shown, Shiny Charm hidden).
    - STOP: the user verifies in **Player Emulator** for Australia, Belgium, the Netherlands, the UK and Brazil and reports pass/fail per market.

- [ ] **P2-10 Trait rerolls (Seed Shrine)** · deps: P2-03, P2-08
  - **Goal:** RNG from TraitConfig; per-unit pity; auto-reroll with "stop at or above"; Crown placement limit wired into PlacementRules.
  - **Accept:** specs: pity at 200/480/1500; the rarest wins on a simultaneous trigger; the stop rule never overwrites. UI screenshot with the odds table.

- [ ] **P2-11 Stat grades (Grade Loom)** · deps: P2-03, P2-08
  - **Goal:** Grades, uniform values, potential from takedowns, interpolated odds, Stat/Focus Cores.
  - **Accept:** specs: odds at p = 0, 0.5 and 1 equal the GDD interpolation and sum to 1,000,000; potential resets on roll.

- [ ] **P2-12 Inventory, loadout and presets** · deps: P2-02
  - **Goal:** Inventory UI (filter/sort), 6-slot loadout, 2 presets (+3 with the pass), auto-sell rules (never shinies, evolved units or rank-5+ traits), storage 150/200/300.
  - **Accept:** UI screenshots; auto-sell specs.

- [ ] **P2-13 Unit level, Train and Bloom** · deps: P2-06, P2-12
  - **Accept:** specs: XP curve `50 × L^1.5`; level cap 50; Bloom costs; duplicates beyond Bloom 5 → Exchange Tokens.

- [ ] **P2-14 Remaining roster units** · deps: P1-12
  - **Goal:** silk_bazaar (Market Day), saif, dalia and yasmin, with actives and ultimates: charge rules, flourish camera (skippable after first view), Zone pattern, pushback.
  - **Accept:** specs per mechanic; the ultimate charge reaches 100 after ≈67 hits; screenshots of each ultimate's VFX placeholder.

- [ ] **P2-15 Evolution** · deps: P2-13, P2-14
  - **Goal:** Saif and Dalia evolution: Relic drops (10% from W1/W2 Nightmare Act 6), Essence, Gold, 1,000-takedown quest, model swap, added passive, ultimate upgrade.
  - **Accept:** specs; a before/after screenshot.

- [ ] **P2-16 Account level, gates and quests** · deps: P2-06
  - **Goal:** XP curve and the gates from GDD §16; 4 dailies and 5 weeklies (UTC resets); evolution guides.
  - **Accept:** specs: a gate blocks below its level; resets are correct across a UTC boundary (inject the clock).

- [ ] **P2-17 Onboarding and analytics funnel** · deps: P2-05, P2-07
  - **Goal:** First-session flow from GDD §4 with funnel events. Verify the AnalyticsService method names with the `http_get` docs tool before use.
  - **Accept:** in Studio, the steps up to the teleport complete in ≤ 25 s with simulated input. The live median ≤ 60 s is measured in P2-22.

- [ ] **P2-18 Monetization plumbing** · deps: P2-03 · STOP
  - **Create:**
    - `src/shared/Config/MonetizationConfig.luau` (keys from GDD §18 → IDs, all `nil` until the user supplies them)
    - `src/server/Services/Receipts.luau` (`ProcessReceipt`, idempotent via the profile receipt record; grants through the Ledger to **paid** balances)
    - pass ownership cache
    - Shop UI that reads prices with `GetProductInfo`
  - **STOP:** the user creates the passes and products in the Creator Dashboard at the GDD target tiers and pastes the IDs. The agent never sets prices.
  - **Accept:** specs: duplicate receipt → no double grant; no hard-coded price exists in `src/` (`grep -rni robux src` finds only comments; every displayed price comes from `GetProductInfo`).

- [ ] **P2-19 Blender: rigging pipeline** · deps: P1-19
  - **Goal:** Armatures for 12 units and 10 enemies:
    - root at the origin; bones with scale 1 and rotation 0; no weights on the root; ≤ 4 influences per vertex
    - export the rig FBX
    - import via the Studio 3D Importer (bulk import doesn't support rigged meshes); STOP if a human click is needed — batch all rigs into one request
    - enemies animate through AnimationController + Animator (no Humanoids)
  - **Accept:** `inspect_instance` shows Bone instances; a rig poses correctly in a screenshot.

- [ ] **P2-20 Blender: animations** · deps: P2-19
  - **Goal:**
    - Units: idle, place and attack, plus ability for Legendary+.
    - Enemies: walk and death (2–3 frame-light loops).
    - One animation per FBX (`bake_anim=True`); named `HY_Anim_<Unit>_<Action>`.
    - The FBX animation import and **Publish to Roblox** are Studio UI steps: STOP once per batch for the user to publish (or, if `docs/TOOLS.md` shows a scriptable path, use it).
    - Store the IDs in `AssetIds.luau`.
    - The client skips animation beyond 120 studs (**TUNE**).
  - **Accept:** the screenshot sequence shows attack anims playing; client frame time stays within the P1-20 budget.

- [ ] **P2-21 VFX textures** · deps: P0-06
  - **Goal:** Blender-baked 256–512² PNG sprites and flipbooks with alpha: petal burst, slash arc, light ring, telegraph ring, shield shimmer, burn embers, moonlight aura. Upload them, then `src/client/VFX/VfxLibrary.luau` builds ParticleEmitters/Beams from code.
  - **Accept:** screenshots of each effect in a playtest; no VFX is server-created.

- [ ] **P2-22 Vertical slice gate** · deps: all P2 · STOP
  - **Accept:**
    - The bot clears W1 Acts 1–6 Normal.
    - P2-08 sim specs are green.
    - Player Emulator passes in all 5 markets (P2-09).
    - Live onboarding median ≤ 60 s from 10 test joins (user-run).

---

## Phase 3: Content alpha (weeks 15–20)

- [ ] **P3-01 Worlds 2–4: maps** · deps: P2-22
  - **Goal:** For W2 "Rose-Water Canals", W3 "Minaret Rooftops" and W4 "Orchard of Ash", repeat P1-02 → P1-03 → P1-17 per world (blockout script, map data module, Blender kit). Each world needs a distinct lane shape: canal bridges and water lanes, vertical rooftop hills, orchard forks.
  - **Accept:** per world: path 330–420 studs; tag counts; screenshots.

- [ ] **P3-02 Worlds 2–4: waves and bosses** · deps: P3-01
  - **Goal:** Design first, then data.
    1. Add a GDD appendix with 3 new final bosses (original names; IP check), each with a distinct board-attack mechanic and 3 phases.
    2. Write 30-wave templates following the §13.3 pacing rules into `WaveConfig.Worlds.W2..W4` and the enemies into `EnemyConfig`.
  - **Accept:** `Validate` passes; the bot clears each world's Act 3 Normal with a reasonable loadout and fails without each attribute counter (as in P1-15).

- [ ] **P3-03 Nightmare difficulty** · deps: P3-02
  - **Accept:** specs: ×2 HP and Fortified shields ×2; it unlocks after that world's Normal Act 6; Essence drops 2 per clear.

- [ ] **P3-04 Infinite mode and leaderboard** · deps: P3-02
  - **Goal:** Waves past 30 cycle template waves 21–29 with +5% count per wave, the frozen wave factor and ×1.06^(w−30); Gem milestones (30 per 5 waves, max 600); a weekly OrderedDataStore leaderboard.
  - **Accept:** specs: HP matches `computeHp` with `lastAuthoredWave = 30`; leaderboard writes are rate-limited.

- [ ] **P3-05 Trials** · deps: P3-02
  - **Goal:** The 8 modifiers; 30-min/daily/weekly rotations keyed by the UTC window; caps (20/day); Seeds 1/3/20 (+20 Gems per 30-min run); weekend doubling for 30-min and daily.
  - **Accept:** specs per modifier and per cap; a playtest of 2 modifiers.

- [ ] **P3-06 Raid: The Sunken Cistern** · deps: P3-02
  - **Goal:** 6 stages × 20 waves; mini-boss at 10 and boss at 20; HP × (1.5 + 0.25n); Raid Sigils; Raid shop from GDD §6.
  - **Accept:** the bot clears stage 1; shop purchase specs (weekly Relic cap).

- [ ] **P3-07 Boss Bounty** · deps: P3-02
  - **Goal:** Daily world-boss rotation, a 5-minute limit, 1 Seed + 30 Gems each, cap 10/day.
  - **Accept:** specs; the timer-fail path works.

- [ ] **P3-08 Roster to launch size** · deps: P2-14
  - **Goal:** 8 Rare, 8 Epic, 8 Legendary and 5 Mythic in the standard pool, plus the Limited Secret, plus the S1 battle-pass Legendary.
    1. Write a design table into a GDD appendix: original names; roles balanced so every attribute check has ≥ 2 counters per rarity band.
    2. Pause for the user's review of names and themes (STOP, a single review).
    3. Then add Config and models (reuse the P1-19/P2-19/P2-20 pipeline).
  - **Accept:** `Validate` passes; the odds-table spec covers the new pool sizes; tri budgets hold.

- [ ] **P3-09 Battle pass S1** · deps: P2-16, P2-18, P3-08
  - **Goal:** 50 levels × 1,000 Pass XP over 6 weeks; free and premium tracks per GDD §17; premium via `BP_PREMIUM`; season dates in Config.
  - **Accept:** specs: XP from sources; reward claims are idempotent.

- [ ] **P3-10 Exchange, shops and codes** · deps: P2-03
  - **Goal:** Exchange selectors (60/300/1,500 Tokens), cosmetics, storage purchases. `CodesService`: codes live server-side only (`src/server/Config/Codes.luau`), with a level gate ≥ 5, expiry, one redemption per account, and amounts of 1,000–3,000 Gems + 10–50 Seeds.
  - **Accept:** specs; brute-forcing codes is rate-limited.

- [ ] **P3-11 Auto Play and layout codes** · deps: P1-15
  - **Goal:** Promote the bot logic to a player feature: the player picks an anchor; it places and upgrades their loadout and **never** fires actives. Layout export/import is a compact base64 string, validated server-side like any placement.
  - **Accept:** specs: a malformed code is rejected; Auto Play clears W1 Act 1.

- [ ] **P3-12 Analytics** · deps: P2-17
  - **Goal:** Economy source/sink events per currency, progression events, and custom events for mode starts and clears. Verify the method names via docs first.
  - **Accept:** events visible in Studio output during a playtest. The user confirms the dashboard shows them after a live test.

- [ ] **P3-13 Audio** · deps: P1-07
  - **Goal:** The 4 music bands from WaveConfig plus core SFX, using Roblox-licensed Creator Store audio (`search_asset`/`insert_asset`) or user-supplied tracks; every entry recorded in LICENSES.
  - **Accept:** music changes at waves 10/20/27 in a playtest log.

- [ ] **P3-14 Mobile UI pass** · deps: P3-09, P3-10
  - **Goal:** Touch targets ≥ 44 px; safe areas; portrait-proof modals.
  - **Accept:** screenshots at phone and tablet resolutions via device simulation (or STOP for a user check).

- [ ] **P3-15 Red-team pass** · deps: P3-05..P3-11
  - **Create:** `src/server/Dev/RemoteFuzz.luau` (Studio only): every remote, 1,000 fuzzed calls each from a Client context (random types, NaN/inf, huge strings, other players' IDs, replayed receipts and ticket IDs).
  - **Accept:**
    - 0 state changes from invalid calls (profile checksum unchanged) and rate limits trip.
    - A two-session ProfileStore lock test refuses the second session.
    - Teleport-data tampering is rejected.
    - Write the findings to `docs/security/redteam-P3.md`.

- [ ] **P3-16 Closed test** · deps: P3-15 · STOP
  - **Goal:** The user invites 100–300 testers. The agent prepares the build checklist, a known-issues list and the telemetry queries.
  - **Accept:** the user reports; issues become tasks.

---

## Phase 4: Beta / soft launch (weeks 21–24)

- [ ] **P4-01 Production build project** · deps: P3-16
  - **Create:** `build.project.json`, the same tree minus `DevPackages`, with `globIgnorePaths` for `**/*.spec.luau`, `**/Dev/**` and `**/Tests/**`.
  - **Accept:** `rojo build build.project.json -o build/prod.rbxl` succeeds, and a script scan of the output finds no `.spec`, `Dev` or `Tests` instances.

- [ ] **P4-02 Maturity questionnaire draft** · deps: P3-16 · STOP
  - **Goal:** Draft answers targeting **Mild** (stylized combat, no blood, no chat dependence) in `docs/compliance/maturity.md`. The user submits them.

- [ ] **P4-03 Thumbnails and icon** · deps: P3-01, P3-08
  - **Goal:** 5 thumbnails at 1920×1080 (staged scenes via `screen_capture` with set camera positions, or Blender `look` renders) and a 512×512 icon, all in the original art style with no text-heavy layouts.
  - **Accept:** files in `assets/marketing/`. STOP: the user uploads them (thumbnail personalization tests up to 5).

- [ ] **P4-04 Mobile performance pass** · deps: P3-14
  - **Goal:** 400 enemies on an emulated mid-range phone: LOD (skip animations beyond 120 studs; hide health bars beyond 80); part and texture memory budget.
  - **Accept:** P1-20 numbers re-measured and logged.

- [ ] **P4-05 Backups and rollback drill** · deps: P2-03
  - **Create:** `src/server/Admin/Restore.luau` (restore a profile version by timestamp via DataStore versions; replay the audit log) and a runbook in `docs/ops/rollback.md`.
  - **Accept:** a drill on a test account restores state exactly.

- [ ] **P4-06 Error telemetry** · deps: P3-12
  - **Goal:** Hook `LogService.MessageOut` on the server to count errors by message hash, flush to analytics custom events every 60 s, and add a dashboard query.
  - **Accept:** a forced error appears in the counts.

- [ ] **P4-07 Rewarded video** · deps: P2-18 · STOP
  - **Goal:** Once the experience has 2,000+ monthly unique visitors, the user enables rewarded video. The reward is the `AD_TICKET` developer product (1 Summon Ticket/day; restricted players are allowed because tickets aren't paid).
  - **Accept:** specs for the daily cap.

- [ ] **P4-08 Jasmine Club subscription** · deps: P2-18 · STOP
  - **Goal:** The user creates the subscription. The agent implements a daily claim of 300 Gems + 2 Seeds to the **paid** balances.
  - **Accept:** specs.

- [ ] **P4-09 Ads and Discord** · deps: P4-03 · STOP
  - **Goal:** The agent drafts ad copy, the Discord channel plan, the code-drop schedule and the launch codes. The user runs a small Ads Manager test and opens the Discord.

- [ ] **P4-10 Onboarding iteration** · deps: P4-06
  - **Goal:** Fix the largest funnel drop each week (one change at a time, logged in DECISIONS).
  - **Accept:** bounce < 60 s and D1/D7 trend up week over week. STOP before scaling ads.

---

## Phase 5: Launch (weeks 25–26)

- [ ] **P5-01 Launch audit** · deps: P4-*
  - **Create:** `docs/LAUNCH_AUDIT.md` with pass/fail evidence for:
    - all specs green; odds sims green; Player Emulator 5/5
    - no hard-coded prices (grep); runtime prices displayed
    - `assets/LICENSES.md` complete; IP name review of every unit, enemy and boss
    - remote fuzz clean; backups drilled; production build excludes dev code
    - maturity submitted
  - **Accept:** every line passes or carries a user-approved waiver.

- [ ] **P5-02 Update 1 at ~80%** · deps: P3-*
  - **Goal:** On branch `update/1`, build Legend Stages and World 5 "Saffron Docks" (see P6-U1).

- [ ] **P5-03 Publish** · deps: P5-01 · STOP
  - **Goal:** The user publishes `build.project.json`'s output, sets the experience public, and sets the title, description and genre. The agent provides the exact text.

- [ ] **P5-04 Launch-weekend watch** · deps: P5-03
  - **Goal:** Every 2 hours, check error telemetry and economy anomalies (Gem/Seed source spikes, duplicate GUID alerts). Hotfixes go on `hotfix/*` branches with tests; STOP for the user to publish.

- [ ] **P5-05 Milestone codes** · deps: P5-03
  - **Goal:** Pre-write like/favorite milestone codes (1,000–3,000 Gems + 10–50 Seeds) with expiry; activate them on the user's go.

---

## Phase 6: Live ops (month 7+)

### Update template (every update)

Each update ships:
- a new banner (Limited and/or Featured pool addition)
- an event currency and event shop
- one mode or world
- 2–4 codes
- a title tag (`[UPD n] Haret Al Yasmin`)
- balance notes in `docs/patch-notes/U<n>.md`
- a Part 2 two weeks later

Before shipping: P5-01 audit lines re-run (odds, policy, prices, licenses), and every new power axis is added to GDD §21 with its cap.

- [ ] **P6-U1-01 Legend Stages** · deps: P5-02
  - **Goal:** Remixed W1–W4 stages at Legend difficulty (×3, Fortified); unlock after a world's Nightmare Act 6; Relic and Essence drops.
  - **Accept:** the bot clears one Legend stage with an evolved loadout; drop specs.
- [ ] **P6-U1-02 World 5 "Saffron Docks"** · deps: P5-02
  - **Goal:** Map kit plus waves plus final boss (pipeline P3-01/P3-02); world HP ×6.0.
- [ ] **P6-U1-03 Update 1 Mythic and event** · deps: P6-U1-02
  - **Goal:** One new Mythic (design → user name review → Config → model); event "Saffron Tide" with Saffron Threads, an event shop and an event banner at 150 Threads per pull (a Paid Random Item if Threads are ever sold, so disclose odds anyway).
- [ ] **P6-U1-04 Ship U1 and Part 2** · deps: P6-U1-01..03 · STOP (publish)

- [ ] **P6-U2-01 Bazaar Dungeons** · deps: P6-U1-04
  - **Goal:** 30 waves; pick 1 of 3 roguelite cards every 5 waves (design a 24-card pool, capped effects); Dungeon Tokens.
- [ ] **P6-U2-02 Divine Seeds and second trait slot** · deps: P6-U1-04
  - **Goal:** `TraitConfig.SecondSlot.enabled = true`. The second slot rolls from the same table, excluding Crown (**TUNE**). Odds UI per slot. Declare the cap in GDD §21.
- [ ] **P6-U2-03 Charms (equipment)** · deps: P6-U2-01
  - **Goal:** One Charm slot per unit; flat Damage/Range plus a minor passive; bought with Dungeon Tokens. Declare the cap in GDD §21.
- [ ] **P6-U2-04 Limited S2 and ship** · deps: P6-U2-01..03 · STOP (publish)

- [ ] **P6-U3-01 Minaret Climb** · deps: P6-U2-04
  - **Goal:** A 50-floor ladder whose rewards loop after floor 50; bulk Seeds and Stat Cores; a seasonal leaderboard.
- [ ] **P6-U3-02 Night Bloom Rifts** · deps: P6-U2-04
  - **Goal:** A hub event every ~60 min at the Rift Circle; up to 6 players; MVP 2× rewards when 3+ join; Night Petals event currency.
- [ ] **P6-U3-03 Ship U3 and Part 2** · deps: P6-U3-01..02 · STOP (publish)

- [ ] **P6-U4 Boss Event** · 5 Normal tiers → Elite (+100% HP, pulse 1.5× more often), a 20-wave limit per tier, exclusive cosmetics, leaderboard.
- [ ] **P6-U5 Trading and Fair-Play Arena** · trading rules from GDD §18 (Lv50, escrow, resets, untradeable limiteds, the `paidOrigin` gate) plus the Arena with traits and grades disabled. STOP: legal review of the trading rules before shipping.
- [ ] **P6-U6 Garden Idle** · AFK zone with a roll every 15 min; Gold plus a low-odds AFK-exclusive unit (disclose odds).

---

## Asset pipeline reference (all Blender tasks)

| Asset | Tris (hard cap 20,000 per mesh) | Texture | Notes |
|---|---|---|---|
| Unit | 3,000–8,000 | 1024² | front/side `look` sheet before export; evolved model is a separate file |
| Enemy | 1,500–4,000 | 512² | pivot at the feet; no Humanoid |
| Boss | ≤ 12,000 | 1024² | phase VFX attachment points named `_Att` |
| Map prop | ≤ 2,000 | trim sheet 1024² | modular; snap to a 2-stud grid |
| Hero map piece (gate, portal) | ≤ 8,000 | 1024² | – |
| VFX sprite / flipbook | – | 256–512² PNG with alpha | – |

**Every export:**
- Scene Unit System **None**.
- Apply transforms; watertight geometry; quads preferred; no n-gons.
- One UV set within 0–1.
- Rigs: root at the origin; bones with scale 1 and rotation 0; ≤ 4 influences per vertex; no weights on the root.
- FBX: **Path Mode Copy + Embed Textures, Apply Scalings = FBX Unit Scale, Add Leaf Bones off, Bake Animation off** (on only for animation files), **one animation per FBX**.
- glTF/GLB needs no scale settings.
- Studio Importer: Scale Unit **Stud**, "Insert Using Scene Position" on.
- Upload ≤ 20 MB via Open Cloud. Animations generally need a Studio publish step.
- After `insert_asset`, delete any Script descendants, then verify with `inspect_instance` and `screen_capture`.
- Every non-self-made source gets a row in `assets/LICENSES.md`. AI-generated meshes (`generate_3d`, `generate_mesh`) record provider and prompt and are reviewed against GDD §2 before use.

---

## Kickoff prompts (paste into Claude Code after `/model fable`)

**Phase 0**
> Read CLAUDE.md, docs/GAME_DESIGN.md and docs/BUILD_PLAN.md fully. We're starting Phase 0. I have completed U0-1 to U0-11 except: [list or "none"]. First inventory the real MCP tools (P0-01) and fix any tool names in CLAUDE.md that differ. Then work through P0-02 to P0-09 in order with the verify loop, committing after each task and ticking it in BUILD_PLAN. Stop and ask me for anything on the Stop-and-ask list (API keys, saving the place, legal). When the Phase 0 exit criteria are met, give me the evidence and wait.

**Phase 1**
> Phase 0 is done. Start Phase 1 of docs/BUILD_PLAN.md. Pick tasks in dependency order, one at a time, with the full verify loop (specs, playtest, console, screenshot) and a commit per task. Every remote must be validated and rate-limited, and every number must come from src/shared/Config. Batch any request that needs my clicks (saving the place, multi-client test) into one message. Stop at P1-21 and prepare the playtest script.

**Phase 2**
> Start Phase 2 (vertical slice). Before P2-01, tell me exactly what to create in the Creator Dashboard (second place, API access) and wait. Treat SummonConfig/TraitConfig/StatGradeConfig as the only source of odds; the odds UI must be generated, never typed. Never create or price products yourself: list the products from GDD §18 that I need to create, and wait for the IDs. Stop at P2-09 for my Player Emulator check and at P2-22 for the gate review.

**Phase 3**
> Start Phase 3 (content alpha). For every new character, boss or world, first add a design appendix to the GDD with original names and a one-line IP check, then pause once for my review before building. Keep World 2–4 pacing consistent with GDD §13.3. Run the red-team pass (P3-15) before asking me to start the closed test.

**Phase 4**
> Start Phase 4 (beta). Build the production project first (P4-01) and prove dev code is excluded. Draft the maturity answers, thumbnails, ad copy and Discord plan for my review; don't submit or publish anything. Each week, pick the single largest onboarding funnel drop to fix, and log it in DECISIONS.

**Phase 5**
> Start Phase 5. Produce docs/LAUNCH_AUDIT.md with evidence for every line (P5-01), then give me the exact publish steps and store text. While I publish, continue Update 1 on branch update/1. During launch weekend, check telemetry every 2 hours and propose hotfixes on hotfix/* branches; I publish.

**Phase 6, per update**
> Start Update [n] from Phase 6 of docs/BUILD_PLAN.md using the update template. Draft the patch notes and a codes list first. Re-run the launch-audit checks for odds, policy, prices and licenses before asking me to publish. Declare a cap in GDD §21 for any new power axis.

**Long autonomous session (safety wrapper; prepend to any phase prompt)**
> You may work autonomously for this session. Rules:
> 1. Before starting, run `git status` and make sure the tree is clean. Ask me to save the Studio place and the open .blend, and confirm `rojo serve` is connected.
> 2. One BUILD_PLAN task at a time. Commit after every task (format `P<phase>-<nn>: <summary>` plus verification evidence), and tick the task. Never batch several tasks into one commit.
> 3. Checkpoint every 3 tasks or 60 minutes: post a 5-line status (done, evidence, next, blockers, anything you need from me), and ask me to save the place if Studio-owned content changed.
> 4. If the same failure persists after 3 fix attempts, mark the task `[!]` with the error and move to the next unblocked task. Don't thrash.
> 5. Never: spend or price Robux, create products or passes, publish or change place or universe settings, submit questionnaires, make legal or IP-clearance calls, handle API keys, delete Studio content you didn't create, push to a remote, rewrite git history, or edit Rojo-managed scripts through MCP. Collect these into one "needs you" list and stop when only such items remain.
> 6. Save the .blend before every `execute_blender_code` that changes geometry. Use `BLENDER_MCP_SAFE_MODE=1` for review-only Blender sessions.
> 7. Stop when the phase exit criteria are met, or when only blocked or "needs you" items remain, and summarize.
