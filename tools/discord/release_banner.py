"""Animated release banner for Discord (GIF): the logo on a night lane, falling jasmine, twinkling stars,
a lantern glow that breathes, and a version ribbon that slides in.

    python tools/discord/release_banner.py 1.0.0  ->  tools/discord/assets/release_<version>.gif
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LOGO = os.path.join(ROOT, "assets", "marketing", "logo", "logo_wide_1600x400.png")
FONT = os.path.join(ROOT, "tools", "logo", "fonts", "Lalezar-Regular.ttf")
W, H, FRAMES, MS = 960, 400, 48, 70
SKY_TOP, SKY_BOTTOM = (18, 20, 46), (52, 40, 70)
GLOW = (255, 190, 100)
CREAM, INK = (248, 226, 160), (40, 26, 20)


def sky() -> Image.Image:
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOTTOM)))
    # ablaq stone courses along the bottom (the lane wall)
    for i in range(0, W, 48):
        d.rectangle((i, H - 22, i + 47, H), fill=(236, 200, 130) if (i // 48) % 2 == 0 else (44, 38, 42))
    return img


def flower(size: int, alpha: int) -> Image.Image:
    s = size * 4
    f = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(f)
    c = s / 2
    for k in range(5):
        a = k * 2 * math.pi / 5
        x, y = c + math.cos(a) * s * 0.22, c + math.sin(a) * s * 0.22
        d.ellipse((x - s * 0.2, y - s * 0.2, x + s * 0.2, y + s * 0.2), fill=(255, 255, 248, alpha))
    d.ellipse((c - s * 0.08, c - s * 0.08, c + s * 0.08, c + s * 0.08), fill=(250, 210, 90, alpha))
    return f.resize((size, size), Image.LANCZOS)


def main() -> None:
    version = sys.argv[1] if len(sys.argv) > 1 else "1.0.0"
    rnd = random.Random(7)
    base = sky()
    logo = Image.open(LOGO).convert("RGBA")
    lw = 760
    logo = logo.resize((lw, round(logo.height * lw / logo.width)), Image.LANCZOS)
    stars = [(rnd.randrange(W), rnd.randrange(int(H * 0.55)), rnd.random() * 2 * math.pi, rnd.choice((1, 1, 2))) for _ in range(70)]
    petals = [
        {"x": rnd.uniform(0, W), "y0": rnd.uniform(-H, H), "v": rnd.uniform(0.6, 1.4), "sway": rnd.uniform(8, 26),
         "ph": rnd.uniform(0, 2 * math.pi), "size": rnd.choice((14, 18, 22, 26)), "a": rnd.choice((170, 210, 255))}
        for _ in range(26)
    ]
    font = ImageFont.truetype(FONT, 44)
    small = ImageFont.truetype(FONT, 22)
    ribbon_text = f"v{version}  IS LIVE"
    frames = []
    for f in range(FRAMES):
        t = f / FRAMES
        img = base.copy().convert("RGBA")
        d = ImageDraw.Draw(img)
        for x, y, ph, r in stars:
            b = 0.5 + 0.5 * math.sin(ph + t * 2 * math.pi * 2)
            c = round(120 + 135 * b)
            d.ellipse((x - r, y - r, x + r, y + r), fill=(c, c, min(255, c + 20), 255))
        # breathing lantern glow behind the logo
        glow = Image.new("L", (W, H), 0)
        g = 0.75 + 0.25 * math.sin(t * 2 * math.pi) + 0.05 * math.sin(t * 2 * math.pi * 7)
        ImageDraw.Draw(glow).ellipse((W * 0.18, H * 0.02, W * 0.82, H * 0.82), fill=round(110 * g))
        img.paste(Image.new("RGBA", (W, H), GLOW + (255,)), (0, 0), glow.filter(ImageFilter.GaussianBlur(70)))
        bob = round(4 * math.sin(t * 2 * math.pi))
        img.alpha_composite(logo, ((W - lw) // 2, 34 + bob))
        # ribbon slides in over the first quarter, then shimmers
        slide = min(1.0, t / 0.25)
        ease = 1 - (1 - slide) ** 3
        rw, rh = 380, 64
        rx = round(W - (rw + 40) * ease)
        ry = H - rh - 40
        d = ImageDraw.Draw(img)
        d.rounded_rectangle((rx, ry, rx + rw, ry + rh), radius=18, fill=(150, 30, 36, 255), outline=CREAM, width=3)
        sx = rx + round((rw + 120) * ((t * 1.5) % 1.0)) - 60
        shine = Image.new("L", (W, H), 0)
        ImageDraw.Draw(shine).polygon([(sx, ry), (sx + 26, ry), (sx - 4, ry + rh), (sx - 30, ry + rh)], fill=90)
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).rounded_rectangle((rx, ry, rx + rw, ry + rh), radius=18, fill=255)
        from PIL import ImageChops
        img.paste(Image.new("RGBA", (W, H), (255, 255, 255, 255)), (0, 0), ImageChops.multiply(shine, mask))
        d = ImageDraw.Draw(img)
        d.text((rx + rw / 2, ry + rh / 2 + 2), ribbon_text, font=font, fill=CREAM, anchor="mm", stroke_width=3, stroke_fill=INK)
        d.text((40 - round(300 * (1 - ease)), H - 70), "Season Story 1 · Nine Episodes", font=small, fill=CREAM, stroke_width=2, stroke_fill=INK)
        for p in petals:
            y = (p["y0"] + t * H * 2 * p["v"]) % (H + 60) - 30
            x = p["x"] + p["sway"] * math.sin(p["ph"] + t * 2 * math.pi * 2)
            fl = flower(p["size"], p["a"]).rotate(t * 360 * p["v"] * (1 if p["ph"] > math.pi else -1), resample=Image.BICUBIC)
            img.alpha_composite(fl, (round(x), round(y)))
        frames.append(img.convert("RGB").quantize(colors=255, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE))
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", f"release_{version.replace('.', '_')}.gif")
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=MS, loop=0, optimize=True, disposal=2)
    frames[FRAMES // 2].convert("RGB").save(out.replace(".gif", "_still.png"))
    print(out, os.path.getsize(out))


if __name__ == "__main__":
    main()
