"""Packs icon.png into the multi-size icon.ico the Windows exporter wants.

Run after tools/make_icon.gd:
    python tools/make_ico.py

Windows picks a different frame for the taskbar, the alt-tab strip and the
file listing, and left to itself it will downscale the 256px frame badly for
the small ones, so every size is written explicitly. Requires Pillow, which
is a build-time dependency only - the game ships no Python.
"""

import os
import sys

from PIL import Image

SIZES = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "icon.png")
DST = os.path.join(ROOT, "icon.ico")

if not os.path.exists(SRC):
    sys.exit("icon.png is missing - run tools/make_icon.gd first")

src = Image.open(SRC).convert("RGBA")
if src.size != (256, 256):
    sys.exit("expected a 256x256 icon.png, got %dx%d" % src.size)
src.save(DST, format="ICO", sizes=SIZES)
print("wrote %s at %s" % (DST, ", ".join("%dpx" % w for w, _ in SIZES)))
