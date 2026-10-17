# haret-al-yasmin

An original-IP, anime-style co-op tower defense game for Roblox, set in **Haret Al Yasmin, "the Jasmine Quarter"**. It is built by an autonomous coding agent (Claude Fable 5.1 in Claude Code) that drives Roblox Studio's built-in MCP server and Blender MCP on your own Windows or macOS machine. All code lives here, synced into Studio with Rojo.

## What's in the repo

| Path | What it is |
|---|---|
| [`reports/Roblox tower defense game blueprint.md`](reports/Roblox%20tower%20defense%20game%20blueprint.md) | The research report: genre analysis and the strategy behind this design |
| [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) | Game design document with every number (roster, summon rates and pity, traits, stat grades, enemies, waves, bosses, economy, monetization, live ops, compliance) |
| [`docs/BUILD_PLAN.md`](docs/BUILD_PLAN.md) | Phased, task-by-task plan from toolchain setup to live ops, with acceptance criteria and copy-paste kickoff prompts |
| [`CLAUDE.md`](CLAUDE.md) | Standing rules for the agent: source of truth, MCP tools, verify loop, hard rules, asset rules, commits |
| `src/shared/Config/` | `--!strict` Luau data tables from the design doc (summons, traits, stat grades, enemies, units, World 1 waves) plus `Validate.luau`, which asserts every rate table sums to 100% |
| `default.project.json`, `wally.toml`, `rokit.toml`, `selene.toml`, `stylua.toml`, `.mcp.json` | Rojo project, packages, pinned toolchain, lint/format config, project MCP servers |

## Quick start

1. **Install the toolchain.** Roblox Studio (enable *Assistant → Manage MCP Servers → Enable Studio as MCP server*), Git, Rokit, uv, Blender with the MCP addon, and Claude Code ≥ v2.1.257. Exact Windows and macOS commands are in [BUILD_PLAN Phase 0 (U0-1 to U0-10)](docs/BUILD_PLAN.md#manual-setup-by-the-user-u0).
2. **Install the project tools.** In this folder run `rokit install`, `rojo plugin install` and `wally install`.
3. **Connect the MCP servers.** On macOS, `.mcp.json` works as-is. On Windows, run `claude mcp add --scope local --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`. Then set `MAX_MCP_OUTPUT_TOKENS=50000`.
4. **Start syncing.** Run `rojo serve`, click *Connect* in Studio's Rojo plugin, and start Blender's MCP server (N panel → MCP for Blender → Start MCP Server).
5. **Launch the agent.** Run `claude`, approve the project MCP servers, run `/model fable`, then paste the **Phase 0 kickoff prompt** from [BUILD_PLAN](docs/BUILD_PLAN.md#kickoff-prompts-paste-into-claude-code-after-model-fable).

A playtest in Studio should print `[HY] Config OK`.
