"""Turns a generated icon on a plain white background into a 256² PNG with alpha (POLISH_PLAN §5).

    python tools/icons/cutout.py <in.png> <out.png> [--size 256] [--margin 0.06]
    python tools/icons/cutout.py --sheet <out.png> <icon.png> ...     preview at 256 / 64 / 28 px on light and dark

The icons have a thick dark outline, so the background is everything near-white that is connected to the image
border: flood-filled from the edges (white inside the outline, e.g. a jasmine petal, is kept). The edge is
softened by one pixel, the subject is cropped to its bounds, centred on a square with a small margin and resized
with Lanczos. Needs Pillow.
"""

import argparse
from collections import deque

from PIL import Image, ImageDraw, ImageFilter

WHITE = 232  # a pixel whose R, G and B are all above this counts as background


def cutout(src: Image.Image) -> Image.Image:
    im = src.convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = bytearray(w * h)

    def whiteish(x: int, y: int) -> bool:
        r, g, b, _ = px[x, y]
        return r > WHITE and g > WHITE and b > WHITE

    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if bg[i] or not whiteish(x, y):
            continue
        bg[i] = 1
        if x > 0:
            q.append((x - 1, y))
        if x < w - 1:
            q.append((x + 1, y))
        if y > 0:
            q.append((x, y - 1))
        if y < h - 1:
            q.append((x, y + 1))
    mask = Image.frombytes("L", (w, h), bytes(0 if b else 255 for b in bg))
    mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    im.putalpha(mask)
    return im


def fit(im: Image.Image, size: int, margin: float) -> Image.Image:
    box = im.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
    if box:
        im = im.crop(box)
    side = int(max(im.size) * (1 + 2 * margin))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2), im)
    return canvas.resize((size, size), Image.LANCZOS)


def sheet(out: str, paths: list[str]):
    sizes = (256, 64, 28)
    cell_w = sum(sizes) + 40
    rows = len(paths)
    img = Image.new("RGBA", (cell_w * 2, rows * 270), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    for col, bgc in enumerate(((233, 223, 203, 255), (42, 30, 20, 255))):
        d.rectangle([col * cell_w, 0, (col + 1) * cell_w, rows * 270], fill=bgc)
        for r, p in enumerate(paths):
            icon = Image.open(p).convert("RGBA")
            x = col * cell_w + 10
            for s in sizes:
                small = icon.resize((s, s), Image.LANCZOS)
                img.alpha_composite(small, (x, r * 270 + (270 - s) // 2))
                x += s + 10
    img.convert("RGB").save(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paths", nargs="+")
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--margin", type=float, default=0.06)
    ap.add_argument("--sheet", action="store_true")
    a = ap.parse_args()
    if a.sheet:
        sheet(a.paths[0], a.paths[1:])
        print("saved", a.paths[0])
        return
    src, out = a.paths
    fit(cutout(Image.open(src)), a.size, a.margin).save(out)
    print("saved", out)


if __name__ == "__main__":
    main()
