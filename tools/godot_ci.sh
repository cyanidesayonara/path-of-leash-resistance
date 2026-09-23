#!/usr/bin/env bash
# Runs Godot for a CI step and fails the step on any script error.
#
#   bash tools/godot_ci.sh ./Godot_v4.7-stable_linux.x86_64 --headless --path . --script res://tests/test_x.gd
#
# A test script's own checks only cover what it looks at: a runtime error in
# code it merely calls is logged as SCRIPT ERROR and the test can still exit
# 0 and print OK (#32). So besides the exit code, any "SCRIPT ERROR" or
# "Parse Error" line in the output fails the step. The full output is still
# printed, so the log shows what went wrong.
set -uo pipefail

log="$(mktemp)"
"$@" 2>&1 | tee "${log}"
rc=${PIPESTATUS[0]}
if grep -qE 'SCRIPT ERROR|Parse Error' "${log}"; then
  echo "::error::script errors in the output above:"
  grep -E 'SCRIPT ERROR|Parse Error' "${log}" | sort | uniq -c
  rm -f "${log}"
  exit 1
fi
rm -f "${log}"
exit "${rc}"
