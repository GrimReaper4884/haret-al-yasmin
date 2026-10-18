"""Removes the triangles of a rigged Meshy GLB that are skinned mostly to the given bones, without
touching the skeleton (like tools/anim/islands.py, only the index buffer is rewritten, so every clip
baked by tools/anim/bake.py still fits).

Made for Al-Adashari (S1-A05): Meshy's image-to-3D gave the one-armed night guard two arms, so his
left forearm and hand are dropped and the bake pins the remaining sleeve to his side.

    python tools/anim/dropbones.py <in.glb> <out.glb> <bone> [<bone> ...]

A triangle goes when any of its corners has its largest skin weight on one of the bones.
"""

import json
import struct
import sys


def load(path):
    f = open(path, "rb").read()
    jl = struct.unpack("<I", f[12:16])[0]
    j = json.loads(f[20 : 20 + jl])
    blob = bytearray(f[20 + jl + 8 :])
    return j, blob


def accessor(j, blob, i):
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    fmt = {5121: "B", 5123: "H", 5125: "I", 5126: "f"}[a["componentType"]]
    stride = bv.get("byteStride", n * struct.calcsize(fmt))
    rows = [struct.unpack_from("<" + fmt * n, blob, off + k * stride) for k in range(a["count"])]
    return rows, a, off, fmt


def main():
    src, out, names = sys.argv[1], sys.argv[2], set(sys.argv[3:])
    j, blob = load(src)
    joints = [j["nodes"][i]["name"] for i in j["skins"][0]["joints"]]
    dropped_joints = {k for k, n in enumerate(joints) if n in names}
    missing = names - {joints[k] for k in dropped_joints}
    if missing:
        sys.exit(f"no such bones: {sorted(missing)}")
    prim = j["meshes"][0]["primitives"][0]
    jts, _, _, _ = accessor(j, blob, prim["attributes"]["JOINTS_0"])
    wts, _, _, _ = accessor(j, blob, prim["attributes"]["WEIGHTS_0"])
    idx_rows, ia, ioff, fmt = accessor(j, blob, prim["indices"])
    idx = [r[0] for r in idx_rows]
    gone = set()
    for v, (js, ws) in enumerate(zip(jts, wts)):
        best = max(range(4), key=lambda k: ws[k])
        if js[best] in dropped_joints:
            gone.add(v)
    keep = []
    for t in range(0, len(idx), 3):
        tri = idx[t : t + 3]
        if not any(v in gone for v in tri):
            keep.extend(tri)
    struct.pack_into(f"<{len(keep)}{fmt}", blob, ioff, *keep)
    ia["count"] = len(keep)
    js = json.dumps(j).encode()
    while len(js) % 4:
        js += b" "
    while len(blob) % 4:
        blob.append(0)
    body = struct.pack("<I4s", len(js), b"JSON") + js + struct.pack("<I4s", len(blob), b"BIN\0") + bytes(blob)
    open(out, "wb").write(struct.pack("<4sII", b"glTF", 2, 12 + len(body)) + body)
    print(f"kept {len(keep) // 3} of {len(idx) // 3} triangles -> {out}")


main()
