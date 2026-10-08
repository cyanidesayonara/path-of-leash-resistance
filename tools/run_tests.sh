#!/usr/bin/env bash
# Runs every test script CI runs, locally, each the way CI runs it: the
# headless ones headless, and the ones CI gives a display (xvfb-run, the
# Compatibility renderer: appearance, HUD, touch, rotate prompt, ShapeBatch)
# with a real rendering context. Run headless, those fail or hang, which says
# nothing about the code.
#
#   GODOT=godot/Godot_v4.7-stable_win64_console.exe bash tools/run_tests.sh [FILTER]
#
# FILTER is a substring of the test's path (`leash`, `test_saves`). Every
# step goes through tools/godot_ci.sh, so a SCRIPT ERROR fails it as in CI.
# TIMEOUT is the seconds one test may take (default 300). The list is read
# from .github/workflows/ci.yml, so it is always CI's list.
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-./Godot_v4.7-stable_linux.x86_64}"
TIMEOUT="${TIMEOUT:-300}"
FILTER="${1:-}"

pass=0
failed=()
while IFS= read -r line; do
  # everything after the CI binary: the flags and the script
  args="${line#*Godot_v4.7-stable_linux.x86_64 }"
  test="$(grep -oE 'res://tests/[A-Za-z0-9_]+\.gd' <<<"${args}")"
  [ -n "${FILTER}" ] && [[ "${test}" != *"${FILTER}"* ]] && continue
  # shellcheck disable=SC2086
  if timeout "${TIMEOUT}" bash tools/godot_ci.sh "${GODOT}" ${args} >"/tmp/run_tests_$$.log" 2>&1; then
    pass=$((pass + 1))
    echo "ok    ${test}"
  else
    failed+=("${test}")
    echo "FAIL  ${test}"
    grep -E 'FAIL|SCRIPT ERROR|Parse Error' "/tmp/run_tests_$$.log" | head -5 | sed 's/^/      /'
  fi
done < <(grep -oE 'godot_ci\.sh \./Godot_v4\.7-stable_linux\.x86_64 [^"]*--script res://tests/[A-Za-z0-9_]+\.gd[^"]*' .github/workflows/ci.yml)
rm -f "/tmp/run_tests_$$.log"

echo "${pass} passed, ${#failed[@]} failed"
for t in "${failed[@]}"; do echo "  failed: ${t}"; done
[ ${#failed[@]} -eq 0 ]
