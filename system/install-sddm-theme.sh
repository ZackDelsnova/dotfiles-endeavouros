#!/usr/bin/env bash
# install-sddm-theme.sh — install the qylock Star Rail SDDM theme.
#
# Dry run by default. Pass --apply to actually write (uses sudo).
# Never enables/disables services, never installs packages, never runs
# qylock's own sddm.sh. See system/README.md.

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────
QYLOCK_REPO="https://github.com/Darkkal44/qylock"
THEME_PATTERN='star.?rail|honkai|hsr'
SDDM_THEMES_DIR="/usr/share/sddm/themes"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_CONF="${SDDM_CONF_DIR}/10-theme.conf"
HYPR_SESSION="/usr/share/wayland-sessions/hyprland.desktop"
DEPS=(
  qt6-declarative qt6-5compat qt6-svg qt6-multimedia qt6-multimedia-ffmpeg
  gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_FONT="${SCRIPT_DIR}/sddm/font/font.ttf"
TS="$(date +%s)"

# ── args ──────────────────────────────────────────────────────────────
APPLY=false
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=true ;;
    -h|--help)
      echo "Usage: bash $(basename "$0") [--apply]"
      echo "  (no flag)  dry run: preflight + detection, print WOULD-do actions"
      echo "  --apply    perform the install (sudo)"
      exit 0 ;;
    *) echo "Unknown argument: $arg (try --help)" >&2; exit 1 ;;
  esac
done

SUDO=""
if $APPLY && [[ $EUID -ne 0 ]]; then SUDO="sudo"; fi

# ── helpers ───────────────────────────────────────────────────────────
ACTIONS=()
WARNINGS=()

info() { printf '  %s\n' "$*"; }
ok()   { printf '  [ok]   %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*" >&2; WARNINGS+=("$*"); }
die()  { printf '\n  [FAIL] %s\n' "$*" >&2; exit 1; }
hdr()  { printf '\n== %s ==\n' "$*"; }

# run CMD...  — execute (as root) under --apply, otherwise just report.
run() {
  local pretty
  pretty="$(printf '%q ' "$@")"; pretty="${pretty% }"
  if $APPLY; then
    info "RUN:   $pretty"
    ${SUDO:+$SUDO} "$@"
    ACTIONS+=("did:   $pretty")
  else
    info "WOULD: $pretty"
    ACTIONS+=("would: $pretty")
  fi
}

# write_root_file PATH CONTENT  — write CONTENT to a root-owned file.
write_root_file() {
  local path="$1" content="$2"
  if $APPLY; then
    info "RUN:   write ${path}"
    printf '%s' "$content" | ${SUDO:+$SUDO} tee "$path" >/dev/null
    ACTIONS+=("did:   write ${path}")
  else
    info "WOULD: write ${path} with:"
    printf '%s' "$content" | sed 's/^/           | /'
    ACTIONS+=("would: write ${path}")
  fi
}

WORKDIR=""
cleanup() { [[ -n "$WORKDIR" && -d "$WORKDIR" ]] && rm -rf -- "$WORKDIR"; }
trap cleanup EXIT

# ── banner ────────────────────────────────────────────────────────────
if $APPLY; then
  echo "install-sddm-theme: APPLY mode — changes WILL be made (sudo)."
else
  echo "install-sddm-theme: DRY RUN — no system changes. Re-run with --apply."
fi

# ── preflight ─────────────────────────────────────────────────────────
hdr "Preflight"

# a) sddm installed
if pacman -Q sddm >/dev/null 2>&1; then
  ok "sddm installed ($(pacman -Q sddm))"
else
  die "sddm is not installed. Install it yourself (pacman -S sddm), then re-run."
fi

# b) active display manager — report only, never change
dm_link="/etc/systemd/system/display-manager.service"
if [[ -L "$dm_link" ]]; then
  active_dm="$(basename "$(readlink -f "$dm_link")" .service)"
else
  active_dm="none"
fi
case "$active_dm" in
  gdm)  ok "active DM: gdm (switch to sddm manually afterwards — see README)" ;;
  sddm) ok "active DM: sddm" ;;
  *)    warn "active DM is '${active_dm}' (expected gdm or sddm). Not changing it." ;;
esac

# c) qylock dependencies (pacman -T also honours 'provides')
missing_deps="$(pacman -T "${DEPS[@]}" || true)"
if [[ -n "$missing_deps" ]]; then
  die "missing qylock dependencies:
$(printf '         - %s\n' $missing_deps)
       Install them yourself, then re-run."
fi
ok "all ${#DEPS[@]} qylock dependencies installed"

# d) DIN Next font — warning only, theme falls back to a generic font
din_match="$(fc-match "DIN Next" 2>/dev/null || true)"
if grep -q "DIN" <<<"$din_match"; then
  ok "DIN Next resolves: ${din_match}"
elif [[ -f "$LOCAL_FONT" ]]; then
  warn "fc-match 'DIN Next' -> '${din_match}', but ${LOCAL_FONT} exists and will be copied into the theme."
else
  warn "DIN Next not found (fc-match -> '${din_match}'). Theme will use a fallback font. See README."
fi

# e) Hyprland session
if [[ -f "$HYPR_SESSION" ]]; then
  ok "Hyprland session present: ${HYPR_SESSION}"
else
  warn "${HYPR_SESSION} not found — SDDM won't list Hyprland."
fi

# tools needed for the (read-only) fetch
command -v git >/dev/null 2>&1 || die "git not found."

# ── fetch qylock (read-only, runs in dry run too) ─────────────────────
hdr "Fetch qylock"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/qylock.XXXXXX")"
CLONE="${WORKDIR}/qylock"
info "git clone --depth=1 ${QYLOCK_REPO} ${CLONE}"
git clone --quiet --depth=1 "$QYLOCK_REPO" "$CLONE" \
  || die "git clone failed (network?)."
ok "cloned ($(git -C "$CLONE" rev-parse --short HEAD))"

# ── detect the Star Rail theme ────────────────────────────────────────
hdr "Detect theme"
[[ -d "${CLONE}/themes" ]] || die "qylock has no themes/ dir. Top level contains:
$(ls -1 "$CLONE" | sed 's/^/         - /')
       Layout changed — use qylock's own sddm.sh (see README)."

mapfile -t all_themes < <(find "${CLONE}/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
mapfile -t matches < <(printf '%s\n' "${all_themes[@]}" | grep -iE "$THEME_PATTERN" || true)

if [[ ${#matches[@]} -ne 1 ]]; then
  die "expected exactly 1 theme matching /${THEME_PATTERN}/i, found ${#matches[@]}:
$(printf '         - %s\n' "${matches[@]:-(none)}")
       All themes in qylock/themes/:
$(printf '         - %s\n' "${all_themes[@]}")
       Not guessing. Edit THEME_PATTERN in this script or pick manually."
fi

THEME_NAME="${matches[0]}"
THEME_SRC="${CLONE}/themes/${THEME_NAME}"
THEME_DST="${SDDM_THEMES_DIR}/${THEME_NAME}"
ok "detected theme: ${THEME_NAME}"
[[ -f "${THEME_SRC}/metadata.desktop" ]] \
  || warn "${THEME_NAME}/metadata.desktop missing — SDDM may not recognise the theme."

# ── install ───────────────────────────────────────────────────────────
hdr "Install"

# theme dir (back up existing install first so cp -a doesn't nest/merge)
if [[ -e "$THEME_DST" ]]; then
  run mv -- "$THEME_DST" "${THEME_DST}.bak.${TS}"
fi
run cp -a -- "$THEME_SRC" "$THEME_DST"
run chown -R root:root -- "$THEME_DST"

# optional local font
if [[ -f "$LOCAL_FONT" ]]; then
  run install -Dm644 -- "$LOCAL_FONT" "${THEME_DST}/font/font.ttf"
else
  info "no ${LOCAL_FONT} — skipping font copy"
fi

# drop-in config
run install -d -m755 -- "$SDDM_CONF_DIR"
if [[ -e "$SDDM_CONF" ]]; then
  run cp -a -- "$SDDM_CONF" "${SDDM_CONF}.bak.${TS}"
fi
write_root_file "$SDDM_CONF" "[Theme]
Current=${THEME_NAME}
"

# ── summary ───────────────────────────────────────────────────────────
hdr "Summary"
info "theme:  ${THEME_NAME}"
info "target: ${THEME_DST}"
info "config: ${SDDM_CONF}"
for a in "${ACTIONS[@]}"; do info "$a"; done
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo
  info "warnings:"
  for w in "${WARNINGS[@]}"; do info "  - $w"; done
fi
echo
if $APPLY; then
  info "Done. Preview: sddm-greeter-qt6 --test-mode --theme ${THEME_DST}"
  info "DM switch (GDM -> SDDM) is MANUAL — see system/README.md."
else
  info "Dry run complete. Re-run with --apply to install."
fi
