# MCP tool surface, as observed on this machine

Observed 2026-10-17 on the owner's Windows 11 PC from a local Claude Code session (v2.1.302).
This file records what the servers actually expose. Where a name differs from `CLAUDE.md`, this file wins.

## Servers (`claude mcp list`)

| Name | Scope | Command | Status |
|---|---|---|---|
| `Roblox_Studio` | user (`~/.claude.json`) | `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` (Studio's built-in StudioMCP) | Connected |
| `blender` | user | `C:\Users\teyam\.blender-mcp\venv\Scripts\blender-mcp.exe` (official Blender Lab server v1.0.3, talks to the "MCP" extension in Blender on localhost:9876) | Connected |
| `discord-feedback` | project (`.mcp.json`) | `python tools/discord/feedback_mcp.py` | Connected |
| `plugin:discord:discord` | plugin | bun | Connected |

Both Studio and Blender servers are stdio processes on this PC. They are not reachable from cloud sessions.
Studio must be open with **Assistant → … → Settings → MCP Servers → "Enable Studio as MCP server"** on, and
Blender must be running with the MCP extension started, or the tool calls time out.

## Observed state at inventory time

- `list_roblox_studios` → one instance: `Haret Al-Yasmin (TEST) (placeId: 120389740593436)`, id `86222389-fc57-45e7-823f-e0b656ce101f`. The place is named **(TEST)**, not "[DEV]".
- `get_studio_state` → Mode `Edit`; available DataModels `Edit` only (Client/Server appear during a playtest).
- Blender: `get_blendfile_summary_path_info` → unsaved default scene; `get_objects_summary` → Camera, Cube, Light. Blender 5.2 is installed.
- `rojo serve` is listening on port 34872 (Rojo 7.7.1, project `HaretAlYasmin`).

## Toolchain on PATH (`~/.rokit/bin`)

| Tool | Version |
|---|---|
| rojo | 7.7.1 |
| selene | 0.32.0 |
| stylua | 2.6.0 |
| lune | 0.11.0 |
| luau-lsp | 1.70.1 |
| wally | 0.3.2 (added to `rokit.toml` 2026-10-17; `wally.toml` has no dependencies yet, so no `Packages/`) |
| uv / uvx | 0.13.1 (winget `astral-sh.uv`, outside rokit) |

`MAX_MCP_OUTPUT_TOKENS=50000` is set as a user environment variable (applies to newly started Claude Code sessions).
`ROBLOX_CREATOR_ID=2465538767` (user-owned) is set at user level. `ROBLOX_OPEN_CLOUD_KEY` (key "haret-assets", Assets read/write + asset-permissions write, no expiry) is set at user level; verified 2026-10-17 by introspect and an Assets API read.
The TEST place has Studio Access to API Services on (2026-10-17).

## Roblox_Studio tools (28)

Every tool except `list_roblox_studios` requires `studio_id`. "DM" = required `datamodel_type`.

| Tool | Required params | Notes |
|---|---|---|
| `list_roblox_studios` | – | Returns `{id, name}` per open Studio. Call first. |
| `get_studio_state` | studio_id | Mode and available DataModels. |
| `start_stop_play` | is_start, studio_id | `true` starts a play session, `false` returns to Edit. |
| `get_console_output` | studio_id | Whole output log, no filter parameter. |
| `execute_luau` | code, DM (Edit/Client/Server), studio_id | Runs on Studio's main thread: Studio is frozen until the code yields. Chunk heavy work with `task.wait()`. Return a value to get it back. |
| `search_game_tree` | DM (Edit/Client/Server), studio_id | Optional `path`, `instance_type`, `keywords`, `max_depth` (default 3, max 10), `head_limit` (default 200). `Edit` is rejected while playing. |
| `inspect_instance` | path, studio_id | Properties, attributes, children summary. Max 20 matches. |
| `script_read` | target_file, studio_id | Dot path. Optional line range via `should_read_entire_file=false`. |
| `script_grep` | query, studio_id | Luau pattern over all scripts; capped at 50 matches. |
| `script_search` | keywords, studio_id | Fuzzy script-name search; capped at 10. |
| `multi_edit` | file_path, edits, DM (Edit), studio_id | Creates scripts too (`className`). **Never use on Rojo-managed paths.** |
| `screen_capture` | capture_id, studio_id | Optional `camera_position` + `look_at_position` (xyz arrays). Edit-time capture. Image output is large; set `MAX_MCP_OUTPUT_TOKENS`. |
| `user_keyboard_input` | actions[], DM (Client), studio_id | Steps: keyDown/keyUp/keyPress/textInput/wait; `key_code` is an Enum.KeyCode name. |
| `user_mouse_input` | actions[], DM (Client), studio_id | Steps: moveTo/mouseButtonDown/Up/Click/scrollUp/Down/wait; `x,y` or `instance_path`. Clicks inside the game viewport have historically not registered in this project; prefer keyboard. |
| `character_navigation` | DM (Client), studio_id | `x,y,z` or `instance_path`; `speed_multiplier` 0.1–10. |
| `search_asset` | studio_id | `query`, `assetType`, `scope` (auto/creator_store/user/group/universe), price filters. Returns `context` with universeId and creator. |
| `insert_asset` | assetId, studio_id | Optional `assetName`, `assetType`, `parentPath`. Delete Script descendants afterwards. |
| `upload_image` | imagePaths[], studio_id | HTTP(S) URLs only; returns `rbxassetid://` map. |
| `store_image` | filePath, studio_id | Local png/jpg ≤ 5 MB → `IMAGEID_<id>` URI for other tools. |
| `generate_mesh` | textPrompt, studio_id | AI mesh; `maxTriangles` 12–20000, `size`, `segmentation`, `async`. |
| `generate_texture` | textPrompt, studio_id | Re-textures an existing MeshPart/Model in place (`instance_path`). Not in CLAUDE.md. |
| `generate_material` | materialPattern, materialId, baseMaterial, materialDescription, studio_id | Returns a MaterialVariant name. |
| `generate_procedural_model` | prompt, studio_id | Parametric model from primitives; inserts into Workspace; use `async`. |
| `segment_mesh` | parts[] (≤ 5), studio_id | Splits a mesh into named sub-parts. Not in CLAUDE.md. |
| `wait_job_finished` | jobId, studio_id | For `async` jobs; `timeout` default 600 s. |
| `http_get` | url, studio_id | Only `create.roblox.com/docs/**` (.md or llms.txt) and `github.com/Roblox/libmp`. Optional `query` keyword filter. |
| `skill` | skill_name, studio_id | rbx-create-skill, rbx-debug, rbx-device-simulator-lua, rbx-docs-search, rbx-perf-profiling, rbx-scene-analysis, rbx-unit-test. |
| `subagent` | task, description, subagent_type, studio_id | Types: explore, screen_capture, unit_test. |

No multi-client playtest tool exists (`start_stop_play` starts a single Play session). Device emulation is
reachable only through the `rbx-device-simulator-lua` skill plus `execute_luau`.

## blender tools (27)

This is the **official Blender Lab MCP server**, not `mcp-for-blender`. None of the tools take an auth or session parameter.

| Tool | Params | Notes |
|---|---|---|
| `execute_blender_code` | code | Runs in the live Blender; assign a JSON-serialisable dict to `result` to return data. |
| `execute_blender_code_for_cli` | blend_file, code | Runs `blender --background <file>`; no UI needed. |
| `get_objects_summary` | – | Collection tree with objects, selection, visibility. **Replaces `get_scene_info`.** |
| `get_object_detail_summary` | name | Transforms, modifiers, materials, parent/children. |
| `get_blendfile_summary_path_info` | – | File path, saved/dirty, age, backups. **Use as the "is Blender up" check** (replaces `get_addon_status`). |
| `get_blendfile_summary_datablocks` | – | Data-block counts, workspace, render engine. |
| `get_blendfile_summary_missing_files` | – | Missing external references. |
| `get_blendfile_summary_of_linked_libraries` | – | Linked .blend tree. |
| `get_blendfile_summary_usage_guess` | – | Heuristic use-case guess. |
| `get_blendfile_summary_*_for_cli` (5) | blend_file | Same five summaries for a file on disk via background Blender. |
| `get_screenshot_of_window_as_image` | size_limit_in_bytes? | PNG of the whole Blender window. |
| `get_screenshot_of_area_as_image` | area_ui_type | PNG of one area (VIEW_3D, IMAGE_EDITOR, UV, …). **Replaces `look` for viewport checks.** |
| `get_screenshot_of_window_as_json` | – | Window layout, areas, active object, selection. |
| `render_viewport_to_path` | output_path | Full render with current settings to a file. |
| `render_thumbnail_to_path` | output_path | Small low-quality render. **Replaces `look` renders.** |
| `jump_to_tab_by_name` / `jump_to_tab_by_space_type` | name / space_type (+allow_edits) | Workspace switching. |
| `jump_to_view3d_object_by_name` / `jump_to_view3d_object_data_by_name` | name (+allow_edits) | Frame an object in the viewport. |
| `get_python_api_docs` | identifier | Bundled bpy API RST (`bpy.ops.export_scene.fbx`, …). |
| `search_api_docs` / `search_manual_docs` | query (+context, index, max_results) | Full-text search over bundled API docs / user manual. |

**Not available on this server:** `get_scene_info`, `get_addon_status`, `look`, `search_assets`, `import_asset`,
`generate_3d`. Poly Haven / Sketchfab imports and AI concept meshes therefore go through `execute_blender_code`
(or a separate tool) rather than dedicated MCP tools, and every asset must be logged by hand in `assets/LICENSES.md`.

## Observed behaviour (Phase 0, 2026-10-17)

- `execute_luau` runs in a VM separate from the game (like the command bar): `require` returns a fresh module copy, so
  drive the live server through `ServerStorage.HaretDebug` and read live state from instances. Some properties are
  capability-gated (`Lighting.Technology` → "lacking capability RobloxScript"); `Workspace.StreamingMinRadius` is not
  readable there either.
- `datamodel_type: "Edit"` is rejected while playing; use `Server`/`Client`. `get_studio_state` lists what is available.
- A camera set from a Client `execute_luau` is reset by Studio ("The execute_luau changed camera type. Resetting").
  `screen_capture` with `camera_position` + `look_at_position` works during Play and is the way to stage a shot.
- `user_keyboard_input` reaches `UserInputService.InputBegan` (the harness keys work) after a single
  `user_mouse_input` click on the viewport. GUI clicks were not needed and remain unverified.
- `get_console_output` returns the whole log every time, including Roblox CorePackages warnings; filter by prefix.
- `search_game_tree` from the root with `max_depth` 3 fills the 60–200 node cap with services; pass `path`.
- `screen_capture` does not draw `BillboardGui`s with `AlwaysOnTop = true` (checked 2026-10-18 with a red-backed probe: the
  AlwaysOnTop copy is missing, the identical non-AlwaysOnTop copy shows). Effects meant to be captured use AlwaysOnTop false.
- `user_mouse_input` clicks on GUI buttons work (by `instance_path` when the path is unambiguous, otherwise by `x, y`
  in AbsolutePosition space, i.e. without the top-bar inset); checked 2026-10-17 on the HUD mute button.
- Blender `render_thumbnail_to_path` ignores the directory of `output_path` and writes under Blender's own temp
  folder (`%TEMP%\blender_<pid>\blender_mcp\<name>.png`); the result reports the real path. `execute_blender_code`
  must assign a dict to `result`; a bare return is ignored.

## Differences from the `CLAUDE.md` tool list

1. Blender: the six `mcp-for-blender` tools above do not exist. Use the replacements marked in bold.
2. Studio: `generate_texture` and `segment_mesh` exist and were not listed.
3. The DEV place is named `Haret Al-Yasmin (TEST)`, not "Haret Al Yasmin [DEV]".
4. `wally` and `uv` were missing at inventory time; both were installed on 2026-10-17.
5. Screenshot payloads need `MAX_MCP_OUTPUT_TOKENS=50000` (U0-10); it is set at user level, so restart Claude Code to pick it up.
