#!/usr/bin/env bash
# Writes the title-screen version label into res://build_label.txt:
#
#   v1.55 (a1b2c3d)     HEAD is exactly tag v1.55 (every release build)
#   v1.54+ (a1b2c3d)    HEAD is past v1.54 without a tag of its own
#   untagged (a1b2c3d)  no tag reachable (shallow clone without tags)
#
# Run from the repo root before an export or a screenshot sweep. main.gd reads
# the file at startup; without it the label says "dev". The file is gitignored
# and packed into exports by each preset's include_filter.
#
# Needs tags in the clone: in Actions, check out with fetch-depth: 0.
set -euo pipefail

cd "$(dirname "$0")/.."

sha="$(git rev-parse --short=7 HEAD)"
if tag="$(git describe --tags --exact-match HEAD 2>/dev/null)"; then
  label="${tag} (${sha})"
elif tag="$(git describe --tags --abbrev=0 HEAD 2>/dev/null)"; then
  label="${tag}+ (${sha})"
else
  label="untagged (${sha})"
fi

printf '%s\n' "${label}" > build_label.txt
echo "build label: ${label}"
