#!/bin/bash

WALLPAPER="$1"
CACHE_DIR="$HOME/.cache/matugen"

awww img "$WALLPAPER" -t grow --transition-duration 1

matugen image "$WALLPAPER" --type auto

if [ -f "$CACHE_DIR/colors.json" ]; then
  PRIMARY=$(jq -r '.palette.primary' "$CACHE_DIR/colors.json")
  SECONDARY=$(jq -r '.palette.secondary' "$CACHE_DIR/colors.json")
  SURFACE=$(jq -r '.palette.surface' "$CACHE_DIR/colors.json")

  hyprctl keyword general:col.active_border "$PRIMARY"
  hyprctl keyword general:col.inactive_border "$SECONDARY"
fi
