"""Downsizes the textures embedded in a GLB so they fit the asset budget (CHARACTER_PIPELINE.md
§Budgets: one base-colour map, 1024² max, 512² for enemies). Meshy's image-to-3d returns 2048²
maps; Studio uploads whatever the GLB carries, so shrink before importing.

    python tools/meshy/shrink_textures.py <in.glb> <out.glb> [--max 1024]

Only images stored in buffer views are touched (Meshy embeds them that way); geometry, materials
and accessors are copied byte for byte. Needs Pillow.
"""

import argparse
import io
import json
import struct
import sys

from PIL import Image


def read_glb(path):
    data = open(path, "rb").read()
    magic, version, _ = struct.unpack("<4sII", data[:12])
    if magic != b"glTF" or version != 2:
        sys.exit(f"{path}: not a glTF 2 binary")
    off = 12
    doc, binary = None, b""
    while off < len(data):
        length, kind = struct.unpack("<I4s", data[off : off + 8])
        chunk = data[off + 8 : off + 8 + length]
        if kind == b"JSON":
            doc = json.loads(chunk)
        elif kind == b"BIN\x00":
            binary = chunk
        off += 8 + length
    return doc, binary


def write_glb(path, doc, binary):
    js = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    js += b" " * (-len(js) % 4)
    binary += b"\x00" * (-len(binary) % 4)
    total = 12 + 8 + len(js) + 8 + len(binary)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<I4s", len(js), b"JSON") + js)
        f.write(struct.pack("<I4s", len(binary), b"BIN\x00") + binary)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--max", type=int, default=1024)
    a = ap.parse_args()

    doc, binary = read_glb(a.src)
    views = doc["bufferViews"]
    replaced = {}  # bufferView index -> new bytes
    for img in doc.get("images", []):
        bv = img.get("bufferView")
        if bv is None:
            continue
        v = views[bv]
        start = v.get("byteOffset", 0)
        raw = binary[start : start + v["byteLength"]]
        im = Image.open(io.BytesIO(raw))
        if max(im.size) <= a.max:
            continue
        scale = a.max / max(im.size)
        im = im.resize((round(im.size[0] * scale), round(im.size[1] * scale)), Image.LANCZOS)
        out = io.BytesIO()
        if img.get("mimeType") == "image/jpeg":
            im.convert("RGB").save(out, "JPEG", quality=90)
        else:
            im.save(out, "PNG", optimize=True)
        replaced[bv] = out.getvalue()
        print(f"image {bv}: {raw and Image.open(io.BytesIO(raw)).size} -> {im.size}")

    # Rebuild the binary chunk with every buffer view in order, 4-byte aligned.
    new_bin = bytearray()
    for i, v in enumerate(views):
        start = v.get("byteOffset", 0)
        chunk = replaced.get(i, binary[start : start + v["byteLength"]])
        new_bin += b"\x00" * (-len(new_bin) % 4)
        v["byteOffset"] = len(new_bin)
        v["byteLength"] = len(chunk)
        new_bin += chunk
    doc["buffers"][0]["byteLength"] = len(new_bin)
    write_glb(a.dst, doc, bytes(new_bin))
    print(f"wrote {a.dst} ({len(new_bin) // 1024} KB binary)")


if __name__ == "__main__":
    main()
