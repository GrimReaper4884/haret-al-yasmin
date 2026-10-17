# CLAUDE.md: Haret Al Yasmin

Original-IP, anime-style co-op tower defense for Roblox. Setting: **Haret Al Yasmin, "the Jasmine Quarter"**, a night-blooming city district whose guardians hold its lanes against **the Wilt**. Design: a server-authoritative TD core (attribute-checked enemies, fair co-op cash) under a gacha meta (summons, traits, stat grades, Bloom, evolution) with bounded pity and Roblox paid-random-item compliance.

| File | Purpose |
|---|---|
| `docs/BUILD_PLAN.md` | Your work queue: phases, tasks, acceptance criteria, kickoff prompts |
| `docs/GAME_DESIGN.md` | Every design number. Mirrors `src/shared/Config/*.luau`; Config wins at runtime; change both in one commit |
| `docs/DECISIONS.md` | Dated log of every TUNE change and design deviation (create it in P0-09) |
| `docs/TOOLS.md` | The MCP tool surface as observed on this machine (create it in P0-01) |
| `assets/LICENSES.md` | Attribution and provenance for every non-self-made asset |
| `reports/…blueprint.md` | Research background. Don't re-research what it covers |

You run on the user's **Windows or macOS** machine: Roblox Studio is open with "Studio as MCP server" enabled, Blender runs the MCP addon, and `rojo serve` is connected to Studio.

## Session start (every session)
1. `git status`: the tree must be clean (commit or ask). Read BUILD_PLAN statuses and DECISIONS.
2. **List the MCP tools** (`/mcp` or tool search for `Roblox_Studio` / `blender`). The names below come from Roblox's and blender-mcp's docs (Oct 2026) and are **unverified on this build**. If a name or parameter differs, use what the server lists and update `docs/TOOLS.md` and this file.
3. Call `list_roblox_studios` and pass its `studio_id` to **every** Studio call. Confirm the place is "Haret Al Yasmin [DEV]".
4. Make sure `rojo serve` is running (start it in the background if not; port 34872) and Studio's Rojo plugin shows Connected. You can't click Connect yourself, so ask the user.
5. Blender (only when needed): `get_scene_info` responds. Save the .blend before any geometry change.

## Source of truth
| What | Owner | How to change it |
|---|---|---|
| All Luau: `src/server` → ServerScriptService, `src/client` → StarterPlayer.StarterPlayerScripts, `src/shared` → ReplicatedStorage.Shared | **Rojo + git** | Edit files on disk; Rojo syncs |
| Wally packages → ReplicatedStorage.Packages / DevPackages | `wally.toml` | `wally install` |
| Live DataModel: Workspace map geometry, ServerStorage.Maps, ReplicatedStorage.Assets, Lighting, SoundService | **Studio place** | Studio MCP. Prefer generator scripts in `tools/studio/*.luau` run via `execute_luau` (Edit) so results are reproducible from git |
| Art sources and export scripts | `assets/blender/`, `tools/blender/` | Blender MCP |
| Asset IDs | `src/shared/Config/AssetIds.luau` | code |

- **Never** `multi_edit` (or otherwise write) a script under a Rojo-managed path through MCP; Rojo overwrites it and git never sees it. Use `script_read` / `script_grep` only to confirm sync.
- **Never** create Script, LocalScript or ModuleScript instances through MCP anywhere. All code goes through Rojo. For one-off probes use `execute_luau`, which leaves no instance.
- Studio-owned changes persist only when the place is saved. Ask the user to save after you change them.

## MCP tools and when to use them
**Roblox_Studio** (built into Studio; every call takes `studio_id`):
- `list_roblox_studios`, `get_studio_state`: session start and before playtests.
- `search_game_tree`, `inspect_instance`: find and inspect live instances (verify sync, imported assets, tags).
- `script_read`, `script_grep`, `script_search`: read-only checks that Rojo synced your files.
- `multi_edit`: **only** for Studio-owned non-Rojo content, if ever. Requires `datamodel_type`. Never for code.
- `execute_luau` (`datamodel_type` Edit / Server / Client): run tests (Jest runner), dump map waypoints, build Studio-owned geometry from `tools/studio/*.luau`, measure perf, fire remotes from Client context for validation tests.
- `start_stop_play`, `get_console_output`, `screen_capture` (optional camera position/target): the playtest loop.
- `user_mouse_input`, `user_keyboard_input`, `character_navigation`: drive UI and characters in a playtest.
- `search_asset`, `insert_asset` (numeric asset ID), `upload_image` (HTTP URLs only), `store_image`: assets. After `insert_asset`, delete any Script descendants.
- `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished`: quick props and blockouts; log them in LICENSES.md as AI-generated.
- `subagent` (explore/playtest), `skill` (debugging, device simulation, docs search), `http_get` (Roblox docs URLs only): research engine APIs here instead of guessing.

**blender** (`uvx mcp-for-blender`, localhost:9876):
- `get_scene_info`, `get_addon_status`: state checks.
- `execute_blender_code`: modelling, decimation, UVs, baking, rigging, export. Load `tools/blender/hy_export.py` via `exec(open(path).read())`. Break big jobs into steps (timeouts).
- `look`: render and verify before every export (viewport, camera, multi-angle sheets, animation frames).
- `search_assets`, `import_asset`: Poly Haven (CC0, preferred), Sketchfab, Poly Pizza (mostly CC-BY, so log attribution).
- `generate_3d` (Tripo / Hunyuan3D / Rodin): concept meshes only; always decimate, re-UV and IP-check.

## Verify loop (every task)
1. Write or modify code **and** its `*.spec.luau`. Numbers come from `src/shared/Config`, never inline literals.
2. `stylua src` and `selene src` (or `tools/check.*`): fix everything.
3. Confirm sync: `script_grep` for a string you just added. If stale, check `rojo serve` and the plugin connection.
4. Tests: `execute_luau` (Edit) → `return require(game.ServerScriptService.Tests.TestRunner).run()` → 0 failures.
5. Playtest: `start_stop_play` (start) → drive with `execute_luau` (Server/Client) and `user_*_input` → `get_console_output` (no errors or warnings from our code; expected `[HY]` lines present) → `screen_capture` and actually look at it → `start_stop_play` (stop).
6. Fix and repeat until **every** Accept line of the task holds. Don't mark a task done on partial evidence.
7. Commit (format below), tick the task in BUILD_PLAN, and log TUNE changes in DECISIONS.

## Hard rules
- **Server-authoritative.** Clients send intents only (place unit X at P, upgrade id, sell id, choose branch, vote, use ability, summon, reroll). Never damage, enemy state, Cash, rewards or rolls.
- **Validate every remote** in `RemoteServer` middleware:
  - typeof checks; finite numbers; string length caps; enum membership against Config;
  - ownership; affordability; match phase;
  - a per-player token bucket.

  Reject and log `[HY][Reject] <remote> <userId> <reason>`. Ask: what if this fires 1,000×/s?
- **Odds = RNG config.** Displayed odds are generated from SummonConfig, TraitConfig and StatGradeConfig (ppm, largest-remainder, 4 decimals summing to exactly 100.0000%) behind a labeled "View Odds" button, shown before purchase and live-updated. Never type odds into UI.
- **PolicyService.** Call `GetPolicyInfoForPlayerAsync` on join (pcall + retry; on failure, restricted). If `ArePaidRandomItemsRestricted`, random outcomes spend **earned** balances only. If `IsPaidItemTradingAllowed` is false, `paidOrigin` units are untradeable. Never hard-code country lists.
- **Never hard-code Robux prices.** Config holds product keys → IDs; prices come from `MarketplaceService:GetProductInfo` at runtime.
- **Original IP only.** No real anime, manga or game names, characters, signature attacks, logos, silhouettes or ripped models; no parody spellings. Names in GDD §2 style; when unsure, ask.
- **Luau strict.** `--!strict` on line 1 of every file; export types; no `any` without a justifying comment.
- **Tests with Jest-Lua.** Every shared/pure module and every validator gets specs. Mandatory specs: odds sums, pity math, the 1M-pull sim, the wave HP curve, placement validation, receipt idempotency.
- **Data.** ProfileStore session locks; GUID unit records; paid vs earned balances; every grant or spend goes through `Ledger` with an idempotency key and an audit-log entry.
- **Caps.** Every power axis has a cap in GDD §21. Never add an uncapped multiplier.
- **Dev code** (`src/server/Dev`, `src/server/Tests`) is a no-op unless `RunService:IsStudio()`, and is excluded from `build.project.json`.
- **No secrets in git.** `ROBLOX_OPEN_CLOUD_KEY`, `ROBLOX_CREATOR_ID` and `BLENDERMCP_*` live in env vars only. Never print them.

## Asset rules
- **Budgets:** ≤ 20,000 tris per mesh (Roblox hard cap). Targets: units 3–8k, enemies 1.5–4k, bosses ≤ 12k, props ≤ 2k.
- **Geometry:** watertight, quads preferred, no n-gons, one UV set within 0–1. Textures PNG: 512² for enemies and props, 1024² for units, bosses and trim sheets.
- **Blender scene:** Unit System None (1 unit = 1 stud); apply transforms. Rigs: root at the origin, bones with scale 1 and rotation 0, ≤ 4 influences per vertex, no weights on the root.
- **FBX:** Path Mode Copy + Embed Textures, **Apply Scalings = FBX Unit Scale**, Add Leaf Bones **off**, Bake Animation off (on only for animation files), **one animation per FBX**. glTF needs no scale settings.
- **Studio Importer:** Scale Unit Stud, "Insert Using Scene Position" on. Upload via `tools/upload_asset.py` (Open Cloud, ≤ 20 MB) or ask the user to use the Importer.
- **Naming:** `HY_<Kind>_<Name>[_Evo]`, e.g. `HY_Enemy_Wisp`, `HY_Anim_Tarek_Attack`. Record IDs in `AssetIds.luau`.
- **Licenses:** CC0 preferred. Any CC-BY asset (most Poly Pizza) gets a row in `assets/LICENSES.md` (asset, author, URL, license, where used) **in the same commit**. AI-generated assets record provider and prompt.

## Commits
- One task per commit, on the current phase branch (`phase/<n>`; ask before merging to `main`).
- Subject: `P1-04: add server enemy simulation` (task ID + imperative, ≤ 72 chars).
- Body: what changed, then `Verified:` with the evidence (spec counts, key console lines, what the screenshot showed).
- Never commit secrets, `Packages/`, place binaries without LFS, or a red test suite. Don't push or rewrite history unless the user asks.

## Picking the next task
Open `docs/BUILD_PLAN.md` and take the first `[ ]` task whose deps are all `[x]`. Mark it `[~]`, do it, then mark it `[x] <hash>`. If you're blocked after 3 honest attempts, mark it `[!] <reason / what you need>` and take the next unblocked task. Design work (new units, bosses, worlds) goes into a GDD appendix and gets one user review before you build it.

## Stop and ask (never decide alone)
- Robux: prices, creating developer products, passes or subscriptions; Ads Manager spend.
- Publishing, making the experience public, changing place or universe settings, the maturity questionnaire.
- Legal: IP clearance of a name or asset, contributor contracts, interpreting paid-random-item or PolicyService rules, trading rules.
- API keys and credentials; installing third-party MCP servers or Studio plugins.
- Deleting or overwriting Studio content you didn't create; anything needing a human click (Rojo Connect, Player Emulator, animation publish, saving the place).

Batch these into one precise request, keep working on unblocked tasks, and stop when only "needs you" items remain.
