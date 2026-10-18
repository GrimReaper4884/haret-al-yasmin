"""Turns a VFX sprite painted on pure black into a 256² PNG with alpha (POLISH_PLAN PV-B01).

    python tools/icons/sprite_alpha.py <in.png> <out.png> [--size 256] [--margin 0.08] [--gain 1.4]

Alpha comes from brightness (max of R, G, B, scaled by `gain`), and the colour is divided back by
that alpha (un-premultiplied) so the sprite keeps its painted colour when Roblox blends it over the
scene. The result is cropped to the visible pixels, centred on a square and resized. Needs Pillow.
"""

import argparse

from PIL import Image


def cut(src: Image.Image, gain: float) -> Image.Image:
    im = src.convert("RGB")
    w, h = im.size
    out = Image.new("RGBA", (w, h))
    sp = im.load()
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = sp[x, y]
            m = max(r, g, b)
            a = min(255, int(m * gain))
            if a < 6:
                op[x, y] = (0, 0, 0, 0)
                continue
            k = 255 / max(m, 1)
            op[x, y] = (min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k)), a)
    return out


def fit(im: Image.Image, size: int, margin: float) -> Image.Image:
    box = im.getchannel("A").point(lambda a: 255 if a > 12 else 0).getbbox()
    if box:
        im = im.crop(box)
    side = int(max(im.size) * (1 + 2 * margin))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2), im)
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--margin", type=float, default=0.08)
    ap.add_argument("--gain", type=float, default=1.4)
    a = ap.parse_args()
    fit(cut(Image.open(a.src), a.gain), a.size, a.margin).save(a.out)
    print("saved", a.out)


if __name__ == "__main__":
    main()
