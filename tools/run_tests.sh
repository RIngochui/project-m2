#!/usr/bin/env bash
# Runs every headless test suite in tests/. Exit code = total failed cases.
# Set GODOT to your Godot 4.5 binary if it isn't on PATH as `godot`.
set -u
cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot not found. Set GODOT=/path/to/Godot_v4.5.x or put 'godot' on PATH." >&2
  exit 127
fi

# First run imports the project (creates .godot/).
if [ ! -d .godot ]; then
  "$GODOT_BIN" --headless --import >/dev/null 2>&1
fi

total=0
for suite in tests/*_tests.gd; do
  echo "== $suite"
  "$GODOT_BIN" --headless --fixed-fps 60 --script "res://$suite" 2>&1 \
    | grep -E "PASS|FAIL|failed|ERROR|SCRIPT ERROR|Parse Error"
  code=${PIPESTATUS[0]}
  total=$((total + code))
done
echo "== total failed: $total"
exit $total
