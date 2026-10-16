"""Builds one review image from Meshy outputs: each id's concept (or mesh_front for props) with
its label, on a light background (transparent PNGs otherwise show black).

    python tools/meshy/contact_sheet.py out.png characters umm_hara hallaq ...
    python tools/meshy/contact_sheet.py out.png props gate fountain ...
    python tools/meshy/contact_sheet.py out.png characters --mesh umm_hara ...   (3D front views)
Needs Pillow (pip install pillow).
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
out, kind, ids = sys.argv[1], sys.argv[2], [a for a in sys.argv[3:] if a != "--mesh"]
prefer_mesh = kind == "props" or "--mesh" in sys.argv
base = ROOT / "assets" / "unapproved" / kind
CELL_W, CELL_H, LABEL = 300, 380, 34
cols = min(len(ids), 5)
rows = (len(ids) + cols - 1) // cols
sheet = Image.new("RGB", (cols * CELL_W, rows * (CELL_H + LABEL)), (233, 223, 203))
draw = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arial.ttf", 22)
except OSError:
    font = ImageFont.load_default()

for i, cid in enumerate(ids):
    folder = base / cid
    pick = None
    for name in ("mesh_front.png", "concept.png") if prefer_mesh else ("concept.png", "mesh_front.png"):
        if (folder / name).exists():
            pick = folder / name
            break
    x, y = (i % cols) * CELL_W, (i // cols) * (CELL_H + LABEL)
    if pick:
        img = Image.open(pick).convert("RGBA")
        img.thumbnail((CELL_W - 10, CELL_H - 10))
        bg = Image.new("RGBA", img.size, (233, 223, 203, 255))
        bg.alpha_composite(img)
        sheet.paste(bg.convert("RGB"), (x + (CELL_W - img.width) // 2, y + (CELL_H - img.height) // 2))
    draw.text((x + CELL_W // 2, y + CELL_H + LABEL // 2), cid, fill=(42, 33, 27), font=font, anchor="mm")

sheet.save(out)
print("saved", out)
