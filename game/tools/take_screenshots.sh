#!/usr/bin/env bash
# Author: Karl Bien Madrid
# Plays a scripted run on a virtual screen and saves PNGs to game/screenshots/.
# Needs Linux with Xvfb (available in the Claude cloud environment).
set -euo pipefail
GAME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$("$(dirname "$0")/get_godot.sh")"

"$GODOT" --headless --path "$GAME_DIR" --import >/dev/null 2>&1
xvfb-run -a -s "-screen 0 1280x720x24" \
  "$GODOT" --path "$GAME_DIR" --rendering-driver opengl3 --audio-driver Dummy \
  --fixed-fps 60 -s res://tools/screenshots.gd
