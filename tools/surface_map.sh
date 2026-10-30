#!/usr/bin/env bash
# Surface map: shots down each walk and off leash with what surface_at() says
# dotted over them (tools/surface_overlay.gd), so ground that is drawn as one
# thing and handles as another shows at a glance. Grey pavement, green grass,
# yellow sand, brown mud, blue water, magenta tile.
#
#   GODOT=godot/Godot_v4.7-stable_win64.exe bash tools/surface_map.sh [OUT] [LEVEL...]
#
# Writes OUT/LEVEL_Y.png (default OUT: surface-map/), all walks by default,
# and OUT/sheet-LEVEL.png per walk when Pillow is there. Needs a real window.
# SURF_DUMP=1 takes clean shots and writes each one's points to LEVEL_Y.txt
# instead, then runs tools/surface_check.py over them: what is drawn held
# against what it handles as, mismatches ringed in OUT/check-*.png.
set -uo pipefail

cd "$(dirname "$0")/.."
OUT="${1:-surface-map}"
shift || true
GODOT="${GODOT:-godot/Godot_v4.7-stable_win64.exe}"
LEVELS="${*:-barri street park beach rain market oldtown trail station besos site spook scrap guell neteja montjuic partit port reial vet tibidabo aigues horta llevant boars gracia raval}"
YS="${YS:-0 -1250 -2500 -3750 -4800 free}"
MAP=--surface-map
[ -n "${SURF_DUMP:-}" ] && MAP=--surface-map=dump

mkdir -p "${OUT}"
for lv in ${LEVELS}; do
  for y in ${YS}; do
    case "$y" in
      0) extra=() ;;
      free) extra=(--at-freedom --shot-at=90) ;;
      *) extra=("--shot-y=$y") ;;
    esac
    timeout 120 "${GODOT}" --fixed-fps 60 --resolution 1280x720 --path . --rendering-method gl_compatibility \
      -- --shot "${MAP}" --seed=1 --level="${lv}" --shot-at=60 --shot-zoom=0.75 "${extra[@]}" \
      --shot-out="${OUT}/${lv}_${y}.png" --shot-quit > "${OUT}/${lv}_${y}.log" 2>&1 || echo "${lv} ${y}: no shot"
    if [ -n "${SURF_DUMP:-}" ]; then
      grep '^SURF ' "${OUT}/${lv}_${y}.log" > "${OUT}/${lv}_${y}.txt"
    fi
    rm -f "${OUT}/${lv}_${y}.log"
  done
  python - "${OUT}" "${lv}" "${YS}" <<'EOF' 2>/dev/null || true
import sys, os
from PIL import Image
out, lv, ys = sys.argv[1], sys.argv[2], sys.argv[3].split()
ims = [Image.open(os.path.join(out, '%s_%s.png' % (lv, y))) for y in ys if os.path.exists(os.path.join(out, '%s_%s.png' % (lv, y)))]
if ims:
    w, h = ims[0].size
    sw, sh = w // 2, h // 2
    sheet = Image.new('RGB', (sw * 3, sh * ((len(ims) + 2) // 3)), (20, 20, 20))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((sw, sh)), ((i % 3) * sw, (i // 3) * sh))
    sheet.save(os.path.join(out, 'sheet-%s.png' % lv))
EOF
done
[ -n "${SURF_DUMP:-}" ] && python tools/surface_check.py "${OUT}"
echo "surface maps in ${OUT}/"
