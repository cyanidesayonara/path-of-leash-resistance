#!/usr/bin/env bash
# Runs every test CI runs, each the way CI runs it: the headless ones
# headless, and the ones that need a display (appearance, HUD, touch, rotate
# prompt, ShapeBatch) with a real rendering context. Run headless, those fail
# or hang, which says nothing about the code.
#
#   GODOT=godot/Godot_v4.7-stable_win64_console.exe bash tools/run_tests.sh [FILTER]
#
# The tests are the lines of tests/ci_tests.txt, so this is always CI's list.
# FILTER is a substring of an item's name (`leash`, `test_saves`, `walk market`).
# Every test goes through tools/godot_ci.sh, so a SCRIPT ERROR fails it as in CI.
#
# TIMEOUT  seconds one item may take (default 300).
# WALKS=1  adds the walk checks: every walk in Game.LEVELS and the tutorial
#          built and checked (--selftest) and played for 1800 frames, the
#          tutorial lesson and snow smokes, and four full autowalks of the
#          street (plain, --chase, --bolt, --rescue).
# SHARD=K/N runs only the K-th of N shares of all that, split by cost so the
#          shares take about as long; CI runs the N shards side by side.
# XVFB=1   runs the tests that need a display under xvfb-run with software GL.
# DRY=1    lists what would run (with SHARD, that shard's share) and exits.
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
TIMEOUT="${TIMEOUT:-300}"
FILTER="${1:-}"
WALKS="${WALKS:-0}"
SHARD="${SHARD:-1/1}"
XVFB="${XVFB:-0}"
GH="${GITHUB_ACTIONS:-false}"
TAB="$(printf '\t')"

# the campaign's walks, read from the game itself so a new walk is checked
# the day it is added
levels() {
  sed -n 's/^const LEVELS: Array\[String\] = \[\(.*\)\]/\1/p' autoload/game.gd | tr -d '"\r ' | tr ',' '\n'
}

# every item, one per line: cost in seconds, kind, payload (tab-separated)
items() {
  awk 'BEGIN { c = 5 }
    /^# cost [0-9]+/ { c = $3; next }
    /^#/ || /^[[:space:]]*$/ { next }
    { sub(/\r$/, ""); printf "%d\ttest\t%s\n", c, $0; c = 5 }' tests/ci_tests.txt
  if [ "${WALKS}" = 1 ]; then
    for lv in $(levels) tutorial; do
      printf '21\twalk\t%s\n' "${lv}"
    done
    printf '15\tsmoke\t1200 --tutorial\n'
    printf '17\tsmoke\t1800 --level=street --weather=snow\n'
    for v in plain --chase --bolt --rescue; do
      printf '75\tautowalk\t%s\n' "${v}"
    done
  fi
}

# Longest first, each to the least loaded shard: every shard computes the same
# plan and keeps its own part, then runs it in list order. Ties go to the
# earlier line and the lower shard.
plan() {
  local k="${SHARD%/*}" n="${SHARD#*/}"
  items | awk -F'\t' -v OFS='\t' '{ print $1, NR, $0 }' | sort -t "${TAB}" -k1,1nr -k2,2n |
    awk -F'\t' -v k="${k}" -v n="${n}" '{
      best = 0
      for (s = 1; s < n; s++) if (load[s] < load[best]) best = s
      load[best] += $1
      if (best == k - 1) { print $2 "\t" $4 "\t" $5; mine += $1 }
    } END { printf "shard %d/%d: about %d s of work\n", k, n, mine > "/dev/stderr" }' |
    sort -t "${TAB}" -k1,1n | cut -f2-
}

name_of() {
  case "$1" in
    test) grep -oE 'res://tests/[A-Za-z0-9_]+\.gd' <<<"$2" ;;
    *) echo "$1 $2" ;;
  esac
}

no_errors() {
  ! grep -qE 'SCRIPT ERROR|Parse Error|Failed to load script' "$1"
}

run_item() {
  local kind="$1" payload="$2" log="$3"
  case "${kind}" in
    test)
      if [ "${XVFB}" = 1 ] && [[ " ${payload} " != *" --headless "* ]]; then
        # shellcheck disable=SC2086
        LIBGL_ALWAYS_SOFTWARE=1 timeout "${TIMEOUT}" xvfb-run -a --server-args="-screen 0 1280x1024x24" \
          bash tools/godot_ci.sh "${GODOT}" ${payload} >"${log}" 2>&1
      else
        # shellcheck disable=SC2086
        timeout "${TIMEOUT}" bash tools/godot_ci.sh "${GODOT}" ${payload} >"${log}" 2>&1
      fi
      ;;
    walk)
      # the level's structural sanity sweep (props on their own ground,
      # goals the walk can satisfy), then 1800 frames of the walk itself
      timeout "${TIMEOUT}" "${GODOT}" --headless --path . -- --level="${payload}" --selftest >"${log}" 2>&1
      [ $? -ne 124 ] || return 1
      grep -q 'SELFTEST OK' "${log}" && ! grep -q 'SELFTEST FAIL' "${log}" && no_errors "${log}" || return 1
      timeout "${TIMEOUT}" "${GODOT}" --headless --path . --quit-after 1800 -- --level="${payload}" >>"${log}" 2>&1
      [ $? -ne 124 ] && no_errors "${log}"
      ;;
    smoke)
      # shellcheck disable=SC2086
      timeout "${TIMEOUT}" "${GODOT}" --headless --path . --quit-after ${payload%% *} -- ${payload#* } >"${log}" 2>&1
      [ $? -ne 124 ] && no_errors "${log}"
      ;;
    autowalk)
      # the attract bot walks the street end to end (out, off the leash,
      # home), with that chase variant forced on; --fixed-fps maps frames to
      # physics time
      local v="${payload}"
      [ "${v}" = plain ] && v=""
      # shellcheck disable=SC2086
      timeout "${TIMEOUT}" "${GODOT}" --headless --fixed-fps 60 --path . --quit-after 12000 -- --level=street --autowalk ${v} >"${log}" 2>&1
      [ $? -ne 124 ] && ! grep -qE 'SCRIPT ERROR|Parse Error' "${log}" &&
        grep -q 'AUTOWALK FINISHED' "${log}" && ! grep -q 'AUTOWALK STALL' "${log}"
      ;;
  esac
}

if [ "${DRY:-0}" = 1 ]; then
  plan | while IFS="${TAB}" read -r kind payload; do name_of "${kind}" "${payload}"; done
  exit 0
fi

log="$(mktemp)"
pass=0
failed=()
while IFS="${TAB}" read -r kind payload; do
  name="$(name_of "${kind}" "${payload}")"
  [ -n "${FILTER}" ] && [[ "${name}" != *"${FILTER}"* ]] && continue
  start=${SECONDS}
  if run_item "${kind}" "${payload}" "${log}"; then
    pass=$((pass + 1))
    if [ "${GH}" = true ]; then
      echo "::group::ok    ${name} ($((SECONDS - start)) s)"
      cat "${log}"
      echo "::endgroup::"
    else
      echo "ok    ${name} ($((SECONDS - start)) s)"
    fi
  else
    failed+=("${name}")
    if [ "${GH}" = true ]; then
      echo "::error::${name} failed after $((SECONDS - start)) s"
      cat "${log}"
    else
      echo "FAIL  ${name} ($((SECONDS - start)) s)"
      grep -E 'FAIL|SCRIPT ERROR|Parse Error' "${log}" | head -5 | sed 's/^/      /'
    fi
  fi
done < <(plan)
rm -f "${log}"

echo "${pass} passed, ${#failed[@]} failed (${SECONDS} s)"
for t in "${failed[@]}"; do echo "  failed: ${t}"; done
[ ${#failed[@]} -eq 0 ]
