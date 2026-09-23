#!/usr/bin/env bash
# Perf sweep: the frame-time probe (dev/perf_probe.gd) on every walk, played
# by the autowalk bot, with the PERF summary and worst spikes kept per walk.
#
#   tools/perf_sweep.sh [OUT_DIR]                (default: perf/)
#   LEVELS="street market" SECS=60 tools/perf_sweep.sh
#
# Needs a real window and vsync off, so it measures what a player's machine
# does: run it on the machine you care about, with nothing heavy running
# alongside (a game in the background halves the numbers). Compare runs from
# the same machine only, and run a before/after pair back to back.
# In CI (software GL under xvfb) the numbers are only good for comparing two
# builds, never as absolutes.
set -uo pipefail

cd "$(dirname "$0")/.."
OUT="${1:-perf}"
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
LEVELS="${LEVELS:-street park beach rain market oldtown trail station site spook scrap guell}"
SECS="${SECS:-60}"
RES="${RES:-1280x720}"

mkdir -p "${OUT}"
RUN=()
if [ -z "${NO_XVFB:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  RUN=(env LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a --server-args="-screen 0 1920x1200x24")
fi

SUMMARY="${OUT}/summary.txt"
: > "${SUMMARY}"
for lv in ${LEVELS}; do
  log="${OUT}/${lv}.log"
  timeout $((SECS + 120)) "${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility --disable-vsync \
    --resolution "${RES}" --path . -- --level="${lv}" --autowalk --perf="${SECS}" > "${log}" 2>&1
  line="$(grep -m1 '^PERF level=' "${log}")"
  if [ -z "${line}" ]; then
    echo "${lv}: no PERF line - see ${log}" | tee -a "${SUMMARY}"
    continue
  fi
  echo "${line}" | tee -a "${SUMMARY}"
  grep '^PERF spike' "${log}" | head -3 | sed 's/^/    /' | tee -a "${SUMMARY}"
done
echo "summary: ${SUMMARY}"
