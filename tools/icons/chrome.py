"""Builds the Theme v2 9-slice chrome frames (LP-C01, LP-F03) from the generated material textures.

    python tools/icons/chrome.py [--raw assets/marketing/icons/raw/chrome] [--out assets/marketing/icons]

Each frame is a border with a transparent centre: Theme.chrome lays the image over a button or panel, so the
button's own colour (wood, danger red, confirm green, gold) and its text show through and only the edge changes.
Sizes and slice rects match `Config/Icons.chrome` exactly; corners stay inside the slice corners and every edge is
uniform along its length, so 9-slice stretching does not smear an ornament. Drawn at 4x and downsampled. Needs Pillow.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SS = 4  # supersampling
OUTLINE = (42, 30, 20, 255)


def rrect_mask(size, inset, radius):
    w, h = size
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle((inset, inset, w - 1 - inset, h - 1 - inset), radius=max(0, radius - inset), fill=255)
    return m


def band(size, outer_inset, width, radius):
    """Mask of a rounded-rect ring from outer_inset to outer_inset + width."""
    return ImageChops.subtract(rrect_mask(size, outer_inset, radius), rrect_mask(size, outer_inset + width, radius))


def fill(size, texture: Image.Image, tile: int):
    """The texture scaled so one tile is `tile` px, tiled over the canvas."""
    t = texture.convert("RGBA").resize((tile, tile), Image.LANCZOS)
    out = Image.new("RGBA", size)
    for y in range(0, size[1], tile):
        for x in range(0, size[0], tile):
            out.paste(t, (x, y))
    return out


def bevel(size, mask: Image.Image, strength: float):
    """Light from the top: brighten the upper half of a band, darken the lower half."""
    w, h = size
    grad = Image.linear_gradient("L").resize((w, h))  # 0 at top -> 255 at bottom
    light = Image.new("RGBA", size, (255, 245, 220, 0))
    light.putalpha(ImageChops.multiply(mask, grad.point(lambda v: int(max(0, 128 - v) * strength * 2))))
    dark = Image.new("RGBA", size, (30, 18, 8, 0))
    dark.putalpha(ImageChops.multiply(mask, grad.point(lambda v: int(max(0, v - 128) * strength * 2))))
    return light, dark


def layer(canvas: Image.Image, src: Image.Image, mask: Image.Image):
    src = src.copy()
    src.putalpha(ImageChops.multiply(src.getchannel("A"), mask))
    canvas.alpha_composite(src)


def frame(size, radius, rings, texture_of, inner_shadow=0.0):
    """rings: list of (width, material or None for the outline colour, bevel strength), outermost first."""
    W, H = size[0] * SS, size[1] * SS
    S = (W, H)
    canvas = Image.new("RGBA", S, (0, 0, 0, 0))
    inset = 0
    for width, material, bev in rings:
        m = band(S, inset, width * SS, radius * SS)
        if material is None:
            layer(canvas, Image.new("RGBA", S, OUTLINE), m)
        else:
            layer(canvas, texture_of(material, S), m)
            if bev:
                lt, dk = bevel(S, m, bev)
                canvas.alpha_composite(lt)
                canvas.alpha_composite(dk)
        inset += width * SS
    if inner_shadow:
        # a soft dark rim just inside the frame, so the centre colour reads as set into it
        rim = band(S, inset, 4 * SS, radius * SS).filter(ImageFilter.GaussianBlur(2 * SS))
        sh = Image.new("RGBA", S, (20, 10, 4, 0))
        sh.putalpha(rim.point(lambda v: int(v * inner_shadow)))
        canvas.alpha_composite(sh)
    return canvas, inset // SS


def corners(canvas: Image.Image, ornament: Image.Image, px: int, at: int):
    o = ornament.resize((px * SS, px * SS), Image.LANCZOS)
    W, H = canvas.size
    a = at * SS
    for x, y in ((a, a), (W - a - px * SS, a), (a, H - a - px * SS), (W - a - px * SS, H - a - px * SS)):
        canvas.alpha_composite(o, (x, y))


def ornament_cut(path: Path) -> Image.Image:
    """The rosette plate on white: keep the plate (crop to its non-white bounds, white -> transparent)."""
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, _ = px[x, y]
            if r > 235 and g > 235 and b > 235:
                px[x, y] = (255, 255, 255, 0)
    return im.crop(im.getchannel("A").getbbox())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default="assets/marketing/icons/raw/chrome")
    ap.add_argument("--out", default="assets/marketing/icons")
    a = ap.parse_args()
    raw, out = Path(a.raw), Path(a.out)
    tex = {n: Image.open(raw / f"{n}.png") for n in ("walnut", "brass", "gold", "ablaq")}
    rosette = ornament_cut(raw / "rosette.png")

    def texture_of(name, S):
        return fill(S, tex[name], {"walnut": 96, "brass": 64, "gold": 64, "ablaq": 96}[name] * SS)

    # panel 128x128, slice 40..88: outline, walnut, brass line, outline; brass rosettes in the corners
    panel, _ = frame((128, 128), 22, [(3, None, 0), (14, "walnut", 0.35), (4, "brass", 0.5), (2, None, 0)], texture_of, 0.6)
    corners(panel, rosette, 22, 2)
    # button 96x64, slice 24..72 / 20..44: outline, brass bevel, a thin walnut line
    button, _ = frame((96, 64), 20, [(2, None, 0), (7, "brass", 0.6), (3, "walnut", 0.2), (1, None, 0)], texture_of, 0.5)
    # primary: the same with gold leaf
    primary, _ = frame((96, 64), 20, [(2, None, 0), (8, "gold", 0.6), (2, None, 0)], texture_of, 0.5)
    # header 256x48, slice 24..232 / 8..40: ablaq courses along the top and bottom edges only
    W, H = 256 * SS, 48 * SS
    header = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    strip = texture_of("ablaq", (W, H))
    for y0 in (0, H - 7 * SS):
        m = Image.new("L", (W, H), 0)
        ImageDraw.Draw(m).rectangle((0, y0, W, y0 + 7 * SS - 1), fill=255)
        layer(header, strip, m)
        m2 = Image.new("L", (W, H), 0)
        edge = y0 + 7 * SS if y0 == 0 else y0 - SS
        ImageDraw.Draw(m2).rectangle((0, edge, W, edge + SS - 1), fill=255)
        layer(header, Image.new("RGBA", (W, H), OUTLINE), m2)

    for name, im, size in (("panel", panel, (128, 128)), ("header", header, (256, 48)), ("button", button, (96, 64)), ("primary", primary, (96, 64))):
        im.resize(size, Image.LANCZOS).save(out / f"chrome_{name}.png")
        print(f"chrome_{name}.png {size[0]}x{size[1]}")


if __name__ == "__main__":
    main()
