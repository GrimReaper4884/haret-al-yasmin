"""Bakes Meshy clip GLBs into Luau bone data the client plays directly (no Studio publishing).

    python tools/anim/bake.py [character ...]

For every character in tools/anim/clips.json, reads assets/unapproved/characters/<id>/clips/<clip>.glb
and writes src/shared/Anim/Clips/<id>.luau.

Why this works: the imported rbxm keeps Meshy's skeleton as Bones under one MeshPart, and every
Meshy GLB of one rig shares the same node defaults (the bind pose), which is also the Bones' rest
CFrame (the root `Hips` only gains a fixed 180° yaw + offset from the importer). So for every bone
    Bone.Transform = rest_local⁻¹ · anim_local
in that bone's own frame, independent of the importer's root fix-up. Translations are in the rig's
raw units (centimetres) and get multiplied by the model's scale at runtime.

Per clip the baker also:
- removes root motion (Hips X/Z drift) so the figure stays on its tile / path point; the measured
  forward speed is kept as `move` (raw units per second) so the client can match walk speed;
- finds the impact frame (peak hand/foot speed) of attack clips and trims them to a short
  wind-up → hit → recover window, so the swing lands when the projectile leaves the hand;
- stores rotations as int16 quaternions (x, y, z with w ≥ 0), base64-encoded.
"""

from __future__ import annotations

import base64
import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CFG = json.loads((ROOT / "tools" / "anim" / "clips.json").read_text(encoding="utf-8"))
SRC = ROOT / "assets" / "unapproved" / "characters"
OUT = ROOT / "src" / "shared" / "Anim" / "Clips"

# Bones that carry the pose; helper leaves (head_end, headfront) and toes stay at rest.
BONES = [
    "Hips", "Spine02", "Spine01", "Spine", "neck", "Head",
    "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
    "RightShoulder", "RightArm", "RightForeArm", "RightHand",
    "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot",
]
EFFECTORS = ["RightHand", "LeftHand", "RightFoot", "LeftFoot"]
FPS = {"idle": 20, "walk": 30, "attack": 30, "ability": 30, "hit": 30}
# Attack windows (seconds around the impact frame).
WIND_UP, RECOVER = 0.42, 0.5


# ------------------------------------------------------------------ quaternion helpers (x, y, z, w)
def qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    )


def qinv(q):
    return (-q[0], -q[1], -q[2], q[3])


def qrot(q, v):
    x, y, z, _ = qmul(qmul(q, (v[0], v[1], v[2], 0.0)), qinv(q))
    return (x, y, z)


def qnorm(q):
    n = math.sqrt(sum(c * c for c in q)) or 1.0
    return tuple(c / n for c in q)


def slerp(a, b, t):
    d = sum(x * y for x, y in zip(a, b))
    if d < 0:
        b, d = tuple(-c for c in b), -d
    if d > 0.9995:
        return qnorm(tuple(x + (y - x) * t for x, y in zip(a, b)))
    th = math.acos(d)
    s = math.sin(th)
    wa, wb = math.sin((1 - t) * th) / s, math.sin(t * th) / s
    return tuple(wa * x + wb * y for x, y in zip(a, b))


# ------------------------------------------------------------------ GLB reading
def read_glb(path: Path):
    f = path.read_bytes()
    jl = struct.unpack("<I", f[12:16])[0]
    j = json.loads(f[20 : 20 + jl])
    bin_start = 20 + jl + 8
    blob = f[bin_start:]

    def accessor(i):
        a = j["accessors"][i]
        bv = j["bufferViews"][a["bufferView"]]
        off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        n = {"SCALAR": 1, "VEC3": 3, "VEC4": 4}[a["type"]]
        assert a["componentType"] == 5126, "float accessors only"
        vals = struct.unpack_from(f"<{a['count'] * n}f", blob, off)
        return [tuple(vals[k * n : (k + 1) * n]) if n > 1 else vals[k] for k in range(a["count"])]

    nodes = j["nodes"]
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i
    anim = j["animations"][0]
    tracks = {}  # node name -> {"translation": (times, values), "rotation": ...}
    for ch in anim["channels"]:
        s = anim["samplers"][ch["sampler"]]
        name = nodes[ch["target"]["node"]]["name"]
        tracks.setdefault(name, {})[ch["target"]["path"]] = (accessor(s["input"]), accessor(s["output"]))
    return nodes, parent, tracks


def sample(track, t, default):
    if not track:
        return default
    times, vals = track
    if t <= times[0]:
        return vals[0]
    if t >= times[-1]:
        return vals[-1]
    lo, hi = 0, len(times) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if times[mid] <= t:
            lo = mid
        else:
            hi = mid
    k = (t - times[lo]) / (times[hi] - times[lo])
    a, b = vals[lo], vals[hi]
    if len(a) == 4:
        return slerp(a, b, k)
    return tuple(x + (y - x) * k for x, y in zip(a, b))


# ------------------------------------------------------------------ baking
def bake_clip(path: Path, slot: str, opts: dict):
    nodes, parent, tracks = read_glb(path)
    byname = {n["name"]: i for i, n in enumerate(nodes)}
    rest = {n["name"]: (tuple(n.get("translation", (0, 0, 0))), tuple(n.get("rotation", (0, 0, 0, 1)))) for n in nodes}
    end = max(max(tr[0][-1] for tr in t.values()) for t in tracks.values())

    def local(name, t):
        tr = tracks.get(name, {})
        return sample(tr.get("translation"), t, rest[name][0]), sample(tr.get("rotation"), t, rest[name][1])

    def world(name, t, cache):
        # Armature-space transform (Armature scale ignored: only relative speeds matter here).
        if name in cache:
            return cache[name]
        p, q = local(name, t)
        pi = parent.get(byname[name])
        pname = nodes[pi]["name"] if pi is not None else None
        if pname is None or pname == "Armature":
            res = (p, q)
        else:
            pp, pq = world(pname, t, cache)
            rp = qrot(pq, p)
            res = ((pp[0] + rp[0], pp[1] + rp[1], pp[2] + rp[2]), qmul(pq, q))
        cache[name] = res
        return res

    fps = opts.get("fps") or FPS[slot]
    src_fps = 30
    n_src = int(round(end * src_fps)) + 1

    # Impact frame: fastest hand/foot (attack slots only).
    hit_t = None
    if slot in ("attack", "ability"):
        prev, best = None, -1.0
        for i in range(n_src):
            t = i / src_fps
            cache = {}
            pos = [world(e, t, cache)[0] for e in EFFECTORS]
            if prev is not None:
                sp = max(math.dist(a, b) for a, b in zip(pos, prev))
                if sp > best:
                    best, hit_t = sp, t
            prev = pos
        if "hit" in opts:
            hit_t = opts["hit"] / src_fps

    t0, t1 = 0.0, end
    if "from" in opts:
        t0 = opts["from"] / src_fps
    elif hit_t is not None:
        t0 = max(0.0, hit_t - WIND_UP)
    if "to" in opts:
        t1 = opts["to"] / src_fps
    elif slot == "hit":
        t1 = min(end, 0.8)  # the flinch only; the rest of a reaction clip is recovery
    elif hit_t is not None:
        t1 = min(end, hit_t + RECOVER)

    # Root motion: forward speed from Hips travel, then pinned to the rest X/Z.
    hp0 = local("Hips", t0)[0]
    hp1 = local("Hips", t1)[0]
    move = math.hypot(hp1[0] - hp0[0], hp1[2] - hp0[2]) / max(1e-6, t1 - t0)

    frames = max(2, int(round((t1 - t0) * fps)) + 1)
    rot_bytes = bytearray()
    hips = []
    for fi in range(frames):
        t = t0 + (t1 - t0) * fi / (frames - 1)
        for b in BONES:
            p, q = local(b, t)
            rp, rq = rest[b]
            d = qnorm(qmul(qinv(rq), q))
            if d[3] < 0:
                d = tuple(-c for c in d)
            rot_bytes += struct.pack("<hhh", *(max(-32767, min(32767, round(c * 32767))) for c in d[:3]))
            if b == "Hips":
                # Pin root X/Z (in-place), keep the vertical bob, express in the Hips' rest frame.
                delta = (rp[0] - rp[0], p[1] - rp[1], rp[2] - rp[2])
                v = qrot(qinv(rq), delta)
                hips.append(tuple(round(c, 2) for c in v))
    clip = {
        "frames": frames,
        "fps": fps,
        "rot": base64.b64encode(bytes(rot_bytes)).decode(),
        "hips": hips,
        "move": round(move, 1),
    }
    if hit_t is not None:
        clip["hit"] = round((hit_t - t0) / (t1 - t0) * (frames - 1), 2)
    return clip


def lua_value(v, indent=1):
    pad = "\t" * indent
    if isinstance(v, dict):
        items = []
        for k, x in v.items():
            items.append(f"{pad}{k} = {lua_value(x, indent + 1)},")
        return "{\n" + "\n".join(items) + "\n" + "\t" * (indent - 1) + "}"
    if isinstance(v, list):
        if v and isinstance(v[0], tuple):
            return "{ " + ", ".join("{" + ", ".join(f"{c:g}" for c in t) + "}" for t in v) + " }"
        return "{ " + ", ".join(lua_value(x, indent + 1) for x in v) + " }"
    if isinstance(v, str):
        return json.dumps(v)
    if isinstance(v, float):
        return f"{v:g}"
    return str(v)


def bake(cid: str):
    slots = CFG["characters"][cid]
    out = {}
    for slot, spec in slots.items():
        opts = spec if isinstance(spec, dict) else {"clip": spec}
        path = SRC / cid / "clips" / f"{opts['clip']}.glb"
        if not path.exists():
            print(f"  {cid}.{slot}: missing {path.relative_to(ROOT)} (run tools/anim/fetch.py)")
            continue
        out[slot] = bake_clip(path, slot, opts)
        out[slot]["name"] = opts["clip"]
    if not out:
        return
    # Rest length of the shin in rig units: the client divides the live bone offset by it to get
    # the model's scale (Model scale does not survive every clone / replication path).
    nodes, _, _ = read_glb(next((SRC / cid / "clips").glob("*.glb")))
    leg = next(n for n in nodes if n["name"] == "LeftLeg")
    ref = round(math.sqrt(sum(c * c for c in leg.get("translation", (0, 0, 0)))), 3)
    OUT.mkdir(parents=True, exist_ok=True)
    body = (
        "--!strict\n"
        f"-- Generated by tools/anim/bake.py from Meshy clips ({', '.join(f'{k}={v['name']}' for k, v in out.items())}).\n"
        "-- Do not edit: change tools/anim/clips.json and rebake. See Anim/BoneAnim for the format.\n"
        "return {\n"
        f"\tbones = {lua_value(BONES)},\n"
        + "".join(f"\t{slot} = {lua_value(clip, 2)},\n" for slot, clip in out.items())
        + "}\n"
    )
    (OUT / f"{cid}.luau").write_text(body, encoding="utf-8", newline=chr(10))
    kb = len(body.encode()) // 1024
    print(f"{cid}: " + ", ".join(f"{k}={v['name']}({v['frames']}f" + (f", hit {v['hit']}" if 'hit' in v else "") + ")" for k, v in out.items()) + f"  [{kb} KB]")


if __name__ == "__main__":
    for cid in sys.argv[1:] or list(CFG["characters"]):
        bake(cid)
