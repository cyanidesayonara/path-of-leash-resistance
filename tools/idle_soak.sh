#!/usr/bin/env bash
# Idle soak: every walk, no input, for SOAK_SECS of game time, at each window
# shape and a few seeds. Counts knocks on the dog, moods and phone cracks, and
# fails any run that crosses a threshold.
#
#   tools/idle_soak.sh [OUT_DIR]                 (default: soak/)
#   LEVELS="street market" tools/idle_soak.sh    (a subset)
#
# Why windowed and not headless: the idle knock (#6) looked like it depended on
# window shape, and a headless run reports a fixed 1280x1280 viewport whatever
# --resolution says. So each run opens a real window: on Linux on an xvfb
# display with software GL (as the appearance tests in ci.yml do), elsewhere
# placed off-screen. --fixed-fps 60 makes game time independent of how fast
# the machine renders. No portrait size: a portrait window pauses the walk
# behind the rotate prompt (#5), so there is nothing to soak.
#
# Thresholds (environment). Set 2026-09-23 from the first full CI soak (108
# runs): the earliest idle knock on any walk was 9.17s and no run had more
# than 3 knocks or 1 mood. They guard against regressions from that baseline;
# the bug they were written for knocked the dog at about 5s.
#   GRACE_SECS=8    any knock before this many seconds fails the run
#   MAX_KNOCKS=3    more knocks than this in the whole soak fails
#   MAX_MOODS=2     more mood arrivals than this fails
# The reference numbers come from CI (xvfb, software GL): a walk can diverge
# slightly between machines through floating-point differences in the rope,
# so compare local runs with local runs.
# A walk that ends early (the idle owner walks into a manhole, say) is
# reported but is not a failure: an idle dog is allowed to lose.
#
# Run timeout. On CI every frame is drawn by llvmpipe on the CPU, so a run's
# wall time grows with the window's pixel count, not with game time: measured
# 2026-10-28 on slow ubuntu-latest runners, a 30s soak took about 100s at
# 844x390, 155s at 1280x720 and 236s at 1920x1080 (about half that on a quick
# runner). RUN_TIMEOUT is the limit for a 1280x720 window and scales with
# pixel area, never below RUN_TIMEOUT itself, so 1920x1080 gets 540s. A run
# cut off by it is reported as TIMEOUT, distinct from a crash.
set -uo pipefail

cd "$(dirname "$0")/.."

OUT="${1:-soak}"
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
SOAK_SECS="${SOAK_SECS:-30}"
GRACE_SECS="${GRACE_SECS:-8}"
MAX_KNOCKS="${MAX_KNOCKS:-3}"
MAX_MOODS="${MAX_MOODS:-2}"
LEVELS="${LEVELS:-barri street park beach rain market oldtown trail station besos site spook scrap guell neteja montjuic partit}"
SIZES="${SIZES:-1280x720 1920x1080 844x390}"
SEEDS="${SEEDS:-1 2 3}"
RUN_TIMEOUT="${RUN_TIMEOUT:-240}"

mkdir -p "${OUT}"
CSV="${OUT}/soak.csv"
echo "level,size,seed,secs,knocks,first_knock,moods,cracks,ended,by_cause,by_mood,verdict" > "${CSV}"

RUN=()
if [ -z "${NO_XVFB:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
  RUN=(env LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a --server-args="-screen 0 1920x1200x24")
  POS=()
else
  POS=(--position 6000,6000)
fi

fails=0
for lv in ${LEVELS}; do
  for size in ${SIZES}; do
    for sd in ${SEEDS}; do
      log="${OUT}/${lv}-${size}-s${sd}.log"
      limit=$(( RUN_TIMEOUT * ${size%x*} * ${size#*x} / (1280 * 720) ))
      [ "${limit}" -ge "${RUN_TIMEOUT}" ] || limit="${RUN_TIMEOUT}"
      t0=${SECONDS}
      timeout "${limit}" "${RUN[@]}" "${GODOT}" --rendering-method gl_compatibility \
        --fixed-fps 60 --disable-vsync "${POS[@]}" --resolution "${size}" --path . \
        -- --level="${lv}" --soak="${SOAK_SECS}" --seed="${sd}" > "${log}" 2>&1
      rc=$?
      wall=$(( SECONDS - t0 ))
      line="$(grep -m1 '^SOAK level=' "${log}")"
      if [ -z "${line}" ] && [ "${rc}" -eq 124 ]; then
        echo "${lv},${size},${sd},,,,,,,,,TIMEOUT(${limit}s)" >> "${CSV}"
        echo "TIMEOUT ${lv} ${size} seed ${sd} - no result in ${limit}s, see ${log}"
        fails=$((fails + 1))
        continue
      fi
      if [ -z "${line}" ] || grep -qE "SCRIPT ERROR|Parse Error" "${log}"; then
        echo "${lv},${size},${sd},,,,,,,,,ERROR" >> "${CSV}"
        echo "ERROR  ${lv} ${size} seed ${sd} - see ${log}"
        fails=$((fails + 1))
        continue
      fi
      field() { sed -n "s/.* $1=\([^ ]*\).*/\1/p" <<< "${line}"; }
      secs="$(field secs)"; knocks="$(field knocks)"; moods="$(field moods)"
      cracks="$(field cracks)"; ended="$(field ended)"
      by_cause="$(field by_cause)"; by_mood="$(field by_mood)"
      first="$(sed -n 's/^SOAK knock t=\([0-9.]*\).*/\1/p' "${log}" | head -1)"
      verdict="ok"
      if [ -n "${first}" ] && awk "BEGIN{exit !(${first} < ${GRACE_SECS})}"; then
        verdict="FAIL(knock at ${first}s)"
      elif [ "${knocks}" -gt "${MAX_KNOCKS}" ]; then
        verdict="FAIL(${knocks} knocks)"
      elif [ "${moods}" -gt "${MAX_MOODS}" ]; then
        verdict="FAIL(${moods} moods)"
      fi
      echo "${lv},${size},${sd},${secs},${knocks},${first},${moods},${cracks},${ended},\"${by_cause//\"/\"\"}\",\"${by_mood//\"/\"\"}\",${verdict}" >> "${CSV}"
      printf '%-6s %-9s %-9s seed %s  knocks %s%s  moods %s  cracks %s  ended %s  (%ss of %ss)\n' \
        "${verdict%%(*}" "${lv}" "${size}" "${sd}" "${knocks}" "${first:+ (first ${first}s)}" \
        "${moods}" "${cracks}" "${ended}" "${wall}" "${limit}"
      [ "${verdict}" = "ok" ] || fails=$((fails + 1))
    done
  done
done

echo "results: ${CSV}"
if [ "${fails}" -gt 0 ]; then
  echo "SOAK FAILED: ${fails} run(s) over threshold"
  exit 1
fi
echo "SOAK OK"
