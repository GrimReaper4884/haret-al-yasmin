"""Build (or refresh) the Haret Al-Yasmin community server from blueprint.json.

    python tools/discord/build_server.py --dry-run                 # validate + print the layout, no network
    python tools/discord/build_server.py --invite-url <APP_ID>     # print the bot invite link
    python tools/discord/build_server.py                           # create what's missing, refresh forums
    python tools/discord/build_server.py --update-messages         # also re-sync welcome/rules text

Idempotent: matches existing roles/channels by name, never deletes anything. Needs the bot in the server with
Administrator for the first run (see docs/community/DISCORD_SERVER.md). Writes server_ids.json next to it.
"""

from __future__ import annotations

import argparse
import base64
import json
import re
import sys
from pathlib import Path

from discord_api import HERE, IDS_FILE, Client, DiscordError, chunk, perm_bits

BLUEPRINT = HERE / "blueprint.json"
TYPES = {"text": 0, "voice": 2, "category": 4, "announcement": 5, "forum": 15}
REQUIRE_TAG = 1 << 4

BOT_ALLOW = ["VIEW_CHANNEL", "SEND_MESSAGES", "SEND_MESSAGES_IN_THREADS", "READ_MESSAGE_HISTORY",
             "ATTACH_FILES", "EMBED_LINKS", "ADD_REACTIONS", "MANAGE_THREADS", "MANAGE_MESSAGES",
             "CREATE_PUBLIC_THREADS"]
READONLY_DENY = ["SEND_MESSAGES", "CREATE_PUBLIC_THREADS", "CREATE_PRIVATE_THREADS", "SEND_MESSAGES_IN_THREADS"]

AUTOMOD = [
    {"name": "Block slurs & adult words", "event_type": 1, "trigger_type": 4,
     "trigger_metadata": {"presets": [1, 2, 3]}, "actions": [{"type": 1}]},
    {"name": "Block spam", "event_type": 1, "trigger_type": 3, "actions": [{"type": 1}]},
    {"name": "Mention spam", "event_type": 1, "trigger_type": 5,
     "trigger_metadata": {"mention_total_limit": 5, "mention_raid_protection_enabled": True},
     "actions": [{"type": 1}]},
    {"name": "Roblox scams", "event_type": 1, "trigger_type": 1,
     "trigger_metadata": {"keyword_filter": ["*free robux*", "*robux generator*", "*roblosecurity*",
                                             "*free nitro*", "*rbx cookie*", "*account checker*"]},
     "actions": [{"type": 1}, {"type": 2, "metadata": {"channel_id": "{mod_log}"}}]},
]


def read_text(rel: str) -> str:
    return (HERE / rel).read_text(encoding="utf-8").strip()


def load_blueprint() -> dict:
    bp = json.loads(BLUEPRINT.read_text(encoding="utf-8"))
    errors = []
    for cat in bp["categories"]:
        for ch in cat["channels"]:
            if ch["type"] == "forum":
                tags = ch.get("tags", [])
                if len(tags) > 20:
                    errors.append(f"{ch['name']}: {len(tags)} tags (max 20)")
                for t in tags:
                    if len(t["name"]) > 20:
                        errors.append(f"{ch['name']}: tag '{t['name']}' longer than 20 chars")
                guide = read_text(ch["guidelines_file"])
                if len(guide) > 4096:
                    errors.append(f"{ch['name']}: guidelines {len(guide)} chars (max 4096)")
            elif len(ch.get("topic", "")) > 1024:
                errors.append(f"{ch['name']}: topic longer than 1024 chars")
    if errors:
        raise SystemExit("Blueprint errors:\n  " + "\n  ".join(errors))
    return bp


def print_layout(bp: dict) -> None:
    print("Roles:", ", ".join(r["name"] for r in bp["roles"]))
    for cat in bp["categories"]:
        flags = []
        if cat.get("readonly"):
            flags.append("read-only")
        if cat.get("visible_to"):
            flags.append("visible to " + "/".join(cat["visible_to"]))
        print(f"\n{cat['name']}" + (f"  [{', '.join(flags)}]" if flags else ""))
        for ch in cat["channels"]:
            extra = ""
            if ch["type"] == "forum":
                user = [t["name"] for t in ch["tags"] if not t.get("moderated")]
                staff = [t["name"] for t in ch["tags"] if t.get("moderated")]
                extra = f"\n      player tags: {', '.join(user)}\n      staff tags:  {', '.join(staff)}"
            print(f"  {ch['type']:<12} {ch['name']}{extra}")


def merge_overwrites(*lists: list[dict]) -> list[dict]:
    merged: dict[str, dict] = {}
    for ows in lists:
        for ow in ows:
            cur = merged.setdefault(ow["id"], {"id": ow["id"], "type": ow["type"], "allow": 0, "deny": 0})
            allow, deny = int(ow.get("allow", 0)), int(ow.get("deny", 0))
            cur["allow"] = (cur["allow"] & ~deny) | allow
            cur["deny"] = (cur["deny"] & ~allow) | deny
    return [{**o, "allow": str(o["allow"]), "deny": str(o["deny"])} for o in merged.values()]


def visibility_overwrites(everyone: str, keys: list[str], role_ids: dict, bot_id: str) -> list[dict]:
    ows = [{"id": everyone, "type": 0, "deny": perm_bits(["VIEW_CHANNEL"])},
           {"id": bot_id, "type": 1, "allow": perm_bits(BOT_ALLOW)}]
    ows += [{"id": role_ids[k], "type": 0, "allow": perm_bits(["VIEW_CHANNEL"])} for k in keys]
    return ows


def link_channels(text: str, name_to_id: dict) -> str:
    """Turn '#bug-reports' into a clickable <#id> mention."""
    def sub(m):
        cid = name_to_id.get(m.group(1))
        return f"<#{cid}>" if cid else m.group(0)
    return re.sub(r"#([\w\-؀-ۿ]+)", sub, text)


class Builder:
    def __init__(self, client: Client, bp: dict, update_messages: bool):
        self.c, self.bp, self.update_messages = client, bp, update_messages
        self.gid = client.resolve_guild_id()
        self.guild = client.get(f"/guilds/{self.gid}")
        self.bot_id = client.get("/users/@me")["id"]
        self.channels = client.get(f"/guilds/{self.gid}/channels")
        self.ids = {"guild_id": self.gid, "bot_user_id": self.bot_id, "roles": {}, "channels": {},
                    "categories": {}, "forum_tags": {}, "pinned_messages": {}}
        if IDS_FILE.exists():
            old = json.loads(IDS_FILE.read_text(encoding="utf-8"))
            if old.get("guild_id") == self.gid:
                self.ids["pinned_messages"] = old.get("pinned_messages", {})
        self.log: list[str] = []

    def note(self, msg: str) -> None:
        self.log.append(msg)
        print(msg)

    # -- roles ---------------------------------------------------------------------------------------------
    def ensure_roles(self) -> None:
        existing = {r["name"]: r for r in self.c.get(f"/guilds/{self.gid}/roles")}
        for spec in self.bp["roles"]:
            role = existing.get(spec["name"])
            if role is None:
                role = self.c.post(f"/guilds/{self.gid}/roles", {
                    "name": spec["name"], "color": int(spec["color"].lstrip("#"), 16), "hoist": spec["hoist"],
                    "mentionable": spec["mentionable"], "permissions": perm_bits(spec["permissions"]),
                })
                self.note(f"+ role {spec['name']}")
            self.ids["roles"][spec["key"]] = role["id"]

    # -- channels ------------------------------------------------------------------------------------------
    def find(self, name: str, ctype: int, parent: str | None) -> dict | None:
        for ch in self.channels:
            if ch["name"] == name and ch["type"] == ctype and (ctype == 4 or ch.get("parent_id") == parent):
                return ch
        if ctype == 4:
            return None
        # adopt a same-named channel outside our categories (e.g. Discord's default #general) and move it in
        ours = set(self.ids["categories"].values())
        for ch in self.channels:
            if ch["name"] == name and ch["type"] == ctype and ch.get("parent_id") not in ours:
                moved = self.c.patch(f"/channels/{ch['id']}", {"parent_id": parent, "lock_permissions": True})
                ch.update(moved)
                self.note(f"~ moved existing #{name} into its category")
                return ch
        return None

    def category_overwrites(self, cat: dict) -> list[dict]:
        everyone, roles = self.gid, self.ids["roles"]
        ows: list[dict] = []
        if cat.get("readonly"):
            ows += [{"id": everyone, "type": 0, "deny": perm_bits(READONLY_DENY)},
                    {"id": roles["developer"], "type": 0, "allow": perm_bits(["SEND_MESSAGES"])},
                    {"id": roles["moderator"], "type": 0, "allow": perm_bits(["SEND_MESSAGES"])},
                    {"id": self.bot_id, "type": 1, "allow": perm_bits(BOT_ALLOW)}]
        if cat.get("visible_to"):
            ows += visibility_overwrites(everyone, cat["visible_to"], roles, self.bot_id)
        return merge_overwrites(ows)

    def channel_overwrites(self, cat_ows: list[dict], spec: dict) -> list[dict]:
        extra: list[dict] = []
        if spec.get("visible_to"):
            # channel visibility replaces the category's role list
            cat_ows = [o for o in cat_ows if o["id"] not in self.ids["roles"].values()]
            extra += visibility_overwrites(self.gid, spec["visible_to"], self.ids["roles"], self.bot_id)
        if spec.get("private_threads_only"):
            extra += [{"id": self.gid, "type": 0,
                       "deny": perm_bits(["SEND_MESSAGES", "CREATE_PUBLIC_THREADS"]),
                       "allow": perm_bits(["CREATE_PRIVATE_THREADS", "SEND_MESSAGES_IN_THREADS"])},
                      {"id": self.bot_id, "type": 1, "allow": perm_bits(BOT_ALLOW)}]
        if spec.get("thread_replies_only"):
            # only the bot posts; members answer in the thread it opens on each post
            extra += [{"id": self.gid, "type": 0,
                       "deny": perm_bits(["SEND_MESSAGES", "CREATE_PUBLIC_THREADS", "CREATE_PRIVATE_THREADS"]),
                       "allow": perm_bits(["SEND_MESSAGES_IN_THREADS"])},
                      {"id": self.bot_id, "type": 1, "allow": perm_bits(BOT_ALLOW)}]
        return merge_overwrites(cat_ows, extra)

    def forum_tags(self, spec: dict, existing: list[dict] | None, emojis: bool) -> list[dict]:
        by_name = {t["name"]: t for t in (existing or [])}
        tags = []
        for t in spec["tags"]:
            tag = {"name": t["name"], "moderated": bool(t.get("moderated"))}
            if emojis and t.get("emoji"):
                tag["emoji_name"] = t["emoji"]
            if t["name"] in by_name:
                tag["id"] = by_name[t["name"]]["id"]
            tags.append(tag)
        wanted = {t["name"] for t in spec["tags"]}
        tags += [t for t in (existing or []) if t["name"] not in wanted][: max(0, 20 - len(tags))]
        return tags

    def channel_body(self, spec: dict, existing: dict | None, emojis: bool = True) -> dict:
        body: dict = {}
        if spec["type"] == "forum":
            body.update({
                "topic": self.render(read_text(spec["guidelines_file"])),
                "available_tags": self.forum_tags(spec, existing and existing.get("available_tags"), emojis),
                "flags": REQUIRE_TAG if spec.get("require_tag") else 0,
                "default_forum_layout": 2 if spec.get("layout") == "gallery" else 1,
                "default_sort_order": 1 if spec.get("sort") == "creation_date" else 0,
            })
            if spec.get("default_reaction"):
                body["default_reaction_emoji"] = {"emoji_name": spec["default_reaction"]}
        elif spec["type"] in ("text", "announcement"):
            body["topic"] = self.render(spec.get("topic", ""))
            if spec.get("slowmode"):
                body["rate_limit_per_user"] = spec["slowmode"]
        elif spec["type"] == "voice" and spec.get("user_limit"):
            body["user_limit"] = spec["user_limit"]
        return body

    def render(self, text: str) -> str:
        names = {}
        for cat in self.bp["categories"]:
            for ch in cat["channels"]:
                if ch["key"] in self.ids["channels"]:
                    names[ch["name"]] = self.ids["channels"][ch["key"]]
        return link_channels(text, names)

    def ensure_channel(self, spec: dict, parent_id: str, cat_ows: list[dict], position: int) -> None:
        ctype = TYPES[spec["type"]]
        existing = self.find(spec["name"], ctype, parent_id)
        ows = self.channel_overwrites(cat_ows, spec)
        if existing is None:
            body = {"name": spec["name"], "type": ctype, "parent_id": parent_id, "position": position,
                    "permission_overwrites": ows, **self.channel_body(spec, None)}
            try:
                ch = self.c.post(f"/guilds/{self.gid}/channels", body)
            except DiscordError as err:
                if spec["type"] != "forum" or err.status != 400:
                    raise
                self.note(f"  ! {spec['name']}: Discord rejected tag emojis, retrying without them")
                body.update(self.channel_body(spec, None, emojis=False))
                ch = self.c.post(f"/guilds/{self.gid}/channels", body)
            self.channels.append(ch)
            self.note(f"+ {spec['type']} #{spec['name']}")
        else:
            ch = existing
            if spec["type"] == "forum":
                # refresh guidelines + tags (keeps tag ids so existing posts keep their tags)
                try:
                    ch = self.c.patch(f"/channels/{ch['id']}", self.channel_body(spec, ch))
                except DiscordError as err:
                    if err.status != 400:
                        raise
                    ch = self.c.patch(f"/channels/{ch['id']}", self.channel_body(spec, ch, emojis=False))
                self.note(f"~ refreshed forum #{spec['name']}")
        self.ids["channels"][spec["key"]] = ch["id"]
        if spec["type"] == "forum":
            self.ids["forum_tags"][spec["key"]] = {t["name"]: t["id"] for t in ch.get("available_tags", [])}

    def build_channels(self, community_pass: bool) -> None:
        for ci, cat in enumerate(self.bp["categories"]):
            cat_ows = self.category_overwrites(cat)
            existing = self.find(cat["name"], 4, None)
            if existing is None:
                existing = self.c.post(f"/guilds/{self.gid}/channels", {
                    "name": cat["name"], "type": 4, "position": ci, "permission_overwrites": cat_ows})
                self.channels.append(existing)
                self.note(f"+ category {cat['name']}")
            self.ids["categories"][cat["key"]] = existing["id"]
            for pi, spec in enumerate(cat["channels"]):
                if bool(spec.get("requires_community")) == community_pass:
                    self.ensure_channel(spec, existing["id"], cat_ows, pi)

    def fix_positions(self) -> None:
        moves = []
        for ci, cat in enumerate(self.bp["categories"]):
            cid = self.ids["categories"][cat["key"]]
            moves.append({"id": cid, "position": ci})
            for pi, spec in enumerate(cat["channels"]):
                if spec["key"] in self.ids["channels"]:
                    # parents are already right (created/moved into place); Discord allows only one
                    # parent change per bulk call, so only positions go here
                    moves.append({"id": self.ids["channels"][spec["key"]], "position": pi})
        self.c.request("PATCH", f"/guilds/{self.gid}/channels", moves)

    # -- community, automod, messages ---------------------------------------------------------------------
    def has_community(self) -> bool:
        return "COMMUNITY" in self.guild.get("features", [])

    def enable_community(self) -> bool:
        if self.has_community():
            return True
        g, cfg = self.bp["guild"], self.bp["community"]
        try:
            self.guild = self.c.patch(f"/guilds/{self.gid}", {
                "features": sorted(set(self.guild.get("features", [])) | {"COMMUNITY"}),
                "rules_channel_id": self.ids["channels"][cfg["rules_channel"]],
                "public_updates_channel_id": self.ids["channels"][cfg["updates_channel"]],
                "safety_alerts_channel_id": self.ids["channels"][cfg["updates_channel"]],
                "verification_level": g["verification_level"],
                "explicit_content_filter": g["explicit_content_filter"],
                "default_message_notifications": g["default_message_notifications"],
                "preferred_locale": g["preferred_locale"],
            })
            self.note("+ enabled Community (rules + mod-log channels, medium verification, media filter)")
            return True
        except DiscordError as err:
            self.note(f"! could not enable Community automatically ({err}).\n"
                      "  Do it by hand: Server Settings → Enable Community, pick #rules and #mod-log, then re-run.")
            return False

    def ensure_automod(self) -> None:
        try:
            have = {r["name"] for r in self.c.get(f"/guilds/{self.gid}/auto-moderation/rules")}
        except DiscordError as err:
            self.note(f"! skipped AutoMod ({err.status})")
            return
        for rule in AUTOMOD:
            if rule["name"] in have:
                continue
            body = json.loads(json.dumps(rule).replace("{mod_log}", self.ids["channels"]["mod_log"]))
            body["enabled"] = True
            try:
                self.c.post(f"/guilds/{self.gid}/auto-moderation/rules", body)
                self.note(f"+ automod: {rule['name']}")
            except DiscordError as err:
                self.note(f"! automod '{rule['name']}' not created ({err.status})")

    def ensure_messages(self) -> None:
        for key, rel in self.bp["messages"].items():
            cid = self.ids["channels"][key]
            parts = chunk(self.render(read_text(rel)))
            known = self.ids["pinned_messages"].get(key, [])
            if not known:
                mine = [m for m in self.c.get(f"/channels/{cid}/messages", limit=50)
                        if m["author"]["id"] == self.bot_id]
                known = [m["id"] for m in reversed(mine)]
            if known and not self.update_messages:
                self.ids["pinned_messages"][key] = known
                continue
            ids = []
            for i, part in enumerate(parts):
                payload = {"content": part, "allowed_mentions": {"parse": []}}
                if i < len(known):
                    self.c.patch(f"/channels/{cid}/messages/{known[i]}", payload)
                    ids.append(known[i])
                else:
                    ids.append(self.c.post(f"/channels/{cid}/messages", payload)["id"])
            self.ids["pinned_messages"][key] = ids
            self.note(f"{'~' if known else '+'} message in #{key}")

    def ensure_icon(self) -> None:
        rel = self.bp["guild"].get("icon")
        if not rel or self.guild.get("icon"):
            return
        data = base64.b64encode((HERE / rel).read_bytes()).decode()
        self.guild = self.c.patch(f"/guilds/{self.gid}", {"icon": f"data:image/png;base64,{data}"})
        self.note("+ server icon")

    def run(self) -> None:
        print(f"Server: {self.guild['name']} ({self.gid})")
        self.ensure_icon()
        self.ensure_roles()
        self.build_channels(community_pass=False)
        if self.enable_community():
            self.build_channels(community_pass=True)
        self.fix_positions()
        self.ensure_automod()
        self.ensure_messages()
        IDS_FILE.write_text(json.dumps(self.ids, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"\nSaved ids to {IDS_FILE.relative_to(HERE.parent.parent)}")
        print("Next: docs/community/DISCORD_SERVER.md → 'After the build' (onboarding, bot role, invites).")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="validate the blueprint and print it; no network")
    ap.add_argument("--invite-url", metavar="APP_ID", help="print the bot invite URL for this application id")
    ap.add_argument("--update-messages", action="store_true", help="re-sync welcome/rules/known-issues text")
    args = ap.parse_args()

    bp = load_blueprint()
    if args.invite_url:
        print("Setup invite (Administrator, remove it after the first build):")
        print(f"https://discord.com/oauth2/authorize?client_id={args.invite_url}&scope=bot&permissions=8")
        return
    if args.dry_run:
        print_layout(bp)
        print("\nBlueprint OK.")
        return
    Builder(Client(), bp, args.update_messages).run()


if __name__ == "__main__":
    main()
