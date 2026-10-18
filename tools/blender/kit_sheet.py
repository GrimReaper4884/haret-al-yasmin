"""Combines the kit thumbnails (docs/art/kit/*.png, written by tools/blender/export_kit.py) into one
labelled review sheet with each module's triangle count (assets/unapproved/kit/kit_report.json).

    python -I tools/blender/kit_sheet.py docs/art/kit_sheet_<date>.png

Needs Pillow.
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
out = Path(sys.argv[1])
thumbs = sorted((ROOT / "docs" / "art" / "kit").glob("kit_*.png"))
report = json.loads((ROOT / "assets" / "unapproved" / "kit" / "kit_report.json").read_text(encoding="utf-8"))
CELL, LABEL, COLS = 240, 40, 6
rows = (len(thumbs) + COLS - 1) // COLS
sheet = Image.new("RGB", (COLS * CELL, rows * (CELL + LABEL)), (233, 223, 203))
draw = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arial.ttf", 15)
except OSError:
    font = ImageFont.load_default()
for i, path in enumerate(thumbs):
    name = path.stem
    img = Image.open(path).convert("RGB")
    img.thumbnail((CELL - 8, CELL - 8))
    x, y = (i % COLS) * CELL, (i // COLS) * (CELL + LABEL)
    sheet.paste(img, (x + (CELL - img.width) // 2, y + 4))
    tris = report.get(name, {}).get("tris", "?")
    label = f"{name.removeprefix('kit_')}  ·  {tris} tris"
    w = draw.textlength(label, font=font)
    draw.text((x + (CELL - w) / 2, y + CELL + 10), label, fill=(40, 30, 20), font=font)
sheet.save(out)
print("saved", out, len(thumbs), "modules")
