"""Tiles a screenshot sweep into labelled contact sheets.

    python tools/contact_sheet.py SHOTS_DIR

Writes two sheets next to the shots:
    sheet-walks.png    every walk-*.png, 4 across
    sheet-screens.png  everything else (title, settings, results, phones)

Each shot keeps its aspect ratio inside its cell, so the phone shapes read as
phone shapes, and carries its file name as a caption. The header names the
build from res://build_label.txt when tools/stamp_version.sh has written one.
Requires Pillow, a build-time dependency only - the game ships no Python.
"""

import glob
import os
import sys

from PIL import Image, ImageDraw, ImageFont

CELL_W = 480
CELL_H = 300
CAPTION_H = 26
PAD = 12
HEADER_H = 40
COLS = 4
BG = (24, 26, 30)
CELL_BG = (40, 43, 50)
INK = (230, 230, 230)
MISSING_INK = (230, 90, 90)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _font(size):
    for name in ("DejaVuSans.ttf", "arial.ttf", "Arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


def _build_label():
    path = os.path.join(ROOT, "build_label.txt")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return f.read().strip() or "dev"
    return "dev"


def make_sheet(paths, title, out_path):
    rows = (len(paths) + COLS - 1) // COLS
    cols = min(COLS, len(paths))
    w = PAD + cols * (CELL_W + PAD)
    h = HEADER_H + PAD + rows * (CELL_H + CAPTION_H + PAD)
    sheet = Image.new("RGB", (w, h), BG)
    draw = ImageDraw.Draw(sheet)
    draw.text((PAD, 10), title, fill=INK, font=_font(20))
    cap_font = _font(15)

    for i, path in enumerate(paths):
        x = PAD + (i % COLS) * (CELL_W + PAD)
        y = HEADER_H + PAD + (i // COLS) * (CELL_H + CAPTION_H + PAD)
        draw.rectangle([x, y, x + CELL_W - 1, y + CELL_H - 1], fill=CELL_BG)
        name = os.path.splitext(os.path.basename(path))[0]
        try:
            with Image.open(path) as im:
                im = im.convert("RGB")
                size = f"{im.width}x{im.height}"
                im.thumbnail((CELL_W, CELL_H), Image.LANCZOS)
                sheet.paste(im, (x + (CELL_W - im.width) // 2, y + (CELL_H - im.height) // 2))
            draw.text((x, y + CELL_H + 4), f"{name}  {size}", fill=INK, font=cap_font)
        except OSError as e:
            draw.text((x + 8, y + 8), f"unreadable: {e}", fill=MISSING_INK, font=cap_font)
            draw.text((x, y + CELL_H + 4), name, fill=MISSING_INK, font=cap_font)

    sheet.save(out_path)
    print(f"sheet: {out_path} ({len(paths)} shots)")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    shots = sys.argv[1]
    every = sorted(p for p in glob.glob(os.path.join(shots, "*.png"))
                   if not os.path.basename(p).startswith("sheet-"))
    if not every:
        print(f"no shots in {shots}")
        return 1
    walks = [p for p in every if os.path.basename(p).startswith("walk-")]
    screens = [p for p in every if p not in walks]
    label = _build_label()
    if walks:
        make_sheet(walks, f"Walks - {label}", os.path.join(shots, "sheet-walks.png"))
    if screens:
        make_sheet(screens, f"Screens - {label}", os.path.join(shots, "sheet-screens.png"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
