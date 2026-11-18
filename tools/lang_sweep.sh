#!/usr/bin/env bash
# Language sweep: every menu screen, settings, the results card, the goal list
# and a walk's HUD in one language, at the three screen shapes the interface
# has to fit (1280x720, 844x390, 390x844), then the contact sheets.
#
#   tools/lang_sweep.sh LANG [OUT_DIR]     (LANG: en, ca or es; default OUT_DIR: shots-LANG/)
#
# GODOT picks the binary, as in tools/shot_sweep.sh. Every shot must write its
# PNG; the script exits non-zero listing any that did not.
set -uo pipefail

cd "$(dirname "$0")/.."

LANG_ID="${1:-en}"
OUT="${2:-shots-${LANG_ID}}"
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
SHOT_TIMEOUT="${SHOT_TIMEOUT:-120}"
SIZES=(1280x720 844x390 390x844)
SCREENS=(main walk details shop progress pause walkcard confirm first notice)

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
    -- --shot --shot-quit --shot-out="${png}" --seed=1 --lang="${LANG_ID}" "$@" \
    > "${OUT_ABS}/${name}.log" 2>&1
  if [ ! -s "${png}" ] || grep -qE "SCRIPT ERROR|Parse Error" "${OUT_ABS}/${name}.log"; then
    echo "  FAILED - see ${OUT}/${name}.log"
    failed+=("${name}")
  fi
}

for res in "${SIZES[@]}"; do
  for sc in "${SCREENS[@]}"; do
    shot "menu-${sc}-${res}" "${res}" --shot-menu="${sc}" --level=street --shot-at=90
  done
  shot "settings-${res}" "${res}" --shot-settings
  shot "results-${res}" "${res}" --shot-results
  shot "goals-${res}" "${res}" --shot-goals --level=street
  shot "hud-${res}" "${res}" --level=street
done

PY="${PYTHON:-python3}"
"${PY}" -c "" 2>/dev/null || PY=python
"${PY}" tools/contact_sheet.py "${OUT_ABS}" || failed+=("contact_sheet")

if [ "${#failed[@]}" -gt 0 ]; then
  echo "SWEEP FAILED: ${failed[*]}"
  exit 1
fi
echo "SWEEP OK: $(ls "${OUT_ABS}"/*.png | wc -l) images in ${OUT}"
