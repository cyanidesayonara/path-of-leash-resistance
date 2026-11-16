#!/usr/bin/env bash
# Regenerates every image on the website (site/img/) from the game itself:
# screenshots from --shot runs, clips from tools/intro_render.gd joined by
# tools/frames_to_gif.py, and the icon from tools/make_icon.gd. Nothing in
# site/img/ is drawn or edited by hand.
#
#   GODOT=path/to/godot bash tools/site_media.sh
#
# GODOT picks the binary (default: ./Godot_v4.7-stable_linux.x86_64). Needs
# Pillow. Shots and films need a rendering context, so on Linux this runs
# under xvfb-run when it is on PATH, like tools/shot_sweep.sh.
#
# Size budget: the whole folder stays well under 5 MB. The clips are
# palette-limited and undithered (--colors, --no-dither), and the screenshots
# are JPEGs; check the total this prints after changing anything.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
OUT=site/img
mkdir -p "${OUT}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# Godot on Windows wants C:/ paths, not the shell's /c/ ones
native() { cygpath -m "$1" 2>/dev/null || echo "$1"; }

RUN=()
if [ -z "${NO_XVFB:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  RUN=(env LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a --server-args="-screen 0 1280x1024x24")
fi

PY="${PYTHON:-python3}"
"${PY}" -c "" 2>/dev/null || PY=python

# shot NAME [user args...]: a 1280x720 screenshot, saved as a JPEG
shot() {
  local name="$1"
  shift
  local png="${TMP}/${name}.png"
  echo "shot ${name}"
  timeout 120 "${RUN[@]}" "${GODOT}" \
    --fixed-fps 60 --rendering-method gl_compatibility --resolution 1280x720 --path . \
    -- --shot --shot-quit --shot-out="$(native "${png}")" --seed=1 "$@" \
    > "${TMP}/${name}.log" 2>&1 || true
  test -s "${png}" || { echo "  FAILED"; cat "${TMP}/${name}.log"; exit 1; }
  "${PY}" -c "import sys; from PIL import Image; Image.open(sys.argv[1]).convert('RGB').save(sys.argv[2], quality=82, optimize=True, progressive=True)" \
    "${png}" "${OUT}/shot-${name}.jpg"
}

# clip NAME SCENE FPS WIDTH [frames_to_gif flags...]
clip() {
  local name="$1" scene="$2" fps="$3" width="$4"
  shift 4
  local dir="${TMP}/frames-${name}"
  echo "clip ${name} (${scene})"
  "${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility --path . \
    --script res://tools/intro_render.gd -- "${scene}" "$(native "${dir}")" "${fps}" "${width}" \
    > "${TMP}/${name}.log" 2>&1 || true
  ls "${dir}"/f*.png >/dev/null 2>&1 || { echo "  FAILED"; cat "${TMP}/${name}.log"; exit 1; }
  "${PY}" tools/frames_to_gif.py "${dir}" "${OUT}/${name}.gif" "${fps}" --colors=128 --no-dither "$@"
}

# screenshots: two crossings, a grid corner, the park pond, a night festival
# and the old town's start line
shot street --level=street --shot-y=-2500 --shot-at=150
shot montserrat --level=montserrat --shot-y=-2500 --shot-at=150
shot eixample --level=eixample --shot-y=-2500 --shot-at=150
shot park --level=park --shot-y=-2500 --shot-at=150
shot gracia --level=gracia --shot-y=-2500 --shot-at=150
shot oldtown --level=oldtown

# the hero is the intro's title over the street; then two chase films, past
# their fade from black so a still of the first frame is not empty
clip hero walkies 12 480 --first=132 --last=179
clip sweeper sweeper 10 400 --first=4
clip boars boars 10 400 --first=4

echo "icon"
"${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility --path . \
  --script res://tools/make_icon.gd -- --out=res://${OUT}/icon.png > "${TMP}/icon.log" 2>&1 || true
test -s "${OUT}/icon.png" || { echo "  FAILED"; cat "${TMP}/icon.log"; exit 1; }

du -ch "${OUT}"/* | tail -1
