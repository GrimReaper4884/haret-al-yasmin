"""Post a release announcement: the animated banner (release_banner.py) plus colour-coded embeds.

    python tools/discord/post_release.py 1.0.0 [--channel announcements] [--dry-run]
"""
from __future__ import annotations

import json
import sys
import uuid
import urllib.request
from pathlib import Path

from discord_api import API, IDS_FILE, load_token

HERE = Path(__file__).resolve().parent
GAME_URL = "https://www.roblox.com/games/120389740593436"

JASMINE, GOLD, RED, NIGHT, OLIVE, TEAL = 0xF8E2A0, 0xE0A93B, 0x96241F, 0x2E3460, 0x6B8E23, 0x2A9D8F


def embeds(version: str, gif: str) -> list[dict]:
    return [
        {
            "title": f"🌙  Haret Al-Yasmin v{version} is live!  🌙",
            "url": GAME_URL,
            "description": (
                "**حارة الياسمين · Jasmine Lane** gets its biggest night yet.\n"
                "The lane gate creaks, the lanterns are lit, and the whole season is open.\n\n"
                f"### ▶️  [Play now on Roblox]({GAME_URL})"
            ),
            "color": GOLD,
            "image": {"url": f"attachment://{gif}"},
        },
        {
            "title": "📜  Season Story 1: nine episodes",
            "color": NIGHT,
            "description": (
                "`01` Night of the Thieves · `02` The Rival Lane · `03` The Siege\n"
                "`04` The Lost Shoe · `05` Fire at the Warehouse · `06` The Blind Beggar\n"
                "`07` The Police Post · `08` The Two Lanes · `09` The Confession\n\n"
                "Story cards in the Play panel, twin roads, saboteurs, smoke, disguises and new bosses.\n"
                "Plus **Endless Night** and the **Orchard Raid** event at the Olive Press."
            ),
        },
        {
            "title": "🛡️  New defenders",
            "color": OLIVE,
            "description": (
                "🌿 **Umm Baki the Midwife** · 🧆 **Abu Samih the Hummus Seller**\n"
                "👞 **Abu Hamoud the Cobbler** · ♨️ **Abu Basim of the Hammam**\n"
                "👑 **Su'da Khanum**\n"
                "🌑 **Al-Adashari, the Night Guard**: a *secret* unit. Find him if you can…\n\n"
                "Level 7 brings a **signature choice** for every defender, and **beads** add a slot of your own."
            ),
        },
        {
            "title": "✨  Look & feel",
            "color": TEAL,
            "description": (
                "• Damage numbers, boss hit flash, boss-death shake, gate shudder\n"
                "• Wave, boss, final-wave, victory and defeat moments\n"
                "• Health rings, boss bar, new enemy clips and faster gaits\n"
                "• Currency icons everywhere, music and sound toggles, a mute button\n"
                "• New arenas: Saha, Warehouse, Olive Press, Post Road, Twin Gates\n"
                "• New logo, loading screen and the game icon"
            ),
        },
        {
            "title": "⚖️  Balance & fixes",
            "color": RED,
            "description": (
                "• Matches scale with party size (1 to 4 players); bosses scale more gently\n"
                "• Stun chains are capped: no more pinning enemies forever\n"
                "• 🐈 The Cat has retired from the lane. Your save updates on join\n"
                f"• Your version shows at the bottom of **Settings** (`v{version}`)"
            ),
        },
        {
            "title": "🎁  Codes",
            "color": JASMINE,
            "description": "Redeem in the **Codes** menu: `YASMIN` · `HARA` · `SHABRIYEH`\nFound a bug? Post it in #bugs. Thank you, testers! 🌼",
            "footer": {"text": f"Haret Al-Yasmin · v{version} · Jasmine Lane is waiting"},
        },
    ]


def post(channel_id: str, payload: dict, gif_path: Path) -> dict:
    boundary = uuid.uuid4().hex
    body = bytearray()
    body += f"--{boundary}\r\nContent-Disposition: form-data; name=\"payload_json\"\r\nContent-Type: application/json\r\n\r\n".encode()
    body += json.dumps(payload).encode("utf-8") + b"\r\n"
    body += (
        f"--{boundary}\r\nContent-Disposition: form-data; name=\"files[0]\"; filename=\"{gif_path.name}\"\r\n"
        "Content-Type: image/gif\r\n\r\n"
    ).encode()
    body += gif_path.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(f"{API}/channels/{channel_id}/messages", data=bytes(body), method="POST")
    req.add_header("Authorization", f"Bot {load_token()}")
    req.add_header("User-Agent", "DiscordBot (https://github.com/haret-al-yasmin, 1.0)")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read())


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    version = args[0] if args else "1.0.0"
    channel = sys.argv[sys.argv.index("--channel") + 1] if "--channel" in sys.argv else "announcements"
    gif = HERE / "assets" / f"release_{version.replace('.', '_')}.gif"
    payload = {
        "content": "## 🌼 The lane gate is open 🌼",
        "embeds": embeds(version, gif.name),
        "attachments": [{"id": 0, "filename": gif.name}],
        "allowed_mentions": {"parse": []},
    }
    if "--dry-run" in sys.argv:
        print(json.dumps(payload, ensure_ascii=False, indent=1))
        print("chars:", sum(len(e.get("title", "")) + len(e.get("description", "")) for e in payload["embeds"]))
        return
    ids = json.loads(IDS_FILE.read_text(encoding="utf-8"))
    msg = post(ids["channels"][channel], payload, gif)
    print("posted", msg["id"], "in", channel)


if __name__ == "__main__":
    main()
