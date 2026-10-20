#!/usr/bin/env bash
# Author: Karl Bien Madrid
# Downloads the Linux build of Godot (once) and prints its path.
# Used by the cloud/CI test and screenshot scripts; not needed on Windows.
set -euo pipefail
VERSION="4.7.2"
DIR="${GODOT_CACHE:-$HOME/.cache/godot}/$VERSION"
BIN="$DIR/Godot_v${VERSION}-stable_linux.x86_64"
if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  curl -sSL -o "$DIR/godot.zip" \
    "https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
  unzip -oq "$DIR/godot.zip" -d "$DIR"
  rm "$DIR/godot.zip"
fi
echo "$BIN"
