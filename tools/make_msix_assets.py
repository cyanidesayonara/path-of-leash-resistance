"""Derives the MSIX tile and logo images from icon.png.

Run after tools/make_icon.gd, alongside tools/make_ico.py:
    python tools/make_msix_assets.py

Writes store/msix/Assets/, which store/msix/AppxManifest.xml references. The
square sizes are straight downsamples of the icon; the wide tile centres the
icon on the icon's own grass colour so it reads as one piece. WACK rejects
images over 200 KB and anything that looks like a template placeholder, so
these stay generated from the real icon. Requires Pillow, a build-time
dependency only - the game ships no Python.
"""

import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "icon.png")
DST = os.path.join(ROOT, "store", "msix", "Assets")

# GRASS in tools/make_icon.gd, Color(0.16, 0.28, 0.21)
GRASS = (41, 71, 54, 255)

SQUARES = {
    "StoreLogo.png": 50,
    "Square44x44Logo.png": 44,
    "Square150x150Logo.png": 150,
}
WIDE = ("Wide310x150Logo.png", (310, 150))


def main():
    os.makedirs(DST, exist_ok=True)
    icon = Image.open(SRC).convert("RGBA")
    for name, px in SQUARES.items():
        icon.resize((px, px), Image.LANCZOS).save(os.path.join(DST, name), optimize=True)
    name, (w, h) = WIDE
    wide = Image.new("RGBA", (w, h), GRASS)
    inner = icon.resize((h, h), Image.LANCZOS)
    wide.alpha_composite(inner, ((w - h) // 2, 0))
    wide.save(os.path.join(DST, name), optimize=True)
    for f in sorted(os.listdir(DST)):
        p = os.path.join(DST, f)
        size = os.path.getsize(p)
        assert size < 200_000, f"{f} is {size} bytes; WACK rejects images over 200 KB"
        print(f"{f}: {Image.open(p).size[0]}x{Image.open(p).size[1]}, {size} bytes")


if __name__ == "__main__":
    main()
