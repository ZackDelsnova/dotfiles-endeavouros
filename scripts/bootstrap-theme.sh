#!/bin/bash
# Fresh-clone bootstrap, started from hyprland.lua at login. Idempotent:
#  - repairs the hyprlock wallpaper symlink if it's missing or dangling
#  - generates all matugen outputs from the committed fallback wallpaper if colors.lua is missing
set -e

WP="$HOME/.config/hypr/fallback-wallpaper.jpg"

# hyprlock background (hyprlock.conf -> ~/.cache/current-wallpaper-hyprlock). Runs before the
# colors.lua early-exit so a cleared ~/.cache is also repaired, not just a fresh clone.
# -e follows the link, so a dangling link (deleted wallpaper) is re-pointed too (-sfn).
HYPRLOCK_WP="$HOME/.cache/current-wallpaper-hyprlock"
if [ ! -e "$HYPRLOCK_WP" ] && [ -f "$WP" ]; then
	mkdir -p "$HOME/.cache"
	ln -sfn "$WP" "$HYPRLOCK_WP"
fi

[ -f "$HOME/.config/hypr/colors.lua" ] && exit 0

[ -f "$WP" ] || { echo "no fallback wallpaper" >&2; exit 1; }

# matugen 4.x: `--type auto` is invalid; --source-color-index 0 avoids an interactive prompt.
matugen image "$WP" -m dark --source-color-index 0

# hl.exec_cmd() launches are concurrent, so waybar may already have started (and failed on the
# missing colors.css) before matugen finished. theme-reload.sh re-applies everything and starts
# waybar if it isn't running.
"$HOME/.dotfiles/scripts/theme-reload.sh"
