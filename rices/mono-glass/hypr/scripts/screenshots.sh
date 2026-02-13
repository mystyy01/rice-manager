#!/usr/bin/env bash
set -euo pipefail

out_dir="$HOME/Pictures/Screenshots"
mkdir -p "$out_dir"
out_file="$out_dir/$(date +'%s_screenshot.png')"

if command -v grimblast >/dev/null 2>&1; then
  grimblast --notify copysave area "$out_file"
  exit 0
fi

# Fallback if grimblast isn't installed.
if ! command -v grim >/dev/null 2>&1 || ! command -v slurp >/dev/null 2>&1; then
  echo "screenshots: need grim+slurp (or install grimblast)" >&2
  exit 1
fi

geom="$(slurp)"
grim -g "$geom" "$out_file"

if command -v wl-copy >/dev/null 2>&1; then
  wl-copy <"$out_file"
fi
