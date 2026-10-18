"""Builds the logo set (POLISH_PLAN PV-D01) from a generated mark and the wordmark set in Lalezar
(SIL Open Font License 1.1, tools/logo/fonts/OFL-Lalezar.txt; register row in COPYRIGHT_REGISTER).

    python tools/logo/compose.py <mark.png> [--out assets/marketing/logo] [--sheet docs/art/x.jpg]

Writes mark_256.png (the arch + jasmine alone), logo_512.png (mark over the two-line wordmark),
logo_wide_1600x400.png (mark left, wordmark right) and wordmark.png (the two text lines alone), all
with alpha. The Arabic line is shaped with
arabic-reshaper + python-bidi because this Pillow has no raqm. --sheet adds a preview at full size
and at 150 px on light and dark grounds (the experience icon's smallest size).
Needs Pillow, arabic-reshaper, python-bidi.
"""

import argparse
import os
import sys

import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "icons"))
from cutout import cutout, fit  # noqa: E402

FONT = os.path.join(HERE, "fonts", "Lalezar-Regular.ttf")
EN = "Haret Al-Yasmin"
AR = "حارة الياسمين"
FILL = (246, 214, 140, 255)  # warm jasmine-gold
STROKE = (58, 38, 18, 255)  # dark walnut outline, like the icon kit


# Lalezar has no isolated presentation forms (U+FExx), so isolated letters keep their base code
# points; the joined forms it does have.
RESHAPER = arabic_reshaper.ArabicReshaper(configuration={"use_unshaped_instead_of_isolated": True})


def shaped(text: str) -> str:
    out = get_display(RESHAPER.reshape(text))
    font = ImageFont.truetype(FONT, 20)
    missing = [c for c in out if c != " " and font.getmask(c).getbbox() is None]
    if missing:
        sys.exit(f"font lacks glyphs: {[hex(ord(c)) for c in missing]}")
    return out


def text_img(text: str, size: int, stroke: int) -> Image.Image:
    font = ImageFont.truetype(FONT, size)
    d = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    box = d.textbbox((0, 0), text, font=font, stroke_width=stroke)
    w, h = box[2] - box[0], box[3] - box[1]
    im = Image.new("RGBA", (w + 4, h + 4), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((2 - box[0], 2 - box[1]), text, font=font, fill=FILL, stroke_width=stroke, stroke_fill=STROKE)
    return im


def wordmark(width: int, ar_size: int, en_size: int, gap: int) -> Image.Image:
    ar = text_img(shaped(AR), ar_size, max(2, ar_size // 14))
    en = text_img(EN, en_size, max(2, en_size // 14))
    w = max(ar.width, en.width)
    im = Image.new("RGBA", (w, ar.height + gap + en.height), (0, 0, 0, 0))
    im.alpha_composite(ar, ((w - ar.width) // 2, 0))
    im.alpha_composite(en, ((w - en.width) // 2, ar.height + gap))
    if w > width:
        im = im.resize((width, round(im.height * width / w)), Image.LANCZOS)
    return im


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mark")
    ap.add_argument("--out", default="assets/marketing/logo")
    ap.add_argument("--sheet")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    mark_full = fit(cutout(Image.open(a.mark)), 1024, 0.02)

    mark = mark_full.resize((256, 256), Image.LANCZOS)
    mark.save(os.path.join(a.out, "mark_256.png"))

    # 512 square: mark on top, wordmark below
    sq = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    m = mark_full.resize((300, 300), Image.LANCZOS)
    sq.alpha_composite(m, ((512 - 300) // 2, 4))
    wm = wordmark(492, 104, 64, 0)
    wm = wm.resize((round(wm.width * 196 / wm.height), 196), Image.LANCZOS) if wm.height > 196 else wm
    sq.alpha_composite(wm, ((512 - wm.width) // 2, 512 - wm.height - 6))
    sq.save(os.path.join(a.out, "logo_512.png"))

    # 1600x400 wide: mark left, wordmark right
    wide = Image.new("RGBA", (1600, 400), (0, 0, 0, 0))
    m = mark_full.resize((380, 380), Image.LANCZOS)
    wide.alpha_composite(m, (20, 10))
    wm = wordmark(1150, 190, 120, 4)
    if wm.height > 380:
        wm = wm.resize((round(wm.width * 380 / wm.height), 380), Image.LANCZOS)
    wide.alpha_composite(wm, (420 + (1160 - wm.width) // 2, (400 - wm.height) // 2))
    wide.save(os.path.join(a.out, "logo_wide_1600x400.png"))

    # Text-only wordmark (the loading screen puts it under its own mark)
    wm = wordmark(1200, 190, 120, 4)
    wm.save(os.path.join(a.out, "wordmark.png"))

    if a.sheet:
        sheet = Image.new("RGBA", (1600 + 40, 400 + 512 + 60), (0, 0, 0, 255))
        d = ImageDraw.Draw(sheet)
        d.rectangle([0, 0, 1640, 460], fill=(233, 223, 203, 255))
        d.rectangle([0, 460, 1640, 972], fill=(42, 30, 20, 255))
        sheet.alpha_composite(wide, (20, 30))
        sheet.alpha_composite(sq, (20, 460))
        small = sq.resize((150, 150), Image.LANCZOS)
        sheet.alpha_composite(small, (560, 460 + 20))
        sheet.alpha_composite(mark, (760, 460 + 20))
        light_small = Image.new("RGBA", (170, 170), (233, 223, 203, 255))
        light_small.alpha_composite(small, (10, 10))
        sheet.alpha_composite(light_small, (1050, 460 + 20))
        sheet.convert("RGB").save(a.sheet, quality=90)
        print("sheet", a.sheet)
    print("wrote", a.out)


if __name__ == "__main__":
    main()
