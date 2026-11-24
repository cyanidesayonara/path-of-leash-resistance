#!/usr/bin/env bash
# Regenerates every image on the website (site/img/) from the game itself:
# two or three screenshots for every walk in the campaign, the intro's title
# and every chase film as GIF clips, a portrait of every dog, and the icon.
#
# Run it from the repo root with Godot in the current directory (or point
# GODOT=/path/to/godot). On Linux CI without a display it wraps Godot in
# xvfb-run + Mesa llvmpipe; set NO_XVFB=1 if you already have a display.
# JOBS controls how many Godot renders run in parallel (default 4).
#
# Size budget: the whole folder stays well under 15 MB. The clips are
# palette-limited and undithered (--colors, --no-dither), and the screenshots
# are 960x540 progressive JPEGs; check the total this prints after everything.
set -euo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
OUT=site/img
JOBS="${JOBS:-4}"
mkdir -p "${OUT}"
TMP="$(mktemp -d)"
STAGE="${TMP}/img"
mkdir -p "${STAGE}"
trap 'rm -rf "${TMP}"' EXIT

# Godot on Windows wants C:/ paths, not the shell's /c/ ones
native() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  elif command -v wslpath >/dev/null 2>&1; then
    wslpath -m "$1"
  else
    echo "$1"
  fi
}

RUN=()
if [ -z "${NO_XVFB:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  RUN=(env LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a --server-args="-screen 0 1280x1024x24")
fi

PY="${PYTHON:-python3}"
"${PY}" -c "" 2>/dev/null || PY=python

PIDS=()
NAMES=()

wait_one() {
  local pid="${PIDS[0]}"
  local name="${NAMES[0]}"
  PIDS=("${PIDS[@]:1}")
  NAMES=("${NAMES[@]:1}")
  wait "${pid}" || {
    echo "FAILED shot ${name}"
    cat "${TMP}/${name}.log" 2>/dev/null || true
    exit 1
  }
}

wait_all() {
  while [ "${#PIDS[@]}" -gt 0 ]; do
    wait_one
  done
}

# shot NAME [user args...]: a 1280x720 capture downscaled to 960x540 JPEG
shot_worker() {
  local name="$1"
  shift
  local png="${TMP}/${name}.png"
  local app="${TMP}/app-${name}"
  mkdir -p "${app}"
  echo "shot ${name}"
  APPDATA="$(native "${app}")" XDG_DATA_HOME="$(native "${app}")" \
    timeout 120 "${RUN[@]}" "${GODOT}" \
    --fixed-fps 60 --rendering-method gl_compatibility --resolution 1280x720 --path . \
    -- --shot --shot-quit --shot-out="$(native "${png}")" --seed=1 "$@" \
    > "${TMP}/${name}.log" 2>&1 || true
  test -s "${png}" || { echo "  FAILED ${name}"; return 1; }
  "${PY}" -c "import sys; from PIL import Image; im = Image.open(sys.argv[1]).convert('RGB'); im = im.resize((960, 540), Image.Resampling.LANCZOS); im.save(sys.argv[2], quality=76, optimize=True, progressive=True)" \
    "${png}" "${STAGE}/shot-${name}.jpg"
  rm -f "${png}"
}

shot() {
  local name="$1"
  while [ "${#PIDS[@]}" -ge "${JOBS}" ]; do
    wait_one
  done
  shot_worker "$@" &
  PIDS+=("$!")
  NAMES+=("${name}")
}

# clip NAME SCENE FPS WIDTH [frames_to_gif flags...]
clip() {
  local name="$1" scene="$2" fps="$3" width="$4"
  shift 4
  local dir="${TMP}/frames-${name}"
  local app="${TMP}/app-clip-${name}"
  mkdir -p "${app}"
  echo "clip ${name} (${scene})"
  APPDATA="$(native "${app}")" XDG_DATA_HOME="$(native "${app}")" \
    "${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility --path . \
    --script res://tools/intro_render.gd -- "${scene}" "$(native "${dir}")" "${fps}" "${width}" \
    > "${TMP}/${name}.log" 2>&1 || true
  ls "${dir}"/f*.png >/dev/null 2>&1 || { echo "  FAILED"; cat "${TMP}/${name}.log"; exit 1; }
  "${PY}" tools/frames_to_gif.py "${dir}" "${STAGE}/${name}.gif" "${fps}" --colors=128 --no-dither "$@"
}

# Chapter 1 (12 walks)
shot tutorial --level=tutorial --shot-y=-1800 --shot-at=220
shot tutorial-2 --level=tutorial --at-freedom --shot-at=260
shot barri --level=barri --shot-y=-2500 --shot-at=260
shot barri-2 --level=barri --at-freedom --shot-at=260
shot street --level=street --shot-y=-2500 --shot-at=260
shot street-2 --level=street --at-freedom --shot-at=260
shot park --level=park --shot-y=-2600 --shot-at=260
shot park-2 --level=park --at-freedom --shot-at=260
shot beach --level=beach --shot-y=-2500 --shot-at=260
shot beach-2 --level=beach --at-freedom --shot-at=260
shot neteja --level=neteja --shot-y=-2200 --shot-at=260
shot neteja-2 --level=neteja --shot-y=-4300 --shot-home --shot-sweeper --shot-at=200
shot neteja-3 --level=neteja --at-freedom --shot-at=260
shot oldtown --level=oldtown --shot-y=-2000 --shot-at=260
shot oldtown-2 --level=oldtown --at-freedom --shot-at=260
shot montjuic --level=montjuic --shot-y=-2500 --shot-at=260
shot montjuic-2 --level=montjuic --at-freedom --shot-at=260
shot market --level=market --shot-y=-2400 --shot-at=260
shot market-2 --level=market --at-freedom --shot-at=260
shot rain --level=rain --shot-y=-3600 --shot-at=200
shot rain-2 --level=rain --at-freedom --shot-at=260
shot besos --level=besos --shot-y=-2050 --shot-at=260
shot besos-2 --level=besos --shot-y=-3200 --shot-home --shot-sweeper --shot-at=200
shot besos-3 --level=besos --at-freedom --shot-at=260
shot ciutadella --level=ciutadella --shot-y=-1400 --shot-at=260
shot ciutadella-2 --level=ciutadella --shot-y=-2650 --shot-at=260
shot ciutadella-3 --level=ciutadella --at-freedom --shot-at=260

# Chapter 2 (10 walks)
shot llevant --level=llevant --shot-y=-2500 --shot-at=260
shot llevant-2 --level=llevant --at-freedom --shot-at=260
shot eixample --level=eixample --shot-y=-2500 --shot-at=260
shot eixample-2 --level=eixample --at-freedom --shot-at=260
shot tibidabo --level=tibidabo --shot-y=-2500 --shot-at=260
shot tibidabo-2 --level=tibidabo --at-freedom --shot-at=260
shot vet --level=vet --shot-y=-2500 --shot-at=260
shot vet-2 --level=vet --shot-y=-2500 --shot-home --shot-sweeper --shot-at=100
shot vet-3 --level=vet --at-freedom --shot-at=260
shot sarria --level=sarria --shot-y=-2500 --shot-at=260
shot sarria-2 --level=sarria --at-freedom --shot-at=260
shot trail --level=trail --shot-y=-2450 --shot-at=260
shot trail-2 --level=trail --at-freedom --shot-at=260
shot angels --level=angels --shot-y=-2500 --shot-at=260
shot angels-2 --level=angels --at-freedom --shot-at=260
shot spook --level=spook --shot-y=-2500 --shot-at=260
shot spook-2 --level=spook --at-freedom --shot-at=260
shot boars --level=boars --shot-y=-2500 --shot-at=260
shot boars-2 --level=boars --shot-y=-3200 --shot-home --shot-sweeper --shot-at=350
shot boars-3 --level=boars --at-freedom --shot-at=260
shot guell --level=guell --shot-y=-3100 --shot-at=260
shot guell-2 --level=guell --shot-y=-930 --shot-at=260
shot guell-3 --level=guell --at-freedom --shot-at=260

# Chapter 3 (7 walks)
shot superilla --level=superilla --shot-y=-2500 --shot-at=140
shot superilla-2 --level=superilla --at-freedom --shot-at=260
shot metro --level=metro --shot-y=-2900 --shot-at=260
shot metro-2 --level=metro --at-freedom --shot-at=260
shot station --level=station --shot-y=-2500 --shot-at=260
shot station-2 --level=station --at-freedom --shot-at=260
shot carmel --level=carmel --shot-y=-2500 --shot-at=260
shot carmel-2 --level=carmel --at-freedom --shot-at=260
shot reial --level=reial --shot-y=-2500 --shot-at=260
shot reial-2 --level=reial --at-freedom --shot-at=260
shot cremada --level=cremada --shot-y=-2500 --shot-at=260
shot cremada-2 --level=cremada --shot-y=-3200 --shot-home --shot-sweeper --shot-at=120
shot cremada-3 --level=cremada --at-freedom --shot-at=260
shot forum --level=forum --shot-y=-2500 --shot-at=260
shot forum-2 --level=forum --at-freedom --shot-at=260

# Chapter 4 (7 walks)
shot diagonal --level=diagonal --shot-y=-2500 --shot-at=260
shot diagonal-2 --level=diagonal --at-freedom --shot-at=260
shot blai --level=blai --shot-y=-2500 --shot-at=260
shot blai-2 --level=blai --at-freedom --shot-at=260
shot aigues --level=aigues --shot-y=-2500 --shot-at=260
shot aigues-2 --level=aigues --at-freedom --shot-at=260
shot gracia --level=gracia --shot-y=-2500 --shot-at=260
shot gracia-2 --level=gracia --shot-y=-3200 --shot-home --shot-sweeper --shot-at=200
shot gracia-3 --level=gracia --at-freedom --shot-at=260
shot horta --level=horta --shot-y=-2500 --shot-at=260
shot horta-2 --level=horta --at-freedom --shot-at=260
shot molina --level=molina --shot-y=-2500 --shot-at=260
shot molina-2 --level=molina --shot-y=-3200 --shot-home --shot-sweeper --shot-at=200
shot molina-3 --level=molina --at-freedom --shot-at=260
shot port --level=port --shot-y=-2000 --shot-at=260
shot port-2 --level=port --shot-y=-4200 --shot-at=380
shot port-3 --level=port --at-freedom --shot-at=380

# Chapter 5 (14 walks)
shot espanya --level=espanya --shot-y=-2500 --shot-at=260
shot espanya-2 --level=espanya --at-freedom --shot-at=260
shot santpau --level=santpau --shot-y=-2500 --shot-at=260
shot santpau-2 --level=santpau --at-freedom --shot-at=260
shot poble --level=poble --shot-y=-2500 --shot-at=260
shot poble-2 --level=poble --at-freedom --shot-at=260
shot sitges --level=sitges --shot-y=-2500 --shot-at=260
shot sitges-2 --level=sitges --at-freedom --shot-at=260
shot atraccions --level=atraccions --shot-y=-2500 --shot-at=260
shot atraccions-2 --level=atraccions --at-freedom --shot-at=260
shot girona --level=girona --shot-y=-1250 --shot-at=260
shot girona-2 --level=girona --at-freedom --shot-at=260
shot aeroport --level=aeroport --shot-y=-2500 --shot-at=260
shot aeroport-2 --level=aeroport --shot-y=-3200 --shot-home --shot-sweeper --shot-at=380
shot aeroport-3 --level=aeroport --at-freedom --shot-at=260
shot site --level=site --shot-y=-1150 --shot-at=140
shot site-2 --level=site --at-freedom --shot-at=260
shot ronda --level=ronda --shot-y=-2500 --shot-at=260
shot ronda-2 --level=ronda --at-freedom --shot-at=260
shot encants --level=encants --shot-y=-2500 --shot-at=260
shot encants-2 --level=encants --at-freedom --shot-at=260
shot tarragona --level=tarragona --shot-y=-2500 --shot-at=260
shot tarragona-2 --level=tarragona --at-freedom --shot-at=260
shot vic --level=vic --shot-y=-1200 --shot-at=260
shot vic-2 --level=vic --at-freedom --shot-at=260
shot partit --level=partit --shot-y=-2500 --shot-at=260
shot partit-2 --level=partit --at-freedom --shot-at=260
shot scrap --level=scrap --shot-y=-2500 --shot-at=260
shot scrap-2 --level=scrap --at-freedom --shot-at=260
shot montserrat --level=montserrat --shot-y=-2600 --shot-at=260
shot montserrat-2 --level=montserrat --shot-y=-2600 --shot-home --shot-sweeper --shot-at=200
shot montserrat-3 --level=montserrat --at-freedom --shot-at=260
shot raval --level=raval --shot-y=-2500 --shot-at=260
shot raval-2 --level=raval --shot-y=-600 --shot-at=260
shot raval-3 --level=raval --at-freedom --shot-at=260

wait_all

# the hero is the intro's title over the street; then every chase walk's
# film, past its fade from black so a still of the first frame is not empty.
# Smaller and fewer colours than the hero, so ten of them fit the budget.
if [ -z "${SHOTS_ONLY:-}" ]; then
  clip hero walkies 12 480 --first=132 --last=179
  CHASE_FILMS=(sweeper flood vet boars cremada aeroport molina mascots montserrat gracia)
  for film in "${CHASE_FILMS[@]}"; do
    clip "${film}" "${film}" 8 320 --first=8 --colors=80
  done

  # every dog side on, as the films draw her, for the dog cards
  echo "dogs"
  APPDATA="$(native "${TMP}/app-dogs")" XDG_DATA_HOME="$(native "${TMP}/app-dogs")"     "${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility --path .     --script res://tools/site_dogs.gd -- "$(native "${STAGE}")" 360 > "${TMP}/dogs.log" 2>&1 || true
  ls "${STAGE}"/dog-*.png >/dev/null 2>&1 || { echo "  FAILED"; cat "${TMP}/dogs.log"; exit 1; }
  for f in "${STAGE}"/dog-*.png; do
    "${PY}" -c "import sys; from PIL import Image; im = Image.open(sys.argv[1]); im.quantize(colors=128, method=Image.Quantize.FASTOCTREE).save(sys.argv[1], optimize=True)" "${f}"
  done

  echo "icon"
  APPDATA="$(native "${TMP}/app-icon")" XDG_DATA_HOME="$(native "${TMP}/app-icon")" \
    "${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility --path . \
    --script res://tools/make_icon.gd -- --out="$(native "${STAGE}/icon.png")" > "${TMP}/icon.log" 2>&1 || true
  test -s "${STAGE}/icon.png" || { echo "  FAILED"; cat "${TMP}/icon.log"; exit 1; }
  rm -f "${OUT}"/*.gif "${OUT}"/dog-*.png "${OUT}"/icon.png
fi

rm -f "${OUT}"/shot-*.jpg
mv "${STAGE}"/* "${OUT}/"

du -ch "${OUT}"/* | tail -1
