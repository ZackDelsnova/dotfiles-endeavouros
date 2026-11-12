# Dotfiles — EndeavourOS / Hyprland 0.57 (Lua config) / GNU Stow

## Layout
- Stow packages at repo root, each mirrors $HOME. One stow package per app.
- Hyprland config is Lua-based (Hyprland 0.57 removed .conf support).
  Loaded via `require()` except colors.lua which uses `dofile()` so
  `hyprctl reload` picks up new values.
- Generated color files live inside the packages (gitignored);
  templates + one fallback are committed.

## Theme pipeline
hyprquickpaper (Quickshell) → commands.sh → awww img + matugen → 
theme-reload.sh → hyprctl reload, waybar restart, kitty SIGUSR1,
mako reload, wofi picks up on next open, hyprlock picks up on next lock.

- matugen 4.2.0 — has no `-o` flag, `--type auto` is invalid (use `-m dark`).
- Hyprland 0.57 Lua API: check /usr/share/hypr/stubs/hl.meta.lua for
  exact field names before writing anything.
- wofi is launched from `/` (Hyprland's cwd), so `@import url("colors.css")`
  fails silently. wofi uses its native `colors=` config + `--wofi-color<N>`
  mechanism instead. Do NOT switch wofi back to @import.

## Glass family (intentional asymmetry)
- waybar: 0.75 (thin strip)
- kitty: 0.85
- mako: 0.85
- wofi: 0.92 (large window needs higher)
- picker: NO glass, cards float over whatever's behind — deliberate.

## Guardrails
- Do NOT run `sudo`, `pacman`, `yay`, or install anything.
- Do NOT run `stow --adopt`.
- Do NOT edit anything under `nvim/` (managed by LazyVim separately).
- Before any `stow` command, run `stow -nv <pkg>` first and show output.
- Show `git diff` after every logical change.
- One step at a time; stop for approval between steps.

## Validating
- `hyprctl configerrors` after any Hyprland change
- `bash -n` + `shellcheck` on scripts
- `qmllint` on shell.qml changes
- `jq empty` on waybar config
- `hyprctl layers` to see actual layer names

## Bootstrap for fresh clone
scripts/bootstrap-theme.sh runs on login. If colors.lua is missing, it
generates from fallback-wallpaper.jpg and creates the hyprlock link.
Idempotent — safe to run on every login.

## Known future work
- Quickshell widgets to eventually replace waybar + wofi
- inactive_opacity = 0.95 in general.lua is intentional (visual hierarchy)
