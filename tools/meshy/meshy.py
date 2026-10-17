"""Meshy AI pipeline for Haret Al-Yasmin characters (docs/CHARACTER_PIPELINE.md).

Reads prompts from tools/meshy/characters.json and drives the Meshy API:
text-to-image concept (T-pose) -> image-to-3d (mesh + texture) -> rigging -> animations, then downloads the results into
assets/unapproved/characters/<id>/ with a manifest.json recording every task id and the credits
spent. Every step is resumable: rerunning `make` skips steps whose task already succeeded.

The API key is read from the MESHY_API_KEY environment variable (never stored in the repo).

Usage (from the repo root):
    python tools/meshy/meshy.py balance
    python tools/meshy/meshy.py library [--search idle] [--category Fighting]
    python tools/meshy/meshy.py make hallaq [--until concept|mesh|rig|anim]
    python tools/meshy/meshy.py make gate            (props stop after the textured mesh)
    python tools/meshy/meshy.py status hallaq
    python tools/meshy/meshy.py clip qahwaji attack 421     (one library action on an existing rig,
                                                        saved as clips/attack.glb; 3 credits)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.meshy.ai/openapi"
ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "tools" / "meshy" / "characters.json"
OUT = ROOT / "assets" / "unapproved" / "characters"
PROPS_OUT = ROOT / "assets" / "unapproved" / "props"
STEPS = ["concept", "mesh", "rig", "anim"]


def key() -> str:
    k = os.environ.get("MESHY_API_KEY", "").strip()
    if not k and sys.platform == "win32":
        # `setx` writes the user environment, which running processes don't see until restarted.
        import winreg

        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as reg:
                k = str(winreg.QueryValueEx(reg, "MESHY_API_KEY")[0]).strip()
        except OSError:
            k = ""
    if not k:
        sys.exit("MESHY_API_KEY is not set. In PowerShell: setx MESHY_API_KEY \"msy_...\" then open a new terminal.")
    return k


def call(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method)
    req.add_header("Authorization", "Bearer " + key())
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        sys.exit(f"Meshy {method} {path} failed: HTTP {e.code} {e.read().decode(errors='replace')[:400]}")


def wait(path: str, label: str) -> dict:
    """Polls a task until it finishes. Returns the task object (exits on failure)."""
    last = -1
    while True:
        t = call("GET", path)
        status, progress = t.get("status"), t.get("progress", 0)
        if progress != last:
            print(f"  {label}: {status} {progress}%", flush=True)
            last = progress
        if status == "SUCCEEDED":
            return t
        if status in ("FAILED", "CANCELED"):
            msg = (t.get("task_error") or {}).get("message", "")
            sys.exit(f"  {label} {status}: {msg}")
        time.sleep(6)


def download(url: str, dest: Path):
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=300) as r, open(dest, "wb") as f:
        f.write(r.read())
    print(f"  saved {dest.relative_to(ROOT)} ({dest.stat().st_size // 1024} KB)")


def load_config() -> dict:
    return json.loads(CONFIG.read_text(encoding="utf-8"))


def folder_for(cid: str) -> Path:
    """Characters go to assets/unapproved/characters/<id>, props to assets/unapproved/props/<id>."""
    if cid in load_config().get("props", {}):
        return PROPS_OUT / cid
    return OUT / cid


def manifest_path(cid: str) -> Path:
    return folder_for(cid) / "manifest.json"


def load_manifest(cid: str) -> dict:
    p = manifest_path(cid)
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {"id": cid, "tasks": {}, "credits": {}}


def save_manifest(cid: str, m: dict):
    p = manifest_path(cid)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(m, indent=2), encoding="utf-8")


def make(cid: str, until: str):
    cfg = load_config()
    prop = cfg.get("props", {}).get(cid)
    ch = prop or cfg["characters"].get(cid)
    if not ch:
        sys.exit(f"No character or prop '{cid}' in {CONFIG.name}")
    m = load_manifest(cid)
    tasks, credits = m["tasks"], m["credits"]
    stop = STEPS.index(until)
    folder = folder_for(cid)

    # 1. Concept art: a styled full-body T-pose image. Text-to-3D alone ignored the cartoon style
    #    and the costume (two realistic barbers without fez or apron), so the look is fixed here,
    #    where it is cheap to iterate (~6 credits), and the 3D step copies it.
    if "concept" not in tasks:
        if prop:
            prompt = (cfg["prop_style"] + " " + ch["prompt"] + " " + ch["texture"])[:2000]
        else:
            # Attackers opt into the colder, hostile texture style ("texture_style": "enemy").
            tstyle = cfg["enemy_texture_style"] if ch.get("texture_style") == "enemy" else cfg["texture_style"]
            prompt = (cfg["style"] + " " + ch["prompt"] + " " + ch["texture"] + " " + tstyle)[:2000]
        body = {"ai_model": "nano-banana-2", "prompt": prompt, "remove_background": True}
        if not prop and ch.get("pose", True):
            body["pose_mode"] = "t-pose"  # the auto-rigger needs a T-pose
        r = call("POST", "/v1/text-to-image", body)
        tasks["concept"] = r["result"]
        save_manifest(cid, m)
    t = wait(f"/v1/text-to-image/{tasks['concept']}", "concept")
    credits["concept"] = t.get("consumed_credits", 0)
    images = t.get("image_urls") or []
    if images:
        download(images[0], folder / "concept.png")
    save_manifest(cid, m)
    if stop < 1:
        return

    # 2. Mesh + texture straight from the concept (keeps its colours), remeshed to a mobile budget,
    #    base colour only (no PBR maps: stylized look, one texture per unit).
    if "mesh" not in tasks:
        body = {
            "input_task_id": tasks["concept"],
            "ai_model": "latest",
            "should_texture": True,
            "enable_pbr": False,
            "texture_resolution": "2k",
            "should_remesh": True,
            "topology": "triangle",
            "target_polycount": int(ch.get("polycount", 8000)),
            "image_enhancement": False,
            "multi_view_thumbnails": True,
            "target_formats": ["glb", "fbx"],
        }
        if not prop and ch.get("pose", True):
            body["pose_mode"] = "t-pose"
        r = call("POST", "/v1/image-to-3d", body)
        tasks["mesh"] = r["result"]
        save_manifest(cid, m)
    t = wait(f"/v1/image-to-3d/{tasks['mesh']}", "mesh")
    credits["mesh"] = t.get("consumed_credits", 0)
    urls = t.get("model_urls") or {}
    if urls.get("glb"):
        download(urls["glb"], folder / f"{cid}_static.glb")
    for view, url in (t.get("thumbnail_urls") or {"front": t.get("thumbnail_url")}).items():
        if url:
            download(url, folder / f"mesh_{view}.png")
    save_manifest(cid, m)
    # Props and non-bipeds (the auto-rigger only handles humanoids) stop at the textured mesh.
    if stop < 2 or prop or not ch.get("rig", True):
        if prop or not ch.get("rig", True):
            print(f"done: {cid} (static mesh) — credits {sum(credits.values())}")
        return

    # 3. Auto-rig (humanoid skeleton) from the textured task.
    if "rig" not in tasks:
        r = call("POST", "/v1/rigging", {"input_task_id": tasks["mesh"], "height_meters": ch.get("height", 1.7)})
        tasks["rig"] = r["result"]
        save_manifest(cid, m)
    t = wait(f"/v1/rigging/{tasks['rig']}", "rig")
    credits["rig"] = t.get("consumed_credits", 0)
    res = t.get("result") or {}
    if res.get("rigged_character_fbx_url"):
        download(res["rigged_character_fbx_url"], folder / f"{cid}_rigged.fbx")
    # GLB is Y-up by spec; Meshy's clip FBX files came in rotated 90° against the rigged FBX in
    # Studio, so the GLBs are the ones to import.
    if res.get("rigged_character_glb_url"):
        download(res["rigged_character_glb_url"], folder / f"{cid}_rigged.glb")
    basic = res.get("basic_animations") or {}
    if basic.get("walking_fbx_url"):
        download(basic["walking_fbx_url"], folder / f"{cid}_walk.fbx")
    if basic.get("walking_glb_url"):
        download(basic["walking_glb_url"], folder / f"{cid}_walk.glb")
    save_manifest(cid, m)
    if stop < 3:
        return

    # 4. One clip per file (Roblox imports one track per FBX), 30 fps.
    anims = {k: v for k, v in cfg["animations"].items() if not k.startswith("_") and v is not None}
    if not anims:
        print("  no animation ids configured yet: run `library` and fill characters.json → animations")
        return
    for name, action in anims.items():
        tk = "anim_" + name
        if tk not in tasks:
            r = call("POST", "/v1/animations", {
                "rig_task_id": tasks["rig"],
                "action_id": int(action),
                "post_process": {"operation_type": "change_fps", "fps": 30},
            })
            tasks[tk] = r["result"]
            save_manifest(cid, m)
        t = wait(f"/v1/animations/{tasks[tk]}", tk)
        credits[tk] = t.get("consumed_credits", 0)
        res = t.get("result") or {}
        url = res.get("processed_animation_fps_fbx_url") or res.get("animation_fbx_url")
        if url:
            download(url, folder / f"{cid}_{name}.fbx")
        if res.get("animation_glb_url"):
            download(res["animation_glb_url"], folder / f"{cid}_{name}.glb")
        save_manifest(cid, m)
    print(f"done: {cid} — credits so far {sum(credits.values())}")


def clip(cid: str, name: str, action: int):
    """Fetches one library action for a character's existing rig into <folder>/clips/<name>.glb.
    These GLBs are baked into Luau bone data by tools/anim/bake.py (no Studio publishing)."""
    m = load_manifest(cid)
    tasks, credits = m["tasks"], m["credits"]
    if "rig" not in tasks:
        sys.exit(f"{cid} has no rig task yet: run `make {cid} --until rig` first")
    tk = f"clip_{name}"
    out = folder_for(cid) / "clips" / f"{name}.glb"
    known = m.setdefault("clips", {}).get(name)
    if out.exists() and known in (None, action):
        m["clips"][name] = action  # already fetched (parallel runs can drop manifest entries)
        save_manifest(cid, m)
        return
    if known != action:
        tasks.pop(tk, None)  # a different action under the same name: fetch again
    if tk not in tasks:
        r = call("POST", "/v1/animations", {"rig_task_id": tasks["rig"], "action_id": int(action)})
        tasks[tk] = r["result"]
        m["clips"][name] = action
        save_manifest(cid, m)
    t = wait(f"/v1/animations/{tasks[tk]}", tk)
    credits[tk] = t.get("consumed_credits", 0)
    res = t.get("result") or {}
    if res.get("animation_glb_url"):
        download(res["animation_glb_url"], out)
    save_manifest(cid, m)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("balance")
    lib = sub.add_parser("library")
    lib.add_argument("--search")
    lib.add_argument("--category")
    mk = sub.add_parser("make")
    mk.add_argument("id")
    mk.add_argument("--until", choices=STEPS, default="anim")
    cl = sub.add_parser("clip")
    cl.add_argument("id")
    cl.add_argument("name")
    cl.add_argument("action", type=int)
    st = sub.add_parser("status")
    st.add_argument("id")
    a = ap.parse_args()

    if a.cmd == "balance":
        print(call("GET", "/v1/balance"))
    elif a.cmd == "library":
        q = []
        if a.search:
            q.append("search=" + urllib.request.quote(a.search))
        if a.category:
            q.append("category=" + a.category)
        rows = call("GET", "/v1/animations/library" + ("?" + "&".join(q) if q else ""))
        items = rows if isinstance(rows, list) else rows.get("result", rows.get("data", []))
        for it in items:
            print(f"{it.get('action_id'):>5}  {it.get('category', ''):<14} {it.get('sub_category', ''):<22} {it.get('name')}")
    elif a.cmd == "make":
        make(a.id, a.until)
    elif a.cmd == "clip":
        clip(a.id, a.name, a.action)
    elif a.cmd == "status":
        print(json.dumps(load_manifest(a.id), indent=2))


if __name__ == "__main__":
    main()
