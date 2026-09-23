#!/usr/bin/env bash
# Behaviour snapshot for refactors: a plain-text record of what the game DOES
# on fixed seeds, so a change that is meant to alter nothing can prove it.
#
#   tools/behaviour_snapshot.sh OUT.txt
#   diff before.txt after.txt        # must be empty for a pure refactor
#
# Records, all headless and --fixed-fps 60 (deterministic on one machine):
#   - the autowalk bot's full walk on every level, plus the three chase
#     variants on street: the finish line and time
#   - an idle soak on every level with two seeds: knocks, moods, cracks, end
#   - every level's --selftest verdict lines
# Compare snapshots from the same machine only: the rope's floating point can
# differ slightly between platforms.
set -uo pipefail

cd "$(dirname "$0")/.."
OUT="${1:?usage: tools/behaviour_snapshot.sh OUT.txt}"
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
LEVELS="${LEVELS:-street park beach rain market oldtown trail station site spook scrap guell}"

run() { timeout 600 "${GODOT}" --headless --fixed-fps 60 --path . "$@" 2>&1; }

{
  for lv in ${LEVELS}; do
    echo "== autowalk ${lv}"
    run --quit-after 12000 -- --level="${lv}" --autowalk | grep -E '^AUTOWALK|SCRIPT ERROR|Parse Error'
  done
  for v in --chase --bolt --rescue; do
    echo "== autowalk street ${v}"
    run --quit-after 12000 -- --level=street --autowalk "${v}" | grep -E '^AUTOWALK|SCRIPT ERROR|Parse Error'
  done
  for lv in ${LEVELS}; do
    for sd in 1 2; do
      echo "== soak ${lv} seed ${sd}"
      run -- --level="${lv}" --soak=30 --seed="${sd}" | grep -E '^SOAK|SCRIPT ERROR|Parse Error'
    done
  done
  for lv in ${LEVELS}; do
    echo "== selftest ${lv}"
    run -- --level="${lv}" --selftest | grep -E 'SELFTEST|SCRIPT ERROR|Parse Error'
  done
} > "${OUT}"
echo "snapshot: ${OUT} ($(wc -l < "${OUT}") lines)"
