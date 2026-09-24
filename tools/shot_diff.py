#!/usr/bin/env python3
"""Pixel diff of two screenshot sweeps (tools/shot_sweep.sh output folders).

    python tools/shot_diff.py BEFORE_DIR AFTER_DIR [DIFF_DIR]

For every PNG in BEFORE_DIR, prints how many pixels differ in AFTER_DIR and
the largest per-channel difference. With DIFF_DIR, also writes an image per
changed shot with the differing pixels in red over a dimmed copy of the
original. Exits non-zero if any shot differs or is missing.

A change meant to leave the picture alone (a render refactor) should report
every shot as identical. Compare sweeps taken on one machine: GPUs and
drivers rasterize differently.
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    before, after = Path(sys.argv[1]), Path(sys.argv[2])
    out = Path(sys.argv[3]) if len(sys.argv) > 3 else None
    if out:
        out.mkdir(parents=True, exist_ok=True)
    bad = 0
    for a in sorted(before.glob("*.png")):
        if a.name.startswith("sheet-"):
            continue
        b = after / a.name
        if not b.exists():
            print(f"{a.name}: MISSING in {after}")
            bad += 1
            continue
        ia = Image.open(a).convert("RGB")
        ib = Image.open(b).convert("RGB")
        if ia.size != ib.size:
            print(f"{a.name}: size {ia.size} -> {ib.size}")
            bad += 1
            continue
        diff = ImageChops.difference(ia, ib)
        if diff.getbbox() is None:
            print(f"{a.name}: identical")
            continue
        mask = diff.convert("L").point(lambda v: 255 if v else 0)
        changed = mask.histogram()[255]
        peak = max(hi for _, hi in diff.getextrema())
        total = ia.size[0] * ia.size[1]
        print(f"{a.name}: {changed} px differ ({100.0 * changed / total:.3f}%), max channel delta {peak}")
        bad += 1
        if out:
            dim = Image.blend(ia, Image.new("RGB", ia.size, (0, 0, 0)), 0.6)
            dim.paste((255, 0, 0), mask=mask)
            dim.save(out / a.name)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
