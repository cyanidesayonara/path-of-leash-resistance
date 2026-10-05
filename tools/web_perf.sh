#!/usr/bin/env bash
# Web build frame-time probe: exports the Web preset, serves it locally, and
# plays each level's autowalk in headless Chrome with the --perf probe, then
# prints the probe's PERF summary line per level.
#
#   GODOT=godot/Godot_v4.7-stable_win64_console.exe bash tools/web_perf.sh [LEVELS...]
#
# Needs the web export templates (see AGENTS.md) and Chrome or Edge. CHROME
# picks the browser, SECS the seconds per level (default 40), PORT the local
# port (default 8063). PERF_ARGS adds probe flags, space-separated (for
# example PERF_ARGS="--perf-no-grade"), and LOGDIR keeps Chrome's whole log.
# Every PERF line is printed: the summary, main's physics step by subsystem,
# and the worst frames.
#
# Headless Chrome runs on the real GPU through ANGLE and is not throttled the
# way a background tab or a hidden window is, so two builds measured this way
# on one machine compare fairly - but only on a quiet machine. Another game
# or a busy browser on the same CPU and GPU tripled every number one evening
# (v1.55 read 18 ms, then 49 ms, with no change to the build). Run builds
# alternately, more than once each, and distrust a step that only shows up
# in runs made at different times. The browser is where draw calls cost the
# most: compare calls_p50 alongside the frame times.
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
SECS="${SECS:-40}"
PORT="${PORT:-8063}"
LEVELS=("$@")
[ ${#LEVELS[@]} -eq 0 ] && LEVELS=(street park market)
if [ -z "${CHROME:-}" ]; then
  for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
           "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
           "$(command -v google-chrome 2>/dev/null)" "$(command -v chromium 2>/dev/null)"; do
    [ -n "$c" ] && [ -f "$c" ] && CHROME="$c" && break
  done
fi
[ -n "${CHROME:-}" ] || { echo "no Chrome or Edge found; set CHROME"; exit 1; }

OUT="$(mktemp -d)"
PROFILE="$(mktemp -d)"
winpath() { command -v cygpath >/dev/null && cygpath -m "$1" || echo "$1"; }
"$GODOT" --headless --path . --import >/dev/null 2>&1
if ! "$GODOT" --headless --path . --export-release "Web" "$(winpath "${OUT}")/index.html" >/dev/null 2>&1 \
    || [ ! -s "${OUT}/index.wasm" ]; then
  echo "web export failed (are the web export templates installed?)"
  exit 1
fi
EXTRA=""
for a in ${PERF_ARGS:-}; do EXTRA="${EXTRA},\"${a}\""; done
for lv in "${LEVELS[@]}"; do
  sed "s/\"args\":\[\]/\"args\":[\"--\",\"--level=${lv}\",\"--autowalk\",\"--perf=${SECS}\"${EXTRA}]/" \
    "${OUT}/index.html" > "${OUT}/perf-${lv}.html"
done
python -m http.server "${PORT}" --directory "$(winpath "${OUT}")" >/dev/null 2>&1 &
SERVER=$!
trap 'kill ${SERVER} 2>/dev/null; rm -rf "${OUT}" "${PROFILE}"' EXIT
sleep 2

for lv in "${LEVELS[@]}"; do
  line=$(timeout $((SECS + 60)) "${CHROME}" --headless=new --user-data-dir="$(winpath "${PROFILE}")" \
    --window-size=1280,720 --disable-background-timer-throttling --disable-renderer-backgrounding \
    --disable-backgrounding-occluded-windows --use-angle=d3d11 --ignore-gpu-blocklist \
    --enable-logging=stderr --v=0 --no-first-run "http://localhost:${PORT}/perf-${lv}.html" 2>&1 \
    | tee "${OUT}/chrome-${lv}.log" | grep -o 'PERF [^"]*')
  echo "${line:-PERF level=${lv} NO RESULT}"
  [ -n "${LOGDIR:-}" ] && cp "${OUT}/chrome-${lv}.log" "${LOGDIR}/"
done
