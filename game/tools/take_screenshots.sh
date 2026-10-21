#!/usr/bin/env bash
# Author: Karl Bien Madrid
# A bot plays a full run on a virtual screen and saves PNGs to game/screenshots/.
# Fails if Godot reports a script error. Needs Linux with Xvfb (available in
# the Claude cloud environment).
set -uo pipefail
GAME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$(dirname "$0")/get_godot.sh")"
LOG="$(mktemp)"

"$GODOT" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
# The time limit stops a stuck bot from running forever.
timeout 1200 xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --path "$GAME_DIR" --rendering-driver opengl3 --audio-driver Dummy \
  --fixed-fps 60 -s res://tools/screenshots.gd > "$LOG" 2>&1
STATUS=$?
grep -vE "ALSA|alsa|audio driver|V-Sync|shader|^\s+at: |^\s*$" "$LOG"

if grep -qE "SCRIPT ERROR|^ERROR:" "$LOG"; then
  echo "Godot reported errors during the bot run (see above)."
  STATUS=1
fi
rm -f "$LOG"
exit "$STATUS"
