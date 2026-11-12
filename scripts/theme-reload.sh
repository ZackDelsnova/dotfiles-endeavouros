#!/bin/bash
# Apply freshly generated matugen colors to running apps.
# Called by quickshell/.config/quickshell/hyprquickpaper/commands.sh after `matugen image`.
# Idempotent and non-interactive: safe to run at login or repeatedly.
# Exits non-zero if Hyprland reports config errors or a reload fails.
set -u

fail=0

check_hypr() {
	sleep 0.2
	if [ -n "$(hyprctl configerrors 2>&1 | tr -d '[:space:]')" ]; then
		echo "theme-reload: hyprctl configerrors after $1:" >&2
		hyprctl configerrors >&2
		fail=1
	fi
}

# Hyprland: re-runs hyprland.lua, which dofile()s colors.lua.
# Required: saving colors.lua does NOT trigger Hyprland's autoreload (verified in step 4).
hyprctl reload >/dev/null
check_hypr "hyprctl reload"

# Waybar: SIGUSR2 = reload config + style.css (which @imports colors.css). Start it if not running.
if pgrep -x waybar >/dev/null; then
	pkill -SIGUSR2 -x waybar
else
	setsid -f waybar >/dev/null 2>&1 </dev/null
fi
check_hypr "waybar"

# Mako: re-reads config (which includes colors.conf). Skipped if mako isn't running yet.
if pgrep -x mako >/dev/null; then
	makoctl reload || { echo "theme-reload: makoctl reload failed" >&2; fail=1; }
fi
check_hypr "mako"

# Kitty: SIGUSR1 = reload config in every running instance (kitty.conf includes colors.conf).
pkill -SIGUSR1 -x kitty || true
check_hypr "kitty"

# Wofi: no-op. It reads style.css (and colors.css) every time it opens.
# Hyprlock: no-op. It reads hyprlock.conf (and hyprlock-colors.conf) every time it locks.
# Quickshell (hyprquickpaper): no-op. The picker calls Qt.quit() right after launching
#   commands.sh, so it loads theme/Colors.qml fresh on next open. `qs kill` is deliberately
#   not used: it could kill unrelated Quickshell configs.

exit "$fail"
