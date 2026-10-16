"""Post today's community daily (challenge + question of the day) in #daily-challenge and open a thread on it.

    python tools/discord/post_daily.py --dry-run            # print today's post, no network
    python tools/discord/post_daily.py                      # post (once per UTC day)
    python tools/discord/post_daily.py --date 2026-10-20    # preview/post another day

Content rotates through dailies.json by UTC day number, so every machine posts the same daily for a date.
"""

from __future__ import annotations

import argparse
import json
import sys
import traceback
from datetime import date, datetime, timezone

from discord_api import HERE, IDS_FILE, Client

LAUNCH = date(2026, 10, 16)  # Daily #1
STATE = HERE.parent.parent / ".triage" / "daily.json"  # {"last_daily": "YYYY-MM-DD"}; gitignored
LOG = STATE.with_name("daily.log")


def build_post(day: date) -> tuple[str, str]:
    data = json.loads((HERE / "dailies.json").read_text(encoding="utf-8"))
    n = day.toordinal()
    ch = data["challenges"][n % len(data["challenges"])]
    q = data["questions"][n % len(data["questions"])]
    number = (day - LAUNCH).days + 1
    when = f"{day.strftime('%a')} {day.day} {day.strftime('%b')}"
    text = (
        f"## 🌼 Daily #{number} · {when} · تحدي اليوم\n"
        f"⚔️ **Challenge:** {ch['en']}\n"
        f"-# {ch['ar']}\n\n"
        f"💬 **Question of the day:** {q['en']}\n"
        f"-# {q['ar']}\n\n"
        "📸 Answer and post your screenshots in the thread below · جاوب بالثريد\n"
        "🎁 Don't forget your daily login reward in the game · لا تنسى مكافأتك اليومية"
    )
    return text, f"Daily #{number} · {when}"


def run() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--date", help="YYYY-MM-DD (UTC); default today")
    ap.add_argument("--force", action="store_true", help="post even if today's daily was already posted")
    args = ap.parse_args()

    day = date.fromisoformat(args.date) if args.date else datetime.now(timezone.utc).date()
    text, thread_name = build_post(day)
    if args.dry_run:
        print(text)
        print(f"\n[thread: {thread_name}] [{len(text)} chars]")
        return

    ids = json.loads(IDS_FILE.read_text(encoding="utf-8"))
    state = json.loads(STATE.read_text(encoding="utf-8")) if STATE.exists() else {}
    if (state.get("last_daily") or ids.get("last_daily")) == day.isoformat() and not args.force:
        print(f"Daily for {day} already posted.")
        return
    client = Client()
    cid = ids["channels"]["daily"]
    msg = client.post(f"/channels/{cid}/messages", {"content": text, "allowed_mentions": {"parse": []}})
    client.post(f"/channels/{cid}/messages/{msg['id']}/threads",
                {"name": thread_name, "auto_archive_duration": 1440})
    STATE.parent.mkdir(exist_ok=True)
    STATE.write_text(json.dumps({"last_daily": day.isoformat()}) + "\n", encoding="utf-8")
    print(f"Posted {thread_name}.")


def main() -> None:
    # Under pythonw (the scheduled task, no console) there is no stdout: log to .triage/daily.log instead.
    if sys.stdout is None:
        LOG.parent.mkdir(exist_ok=True)
        sys.stdout = sys.stderr = open(LOG, "a", encoding="utf-8")
        print(f"--- {datetime.now(timezone.utc).isoformat(timespec='seconds')}")
    else:
        sys.stdout.reconfigure(encoding="utf-8")
    try:
        run()
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
    finally:
        sys.stdout.flush()


if __name__ == "__main__":
    main()
