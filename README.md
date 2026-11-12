# dotfiles

EndeavourOS (Arch) + Hyprland 0.57 with a Lua config, themed dynamically from the current
wallpaper via matugen, managed with GNU Stow (one package per app).

> **For AI-assisted development:** [`CLAUDE.md`](CLAUDE.md) holds the architecture notes,
> guardrails, and validation commands. This README doesn't repeat them.

---

## Features

- **Wallpaper-driven color scheme.** Picking a wallpaper runs matugen, which renders one
  color file per app (Hyprland borders, hyprlock, waybar, wofi, kitty, mako, and the picker itself)
  and hot-reloads everything that's running.
- **Glassy translucent UI.** waybar, wofi, kitty, and mako use translucent backgrounds that
  Hyprland blurs behind (`blur = true` layer rules for waybar/wofi/mako; kitty is covered by
  Hyprland's global window blur).
- **Custom Quickshell wallpaper picker** (`hyprquickpaper`, modified from upstream):
  - looping carousel with sheared cards
  - `a` / `d` page-jump by one screen's worth of cards
  - sharp previews (thumbnails generated at up to 1000 px tall with ImageMagick, mipmapped)
  - opens centered on the currently applied wallpaper
- **hyprlock follows the wallpaper.** Its background is a symlink that the theme script updates,
  and `immediate_render = true` means no dropped keystrokes while it fades in.
- **Auto-lock** via hypridle after 10 minutes idle, then screen off at 11 minutes. No suspend.
- **Screen recording toggle** (`SUPER + ALT + R`): pick a region with slurp; recording runs in
  the background with audio. Press again to stop; the file is saved as a timestamped `.mp4`
  with notifications at each step.
- **Fresh-clone bootstrap.** On login, `scripts/bootstrap-theme.sh` generates a full palette
  from the committed `fallback-wallpaper.jpg` if no generated colors exist yet.
- **GNU Stow layout**, one package per app.

---

## Requirements

All packages below come from the official Arch repos (`extra`). Versions are the ones this
setup is running on.

### Core

| Package | Version | Role |
|---|---|---|
| `hyprland` | 0.57.2-1 | Compositor. **≥ 0.57 required:** the config is Lua (`.conf` support was removed). |
| `hyprlock` | 0.9.7-2 | Lock screen |
| `hypridle` | 0.1.8-2 | Idle daemon (auto-lock, DPMS) |
| `awww` | 0.12.1-1 | Wallpaper daemon (`awww-daemon`) + setter (`awww img`) |
| `matugen` | 4.2.0-1 | Material You palette generator. **4.2.x required:** the CLI differs from earlier versions (see [Known behaviors](#known-behaviors)). |
| `quickshell` | 0.3.2-1 | Runs the wallpaper picker |
| `stow` | 2.4.1-1 | Symlinks packages into `$HOME` |

### UI

| Package | Version | Role |
|---|---|---|
| `waybar` | 0.16.0-1 | Status bar |
| `wofi` | 1.5.3-1 | App launcher |
| `kitty` | 0.50.0-1 | Terminal |
| `mako` | 1.11.0-1 | Notification daemon |

### Shell / tools

| Package | Version | Notes |
|---|---|---|
| `zsh` | 5.9.2-1 | Stow package exists, but `.zshrc` is currently a placeholder (see [Known issues](#known-issues--todo)) |
| `starship` | 1.27.0-1 | Config present, not yet wired into zsh |
| `neovim` | 0.12.6-1 | Binary is `nvim`. Config is a LazyVim starter, managed separately. |
| `cava` | 1.0.0-1 | Installed but not themed (stock config, no active integration) |

### Used by scripts

| Package | Version | Used by |
|---|---|---|
| `imagemagick` | 7.1.2.35-1 | `cache.sh`: picker thumbnails (`magick`) |
| `jq` | 1.8.2-1 | `cache.sh`: reads the picker's `config.json` |

### Used by keybinds

| Package | Version | Used by |
|---|---|---|
| `hyprshot` | 1.3.0-4 | Screenshots |
| `grim` | 1.5.0-2 | Screenshot backend for hyprshot |
| `slurp` | 1.5.0-2 | Region selection (screenshots, recording) |
| `wf-recorder` | 0.6.0-2 | Screen recording |
| `libnotify` | 0.8.9-1 | `notify-send` for recording notifications |
| `wireplumber` | 0.5.19-1 | `wpctl` for volume keys |
| `brightnessctl` | 0.5.1-3 | Brightness keys |
| `playerctl` | 2.4.1-5 | Media keys |
| `thunar` | 4.20.10-1 | File manager (`SUPER + E`) |
| `yazi` | 26.9.1-2 | TUI file manager (`SUPER + SHIFT + E`) |

`hyprland.lua` also autostarts `nm-applet` and `blueman-applet` for the waybar tray
(packages `network-manager-applet` and `blueman`).

### Fonts

| Package | Version | Where it's used |
|---|---|---|
| `ttf-jetbrains-mono-nerd` | 3.5.1-2 | Font family `"JetBrainsMono Nerd Font"`: kitty's font, and the first font in waybar's font list. It provides the waybar icon glyphs (wifi, ethernet, battery). |
| `ttf-jetbrains-mono` | 2.304-2 | Font family `"JetBrains Mono"`: wofi's font, and waybar's text fallback |
| `noto-fonts-cjk` | 20240730-1 | Not named in any config. fontconfig falls back to it for waybar's kanji workspace labels (一 … 十). |
| `noto-fonts` | 1:2026.11.01-1 | Not named in any config. fontconfig falls back to it for waybar's volume symbols (🔈🔉🔊). |

---

## Installation

> The paths below assume the repo lives at `~/.dotfiles`. `hyprland.lua`, `commands.sh` and
> `bootstrap-theme.sh` call `~/.dotfiles/scripts/…` by absolute path.

1. **Clone:**
   ```sh
   git clone <this-repo> ~/.dotfiles
   ```

2. **Install packages** (adjust to taste):
   ```sh
   sudo pacman -S --needed \
     hyprland hyprlock hypridle awww matugen quickshell stow \
     waybar wofi kitty mako \
     zsh starship neovim cava \
     imagemagick jq \
     hyprshot grim slurp wf-recorder libnotify wireplumber brightnessctl playerctl thunar yazi \
     network-manager-applet blueman \
     ttf-jetbrains-mono-nerd ttf-jetbrains-mono noto-fonts noto-fonts-cjk
   ```

3. **Stow the packages.** Dry-run each package first. Stow refuses to overwrite existing
   files, so back up any existing `~/.config/<app>` first.
   ```sh
   cd ~/.dotfiles
   stow -nv cava hypr kitty mako matugen nvim quickshell starship waybar wofi zsh   # dry run
   stow     cava hypr kitty mako matugen nvim quickshell starship waybar wofi zsh
   ```
   `scripts/` is **not** a stow package; it's called in place.

   With an empty target, stow folds each app directory into a single symlink (e.g.
   `~/.config/hypr → ~/.dotfiles/hypr/.config/hypr`). As a result, matugen's generated files
   land inside the repo, where `.gitignore` excludes them.

4. **Adjust machine-specific values** (hardcoded for the author's machine):
   - `hypr/.config/hypr/monitors.lua`: output `HDMI-A-1`, `1920x1080@144`
   - `quickshell/.config/quickshell/hyprquickpaper/config.json`: `wallpaper_path` and
     `cache_path` are absolute `/home/zack/...` paths. They must be absolute and must end with
     `/` (upstream requirement).

5. **Add wallpapers** to `~/Pictures/Wallpapers/`. The picker lists `*.png` and `*.jpg`.

6. **First run.** Either:
   - log out and back in. `bootstrap-theme.sh` runs at Hyprland start and generates colors
     from `fallback-wallpaper.jpg`. Or
   - run it manually:
     ```sh
     ~/.dotfiles/scripts/bootstrap-theme.sh
     ```

   Then apply a real wallpaper, either from the picker (`SUPER + W`) or directly:
   ```sh
   ~/.dotfiles/quickshell/.config/quickshell/hyprquickpaper/commands.sh ~/Pictures/Wallpapers/<file>
   ```

   The bootstrap only generates colors. It doesn't set the desktop wallpaper or write
   `~/.cache/current-wallpaper`, so pick a wallpaper once after the first login.

**`~/.cache/current-wallpaper`** is the source of truth for the active wallpaper. It holds the
full path written by `commands.sh` and is read by the picker to open on the current wallpaper.
Related state:

| Path | What |
|---|---|
| `~/.cache/current-wallpaper` | Full path of the active wallpaper |
| `~/.cache/current-wallpaper-hyprlock` | Symlink to the active wallpaper (hyprlock's background) |
| `~/.cache/quickshell/thumbs/` | Picker thumbnails (per `config.json`) |
| `~/.cache/hyprquickpaper.log` | Log of every `commands.sh` run (it runs detached, so errors would otherwise be invisible) |

---

## Repo structure

```
~/.dotfiles
├── CLAUDE.md                  architecture notes + guardrails (AI-assisted dev)
├── README.md
├── scripts/                   NOT a stow package; called by absolute path
│   ├── bootstrap-theme.sh     login-time bootstrap (fallback palette, hyprlock link)
│   └── theme-reload.sh        pushes new colors into running apps
├── cava/                      cava: stock config + bundled shaders/themes
├── hypr/                      Hyprland, hyprlock, hypridle
│   └── .config/hypr/
│       ├── hyprland.lua       entry point: loads colors, requires modules, autostart, animations, input
│       ├── general.lua        gaps, borders, opacity, blur, glass layer rules
│       ├── binds.lua          keybinds
│       ├── rules.lua          window rules
│       ├── monitors.lua       monitor layout
│       ├── colors.fallback.lua   committed Catppuccin Mocha palette (used if colors.lua is missing/broken)
│       ├── fallback-wallpaper.jpg  bootstrap source image
│       ├── hyprlock.conf      lock screen layout
│       ├── hypridle.conf      idle timers
│       └── .luarc.json        points lua-language-server at /usr/share/hypr/stubs
├── kitty/                     kitty.conf (opacity + include colors.conf)
├── mako/                      config (include colors.conf)
├── matugen/                   config.toml + templates/ (one template per generated file)
├── nvim/                      LazyVim starter (managed separately)
├── quickshell/                hyprquickpaper wallpaper picker
│   └── .config/quickshell/hyprquickpaper/
│       ├── shell.qml          the picker UI
│       ├── commands.sh        wallpaper → theme pipeline
│       ├── cache.sh           thumbnail generator
│       └── config.json        paths, cards per screen, batch size
├── starship/                  starship.toml
├── waybar/                    config (JSON) + style.css
├── wofi/                      config + style.css
└── zsh/                       .zshrc (placeholder)
```

### Source vs generated

matugen writes these files. They are **gitignored** and must not be edited by hand; change the
template in `matugen/.config/matugen/templates/` instead.

| Generated file | Template |
|---|---|
| `hypr/.config/hypr/colors.lua` | `hyprland.lua.template` |
| `hypr/.config/hypr/hyprlock-colors.conf` | `hyprlock.conf.template` |
| `kitty/.config/kitty/colors.conf` | `kitty.conf.template` |
| `mako/.config/mako/colors.conf` | `mako.conf.template` |
| `waybar/.config/waybar/colors.css` | `waybar.css.template` |
| `wofi/.config/wofi/colors` | `wofi-colors.template` |
| `quickshell/.config/quickshell/hyprquickpaper/theme/Colors.qml` | `Colors.qml.template` |

The one committed fallback is `hypr/.config/hypr/colors.fallback.lua`. `hyprland.lua` loads it
when `colors.lua` is missing or fails to load, so Hyprland still starts with readable borders.

See [`CLAUDE.md`](CLAUDE.md) for the architecture deep-dive.

---

## Theme pipeline

```
hyprquickpaper (Quickshell, SUPER+W)
  └─ commands.sh <wallpaper>
       ├─ awww img <wallpaper> -t grow --transition-duration 1
       ├─ ln -sf <wallpaper> ~/.cache/current-wallpaper-hyprlock
       ├─ echo <wallpaper> > ~/.cache/current-wallpaper
       ├─ matugen image <wallpaper> -m dark --source-color-index 0
       │    └─ renders all 7 templates (see table above)
       └─ scripts/theme-reload.sh
            ├─ hyprctl reload           → hyprland.lua re-runs, dofile()s colors.lua
            ├─ waybar: SIGUSR2           → reloads config + style.css (starts waybar if not running)
            ├─ mako: makoctl reload      (only if mako is running)
            ├─ kitty: SIGUSR1            → every running instance reloads kitty.conf
            ├─ wofi: nothing             → reads its colors file on next open
            ├─ hyprlock: nothing         → reads hyprlock-colors.conf on next lock
            └─ picker: nothing           → it Qt.quit()s on apply; loads Colors.qml on next open
```

`theme-reload.sh` runs `hyprctl configerrors` after each step and exits non-zero if any appear.
`--source-color-index 0` stops matugen from asking interactively for a source color, which would
hang the detached script.

The kitty template derives UI colors and ANSI neutrals (0/7/8/15) from the wallpaper. The ANSI
hues (1–6, 9–14) stay fixed at Catppuccin Mocha, because matugen's base16 output is often unreadable.

### Two loading quirks this repo works around

**(a) `dofile()`, not `require()`, for colors.** Lua's `require()` caches modules in
`package.loaded`, so a `hyprctl reload` would keep the old palette. `hyprland.lua` loads
`colors.lua` with `dofile()` (wrapped in `pcall`, falling back to `colors.fallback.lua`), which
re-reads the file on every reload. `colors` is intentionally a global so the `require()`d
`general.lua` can read it. Saving `colors.lua` doesn't trigger Hyprland's autoreload, which is
why `theme-reload.sh` runs `hyprctl reload` explicitly.

**(b) wofi uses its native `colors=` mechanism, not CSS `@import`.** wofi is launched from `/`
(Hyprland's cwd) and passes its stylesheet to GTK as in-memory data. As a result,
`@import url("colors.css")` resolves to `/colors.css` and fails silently, leaving every color
undefined. Instead:

- `wofi/config` sets `colors=colors`, which resolves relative to `~/.config/wofi`, not the cwd.
- matugen renders `~/.config/wofi/colors` as plain hex lines (0 = surface_container, 1 = on_surface, 2 = primary).
- wofi substitutes `--wofi-color<N>` (`#RRGGBB`) and `--wofi-rgb-color<N>` (`R, G, B`) macros in
  `style.css` before GTK parses it.

**Do not switch wofi back to `@import`.** waybar loads its CSS from a file path, so it does keep
`@import url("colors.css")` + `@define-color`.

### Glass family (intentional asymmetry)

| Surface | Background alpha | Set in |
|---|---|---|
| waybar | 0.75 (thin strip) | `waybar/.config/waybar/style.css`: `alpha(@surface_container, 0.75)` |
| kitty | 0.85 | `kitty/.config/kitty/kitty.conf`: `background_opacity 0.85` |
| mako | 0.85 | `matugen/.config/matugen/templates/mako.conf.template`: `set_alpha: 0.85` |
| wofi | 0.92 (large window needs a higher alpha) | `wofi/.config/wofi/style.css`: `rgba(--wofi-rgb-color0, 0.92)` |
| picker | none | Deliberately **not** glassy: its cards float over whatever is behind them, with no backdrop to compete with the previews. |

The blur comes from `general.lua`: a `blur = true, ignore_alpha = 0.5` layer rule for each of the
`waybar`, `wofi`, and `notifications` (mako) layers. The picker's layer (`hyprquickpaper`) is
deliberately left out. kitty is a regular window and is blurred by the global `decoration.blur`.

---

## Keybinds

`SUPER` is the main modifier. Everything below is from `hypr/.config/hypr/binds.lua`.

### Windows

| Keys | Action |
|---|---|
| `SUPER + Q` | Close window |
| `SUPER + SHIFT + Q` | Kill window |
| `SUPER + F` | Toggle floating |
| `SUPER + P` | Toggle split (dwindle) |
| `SUPER + ←/→/↑/↓` | Move focus |
| `SUPER + H/L/K/J` | Move focus (left/right/up/down) |
| `SUPER + LMB drag` | Move window |
| `SUPER + RMB drag` | Resize window |

### Workspaces

| Keys | Action |
|---|---|
| `SUPER + 1…9, 0` | Switch to workspace 1–10 |
| `SUPER + SHIFT + 1…9, 0` | Move window to workspace 1–10 |
| 3-finger horizontal swipe | Switch workspace (touchpad gesture, `hyprland.lua`) |

### Apps

| Keys | Action |
|---|---|
| `SUPER + Return` | kitty |
| `SUPER + D` | wofi app launcher (press again to close; fires on key release) |
| `SUPER + E` | thunar |
| `SUPER + SHIFT + E` | yazi in kitty |
| `SUPER + W` | Wallpaper picker (`quickshell -c hyprquickpaper`) |

### Session

| Keys | Action |
|---|---|
| `SUPER + N` | Lock (hyprlock, fires on key release) |
| `SUPER + M` | Log out: `hyprshutdown` if installed, otherwise exits Hyprland |

### Screenshots & recording

Screenshots go to `~/Pictures/Screenshots` (`HYPRSHOT_DIR`); recordings go to
`~/Videos/Screenrecording`. All hyprshot modes use `-z` (freeze the screen while selecting).

| Keys | Action |
|---|---|
| `SUPER + S` / `Print` | Screenshot whole output |
| `SUPER + SHIFT + S` / `SHIFT + Print` | Screenshot region |
| `SUPER + ALT + S` | Screenshot window |
| `SUPER + ALT + R` | Toggle region recording with audio (`recording-YYYY-MM-DD_HH-MM-SS.mp4`; Esc during selection cancels) |

### Media / hardware keys (also work while locked)

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume ±5% (capped at 100%), repeats |
| `XF86AudioMute` / `XF86AudioMicMute` | Toggle output / mic mute |
| `XF86MonBrightnessUp` / `Down` | Brightness ±5% |
| `XF86AudioPlay` / `Pause` / `Next` / `Prev` | playerctl play-pause / next / previous |

### Wallpaper picker (`shell.qml`)

| Keys | Action |
|---|---|
| `j` / `←` | Previous wallpaper |
| `k` / `→` | Next wallpaper |
| `a` | Page left (−7, `number_of_pictures` in `config.json`) |
| `d` | Page right (+7) |
| `Space` / `Enter` | Apply selected wallpaper and close |
| `Esc` | Quit |
| Mouse wheel | One card per notch |
| Click | Apply the clicked wallpaper |

The carousel wraps around in both directions.

### Lock

- Manual: `SUPER + N`, or run `hyprlock`.
- Automatic: hypridle locks after 600 s (10 min) idle and turns the screen off at 660 s
  (11 min). It also locks before sleep (`before_sleep_cmd = loginctl lock-session`).

---

## Customization

### Change the wallpaper
Use the picker (`SUPER + W`) or call the pipeline directly:
```sh
~/.dotfiles/quickshell/.config/quickshell/hyprquickpaper/commands.sh /path/to/wallpaper.jpg
```

### Change the scheme type
The matugen call is in
`quickshell/.config/quickshell/hyprquickpaper/commands.sh` (and in `scripts/bootstrap-theme.sh`):
```sh
matugen image "$WALLPAPER" -m dark --source-color-index 0
```
No `--type` is passed, so matugen's default scheme is used (`scheme-tonal-spot`). To try
another, add `--type <scheme>`, e.g. `scheme-fidelity`, `scheme-neutral`, `scheme-content`, or
`scheme-expressive`. Don't use `--type auto`: it's invalid in matugen 4.2.0.

### Change the glass
Edit the alphas listed in the [glass table](#glass-family-intentional-asymmetry). Notes:
- mako's alpha lives in the **matugen template**, not `mako/config`. Re-run `commands.sh`
  after changing it.
- kitty's `dynamic_background_opacity yes` lets you change opacity live, but per kitty's docs
  that setting only affects kitty instances started after it's set.
- Blur strength is global, in `general.lua` → `decoration.blur` (`size = 8`, `passes = 3`).

### Fonts and non-matugen styling
- waybar: `waybar/.config/waybar/style.css` (font, sizes, radii); modules and icons in
  `waybar/.config/waybar/config`. The ethernet icon is Nerd Font `nf-md-ethernet` (U+F0200).
- wofi: `wofi/.config/wofi/style.css`
- kitty: `kitty/.config/kitty/kitty.conf` (`font_family`)
- hyprlock: `hypr/.config/hypr/hyprlock.conf` (layout; colors come from `hyprlock-colors.conf`)
- picker: `quickshell/.config/quickshell/hyprquickpaper/config.json` (`number_of_pictures` =
  cards per screen and page-jump size; `cache_batch_size` = parallel thumbnail jobs)
- Which palette roles each app uses: the templates in `matugen/.config/matugen/templates/`

---

## Known behaviors

These are intentional. Don't "fix" them.

- **hyprlock wrong-password delay.** A wrong password takes about 2 seconds to be rejected. This
  is pam_unix's default auth-failure delay (~2s) and isn't configured by this repo
  (`/etc/pam.d/hyprlock` just includes `login`). The first unlock attempt is instant.
- **`inactive_opacity = 0.95`** in `general.lua` slightly fades unfocused windows on purpose,
  for visual hierarchy.
- **matugen 4.2.0 CLI:** there is no `-o` flag (outputs come from `config.toml`), and
  `--type auto` is invalid; use `-m dark`.
- **Hyprland 0.57 Lua API:** `/usr/share/hypr/stubs/hl.meta.lua` is the authoritative reference
  for field and function names (`.luarc.json` points the language server there). Dispatches from
  shell use the Lua form, e.g. `hyprctl dispatch 'hl.dsp.dpms("off")'` as in `hypridle.conf`.
- **cava 1.0.0-1** is the version in Arch's `extra` repo. It's installed but not themed (stock
  config, no active integration).

---

## Known issues / TODO

- **zsh / starship:** installed, not yet wired. `zsh/.zshrc` is a placeholder (empty), so
  nothing runs `starship init zsh`. `starship.toml` also uses hardcoded hex colors, not the
  matugen palette.
- **cava:** installed but not themed (stock config, no active integration).
- **hyprlock delay:** see [Known behaviors](#known-behaviors). It's pam_unix's default auth
  failure delay (~2s), not configured by this repo.
- **`float-dialogs` naming oddity:** the window rule in `hypr/.config/hypr/rules.lua` is named
  `float-dialogs`, but sets `float = false`. In practice it only applies `rounding = 15` and
  `border_size = 2` to the matched settings/file dialogs.
- **Hardcoded paths:** the picker's `config.json` uses absolute `/home/zack/...` paths, and
  `monitors.lua` targets a single `HDMI-A-1` output. Both need editing on another machine (see
  [Installation](#installation) step 4).
- **Picker file types:** the picker lists `*.png` and `*.jpg` only, while `cache.sh` also
  thumbnails `.jpeg`. `.jpeg` wallpapers won't show in the picker.

---

## Credits

- **[hyprquickpaper](https://github.com/iamsurjog/hyprquickpaper)**: upstream of the wallpaper
  picker (its `README.md` and `CONTRIBUTING.md` are kept in
  `quickshell/.config/quickshell/hyprquickpaper/`). Upstream was itself inspired by
  [ilyamiro's dots](https://github.com/ilyamiro/nixos-configuration). This repo's copy adds the
  looping carousel, `a`/`d` page-jump, open-on-current-wallpaper, matugen-driven colors, and
  sharper thumbnails.
- **[matugen](https://github.com/InioX/matugen)**: Material You palette generation.
- **[Quickshell](https://git.outfoxxed.me/quickshell/quickshell)**: QML shell toolkit the picker runs on.
- **[Catppuccin](https://github.com/catppuccin/catppuccin) Mocha**: the fallback Hyprland palette
  and kitty's fixed ANSI hues.
- **[LazyVim](https://github.com/LazyVim/LazyVim)**: the `nvim/` starter config.

---

## Future work

- Quickshell widgets to eventually replace waybar and wofi.
