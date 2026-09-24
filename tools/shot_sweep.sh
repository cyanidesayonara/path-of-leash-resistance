#!/usr/bin/env bash
# Screenshot sweep: photographs every walk plus the menu screens and the
# street at both phone shapes, one PNG each, then builds the contact sheet.
#
#   tools/shot_sweep.sh [OUT_DIR]          (default: shots/)
#
# GODOT picks the binary (default: ./Godot_v4.7-stable_linux.x86_64, which is
# where ci.yml unpacks it). On Linux with xvfb-run on PATH each shot runs on a
# virtual display with software GL, exactly like the appearance tests in
# ci.yml; elsewhere Godot opens a real window. Set NO_XVFB=1 to force that.
#
# Shots are deterministic on one machine: a fixed frame rate, a fixed seed,
# and the cosmetic animation clock pinned to the frame count (AnimClock),
# so tools/shot_diff.py can show a render refactor changed no pixel.
#
# Every shot must write its PNG; the script exits non-zero listing any that
# did not, after still attempting the rest.
set -uo pipefail

cd "$(dirname "$0")/.."

OUT="${1:-shots}"
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
# a shot that has not quit by then is stuck; --shot-quit normally ends it
# within a few seconds of the PNG landing
SHOT_TIMEOUT="${SHOT_TIMEOUT:-120}"
LEVELS=(street park beach rain market oldtown trail station site spook scrap guell neteja)

mkdir -p "${OUT}"
OUT_ABS="$(cd "${OUT}" && pwd)"
rm -f "${OUT_ABS}"/*.png "${OUT_ABS}"/*.log

RUN=()
if [ -z "${NO_XVFB:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  RUN=(env LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a --server-args="-screen 0 1280x1024x24")
fi

failed=()

# shot NAME WxH [user args...]
shot() {
  local name="$1" res="$2"
  shift 2
  local png="${OUT_ABS}/${name}.png"
  echo "shot ${name} (${res})"
  timeout "${SHOT_TIMEOUT}" "${RUN[@]}" "${GODOT}" \
    --fixed-fps 60 --rendering-method gl_compatibility --resolution "${res}" --path . \
    -- --shot --shot-quit --shot-out="${png}" --seed=1 "$@" \
    > "${OUT_ABS}/${name}.log" 2>&1
  if [ ! -s "${png}" ] || grep -qE "SCRIPT ERROR|Parse Error" "${OUT_ABS}/${name}.log"; then
    echo "  FAILED - see ${OUT}/${name}.log"
    failed+=("${name}")
  fi
}

for lv in "${LEVELS[@]}"; do
  shot "walk-${lv}" 1280x720 --level="${lv}"
done
shot title 1280x720 --shot-title
shot settings 1280x720 --shot-settings
shot results 1280x720 --shot-results
shot street-844x390 844x390 --level=street
shot street-390x844 390x844 --level=street

# python3 where it is real; on Windows that name is often a Store stub
PY="${PYTHON:-python3}"
"${PY}" -c "" 2>/dev/null || PY=python
"${PY}" tools/contact_sheet.py "${OUT_ABS}" || failed+=("contact_sheet")

if [ "${#failed[@]}" -gt 0 ]; then
  echo "SWEEP FAILED: ${failed[*]}"
  exit 1
fi
echo "SWEEP OK: $(ls "${OUT_ABS}"/*.png | wc -l) images in ${OUT}"
