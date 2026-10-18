"""Cuts character portraits out of Studio captures (POLISH_PLAN PV-C05).

    python tools/icons/portraits.py <capture.jpg> <id,id,...> [--size 128]

The capture comes from tools/icons/portrait_render.luau (run in the Client context during Play, then
`screen_capture`): a 6 x 2 grid of 250 px ViewportFrames at (60 + col*250, 60 + row*255) on pure
magenta. `ids` lists the characters in grid order; `-` skips a cell. Each cell is keyed (magenta and
its JPEG fringe become transparent), given the 2 px dark outline of the icon kit and saved as
assets/marketing/portraits/<Model>.png, where Model is CharacterLooks[id].model, or <id>_primitive.png
for a figure that has no imported model yet. The file name is what Config/Icons.portraits records, so
a portrait is only shown while it matches the character's current model. Needs Pillow.
"""

import argparse
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "marketing" / "portraits"
CELL, X0, Y0, DX, DY, COLS = 250, 60, 60, 250, 255, 6
INSET = 2  # the ViewportFrame's 1 px border
OUTLINE = (31, 27, 24)


def models() -> dict[str, str]:
    text = (ROOT / "src/shared/Config/CharacterLooks.luau").read_text(encoding="utf-8")
    out = {}
    for block in re.split(r"\n\t(?=[a-z_]+ = \{)", text):
        m = re.match(r"([a-z_]+) = \{.*?model = \"(\w+)\"", block, re.S)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def key(cell: Image.Image) -> Image.Image:
    """Alpha from the distance to magenta: far = opaque, near = clear, a soft ramp in between."""
    im = cell.convert("RGB")
    r, g, b = im.split()
    # magenta has high R and B and low G: score = how much green rises above min(R, B), plus how far R/B fall
    mag = ImageChops.subtract(ImageChops.darker(r, b), g)  # 255 on pure magenta, ~0 on most colours
    alpha = mag.point(lambda v: 255 if v < 90 else (0 if v > 170 else int(255 * (170 - v) / 80)))
    alpha = alpha.filter(ImageFilter.MinFilter(3))  # eat the JPEG fringe
    # despill near the edge only: lift green toward min(R, B) so leftover magenta tint turns neutral
    lifted = ImageChops.lighter(g, ImageChops.multiply(ImageChops.darker(r, b), Image.new("L", im.size, 200)))
    edge = ImageChops.invert(alpha).filter(ImageFilter.MaxFilter(5))
    g2 = Image.composite(lifted, g, edge)
    return Image.merge("RGBA", (r, g2, b, alpha))


def outline(im: Image.Image, width: int) -> Image.Image:
    a = im.getchannel("A")
    grown = a.filter(ImageFilter.MaxFilter(2 * width + 1))
    base = Image.new("RGBA", im.size, OUTLINE + (0,))
    base.putalpha(grown)
    base.alpha_composite(im)
    return base


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("capture")
    ap.add_argument("ids")
    ap.add_argument("--size", type=int, default=128)
    a = ap.parse_args()
    look = models()
    page = Image.open(a.capture)
    OUT.mkdir(parents=True, exist_ok=True)
    for k, cid in enumerate(a.ids.split(",")):
        if cid == "-":
            continue
        col, row = k % COLS, k // COLS
        x, y = X0 + col * DX, Y0 + row * DY
        cell = page.crop((x + INSET, y + INSET, x + CELL - INSET, y + CELL - INSET))
        big = key(cell).resize((a.size * 2, a.size * 2), Image.LANCZOS)
        im = outline(big, 4).resize((a.size, a.size), Image.LANCZOS)  # 4 px at 2x = 2 px at size
        name = look.get(cid) or f"{cid}_primitive"
        im.save(OUT / f"{name}.png")
        print(f"{cid} -> assets/marketing/portraits/{name}.png")


if __name__ == "__main__":
    main()
