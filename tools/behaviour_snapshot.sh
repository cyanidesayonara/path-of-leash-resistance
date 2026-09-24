#!/usr/bin/env bash
# Behaviour snapshot for refactors: a plain-text record of what the game DOES
# on fixed seeds, so a change that is meant to alter nothing can prove it.
#
#   tools/behaviour_snapshot.sh OUT.txt
#   diff before.txt after.txt        # must be empty for a pure refactor
#
# Records, all headless and --fixed-fps 60 (deterministic on one machine):
#   - the autowalk bot's full walk on every level, plus the three chase
#     variants on street: the leg and finish times
#   - an idle soak on every level with two seeds: knocks, moods, cracks, end
#   - every level's --selftest verdict lines
#
# Each run gets its own empty user-data folder, so no run sees records or
# settings saved by another (or by whoever last played on this machine), and
# the runs can go in parallel: JOBS=4 by default.
# Compare snapshots from the same machine only: the rope's floating point can
# differ slightly between platforms.
set -uo pipefail

cd "$(dirname "$0")/.."
OUT="${1:?usage: tools/behaviour_snapshot.sh OUT.txt}"
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
LEVELS="${LEVELS:-street park beach rain market oldtown trail station site spook scrap guell neteja}"
JOBS="${JOBS:-4}"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

# one line per job: an ordering key, a header, then the Godot user args
n=0
add() { n=$((n + 1)); printf '%03d\t%s\t%s\n' "${n}" "$1" "$2" >> "${WORK}/jobs"; }
for lv in ${LEVELS}; do add "autowalk ${lv}" "--quit-after 12000 -- --level=${lv} --autowalk"; done
for v in --chase --bolt --rescue; do add "autowalk street ${v}" "--quit-after 12000 -- --level=street --autowalk ${v}"; done
for lv in ${LEVELS}; do for sd in 1 2; do add "soak ${lv} seed ${sd}" "-- --level=${lv} --soak=30 --seed=${sd}"; done; done
for lv in ${LEVELS}; do add "selftest ${lv}" "-- --level=${lv} --selftest"; done

export GODOT WORK
run_job() {
  local key="$1" header="$2" args="$3"
  local home="${WORK}/home-${key}"
  mkdir -p "${home}"
  {
    echo "== ${header}"
    # APPDATA (Windows) and XDG_DATA_HOME (Linux) move user:// to a fresh folder
    # shellcheck disable=SC2086
    APPDATA="${home}" XDG_DATA_HOME="${home}" timeout 600 "${GODOT}" --headless --fixed-fps 60 --path . ${args} 2>&1 \
      | grep -E '^AUTOWALK|^SOAK|SELFTEST|SCRIPT ERROR|Parse Error'
  } > "${WORK}/out-${key}"
}
export -f run_job

while IFS=$'\t' read -r key header args; do
  printf '%s\0%s\0%s\0' "${key}" "${header}" "${args}"
done < "${WORK}/jobs" | xargs -0 -n 3 -P "${JOBS}" bash -c 'run_job "$1" "$2" "$3"' _

cat "${WORK}"/out-* > "${OUT}"
echo "snapshot: ${OUT} ($(wc -l < "${OUT}") lines, ${n} runs)"
