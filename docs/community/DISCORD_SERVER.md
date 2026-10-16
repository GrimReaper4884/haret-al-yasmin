# Discord community server

*Status: ready to build · Last updated 2026-10-16 · Owner: lead engineer*

The community server is where players get updates and codes, find a party, and send us bugs, ideas and
feedback in a shape an agent can triage. The layout lives in code (`tools/discord/blueprint.json`) and one
script builds it, so it can be rebuilt or extended the same way every time.

- Layout + text: `tools/discord/blueprint.json`, `guidelines/*.md` (forum post templates), `messages/*.md`
- Builder: `tools/discord/build_server.py` (stdlib Python, idempotent, never deletes)
- Agent access: `tools/discord/feedback_mcp.py`, registered as `discord-feedback` in `.mcp.json`
- Agent prompts: `docs/community/TRIAGE_AGENT_PROMPT.md`

## Why this layout

No ready-made Discord template covers a game-feedback server well (searches turned up layout guides, not
templates), so the layout combines the practices those guides agree on:

- **Forum channels for bugs and suggestions**, one thread per report, tags for area and status, a pinned
  template in the forum guidelines ([BugNet: collecting bug reports from Discord](https://bugnet.io/blog/best-practices-for-collecting-bug-reports-from-discord-communities),
  [BugNet: Discord for bug collection](https://bugnet.io/blog/how-to-use-discord-for-game-bug-collection),
  [BetaHub: Discord community feedback](https://betahub.io/blog/guides/2025/07/16/discord-community-feedback.html)).
- **A read-only #known-issues** so players don't re-report, and **bugs separate from ideas** (same sources).
- **Report template fields** (what happened / expected / steps / frequency / device / where / when /
  media) from the guides above and [EVE Online's bug-report template](https://forums.eveonline.com/t/bug-reporting-code-of-conduct-and-submission-template/453386).
- **👍 as the default reaction** on bug, suggestion and feedback posts, so votes are one click and the
  agent can count them.
- **Status tags are staff-only** (Discord "moderated" tags): players pick the area, staff and the triage
  bot set Triaged / Confirmed / Critical / Fixed. Players can't mark their own post Critical.
- **#private-report** for exploits, purchase problems and safety reports: players can only open
  *private threads* there, so exploit steps never go public.
- Bilingual (English + Arabic) welcome, rules and templates, plus an Arabic chat channel, because the
  audience is mostly Arabic-speaking (`GAME_DESIGN.md` §2).

## Layout

| Category | Channels | Notes |
| --- | --- | --- |
| 📌 START HERE · ابدأ هنا | welcome, rules, announcements, patch-notes, codes, known-issues | read-only for players; announcements are follow-able announcement channels |
| 💬 COMMUNITY · المجتمع | general, عربي, team-up, strategy, screenshots-and-clips, off-topic | slowmode on team-up and clips |
| 🐞 FEEDBACK · الملاحظات | **bug-reports**, **suggestions**, **game-feedback**, **help** (forums), private-report | tag required on every post |
| 🧪 TESTERS | tester-chat | Tester role only |
| 🔒 TEAM | staff-chat, mod-log, triage-reports, claude-control | staff only; claude-control is Developer + bot only |
| 🔊 VOICE | Lounge, Party 1, Party 2 | parties capped at 4 like a match |

Roles: Developer (admin), Moderator, Tester, Bug Hunter (reward for good reports), Content Creator,
Update Pings. Run `python tools/discord/build_server.py --dry-run` to print every channel and tag.

The builder also enables Community (needed for forums and announcement channels) with medium
verification and the explicit-media filter, and adds AutoMod rules: Discord's slur/sexual/profanity
presets, spam, mention spam, and a Roblox-scam keyword rule ("free robux", "roblosecurity"…) that also
alerts #mod-log. AutoMod presets are English-centric; add Arabic keywords by hand as moderators see them.

## Safety and policy (read once)

- **Discord is 13+.** Our game targets 9–16, so the server is for the 13+ part of the audience. Rules say
  so, verification is medium, and the rules repeat that staff never ask for passwords or cookies (cookie
  logging is the most common Roblox scam on Discord).
- **No Discord link inside the game.** Roblox only allows off-platform links that `PolicyService`
  permits, and Discord is not one of them (`research/ROBLOX_IP_AND_POLICY.md`). Promote the server through
  the Roblox group/experience social links (shown to 13+ only), YouTube and TikTok.
- Codes announced on Discord must not be the only way to get paid-equivalent value (same doc).

## Setup (one time, about 15 minutes)

These steps need your Discord account, so you do them; the rest is scripted.

1. ~~**Create an empty server.**~~ Done 2026-10-16: *Haret Al-Yasmin · حارة الياسمين* with the icon from
   `tools/discord/assets/server_icon.png` (drawn by `assets/logo.html` from the cast concept art; the
   builder re-applies it if the server ever has no icon). Discord's default #general is moved into
   💬 COMMUNITY by the builder; delete the empty "Text Channels"/"Voice Channels" categories and the default
   "General" voice channel afterwards.
2. **Create the bot.** [Discord Developer Portal](https://discord.com/developers/applications) → *New
   Application* (e.g. "Jasmine Lane Bot") → **Bot** → *Reset Token* → copy it.
   Under *Privileged Gateway Intents* turn on **Message Content Intent**.
   Copy the **Application ID** from *General Information*.
3. **Store the token** (never paste it into chat, a file in the repo, or a Discord channel). Either:
   - in Claude Code: `/discord:configure <token>` (saves to `~/.claude/channels/discord/.env`; both the
     builder and the MCP server read that file), or
   - set a user environment variable `DISCORD_BOT_TOKEN` in Windows (Settings → System → About →
     Advanced system settings → Environment Variables).
4. **Invite the bot** with Administrator for the first build:

```bash
python tools/discord/build_server.py --invite-url YOUR_APPLICATION_ID
```

   Open the printed link, pick the new server, authorize.
5. **Build the server:**

```bash
python tools/discord/build_server.py
```

   It prints each thing it creates and writes `tools/discord/server_ids.json` (channel, role and tag ids;
   not secret, commit it). Safe to re-run any time; it only adds what's missing and refreshes forum tags
   and templates. Use `--update-messages` after editing `messages/*.md`.

## After the build (by hand, in Discord)

- **Give yourself the Developer role**, and Moderator to anyone you trust.
- **Lower the bot's power:** Server Settings → Roles → the bot's role → turn off *Administrator* and turn
  on: View Channels, Send Messages, Send Messages in Threads, Read Message History, Manage Threads,
  Manage Messages, Attach Files, Embed Links, Add Reactions. (Re-enable Administrator only to re-run the
  builder for new roles/AutoMod.)
- **Onboarding** (Server Settings → Onboarding): default channels = welcome, rules, announcements, general,
  bug-reports, suggestions; a question "Which language?" (English / العربية → shows عربي) and "Ping me for
  updates?" (→ Update Pings).
- **Server guide / welcome screen**: point to #rules, #codes, #bug-reports.
- Invite link: **https://discord.gg/VeT9cvbuMq** (never expires, lands in #welcome; created by the bot 2026-10-16). It goes in the experience's **Social Links** only, never inside the game: `PolicyService.AllowedExternalLinkReferences` is a legacy field that always returns an empty array, so no player is cleared to see a Discord reference in-experience.
- Pin a message in #codes with the current codes from `src/shared/Config/Codes.luau` (only codes meant for
  Discord; `QITT` is the "announced on community channels" one).

## Connecting Claude to Discord (no need to sit at the desktop)

Two pieces, both using the same bot:

**1. `discord-feedback` MCP server (already wired in `.mcp.json`).** Any Claude Code session opened in
this repo — the desktop app, a scheduled task, or the CLI — gets tools to list/read feedback posts, set
staff tags, reply in feedback threads, post in staff channels and edit #known-issues. It is a small
stdlib-Python server in this repo (`tools/discord/feedback_mcp.py`), so nothing third-party sees the token.
Community MCP servers exist ([barryyip0625/mcp-discord](https://mcpservers.org/servers/barryyip0625/mcp-discord),
[IQAIcom/mcp-discord](https://glama.ai/mcp/servers/@IQAIcom/mcp-discord)) but are broader (delete,
moderate, any channel) than a triage agent should have; ours is limited to feedback forums and staff
channels and cannot ping, delete or ban.

**2. Claude Code Discord channel (talk to Claude from your phone).** The official
[channels feature](https://code.claude.com/docs/en/channels) pushes your Discord messages into a running
Claude Code session and sends Claude's replies back. It's a research preview and needs the Claude Code
**CLI** (not just the desktop app) plus [Bun](https://bun.sh). On this PC neither is installed yet:

```powershell
irm https://claude.ai/install.ps1 | iex
```

```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

Then, in a terminal opened in this repo folder:

1. `claude` → `/plugin install discord@claude-plugins-official` (choose *user* scope) → `/reload-plugins`
2. `/discord:configure <token>` (same bot token; skip if already done) → exit
3. Start the always-on session:

```bash
claude --channels plugin:discord@claude-plugins-official
```

4. DM the bot on Discord → it answers with a pairing code → in Claude Code run `/discord:access pair <code>`
   then `/discord:access policy allowlist` so only you can command it.
5. To also talk to it in #claude-control (not just DMs), opt that channel in per the plugin's
   [ACCESS.md](https://github.com/anthropics/claude-plugins-official/blob/main/external_plugins/discord/ACCESS.md).
6. Paste prompt **C** from `TRIAGE_AGENT_PROMPT.md` as the session's first message.
7. Put your Discord user id in `.triage/state.json` as `"developer_id"` (Discord → Settings → Advanced →
   Developer Mode, then right-click your name → Copy User ID). The fix runner only accepts approvals from it.

The session must stay open (leave the terminal running; channels only deliver to a live session). If
Claude hits a permission prompt while you're away it waits; `.claude/settings.json` pre-allows the
read-only and test commands the agents need so that happens rarely.

Lighter alternative with no install: the desktop app's **Remote Control** lets you drive a desktop
session from the Claude mobile app. It doesn't read Discord, but the MCP tools still work inside it.

## Community dailies

#daily-challenge gets one post a day: a challenge built around the real modes (episodes, difficulties,
Endless Night, roles) and a question of the day, both in English and Arabic, plus a reminder to claim
the in-game daily login reward. Only the bot posts there; players answer in the thread it opens on each post.
Content rotates through `tools/discord/dailies.json` (21 challenges × 20 questions, so a pair doesn't repeat
for over a year); add lines there any time. Daily #1 was 2026-10-16.

```bash
python tools/discord/post_daily.py --dry-run
```

```bash
python tools/discord/post_daily.py
```

It posts at most once per UTC day (state in `.triage/daily.json`), so it is safe to schedule hourly or on
every PC start. On the lead's PC it runs from the Windows task **HaretAlYasmin Discord Daily** (pythonw,
daily 15:00 local + 2 min after logon if missed; output in `.triage/daily.log`). Remove it with
`Unregister-ScheduledTask -TaskName 'HaretAlYasmin Discord Daily'`. Static game info
(modes, defenders, odds, pity, daily rewards, pass, codes) lives in #game-info (`messages/game-info.md`);
re-sync it with `build_server.py --update-messages` when numbers in `Config/TD.luau` change.

## Running the triage automatically

Create a daily scheduled task in the Claude desktop app (or ask Claude: "schedule the triage agent daily
at 09:00") whose prompt is prompt **A** from `TRIAGE_AGENT_PROMPT.md`, working folder = this repo. Each run
posts the digest to #triage-reports and the approval request to #claude-control; reply `approve BUG-0003`
there or in your DM to the bot and the always-on session runs the fix agents (prompt **B**).
