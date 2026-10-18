"""Experience icon (512x512): the approved logo set (C-219) on a night-lane backdrop.

    python tools/logo/icon.py  ->  assets/marketing/icon/icon_512.png (+ preview at 512/256/150 px)
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LOGO = os.path.join(ROOT, "assets", "marketing", "logo", "logo_512.png")
OUT = os.path.join(ROOT, "assets", "marketing", "icon")
S = 512
NIGHT_IN, NIGHT_OUT = (46, 52, 92), (14, 16, 34)  # indigo sky, darker at the corners
GLOW = (255, 196, 110)  # lantern light behind the gate
STONE_A, STONE_B = (236, 200, 130), (40, 36, 40)  # ablaq border, as on the arch


def backdrop() -> Image.Image:
    bg = Image.new("RGB", (S, S))
    px = bg.load()
    for y in range(S):
        for x in range(S):
            d = min(1.0, math.hypot(x - S / 2, y - S * 0.42) / (S * 0.72))
            px[x, y] = tuple(round(a + (b - a) * d) for a, b in zip(NIGHT_IN, NIGHT_OUT))
    glow = Image.new("L", (S, S), 0)
    ImageDraw.Draw(glow).ellipse((S * 0.2, S * 0.05, S * 0.8, S * 0.65), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    bg.paste(Image.new("RGB", (S, S), GLOW), (0, 0), glow)
    return bg


def border(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    w, n = 14, 16  # stripe width, blocks per side
    step = S / n
    for i in range(n):
        c = STONE_A if i % 2 == 0 else STONE_B
        a, b = round(i * step), round((i + 1) * step)
        d.rectangle((a, 0, b, w), fill=c)
        d.rectangle((a, S - w, b, S), fill=c)
        d.rectangle((0, a, w, b), fill=c)
        d.rectangle((S - w, a, S, b), fill=c)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    icon = backdrop()
    logo = Image.open(LOGO).convert("RGBA")
    inner = S - 2 * 26
    logo = logo.resize((inner, inner), Image.LANCZOS)
    icon.paste(logo, (26, 22), logo)
    border(icon)
    icon.save(os.path.join(OUT, "icon_512.png"))
    sheet = Image.new("RGB", (512 + 256 + 150 + 40, 512), (30, 30, 30))
    sheet.paste(icon, (0, 0))
    sheet.paste(icon.resize((256, 256), Image.LANCZOS), (532, 0))
    sheet.paste(icon.resize((150, 150), Image.LANCZOS), (808, 0))
    sheet.save(os.path.join(OUT, "icon_sizes_preview.png"))


if __name__ == "__main__":
    main()
