# system/ — login and boot themes (NOT dotfiles)

This directory holds the install scripts for two system-level themes:

| Script                    | Installs                         | Target                                   |
|---------------------------|----------------------------------|------------------------------------------|
| `install-sddm-theme.sh`   | qylock **Star Rail** SDDM theme  | `/usr/share/sddm/themes/<name>/` + `/etc/sddm.conf.d/10-theme.conf` |
| `install-grub-theme.sh`   | StarRailGrubThemes **Acheron**   | `/usr/share/grub/themes/Acheron/` + `/etc/default/grub` |

These files are **not stowed**. Do not run `stow system`.

## Why not Stow?

- The targets are owned by root and live in `/etc` and `/usr/share`. Stow is meant for `$HOME`.
- SDDM's greeter runs as the `sddm` user and GRUB reads from `/boot`/`/usr`
  at boot time. Neither can follow a symlink into `/home/<user>`, because
  of permissions and because `/home` may not be mounted when GRUB reads.
- Package updates (`sddm`, `grub`) can replace or remove files in these
  directories. A symlink there would break without any warning.

So each script copies real files into place and keeps a timestamped backup
of anything it overwrites.

## Prerequisites

### SDDM script
- `sddm` (the package must be installed; it does not need to be enabled)
- qylock dependencies:
  `qt6-declarative qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg
   gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly`
- `git` (to clone qylock)
- Optional: the **DIN Next** font (see below). Without it the theme falls back
  to a generic sans font and the script prints a warning.
- `/usr/share/wayland-sessions/hyprland.desktop` (the script warns if it is missing)

### GRUB script
- `grub`, and GRUB must be the active bootloader (`/boot/grub/grub.cfg` exists)
- `/etc/default/grub`
- `curl` and `unzip`. `jq` is optional; it is used for parsing the GitHub API
  if present. `git` is needed for the fallback path.

## Usage

Each script does a **dry run by default**. A dry run does all the read-only
work (preflight checks, clone or download, theme detection) and prints
`WOULD: …` for every write, without touching the system.

```bash
cd ~/.dotfiles/system

bash install-sddm-theme.sh            # dry run: review output
bash install-sddm-theme.sh --apply    # real install (prompts for sudo)

bash install-grub-theme.sh            # dry run, shows /etc/default/grub diff
bash install-grub-theme.sh --apply    # real install + grub-mkconfig
```

Only `--apply` calls `sudo`. The scripts never install packages and never
enable or disable services.

The GRUB theme only shows at boot, so **reboot** to see it.

## GDM → SDDM transition (manual, do this LAST)

`install-sddm-theme.sh` does **not** switch display managers. After the
theme is installed and the dry and real runs look right, switch by hand:

```bash
# optional: preview the theme without logging out
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/<name>

sudo systemctl disable gdm.service
sudo systemctl enable sddm.service
# reboot (don't just start sddm while GDM's session is running)
```

To go back to GDM:

```bash
sudo systemctl disable sddm.service
sudo systemctl enable gdm.service
```

## DIN Next font (licensing)

Some qylock themes use **DIN Next**. It is a commercial font (Monotype/Linotype)
and is **not redistributable**, so it must never be committed to this repo.
`system/sddm/font/*.ttf` and `*.otf` are gitignored. Only `.gitkeep` is tracked.

You can get the font in either of two ways:
- Put your licensed copy at `~/.dotfiles/system/sddm/font/font.ttf`. The SDDM
  script copies it into `<theme>/font/font.ttf`, which is where some qylock
  versions look for it.
- Install it system-wide (for example the AUR `ttf-din-next`), so that
  `fc-match "DIN Next"` resolves to a DIN file.

The script checks `fc-match "DIN Next"` and only **warns** if the font is
missing.

## Fallback

If `install-sddm-theme.sh` fails (for example because qylock changed its repo
layout), use qylock's own installer instead:
`git clone https://github.com/Darkkal44/qylock && cd qylock && ./sddm.sh`.
Read that script first. It is less reproducible than this approach, which is
why it is not the default.

## Rollback

Before overwriting anything, both scripts make backups named `<path>.bak.<unix-epoch>`.
To read the time from an epoch, use `date -d @<epoch>`.

| Script | Backups created (only if the target existed)                      |
|--------|-------------------------------------------------------------------|
| SDDM   | `/etc/sddm.conf.d/10-theme.conf.bak.<epoch>`, `/usr/share/sddm/themes/<name>.bak.<epoch>/` |
| GRUB   | `/etc/default/grub.bak.<epoch>`, `/usr/share/grub/themes/Acheron.bak.<epoch>/` |

```bash
# SDDM: remove theme config (SDDM falls back to its default theme)
sudo rm /etc/sddm.conf.d/10-theme.conf
#   …or restore a previous one
sudo cp -a /etc/sddm.conf.d/10-theme.conf.bak.<epoch> /etc/sddm.conf.d/10-theme.conf

# GRUB: restore defaults, then REGENERATE grub.cfg (required)
sudo cp -a /etc/default/grub.bak.<epoch> /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

You can delete the theme directories under `/usr/share/{sddm,grub}/themes/`
once nothing references them.
