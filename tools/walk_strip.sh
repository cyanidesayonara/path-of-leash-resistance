#!/usr/bin/env bash
# One sheet per walk of the whole of it, to study square by square:
#   GODOT=... bash tools/walk_strip.sh OUT LEVEL...
# Needs Pillow. OUT/LEVEL.png reads down the left column, then the next.
set -u
OUT="$1"; shift
mkdir -p "${OUT}"
PY="${PYTHON:-python3}"; "${PY}" -c "import PIL" 2>/dev/null || PY=python
native() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
for lv in "$@"; do
  dir="${OUT}/.frames/${lv}"
  rm -rf "${dir}"; mkdir -p "${dir}"
  timeout 180 "${GODOT}" --path . --fixed-fps 60 --rendering-method gl_compatibility --resolution 1280x720 \
    --script res://tools/walk_strip.gd -- --level="${lv}" --out="$(native "${dir}")" > "${dir}/log" 2>&1
  "${PY}" - "$(native "${dir}")" "$(native "${OUT}/${lv}.png")" "${lv}" <<'P'
import glob, math, sys
from PIL import Image, ImageDraw
d, out, name = sys.argv[1:4]
f = sorted(glob.glob(d + "/*.png"))
if not f:
    sys.exit("no frames for " + name)
cols = 2
rows = math.ceil(len(f) / cols)
w, h = 960, 540
W = Image.new("RGB", (w * cols, h * rows))
for i, x in enumerate(f):
    W.paste(Image.open(x).convert("RGB").resize((w, h), Image.Resampling.LANCZOS), ((i // rows) * w, (i % rows) * h))
W.save(out)
print(name, len(f), "frames")
P
done
