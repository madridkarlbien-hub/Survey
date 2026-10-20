#!/usr/bin/env bash
# Author: Karl Bien Madrid
# Runs all automated tests headless. Fails if any test fails or Godot reports an error.
set -uo pipefail
GAME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$(dirname "$0")/get_godot.sh")"
LOG="$(mktemp)"

"$GODOT" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
"$GODOT" --headless --path "$GAME_DIR" --fixed-fps 60 -s res://tests/run_tests.gd 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}

if grep -qE "SCRIPT ERROR|^ERROR:" "$LOG"; then
  echo "Godot reported errors during the tests (see above)."
  STATUS=1
fi
rm -f "$LOG"
exit "$STATUS"
