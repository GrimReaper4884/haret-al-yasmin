"""Lists or removes loose mesh islands in a Meshy character GLB, without touching the skeleton.

Meshy fuses hand-held props into the body mesh, skinned to whatever bone was nearest (Abu Hatem's
coffee pot floats at his hip and swings with the thigh). Removing those triangles from the index
buffer keeps every node, bone rest pose and skin identical, so the baked clips (tools/anim/bake.py)
still match the re-imported model.

    python tools/anim/islands.py list <in.glb>
    python tools/anim/islands.py drop <in.glb> <out.glb> <island> [<island> ...]
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


def accessor_view(j, blob, i):
    a = j["accessors"][i]
    bv = j["bufferViews"][a["bufferView"]]
    off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    return a, off


def islands(j, blob):
    prim = j["meshes"][0]["primitives"][0]
    ia, ioff = accessor_view(j, blob, prim["indices"])
    fmt = {5125: "I", 5123: "H"}[ia["componentType"]]
    idx = struct.unpack_from(f"<{ia['count']}{fmt}", blob, ioff)
    pa, poff = accessor_view(j, blob, prim["attributes"]["POSITION"])
    pos = [struct.unpack_from("<3f", blob, poff + 12 * k) for k in range(pa["count"])]
    # Union-find over vertices sharing triangles, plus vertices at the same position (UV seams).
    parent = list(range(pa["count"]))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    for t in range(0, len(idx), 3):
        union(idx[t], idx[t + 1])
        union(idx[t], idx[t + 2])
    seen = {}
    for v, p in enumerate(pos):
        key = (round(p[0], 4), round(p[1], 4), round(p[2], 4))
        if key in seen:
            union(v, seen[key])
        else:
            seen[key] = v
    comps = {}
    for t in range(0, len(idx), 3):
        comps.setdefault(find(idx[t]), []).append(t)
    out = sorted(comps.values(), key=len, reverse=True)
    return idx, pos, out, ia, ioff, fmt


def bbox(pos, idx, tris):
    vs = [pos[idx[t + k]] for t in tris for k in range(3)]
    lo = [min(v[i] for v in vs) for i in range(3)]
    hi = [max(v[i] for v in vs) for i in range(3)]
    return lo, hi


def main():
    mode, src = sys.argv[1], sys.argv[2]
    j, blob = load(src)
    idx, pos, comps, ia, ioff, fmt = islands(j, blob)
    if mode == "list":
        for n, tris in enumerate(comps):
            lo, hi = bbox(pos, idx, tris)
            c = [round((a + b) / 2, 3) for a, b in zip(lo, hi)]
            size = [round(b - a, 3) for a, b in zip(lo, hi)]
            print(f"{n:>3}: {len(tris):>6} tris  centre {c}  size {size}")
        return
    out, drop = sys.argv[3], {int(x) for x in sys.argv[4:]}
    keep = [i for n, tris in enumerate(comps) if n not in drop for t in tris for i in idx[t : t + 3]]
    # Rewrite the index accessor in place (shorter list; the tail of the old range is unused).
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
