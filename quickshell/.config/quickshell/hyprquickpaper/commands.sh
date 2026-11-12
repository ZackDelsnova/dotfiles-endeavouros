#!/bin/bash
# Wallpaper → theme pipeline. Called by shell.qml (detached) with the selected wallpaper path.
# Can also be run manually: commands.sh <wallpaper-path>
set -e

# Log everything (this script runs detached from Quickshell, so errors are otherwise invisible).
# tee keeps output on the terminal for manual runs too.
mkdir -p "$HOME/.cache"
exec > >(tee -a "$HOME/.cache/hyprquickpaper.log") 2>&1
echo "=== $(date '+%F %T') commands.sh $*"

WALLPAPER="$1"
[ -f "$WALLPAPER" ] || { echo "no wallpaper: $WALLPAPER" >&2; exit 1; }

awww img "$WALLPAPER" -t grow --transition-duration 1
# hyprlock.conf's background path points here, so the lock screen follows the wallpaper.
ln -sf "$WALLPAPER" "$HOME/.cache/current-wallpaper-hyprlock"

echo "$WALLPAPER" > "$HOME/.cache/current-wallpaper"

# matugen 4.x: `--type auto` is invalid; --source-color-index 0 prevents an interactive
# source-color prompt that would hang this detached script.
matugen image "$WALLPAPER" -m dark --source-color-index 0

"$HOME/.dotfiles/scripts/theme-reload.sh"
