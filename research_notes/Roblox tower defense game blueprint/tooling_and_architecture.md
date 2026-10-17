# AI-Assisted Tooling and Technical Architecture for a Roblox Tower Defense Game (Claude Fable 5.1 + Roblox Studio MCP + Blender MCP)

Research date: 2026-10-17. Primary sources: Roblox creator-docs (fetched as Markdown source from github.com/Roblox/creator-docs, which backs create.roblox.com/docs; create.roblox.com and devforum.roblox.com could not be reached directly from the research environment), GitHub READMEs, platform.claude.com and code.claude.com docs.

## 1. Roblox Studio MCP: official server, built-in Studio MCP, community alternatives, Rojo workflow

### Takeaway
The original `Roblox/studio-rust-mcp-server` was archived on April 3, 2026. Roblox now recommends the **built-in Studio MCP server**: you turn it on in Studio under Assistant > Manage MCP Servers. It works over stdio and offers about 27 tools. They cover reading, editing and searching scripts, running Luau in Edit, Client or Server contexts, playtesting, reading console output, screen capture, simulating mouse, keyboard and character input, searching and inserting assets, uploading images, AI mesh and material generation, and controlling multiple Studio instances. Claude Code and Claude Desktop are supported through quick connect. The best-maintained community alternative is the `Chrrxs/robloxstudio-mcp` fork. Its parent, `boshyxd/robloxstudio-mcp`, was archived on June 6, 2026.

### Cited Findings
**Legacy official server (studio-rust-mcp-server)**
- The repo was archived (read-only) on April 3, 2026, and states "This MCP Server is no longer being actively developed." It points to the built-in Studio MCP server as "the best way to connect external AI tools going forward." — [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server)
- Architecture: a Rust `axum` web server that a Studio plugin long-polls, plus an `rmcp` stdio MCP server. — [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server)
- Legacy tools: `run_code`, `insert_model` (inserts from the Creator Store), `get_console_output`, `start_stop_play`, `run_script_in_play_mode` (returns logs, errors and duration, with a timeout), and `get_studio_mode`. Claude Code setup: `claude mcp add --transport stdio Roblox_Studio -- <path> --stdio`. Binaries ship for Windows and macOS only. — [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server)
- Safety warning: third-party tools connected to it can "modify and read the contents of your opened place." — [Roblox/studio-rust-mcp-server](https://github.com/Roblox/studio-rust-mcp-server)

**Built-in Studio MCP server (current, recommended)**
- It is built into Roblox Studio and runs as a local process using **stdio transport**. Docs description: "read your game structure, edit scripts, insert models, execute code, and control play mode." It requires the latest Studio. A search snippet says the page was last updated in June 2026; I did not confirm that date on the page itself. — [Roblox docs: Connect to the Roblox Studio MCP server (source)](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md); [create.roblox.com/docs/studio/mcp](https://create.roblox.com/docs/studio/mcp)
- To enable it in Studio: open **Assistant**, choose **… > Manage MCP Servers**, and turn on **Enable Studio as MCP server**. A green indicator shows how many clients are connected. — [Roblox docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)
- Quick connect supports Antigravity, Codex CLI, **Claude Code**, **Claude Desktop**, Cursor, Gemini CLI and VS Code. Any other stdio client works through JSON or CLI configuration. — [Roblox docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)
- JSON configuration by OS:
  - Windows: `"Roblox_Studio": {"command": "cmd.exe", "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]}`
  - macOS: `"Roblox_Studio": {"command": "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"}`
  - CLI forms: `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` (Windows) and `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP` (macOS).
  - With multiple servers, add the `Roblox_Studio` entry to your existing `mcpServers` dictionary.
  - Source: [Roblox docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)
- **Full built-in tool list** — [Roblox docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md):
  - *Scripts*:
    - `script_read`: dot-notation path such as `game.ServerScriptService.MyScript`; reads the whole script or a line range.
    - `multi_edit`: applies multiple edits in one operation and creates the script if the path doesn't exist; requires `datamodel_type` (Edit).
    - `script_search`: fuzzy name search, up to 10 results.
    - `script_grep`: searches across all scripts, up to 50 matches.
  - *Asset and content generation*:
    - `generate_mesh`: AI textured mesh from a text prompt.
    - `generate_material`: creates a MaterialVariant.
    - `generate_procedural_model`: builds a ProceduralModel from primitive parts; supports reference images.
    - `wait_job_finished`
    - `search_asset`: Creator Store plus Creator Inventory, with filters.
    - `insert_asset`: by numeric asset ID; covers models, meshes, images, audio, video, animations and packages.
    - `upload_image`: batch upload from HTTP URLs; returns a path→assetId map.
    - `store_image`: local file → image URI usable by other tools.
  - *Data model exploration*:
    - `subagent`: `explore` and `playtest` types.
    - `search_game_tree`: flat JSON, filterable, with a depth limit.
    - `inspect_instance`: all readable properties, attributes and a children summary.
  - *Luau execution*: `execute_luau`, which requires `datamodel_type` set to Edit, Client or Server.
  - *Playtesting*:
    - `get_studio_state`
    - `start_stop_play`
    - `get_console_output`
    - `screen_capture`: optional camera position and look-at target.
  - *Player input simulation*:
    - `character_navigation`: moves to a position or instance path, with a speed multiplier.
    - `user_keyboard_input`
    - `user_mouse_input`: targets instances or screen coordinates.
  - *Docs and skills*:
    - `http_get`: allowed Roblox documentation URLs only.
    - `skill`: covers debugging, device simulation and docs search.
  - *Session*: `list_roblox_studios`.
- Every tool call takes a `studio_id`. One client can drive multiple Studio instances, and `list_roblox_studios` returns each instance's name, Studio instance ID and place ID. — [Roblox docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)
- Safety warning: "MCP clients can read and modify content in your open Roblox places. Make sure to only connect clients you trust." — [Roblox docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md)

**Community alternatives**
- `boshyxd/robloxstudio-mcp` was archived on June 6, 2026 because the author lost access to their NPM account. The last version line reads "v2.7.0-next.6 - 43 tools." It recommends switching to the `Chrrxs/robloxstudio-mcp` fork.
  - Setup: install the Studio plugin and enable **Allow HTTP Requests**.
  - Claude Code: `claude mcp add robloxstudio -- npx -y robloxstudio-mcp@latest`.
  - A read-only "Inspector" edition exposes 31 tools: `get_file_tree`, `search_objects`, `get_instance_properties`, `get_script_source`, `grep_scripts`, `get_playtest_output`, `get_output_log`, `capture_screenshot`, `search_assets` and others.
  - Source: [boshyxd/robloxstudio-mcp README](https://github.com/boshyxd/robloxstudio-mcp)
- `Chrrxs/robloxstudio-mcp` (npm `@chrrxs/robloxstudio-mcp`, based on boshyxd v2.7.0) is actively maintained.
  - Claude Code: `claude mcp add robloxstudio -- npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin`
  - Tools:
    - `eval_server_runtime` and `eval_client_runtime`: run Luau in a live server or client context and share the game's `require` cache.
    - `breakpoints`: records hits without pausing.
    - `get_runtime_logs`: edit, server or a specific client.
    - `solo_playtest` and `multiplayer_playtest`: multi-client sessions.
    - `manage_instance`: opens or closes Studio windows, including a baseplate, a local file, a published place or an older revision.
    - `capture_script_profiler` and `capture_micro_profiler`
    - `get_memory_breakdown` and `get_scene_analysis`
    - `execute_luau`, `set_properties` and `find_and_replace_in_scripts`
    - `capture_screenshot`, plus mouse and keyboard input
    - `search_assets`, `get_asset_details` and `preview_asset`: hierarchy and security scan.
    - `insert_asset`: strips scripts and package links before parenting.
    - `manage_monetization`: developer products and game passes via an Open Cloud key. New items stay off sale, and a name that already exists is refused because these items can't be deleted.
    - `get_roblox_docs` and `get_roblox_skills`
    - Wine launcher env vars (`ROBLOX_STUDIO_WINE_LAUNCHER`, `ROBLOX_STUDIO_EXE`).
  - Source: [Chrrxs/robloxstudio-mcp README](https://github.com/Chrrxs/robloxstudio-mcp)

**Rojo / git workflow**
- Rojo lets you work on scripts and models from the filesystem with VS Code and Git. It streams `rbxm`/`rbxmx` into the game in real time and can deploy from the command line. `rojo syncback` pulls instances back from place files. An optional two-way sync in the Studio plugin syncs supported Studio edits back to disk. Fully automatic conversion of existing games "may require manual project configuration." It requires Rust 1.88+ to build and is MPL-2.0 licensed. — [rojo-rbx/rojo README](https://github.com/rojo-rbx/rojo)

### Inferences
- Use the **built-in Studio MCP** as the primary bridge. It is first-party, supports Claude Code quick connect and covers the full write–playtest–observe loop: `multi_edit`/`execute_luau` → `start_stop_play` → `get_console_output`/`screen_capture` → `user_*_input`. The legacy rust server should not be used for new work.
- Studio runs only on Windows and macOS (the MCP configs exist only for those OSes), so the agent must run on the developer's own Windows or Mac machine, not in a Linux cloud container. The Wine path in the Chrrxs fork is unofficial.
- Recommended hybrid workflow:
  - Keep code (ModuleScripts, Scripts, LocalScripts) in a git repo synced with Rojo, so Claude Code can edit files directly, diff them and run tests.
  - Use Studio MCP for things Rojo can't do: inspecting the live DataModel, placing and editing 3D content, inserting assets, playtesting, and reading output.
  - Avoid having MCP `multi_edit` and Rojo both write the same scripts, or Rojo sync will overwrite MCP edits. Pick one source of truth per script; Rojo-owned is the usual choice.
- The Chrrxs fork's multiplayer playtest and profiler tools are valuable for a TD game (testing replication of hundreds of enemies across several clients). It is a reasonable add-on, but it is third-party and its plugin needs HTTP requests enabled.

### Gaps
- I could not find a stated per-call timeout or output size limit for the built-in MCP. I also did not confirm whether `start_stop_play` supports multi-client "Start Server + N players" (the legacy `run_server` mode existed).
- I could not confirm exact quick-connect behavior on Claude Code, such as whether it writes to `~/.claude.json` user scope or project scope.
- Whether `generate_mesh` output is production-quality or within triangle budgets is not documented.
- No release/version number is published for the built-in MCP. It ships with Studio.

## 2. Blender MCP (ahujasid/blender-mcp) and the Blender → Roblox asset pipeline

### Takeaway
`ahujasid/blender-mcp` (now packaged as `mcp-for-blender`) has nine tools. The main ones are `execute_blender_code` (arbitrary Python), `look` (renders), `get_scene_info`, `generate_3d` (Tripo, Hunyuan3D, Hyper3D Rodin) and `search_assets`/`import_asset` (Poly Haven, Sketchfab, Poly Pizza). It runs over an unauthenticated localhost socket on port 9876. Roblox export rules:
- **20,000 triangles max per mesh**
- ≤4 bone influences per vertex
- one animation per FBX
- textures up to 4096² (1024² recommended per asset)
- FBX with **Apply Scalings = FBX Unit Scale**, or the alternative Scale 0.01
- glTF needs no scaling fixes

Open Cloud's Assets API can upload FBX/glTF models (≤20 MB), images and animations (`.rbxm`) programmatically.

### Cited Findings
**Blender MCP**
- Community project, not made by the Blender Foundation; MIT licensed; about 31.2k stars. No version number appears in the Releases section. — [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- Architecture: a Blender addon (`addon.py`) runs a socket server inside Blender, and the MCP server (`src/blender_mcp/server.py`) connects to it. — [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- Install:
  - Automatic: `uvx mcp-for-blender setup`
  - Claude Code: `claude mcp add blender uvx mcp-for-blender`
  - Claude Desktop: an `mcpServers.blender` entry with `command: "uvx"` and `args: ["mcp-for-blender"]`.
  - Addon: `uvx mcp-for-blender install-addon`, then enable "Interface: MCP for Blender."
  - In Blender: press N, open the MCP for Blender tab and click **Start MCP Server**.
  - Requirements: Blender 3.0+, Python 3.10+ and uv. Don't `pip install uv`.
  - Source: [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- Tools (9):
  - `execute_blender_code`
  - `look`: viewport, camera, multi-angle sheets and animation frames, in several shading modes.
  - `get_scene_info`
  - `generate_3d`: Tripo, Hunyuan3D or Hyper3D Rodin.
  - `search_assets` and `import_asset`: Poly Haven, Sketchfab and Poly Pizza.
  - `get_addon_status`
  - `disable_telemetry` and `record_trajectory_feedback`
  - Source: [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- Integrations:
  - Poly Haven: CC0, no key.
  - Sketchfab: API key.
  - Poly Pizza: free key. About 69% of models are CC-BY and need attribution; the addon writes a credit line, and you can filter to CC0.
  - Hyper3D Rodin: key.
  - Hunyuan3D (Tencent Cloud): SecretId/SecretKey; international accounts need a toggle.
  - Tripo
  - Credentials go in `BLENDERMCP_*` env vars or addon preferences.
  - Source: [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- Limitations and safety — [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp):
  - Arbitrary Python can run, so save first.
  - The socket has **no auth and no encryption**; keep it on localhost.
  - Run only one MCP server instance at a time.
  - Complex requests can time out, so break them into steps.
  - Poly Haven downloads block Blender's main thread.
  - Poly Pizza downloads can fail behind Cloudflare on datacenter or VPN IPs.
  - `BLENDER_MCP_SAFE_MODE=1` blocks file access, subprocesses, network access and persistent processes.
- Environment variables: `BLENDER_HOST` (localhost), `BLENDER_PORT` (9876) and `DISABLE_TELEMETRY=true`. Anonymous usage telemetry is on by default; prompts, code and scene data are collected only on opt-in. — [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)

**Roblox mesh specifications**
- "Individual meshes can not exceed **20,000 triangles**." Geometry must be watertight, use quads where possible (no n-gons) and have volume. — [Roblox: General specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md)
- Rigging — [Roblox: General specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md):
  - Bones must be frozen, with scale 1,1,1 and rotation 0,0,0.
  - The root sits at 0,0,0.
  - **Max 4 influences per vertex.**
  - No influences on the root.
  - **Only a single animation track per FBX export**, so export one file per animation.
- Cages use `_InnerCage`/`_OuterCage` suffixes. The Importer converts `_Att` objects to Attachments. — [Roblox: General specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/specifications.md); [Roblox: Meshes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/meshes.md)
- Blender FBX export: Path Mode = Copy with Embed Textures; **Apply Scalings = FBX Unit Scale**; disable **Add Leaf Bones**; disable **Bake Animation** unless exporting keyframes. — [Roblox: Export settings](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/export-requirements.md)
- Scale and units — [Roblox: Blender guide](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/blender.md):
  - Set Blender Scene Units > Unit System to **None** to match studs.
  - FBX scaling options: (a) **FBX Unit Scale** (recommended); (b) export Transform Scale **0.01**; or (c) scene Unit Scale 0.01, which "can cause unexpected Blender issues."
  - glTF "do[es] not require these additional scaling configurations."
  - Blender is Z-up and Studio is Y-up. In the Studio Importer, set Scale Unit to **Stud** and enable "Insert Using Scene Position."
- The Importer accepts `.fbx`, `.gltf` and `.obj`. FBX and glTF support multiple meshes and hierarchies, PBR textures, cages, rigs, avatar components, animation data and vertex colors. — [Roblox: Importer](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/importer.md)
- The Asset Manager can bulk-import, but it does not support meshes with rigging, skinning or animation. — [Roblox: Meshes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/meshes.md)

**Textures and PBR**
- Texture formats are PNG, JPG, TGA and BMP, up to **4096×4096**. Guidance: 256² for 5×5-stud objects, 512² for 10×10 and 1024² for 20×20. — [Roblox: Texture specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md)
- The same page, in its UV section, says "Roblox supports up to 1024×1024 pixel spaces for texture maps." This internal inconsistency is unresolved. The UV rules are a single UV set and coordinates within 0–1. — [Roblox: Texture specifications](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md)
- SurfaceAppearance supports ColorMap, NormalMap, RoughnessMap, MetalnessMap and an emissive mask (five map types per the PBR page; the Meshes page says "up to four"). If both are present, SurfaceAppearance overrides MaterialVariant texture maps. — [Roblox: PBR textures](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/surface-appearance.md); [Roblox: Meshes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/meshes.md)
- Collision fidelity options are Box, Hull, Default and Tunable (with a CollisionPrecision slider). — [Roblox: Meshes](https://github.com/Roblox/creator-docs/blob/main/content/en-us/parts/meshes.md)

**Rigging and animation**
- Imported rigs become `Bone` instances that you can pose and animate in the Animation Editor. Bones affect appearance but not collision. — [Roblox: Rigging](https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/rigging.md)
- For a custom Motor6D rig, make sure `AssemblyRootPart` is the part meant to stay stationary; PrimaryPart does not set it. You publish with **… > Publish to Roblox**, then use the asset ID. Name the final keyframe `End` when replacing default animations. — [Roblox: Animation Editor](https://github.com/Roblox/creator-docs/blob/main/content/en-us/animation/editor.md)
- Avatar Setup automatically adds an R15 rig, skinning, FACS facial animation, cages, 15-part partitioning and attachments. It is aimed at avatar and Marketplace assets. — [Roblox: Avatar Setup](https://github.com/Roblox/creator-docs/blob/main/content/en-us/avatar-setup/index.md)

**Open Cloud Assets API (automation)**
- `POST https://apis.roblox.com/assets/v1/assets` with an `x-api-key` header (or OAuth2 `asset:read`/`asset:write` scopes) and a multipart `fileContent`. It creates one asset per call, **≤20 MB**. — [Roblox: Usage guide for assets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md)
- Supported upload types — [Roblox: Usage guide for assets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md):
  - Animation (`.rbxm`/`.rbxmx`, which "might not upload or function" if edited outside Studio)
  - Audio
  - Decal/Image (png/jpeg/bmp/tga, <8000×8000)
  - Mesh (only content re-uploaded from the Asset Delivery API)
  - **Model** (`.fbx`, `.gltf`/`.glb`, `.rbxm`), imported as a Model containing MeshParts and uploaded as a **package**
  - Video
- `PATCH /assets/v1/assets/{assetId}` can update content only for `.fbx` and creates a new version. Uploads return an `operations/{id}`; poll `GET /assets/v1/operations/{id}`. Reference assets as `rbxassetid://<id>`. — [Roblox: Usage guide for assets](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud/guides/usage-assets.md)

### Inferences
- A practical AI pipeline:
  1. Blender MCP `execute_blender_code` models, retopologizes or decimates assets (keep each mesh well under 20k triangles; low-poly TD assets ideally 1–5k), unwraps a single UV set and bakes PBR maps.
  2. `look` verifies the result visually.
  3. A Python export runs with FBX Unit Scale (or glTF).
  4. The file is uploaded via Open Cloud (`curl`/script from Claude Code) or imported through the Studio Importer.
  5. Studio MCP `insert_asset` places it and `inspect_instance`/`screen_capture` validate it.
- Studio MCP's `upload_image` takes HTTP URLs, not local files. For local textures use Open Cloud or the Studio Importer.
- For enemies: rigged meshes with Bones animated via AnimationController/Animator on the client. Export each animation as its own FBX (single track rule). Animation assets usually still need a Studio publish step because Open Cloud accepts only Studio-authored `.rbxm`.
- AI-generated meshes (Rodin, Hunyuan, Tripo, Studio `generate_mesh`) should be checked for triangle count, watertightness and license or attribution (Poly Pizza CC-BY) before use.

### Gaps
- I did not find an official Roblox doc describing the Animation Editor's "Import from FBX Animation" flow. It is widely used but unverified here.
- No official per-place mesh or memory budget numbers were found beyond the per-mesh 20k triangles.
- The Blender MCP README doesn't state a version number or date. I did not verify whether `generate_3d` triangle counts are configurable.

## 3. Claude Fable 5.1: model facts and multi-MCP setup in Claude Code / Claude Desktop

### Takeaway
Claude Fable 5.1 (`claude-fable-5-1`) was released on September 1, 2026. It is Anthropic's top model "for demanding reasoning and long-horizon agentic work."
- 1M context, 128K max output
- Adaptive thinking, always on; default effort `high`
- $10 / $50 per million tokens (cache reads $0.25 per million)
- Forced tool use is **not** supported

In Claude Code, select it with `/model fable` or `claude --model fable` (v2.1.257+ required). Add Roblox Studio MCP and Blender MCP side by side with `claude mcp add` or a committed `.mcp.json`.

### Cited Findings
- "Latest. Released September 1, 2026." Model ID `claude-fable-5-1` (Bedrock: `anthropic.claude-fable-5-1`; the same ID on Google Cloud, Microsoft Foundry and Claude Platform on AWS). — [Claude Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview)
- Specs — [Claude Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview):
  - 1M token context, 128K max output
  - Text and image input → text output
  - Adaptive thinking (always on), default effort `high`
  - "Slower" latency
  - Knowledge and training cutoff June 2026
  - Retirement not sooner than September 1, 2027
- Pricing: $10 input / $50 output per million tokens; 5-minute cache write $12.50; 1-hour cache write $20; **cache read $0.25** (2.5% of input); Batch 50% off. — [Claude Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview)
- Positioning: it extends Fable 5 at the same prices, with "stronger long-running agentic coding, multistep research." Anthropic's docs say "For most workloads, start with Claude Opus 5.5". Fable 5.1 is meant for demanding or long-horizon work, or when Opus 5.5 at higher effort falls short. Claude Mythos 5.1 has the same capabilities but only for verified organizations. — [Claude Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview)
- Breaking API changes versus Fable 5 — [Claude Fable 5.1 overview](https://platform.claude.com/docs/en/models/fable-5-1/overview):
  - **Forced tool use returns an error.**
  - Only Fable 5.1 and Mythos 5.1 can read Fable 5.1's thinking blocks.
  - Editing earlier turns invalidates thinking blocks.
  - Additive features: per-message effort (beta), turn-scoped system messages (beta), progress updates between tool calls (`display: "updates"`, beta), and content provenance.
- Comparison lineup: Opus 5.5 ($4/$20, 1M, default effort medium), Sonnet 5.5 ($2/$10) and Haiku 5.5 (from $0.10/$0.50). All have 1M context and 128K output. — [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview)
- Third-party coverage describes Fable 5.1 as an "agentic powerhouse" that ties for top of the Artificial Analysis index. Reported benchmark numbers conflict between outlets (53 vs 66), so they are unverified. — [The Batch](https://www.deeplearning.ai/the-batch/fable-holds-the-top-spot-for-now); [mezha.ua](https://mezha.ua/en/news/anthropic-claude-fable-5-1-314761/amp/)

**Claude Code usage**
- Aliases: `fable` resolves to Fable 5.1 (except in Claude apps gateway sessions, where it resolves to Fable 5), and `best` resolves to Fable where available. Select with `/model fable` or `claude --model fable`, or pin with `claude-fable-5-1`. Fable 5.1 **requires Claude Code v2.1.257+**. — [Claude Code model config](https://code.claude.com/docs/en/model-config)
- Tips from the same docs — [Claude Code model config](https://code.claude.com/docs/en/model-config):
  - "Describe the outcome, not the steps."
  - It "verifies its own work with less prompting."
  - "give it work you would normally break into pieces."
  - Requests flagged by safety classifiers (mostly cyber and bio) trigger automatic model fallback.
- Billing: depending on plan, Fable usage may bill to **usage credits** and show a consent prompt. In unattended sessions such as Remote Control, background sessions and agent teams, the prompt waits for `dialogExpiry` (5 minutes by default), and then the turn ends without the request. — [Claude Code model config](https://code.claude.com/docs/en/model-config)
- MCP commands: stdio servers use `claude mcp add [--scope local|project|user] [--env K=V] <name> -- <command> [args...]`. Everything after `--` passes through untouched. `claude mcp add-json <name> '<json>'` takes an entry copied from a Claude Desktop config (the object inside `mcpServers`). Check with `claude mcp list`, `claude mcp get <name>` or `/mcp`. — [Claude Code MCP docs](https://code.claude.com/docs/en/mcp)
- Scopes: Local (current project, stored in `~/.claude.json`), Project (`.mcp.json` at the repo root, shared via version control) and User (all projects, `~/.claude.json`). Project servers from `.mcp.json` need interactive approval ("Pending approval") and a trusted workspace. — [Claude Code MCP docs](https://code.claude.com/docs/en/mcp)
- Limits: `MCP_TIMEOUT` sets the startup timeout (for example 10000 ms). MCP output warns at 10,000 tokens and caps at **25,000 tokens** by default (`MAX_MCP_OUTPUT_TOKENS` raises the cap). Text results over 50,000 characters are saved to a file, and image results stay subject to the token cap. `MCP_TOOL_TIMEOUT` defaults to about 28 hours, and stdio servers have no per-request timer. Tool search is on by default, so tool definitions are deferred and many servers add little context. — [Claude Code MCP docs](https://code.claude.com/docs/en/mcp)

### Inferences
- Example project `.mcp.json` for a Windows dev machine (an assembly of documented entries, not one documented file):
  `{"mcpServers": {"Roblox_Studio": {"command": "cmd.exe", "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]}, "blender": {"command": "uvx", "args": ["mcp-for-blender"]}}}`
  On macOS, use the `StudioMCP` path. Claude Desktop uses the same `mcpServers` block in its config file.
- Because Studio `screen_capture` and Blender `look` return images, raise `MAX_MCP_OUTPUT_TOKENS` if captures get truncated.
- Because forced `tool_choice` errors on Fable 5.1, any custom Agent SDK harness must use `auto` tool choice.
- Cost and effort: the docs recommend Opus 5.5 as the default. A sensible plan is Fable 5.1 for architecture and hard debugging, and Opus or Sonnet 5.5 for bulk asset scripting. The model choices are documented; this split is my inference.

### Gaps
- I did not fetch Anthropic's announcement page (`anthropic.com/claude-fable-and-mythos-5-1`) or the system card for official benchmark numbers.
- Claude Desktop-specific limits (tool output, image handling) for Fable 5.1 were not verified.

## 4. Roblox TD technical architecture best practices

### Takeaway
Use a server-authoritative simulation in which each enemy is plain data (id, type, path id, spawn time, speed, HP, progress along the path). Clients render the models and interpolate positions from that data. Replicate compact snapshots or events, not Humanoids or physics parts. Back the design with these engine facts:
- UnreliableRemoteEvent (≤1,000-byte payloads, unordered) for frequent cosmetic updates
- Reliable RemoteEvents for state changes
- Parallel Luau Actors for heavy targeting math
- ProfileStore for session-locked player data, within DataStore limits
- MemoryStore queues for matchmaking
- `TeleportAsync` with reserved servers for lobby→match
- strict Luau types
- Knit is archived, so use plain ModuleScripts plus Wally packages
- Jest-Lua for tests
- React-lua, Fusion or Vide for UI

### Cited Findings
**Enemy simulation and rendering (community guidance, no official Roblox TD guide found)**
- DevForum developers report that client-rendered enemy systems handle about 1,000 enemies smoothly, with the bottleneck in tower targeting. The suggested fixes are spatial partitioning (grids or octrees) and cached enemy positions. — [DevForum: How to optimize tower system](https://devforum.roblox.com/t/how-to-optimize-tower-system/2830931/9) (via search snippet)
- One pattern keeps enemies as server-side data tables with no models, sends batched updates every 10–20 heartbeats, and reports about 500 enemies before performance drops. — [DevForum: Client side rendering confusion](https://devforum.roblox.com/t/client-side-rendering-confusion/2701037) (via search snippet)
- "the server just needs the data of where the enemy is on the road as well as some enemy logic. anything else is something you can let the client handle/render." — [DevForum: How should I make a Tower Defense type movement system?](https://devforum.roblox.com/t/how-should-i-make-a-tower-defense-type-movement-system/2665165) (via search snippet)
- Server-tweened or Humanoid enemies reportedly lag at around 100 enemies. — [DevForum: Tower Defense Enemy Movement](https://devforum.roblox.com/t/tower-defense-enemy-movement/1930853) (via search snippet)

**Networking**
- RemoteEvents are reliable and ordered. Excess client→server events beyond the throttle are delayed, not dropped. — [Roblox: Remote events and callbacks](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/events/remote.md)
- UnreliableRemoteEvents guarantee neither delivery nor order. They drop payloads **over 1,000 bytes** and messages that exceed the throttle, and they discard messages when no handler is connected. Include a timestamp or sequence number. — [Roblox: Remote events and callbacks](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/events/remote.md)
- Table keys of non-string type are converted to strings when sent over remotes. — [Roblox: Remote events and callbacks](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/events/remote.md)

**Security**
- "Never trust the client." Exploiters can fire remotes "at any frequency with arbitrary arguments" and own their character's physics. All critical logic must be validated or run on the server. Design question from the docs: "What happens if this feature is used 1,000+ times per second?" — [Roblox: Security tactics](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/security/security-tactics.md)
- From Knit's archival notes: any networking layer is a wrapper over RemoteEvents, UnreliableRemoteEvents and RemoteFunctions, and network data "requires runtime type-checking" (for example, `assert` that a value is a number). — [Knit ARCHIVAL.md](https://github.com/Sleitnick/Knit/blob/main/ARCHIVAL.md)

**Performance**
- Parallel Luau: put scripts under `Actor` instances and call `task.desynchronize()`/`task.synchronize()` or `:ConnectParallel()`. Scripts under the same Actor run serially, so you need multiple Actors. Instances cannot be modified in parallel phases. — [Roblox: Parallel Luau](https://github.com/Roblox/creator-docs/blob/main/content/en-us/scripting/multithreading.md)
- StreamingEnabled is on by default for new places and cannot be set by script. Recommended settings — [Roblox: Instance streaming](https://github.com/Roblox/creator-docs/blob/main/content/en-us/workspace/streaming/index.md):
  - `StreamingMinRadius` 64 (default)
  - `StreamingTargetRadius` 1024 (default)
  - `StreamOutBehavior.Opportunistic`
  - `ModelStreamingBehavior.Improved`
  - Model modes: Atomic, Persistent and PersistentPerPlayer

**Data**
- ProfileStore is a single-ModuleScript DataStore wrapper that provides auto-save and **session locking** to prevent dupes. It is player-data oriented and "not designed (and never will be) for in-game leaderboards or any kind of global state." Its API style is `:StartSessionAsync()` and `Profile.Data`. — [MadStudioRoblox/ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)
- DataStore limits — [Roblox: Data store limits](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/data-stores/error-codes-and-limits.md):
  - Value up to **4,194,304 characters per key**
  - Per-key throughput: 25 MB/min read, 4 MB/min write
  - Server request budget: reads `300 + concurrentUsers × 40` per minute, writes `300 + concurrentUsers × 20` per minute
  - Storage: `500 MB + 1 MB × lifetime users`
  - Throughput rounds up to the next KB per request
- MemoryStore — [Roblox: Memory stores](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/memory-stores/index.md):
  - Structures: queue, sorted map and hash map. Skill-based matchmaking is a documented queue use case.
  - Memory quota: `64 KB + 1.2 KB × users`
  - Requests: `1000 + 120 × concurrent users` request units per minute, game-wide
  - Max 100 MB per sorted map or queue
  - Data is TTL-evicted
- Teleport — [Roblox: Teleport between places](https://github.com/Roblox/creator-docs/blob/main/content/en-us/projects/teleport.md):
  - Call `TeleportService:TeleportAsync(placeId, players, TeleportOptions)` **from the server only**; the client `Teleport()` is deprecated.
  - Reserved servers: `TeleportOptions.ShouldReserveServer = true` creates a new one, or set `ReservedServerAccessCode`.
  - `SetTeleportData` data is client-visible and unencrypted, so don't pass secure data. Use DataStores or MemoryStores instead.
  - Access settings such as "Secure within universe only" restrict non-start places to server-initiated teleports.

**Code quality, frameworks, testing, UI**
- Luau type modes are `--!nocheck`, `--!nonstrict` and `--!strict`. Errors show in Script Analysis. — [Roblox: Type checking](https://github.com/Roblox/creator-docs/blob/main/content/en-us/luau/type-checking.md)
- **Knit is archived** ("No Longer Maintained"). The author's reasoning: Knit can't fully benefit from types, ModuleScripts already provide the service pattern, and a thin wrapper over remotes is enough. — [Sleitnick/Knit](https://github.com/Sleitnick/Knit); [Knit ARCHIVAL.md](https://github.com/Sleitnick/Knit/blob/main/ARCHIVAL.md)
- Jest Lua is installed via Wally `dev-dependencies` (for example `jsdotlua/jest-globals@3.10.0`). It "can currently only run inside of Roblox," and Roblox uses it internally. — [jsdotlua/jest-lua](https://github.com/jsdotlua/jest-lua)
- React Lua (`jsdotlua/react-lua`) is a translation of ReactJS 17.x and the community fork of Roblox's read-only mirror. — [jsdotlua/react-lua](https://github.com/jsdotlua/react-lua)
- Fusion: "portable Luau companion library," MIT. — [dphfox/Fusion](https://github.com/dphfox/Fusion)
- Vide: Solid-inspired reactive UI, "Fully Luau typecheckable." — [centau/vide](https://github.com/centau/vide)

### Inferences
These are recommendations synthesized from the sources above, not prescriptions taken from any one source.

**Enemy model**
- The server holds `{id, typeId, pathId, spawnT, speed, hp, slowUntil, ...}` and computes progress `d(t)` analytically along a precomputed waypoint or Bezier polyline (distance-parameterized, as a cumulative length table).
- The server broadcasts compact events: spawn (`id, type, pathId, spawnServerTime`) and damage/death/speed changes, sent reliably.
- Optionally it sends periodic progress corrections through an UnreliableRemoteEvent, kept under 1,000 bytes and packed with `buffer`.
- Clients compute positions locally with `workspace:GetServerTimeNow()` and move pooled models via `BulkMoveTo` or CFrame updates. No Humanoids: use AnimationController + Animator on rigged MeshParts and skip animations for distant enemies.

**Targeting**
- Use a server-side spatial grid of path-distance buckets.
- "First" = max progress, "Last" = min progress, "Strongest" = max HP, "Closest" = min distance, all within range.
- Recompute targets at about 10 Hz rather than every frame. Move to Actors if the tower count is large.
- Hitscan or "instant/timed damage" is computed on the server, and clients draw tracer or projectile VFX only. True physical projectiles are needed only for special towers.

**Places**
- Lobby place: ProfileStore, shop, and a MemoryStore queue or party system that calls `TeleportAsync` with `ShouldReserveServer`.
- Match place: waves, economy, towers. Pass only the map or difficulty ID in TeleportData, and validate it against a server-side allowlist.
- Write results back via ProfileStore on match end and on player removal.

**Remote security**
- Validate every place, upgrade or sell request on the server: type checks, ownership, money, placement validity (raycast plus spacing), and a per-player rate limit such as a token bucket.
- The client never sends damage, positions or currency.

**Repository and tooling**
- Rojo + Wally + git. Plain ModuleScript "services/controllers" with `--!strict`. Jest-Lua tests run inside Studio, triggered through MCP `execute_luau` or a run-in-Roblox step, with results read via `get_console_output`.
- UI: Vide or Fusion for lightweight typed reactive UI, or React-lua if the team knows React.

### Gaps
- No official Roblox guide or benchmark exists for TD enemy counts or bandwidth. Community numbers (about 500–1,000 enemies) are anecdotal.
- devforum.roblox.com could not be fetched directly, so DevForum claims rely on search-result snippets.
- I did not verify the exact RemoteEvent throttle numbers (the docs point to the RemoteEvent API page), `buffer` library limits, `BulkMoveTo` performance claims, or current Wally, Fusion and Vide version numbers.
- ProfileService (legacy) versus ProfileStore: ProfileStore is the current MAD STUDIO library. I did not confirm ProfileService's deprecation status from a primary source.
- TestEZ status (Roblox/testez) was not verified because the GitHub API was blocked. Jest-Lua is the documented Roblox-internal choice.
