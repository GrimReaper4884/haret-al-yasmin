"""Minimal Discord REST client shared by build_server.py and feedback_mcp.py (stdlib only).

Token lookup, in order: DISCORD_BOT_TOKEN env var (also the Windows user variable `setx` writes), then
~/.claude/channels/discord/.env (the file the
official Claude Code Discord channel plugin writes with /discord:configure), so one bot serves both.
The token is never printed or written anywhere by these tools.
"""

from __future__ import annotations

import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://discord.com/api/v10"
HERE = Path(__file__).resolve().parent
IDS_FILE = HERE / "server_ids.json"  # written by build_server.py; ids are not secret

PERMS = {
    "CREATE_INSTANT_INVITE": 0, "KICK_MEMBERS": 1, "BAN_MEMBERS": 2, "ADMINISTRATOR": 3,
    "MANAGE_CHANNELS": 4, "MANAGE_GUILD": 5, "ADD_REACTIONS": 6, "VIEW_AUDIT_LOG": 7,
    "PRIORITY_SPEAKER": 8, "STREAM": 9, "VIEW_CHANNEL": 10, "SEND_MESSAGES": 11, "SEND_TTS_MESSAGES": 12,
    "MANAGE_MESSAGES": 13, "EMBED_LINKS": 14, "ATTACH_FILES": 15, "READ_MESSAGE_HISTORY": 16,
    "MENTION_EVERYONE": 17, "USE_EXTERNAL_EMOJIS": 18, "CONNECT": 20, "SPEAK": 21, "MUTE_MEMBERS": 22,
    "DEAFEN_MEMBERS": 23, "MOVE_MEMBERS": 24, "CHANGE_NICKNAME": 26, "MANAGE_NICKNAMES": 27,
    "MANAGE_ROLES": 28, "MANAGE_WEBHOOKS": 29, "MANAGE_THREADS": 34, "CREATE_PUBLIC_THREADS": 35,
    "CREATE_PRIVATE_THREADS": 36, "SEND_MESSAGES_IN_THREADS": 38, "MODERATE_MEMBERS": 40,
}


def perm_bits(names: list[str]) -> str:
    value = 0
    for name in names:
        value |= 1 << PERMS[name]
    return str(value)


class DiscordError(RuntimeError):
    def __init__(self, status: int, body: str):
        super().__init__(f"Discord API {status}: {body[:500]}")
        self.status = status
        self.body = body


def _windows_user_env(name: str) -> str:
    """`setx` writes HKCU\\Environment, which processes started earlier never see in os.environ."""
    try:
        import winreg
    except ImportError:
        return ""
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as key:
            return str(winreg.QueryValueEx(key, name)[0]).strip()
    except OSError:
        return ""


def load_token() -> str:
    token = os.environ.get("DISCORD_BOT_TOKEN", "").strip() or _windows_user_env("DISCORD_BOT_TOKEN")
    if not token:
        env_file = Path.home() / ".claude" / "channels" / "discord" / ".env"
        if env_file.exists():
            for line in env_file.read_text(encoding="utf-8").splitlines():
                m = re.match(r"\s*DISCORD_BOT_TOKEN\s*=\s*['\"]?([^'\"\s]+)", line)
                if m:
                    token = m.group(1)
    if not token:
        raise SystemExit(
            "No bot token. Set DISCORD_BOT_TOKEN in your environment, or run /discord:configure <token> "
            "in Claude Code (saves it to ~/.claude/channels/discord/.env)."
        )
    return token


class Client:
    def __init__(self, token: str | None = None):
        self._token = token or load_token()

    def request(self, method: str, path: str, body: object | None = None, query: dict | None = None):
        url = API + path
        if query:
            url += "?" + urllib.parse.urlencode({k: v for k, v in query.items() if v is not None})
        data = None if body is None else json.dumps(body).encode("utf-8")
        for _attempt in range(6):
            req = urllib.request.Request(url, data=data, method=method)
            req.add_header("Authorization", f"Bot {self._token}")
            req.add_header("User-Agent", "DiscordBot (https://github.com/haret-al-yasmin, 1.0)")
            if data is not None:
                req.add_header("Content-Type", "application/json")
            try:
                with urllib.request.urlopen(req, timeout=30) as resp:
                    raw = resp.read()
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as err:
                text = err.read().decode("utf-8", "replace")
                if err.code == 429:
                    try:
                        wait = float(json.loads(text).get("retry_after", 1))
                    except ValueError:
                        wait = 2.0
                    time.sleep(wait + 0.25)
                    continue
                if err.code >= 500:
                    time.sleep(1.5)
                    continue
                raise DiscordError(err.code, text) from None
        raise DiscordError(429, "rate limited repeatedly")

    def get(self, path, **query):
        return self.request("GET", path, query=query or None)

    def post(self, path, body):
        return self.request("POST", path, body)

    def patch(self, path, body):
        return self.request("PATCH", path, body)

    def put(self, path, body=None):
        return self.request("PUT", path, body)

    def resolve_guild_id(self) -> str:
        gid = os.environ.get("DISCORD_GUILD_ID", "").strip()
        if gid:
            return gid
        if IDS_FILE.exists():
            gid = json.loads(IDS_FILE.read_text(encoding="utf-8")).get("guild_id")
            if gid:
                return gid
        guilds = self.get("/users/@me/guilds")
        if len(guilds) == 1:
            return guilds[0]["id"]
        names = ", ".join(f"{g['name']} ({g['id']})" for g in guilds) or "none"
        raise SystemExit(f"Bot is in {len(guilds)} servers ({names}). Set DISCORD_GUILD_ID to pick one.")


def chunk(text: str, limit: int = 1900) -> list[str]:
    """Split on paragraph/line boundaries to stay under Discord's 2000-char message cap."""
    parts, current = [], ""
    for line in text.splitlines(keepends=True):
        while len(line) > limit:
            if current:
                parts.append(current)
                current = ""
            parts.append(line[:limit])
            line = line[limit:]
        if len(current) + len(line) > limit:
            parts.append(current)
            current = ""
        current += line
    if current.strip():
        parts.append(current)
    return parts
