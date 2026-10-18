"""Writes a GLB that plays a *baked* slot (src/shared/Anim/Clips/<id>.luau) on the character's rig,
so the in-game result can be checked in Blender (tools/anim/preview.py) without Studio.

    python tools/anim/baked_glb.py <id> <slot> <out.glb> [<mesh.glb>]

Rebuilds each bone's local transform as rest · delta (the inverse of tools/anim/bake.py), with the
root pinned in place exactly as the client plays it.
"""

import base64
import json
import math
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).parent))
from bake import qmul, qrot  # noqa: E402

cid, slot, out = sys.argv[1], sys.argv[2], Path(sys.argv[3])
src = (ROOT / "src" / "shared" / "Anim" / "Clips" / f"{cid}.luau").read_text(encoding="utf-8")
bones = re.findall(r'"(\w+)"', re.search(r"bones = \{(.*?)\}", src).group(1))
blk = src[src.index(f"\t{slot} = {{") :]
frames = int(re.search(r"frames = (\d+)", blk).group(1))
fps = int(re.search(r"fps = (\d+)", blk).group(1))
rot = base64.b64decode(re.search(r'rot = "([^"]+)"', blk).group(1))
hips = [tuple(float(c) for c in m) for m in re.findall(r"\{([-\d.e]+), ([-\d.e]+), ([-\d.e]+)\}", re.search(r"hips = \{(.*?)\},\n", blk).group(1))]

rig = Path(sys.argv[4]) if len(sys.argv) > 4 else ROOT / "assets" / "unapproved" / "characters" / cid / f"{cid}_rigged.glb"  # optional mesh (e.g. a one-armed cut)
f = rig.read_bytes()
jl = struct.unpack("<I", f[12:16])[0]
j = json.loads(f[20 : 20 + jl])
blob = bytearray(f[20 + jl + 8 :])
byname = {n["name"]: i for i, n in enumerate(j["nodes"])}

def add(data: bytes, count: int, typ: str, extra=None) -> int:
    while len(blob) % 4:
        blob.append(0)
    off = len(blob)
    blob.extend(data)
    j["bufferViews"].append({"buffer": 0, "byteOffset": off, "byteLength": len(data)})
    acc = {"bufferView": len(j["bufferViews"]) - 1, "componentType": 5126, "count": count, "type": typ}
    acc.update(extra or {})
    j["accessors"].append(acc)
    return len(j["accessors"]) - 1

times = [i / fps for i in range(frames)]
t_acc = add(struct.pack(f"<{frames}f", *times), frames, "SCALAR", {"min": [0.0], "max": [times[-1]]})
channels, samplers = [], []
for bi, name in enumerate(bones):
    node = j["nodes"][byname[name]]
    rq = tuple(node.get("rotation", (0, 0, 0, 1)))
    rp = tuple(node.get("translation", (0, 0, 0)))
    qs, ps = [], []
    for fi in range(frames):
        k = (fi * len(bones) + bi) * 6
        x, y, z = (c / 32767 for c in struct.unpack_from("<hhh", rot, k))
        d = (x, y, z, math.sqrt(max(0.0, 1 - x * x - y * y - z * z)))
        qs.extend(qmul(rq, d))
        if name == "Hips":
            v = qrot(rq, hips[fi])
            ps.extend((rp[0] + v[0], rp[1] + v[1], rp[2] + v[2]))
    samplers.append({"input": t_acc, "output": add(struct.pack(f"<{len(qs)}f", *qs), frames, "VEC4"), "interpolation": "LINEAR"})
    channels.append({"sampler": len(samplers) - 1, "target": {"node": byname[name], "path": "rotation"}})
    if ps:
        samplers.append({"input": t_acc, "output": add(struct.pack(f"<{len(ps)}f", *ps), frames, "VEC3"), "interpolation": "LINEAR"})
        channels.append({"sampler": len(samplers) - 1, "target": {"node": byname[name], "path": "translation"}})
j["animations"] = [{"name": f"baked_{slot}", "channels": channels, "samplers": samplers}]
while len(blob) % 4:
    blob.append(0)
j["buffers"][0]["byteLength"] = len(blob)
js = json.dumps(j).encode()
while len(js) % 4:
    js += b" "
body = struct.pack("<I4s", len(js), b"JSON") + js + struct.pack("<I4s", len(blob), b"BIN\0") + bytes(blob)
out.write_bytes(struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body)
print(f"{cid}.{slot}: {frames} frames -> {out}")
