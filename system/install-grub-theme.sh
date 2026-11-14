#!/usr/bin/env bash
# install-grub-theme.sh — install the StarRailGrubThemes "Acheron" GRUB theme.
#
# Dry run by default. Pass --apply to actually write (uses sudo).
# Never installs packages. GRUB themes are only visible at boot — reboot.
# See system/README.md.
#
# If more than one asset/dir matches, narrow it with an env override, e.g.:
#   ACHERON_MATCH='acheron.*en' bash install-grub-theme.sh

set -euo pipefail

# ── config ────────────────────────────────────────────────────────────
GH_REPO="voidlhf/StarRailGrubThemes"
API_URL="https://api.github.com/repos/${GH_REPO}/releases/latest"
CLONE_URL="https://github.com/${GH_REPO}"
MATCH="${ACHERON_MATCH:-acheron}"          # case-insensitive ERE
THEME_DST="/usr/share/grub/themes/Acheron"
THEME_TXT="${THEME_DST}/theme.txt"
DEFAULT_GRUB="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"
THEME_LINE="GRUB_THEME=\"${THEME_TXT}\""
TS="$(date +%s)"

# ── args ──────────────────────────────────────────────────────────────
APPLY=false
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=true ;;
    -h|--help)
      echo "Usage: bash $(basename "$0") [--apply]"
      echo "  (no flag)  dry run: preflight + fetch, show /etc/default/grub diff"
      echo "  --apply    install theme, edit /etc/default/grub, run grub-mkconfig (sudo)"
      echo "  env ACHERON_MATCH=<regex>  narrow asset/dir match (default: acheron)"
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

WORKDIR=""
cleanup() { [[ -n "$WORKDIR" && -d "$WORKDIR" ]] && rm -rf -- "$WORKDIR"; }
trap cleanup EXIT

# ── banner ────────────────────────────────────────────────────────────
if $APPLY; then
  echo "install-grub-theme: APPLY mode — changes WILL be made (sudo)."
else
  echo "install-grub-theme: DRY RUN — no system changes. Re-run with --apply."
fi

# ── preflight ─────────────────────────────────────────────────────────
hdr "Preflight"

# a) grub installed
if pacman -Q grub >/dev/null 2>&1; then
  ok "grub installed ($(pacman -Q grub))"
else
  die "grub is not installed."
fi

# b) GRUB is the active bootloader
[[ -f "$GRUB_CFG" ]] || die "${GRUB_CFG} not found — this system does not appear to boot with GRUB (not GRUB). Aborting."
ok "${GRUB_CFG} exists"

# c) /etc/default/grub present and readable (needed to build the diff)
[[ -f "$DEFAULT_GRUB" ]] || die "${DEFAULT_GRUB} not found."
[[ -r "$DEFAULT_GRUB" ]] || die "${DEFAULT_GRUB} is not readable by $(id -un)."
[[ -d "$(dirname "$DEFAULT_GRUB")" ]] || die "$(dirname "$DEFAULT_GRUB") missing."
ok "${DEFAULT_GRUB} present and readable"

# graphical terminal required for themes
if grep -qE '^[[:space:]]*GRUB_TERMINAL_OUTPUT=["]?console' "$DEFAULT_GRUB"; then
  warn "GRUB_TERMINAL_OUTPUT=console is set — themes will NOT display. Comment it out or set it to gfxterm."
fi

# d) tools
for tool in curl unzip; do
  command -v "$tool" >/dev/null 2>&1 || die "${tool} not found."
done
ok "curl + unzip available"
HAVE_JQ=false
if command -v jq >/dev/null 2>&1; then HAVE_JQ=true; ok "jq available (used for API parsing)"; fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/starrail-grub.XXXXXX")"

# ── fetch (read-only, runs in dry run too) ────────────────────────────
# Sets THEME_SRC to the directory containing theme.txt, or returns 1.
THEME_SRC=""

fetch_release() {
  hdr "Fetch: GitHub release API"
  local api_json="${WORKDIR}/release.json"
  info "GET ${API_URL}"
  if ! curl -fsSL -H 'Accept: application/vnd.github+json' -o "$api_json" "$API_URL"; then
    warn "GitHub API request failed (rate limit / network?)."
    return 1
  fi

  local -a names urls
  if $HAVE_JQ; then
    mapfile -t names < <(jq -r --arg re "$MATCH" \
      '.assets[]? | select(.name | test($re; "i")) | .name' "$api_json")
    mapfile -t urls  < <(jq -r --arg re "$MATCH" \
      '.assets[]? | select(.name | test($re; "i")) | .browser_download_url' "$api_json")
  else
    mapfile -t urls < <(grep -o '"browser_download_url": *"[^"]*"' "$api_json" \
      | sed 's/.*"\(http[^"]*\)"$/\1/' | grep -iE "/[^/]*(${MATCH})[^/]*$" || true)
    names=()
    for u in "${urls[@]}"; do names+=("$(basename "$u")"); done
  fi

  if [[ ${#urls[@]} -eq 0 ]]; then
    local tag; tag="$($HAVE_JQ && jq -r '.tag_name // "?"' "$api_json" || echo "?")"
    warn "release ${tag}: no asset matching /${MATCH}/i."
    return 1
  fi
  if [[ ${#urls[@]} -gt 1 ]]; then
    warn "release has ${#urls[@]} assets matching /${MATCH}/i:"
    printf '         - %s\n' "${names[@]}" >&2
    warn "ambiguous — set ACHERON_MATCH to pick one. Trying git fallback."
    return 1
  fi

  local name="${names[0]}" url="${urls[0]}"
  ok "matched asset: ${name}"
  local archive="${WORKDIR}/${name}" extract="${WORKDIR}/release"
  mkdir -p "$extract"
  info "download ${url}"
  curl -fsSL -o "$archive" "$url" || { warn "asset download failed."; return 1; }
  case "$name" in
    *.zip)              unzip -q "$archive" -d "$extract" ;;
    *.tar.gz|*.tgz|*.tar.xz|*.tar.zst|*.tar) tar -xf "$archive" -C "$extract" ;;
    *) warn "unknown archive type: ${name}"; return 1 ;;
  esac

  local -a txts
  mapfile -t txts < <(find "$extract" -type f -name theme.txt)
  if [[ ${#txts[@]} -ne 1 ]]; then
    warn "asset contains ${#txts[@]} theme.txt files (expected 1):"
    printf '         - %s\n' "${txts[@]#"$extract"/}" >&2
    return 1
  fi
  THEME_SRC="$(dirname "${txts[0]}")"
  ok "theme dir in asset: ${THEME_SRC#"$extract"/}"
}

fetch_git() {
  hdr "Fetch: git fallback"
  command -v git >/dev/null 2>&1 || die "git not found (needed for fallback)."
  local clone="${WORKDIR}/StarRailGrubThemes"
  info "git clone --depth=1 ${CLONE_URL} ${clone}"
  git clone --quiet --depth=1 "$CLONE_URL" "$clone" || die "git clone failed (network?)."
  ok "cloned ($(git -C "$clone" rev-parse --short HEAD))"

  local -a txts
  mapfile -t txts < <(find "$clone" -type f -name theme.txt -not -path '*/.git/*' \
    | grep -iE "$MATCH" | sort || true)
  if [[ ${#txts[@]} -ne 1 ]]; then
    die "expected exactly 1 theme.txt under a path matching /${MATCH}/i, found ${#txts[@]}:
$(printf '         - %s\n' "${txts[@]#"$clone"/}")
       Not guessing. Re-run with ACHERON_MATCH='<narrower regex>'."
  fi
  THEME_SRC="$(dirname "${txts[0]}")"
  ok "Acheron found at: ${THEME_SRC#"$clone"/}"
}

fetch_release || fetch_git
[[ -n "$THEME_SRC" && -f "${THEME_SRC}/theme.txt" ]] || die "no theme source resolved."

# ── build proposed /etc/default/grub ──────────────────────────────────
hdr "/etc/default/grub"
PROPOSED="${WORKDIR}/grub.proposed"
cp -- "$DEFAULT_GRUB" "$PROPOSED"

if grep -qE '^[[:space:]]*GRUB_THEME=' "$PROPOSED"; then
  info "active GRUB_THEME= line found — replacing"
  sed -i -E "s|^[[:space:]]*GRUB_THEME=.*|${THEME_LINE}|" "$PROPOSED"
elif grep -qE '^[[:space:]]*#[[:space:]]*GRUB_THEME=' "$PROPOSED"; then
  info "commented GRUB_THEME= line found — replacing (uncommenting)"
  sed -i -E "0,/^[[:space:]]*#[[:space:]]*GRUB_THEME=.*/s||${THEME_LINE}|" "$PROPOSED"
else
  info "no GRUB_THEME= line — appending"
  printf '\n%s\n' "$THEME_LINE" >> "$PROPOSED"
fi

if diff -q "$DEFAULT_GRUB" "$PROPOSED" >/dev/null; then
  ok "${DEFAULT_GRUB} already up to date"
  GRUB_CHANGED=false
else
  info "proposed change:"
  diff -u --label "$DEFAULT_GRUB" --label "${DEFAULT_GRUB} (new)" \
    "$DEFAULT_GRUB" "$PROPOSED" | sed 's/^/    /' || true
  GRUB_CHANGED=true
fi

# ── install ───────────────────────────────────────────────────────────
hdr "Install"

if [[ -e "$THEME_DST" ]]; then
  run mv -- "$THEME_DST" "${THEME_DST}.bak.${TS}"
fi
run install -d -m755 -- "$(dirname "$THEME_DST")"
run cp -a -- "$THEME_SRC" "$THEME_DST"
run chown -R root:root -- "$THEME_DST"

if $GRUB_CHANGED; then
  run cp -a -- "$DEFAULT_GRUB" "${DEFAULT_GRUB}.bak.${TS}"
  run install -m644 -o root -g root -- "$PROPOSED" "$DEFAULT_GRUB"
fi

run grub-mkconfig -o "$GRUB_CFG"

# ── summary ───────────────────────────────────────────────────────────
hdr "Summary"
info "theme:  ${THEME_DST}"
info "config: ${THEME_LINE}"
for a in "${ACTIONS[@]}"; do info "$a"; done
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo
  info "warnings:"
  for w in "${WARNINGS[@]}"; do info "  - $w"; done
fi
echo
if $APPLY; then
  info "Done. REBOOT to see the theme — GRUB themes are only visible at boot."
  info "Rollback: see system/README.md (backups use suffix .bak.${TS})."
else
  info "Dry run complete. Re-run with --apply to install."
  info "After --apply you must REBOOT to see the theme."
fi
