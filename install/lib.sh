#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

PLATFORM="${PLATFORM:-}"
PKG_MANAGER="${PKG_MANAGER:-}"
if ! declare -p INSTALL_FAILURES >/dev/null 2>&1; then
  INSTALL_FAILURES=()
fi
if ! declare -p CONFIG_BACKUPS >/dev/null 2>&1; then
  CONFIG_BACKUPS=()
fi
declare -ga INSTALL_FAILURES CONFIG_BACKUPS

_DF_COLOR=0
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ]; then
  _DF_COLOR=1
fi

if [ "$_DF_COLOR" -eq 1 ]; then
  _RST=$'\e[0m'
  _GREEN=$'\e[38;2;166;227;161m'
  _YELLOW=$'\e[38;2;249;226;175m'
  _RED=$'\e[38;2;243;139;168m'
  _BLUE=$'\e[38;2;137;180;250m'
  _MAUVE=$'\e[38;2;203;166;247m'
  _MUTED=$'\e[38;2;108;112;134m'
else
  _RST=""
  _GREEN=""
  _YELLOW=""
  _RED=""
  _BLUE=""
  _MAUVE=""
  _MUTED=""
fi

section() {
  printf '\n%s==>%s %s%s%s\n' "$_MAUVE" "$_RST" "$_BLUE" "$*" "$_RST"
}

info() {
  printf '%s  ->%s %s\n' "$_MUTED" "$_RST" "$*"
}

ok() {
  printf '%s  ✓%s %s\n' "$_GREEN" "$_RST" "$*"
}

warn() {
  printf '%s  !%s %s\n' "$_YELLOW" "$_RST" "$*" >&2
}

fail() {
  printf '%s  x%s %s\n' "$_RED" "$_RST" "$*" >&2
}

die() {
  fail "$*"
  exit 1
}

detect_platform() {
  if [ -n "${PLATFORM:-}" ] && [ -n "${PKG_MANAGER:-}" ]; then
    export PLATFORM PKG_MANAGER
    return
  fi

  case "$(uname -s)" in
    Darwin)
      PLATFORM="macos"
      PKG_MANAGER="brew"
      ;;
    Linux)
      [ -r /etc/os-release ] || die "Cannot detect Linux distribution: /etc/os-release is missing"
      # shellcheck disable=SC1091
      . /etc/os-release
      case "${ID:-}" in
        ubuntu)
          if grep -qi microsoft /proc/version 2>/dev/null; then
            PLATFORM="wsl-ubuntu"
          else
            PLATFORM="ubuntu"
          fi
          PKG_MANAGER="apt"
          ;;
        debian)
          PLATFORM="debian"
          PKG_MANAGER="apt"
          ;;
        fedora)
          PLATFORM="fedora"
          PKG_MANAGER="dnf"
          ;;
        arch)
          PLATFORM="arch"
          PKG_MANAGER="pacman"
          ;;
        *)
          die "Unsupported Linux distribution: ${ID:-unknown}"
          ;;
      esac
      ;;
    *)
      die "Unsupported OS: $(uname -s)"
      ;;
  esac

  export PLATFORM PKG_MANAGER
}

require_sudo() {
  if [ "$PKG_MANAGER" != "brew" ] && ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required for Linux installs"
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  warn "Homebrew is missing; installing it for macOS support"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1 || die "Homebrew installation completed but brew is not on PATH"
}

pkg_update() {
  detect_platform
  require_sudo
  case "$PKG_MANAGER" in
    apt) sudo apt-get update ;;
    dnf)
      local dnf_status=0
      sudo dnf check-update || dnf_status=$?
      if [ "$dnf_status" -ne 0 ] && [ "$dnf_status" -ne 100 ]; then
        die "dnf metadata check failed (exit $dnf_status)"
      fi
      ;;
    pacman)
      # Source policy: Arch does not support partial upgrades. Checked 2026-09-13.
      # https://wiki.archlinux.org/title/System_maintenance#Partial_upgrades_are_unsupported
      sudo pacman -Syu
      ;;
    brew)
      ensure_homebrew
      brew update
      ;;
    *) die "Unsupported package manager: $PKG_MANAGER" ;;
  esac
}

pkg_install() {
  detect_platform
  require_sudo
  if [ "$#" -eq 0 ]; then
    return
  fi

  case "$PKG_MANAGER" in
    apt) sudo apt install -y "$@" ;;
    dnf) sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --needed --noconfirm "$@" ;;
    brew)
      ensure_homebrew
      brew install "$@"
      ;;
    *) die "Unsupported package manager: $PKG_MANAGER" ;;
  esac
}

pkg_install_cask() {
  detect_platform
  if [ "$PKG_MANAGER" != "brew" ]; then
    die "Cask install requested on non-Homebrew platform"
  fi
  ensure_homebrew
  brew install --cask "$@"
}

ensure_xdg_dirs() {
  mkdir -p \
    "$HOME/.config" \
    "$HOME/.local/bin" \
    "$HOME/.local/share" \
    "$HOME/.local/share/go" \
    "$HOME/.local/share/zsh/plugins" \
    "$HOME/.local/state" \
    "$HOME/.local/state/zsh" \
    "$HOME/.cache/go/pkg/mod" \
    "$HOME/.cache/go-build" \
    "$HOME/.cache/zsh" \
    "$HOME/.cache"
}

path_prepend_local_bin() {
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

run_required_script() {
  local label="$1"
  local script="$2"
  [ -f "$script" ] || die "Missing install script: $script"
  info "$label"
  bash "$script"
  ok "$label"
}

run_tolerant_script() {
  local label="$1"
  local script="$2"
  info "$label"
  if [ ! -f "$script" ]; then
    warn "$label failed: missing install script: $script"
    INSTALL_FAILURES+=("$label")
    return 1
  fi
  if bash "$script"; then
    ok "$label"
  else
    warn "$label failed"
    INSTALL_FAILURES+=("$label")
  fi
}

# Package name for source=pkg records: an exact "$PKG_MANAGER:name" token
# wins, then a bare name, then a "*:name" fallback.
pkg_name_for() {
  local app="$1"
  local spec="${APP_PKG[$app]:-$app}"
  local default="$app"
  local exact=""
  local part
  while IFS= read -r part; do
    [ -n "$part" ] || continue
    case "$part" in
      "$PKG_MANAGER":*) exact="${part#*:}" ;;
      '*':*) default="${part#*:}" ;;
      *:*) ;;
      *) default="$part" ;;
    esac
  done < <(tr '|' '\n' <<<"$spec")
  printf '%s\n' "${exact:-$default}"
}

apply_fixlink() {
  local fixlink="${APP_FIXLINK[$1]:-}"
  [ -n "$fixlink" ] || return 0

  local distro="${fixlink%%:*}"
  local link="${fixlink#*:}"
  if ! command -v "$link" >/dev/null 2>&1 && command -v "$distro" >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$(command -v "$distro")" "$HOME/.local/bin/$link"
    info "$link symlinked to $(command -v "$distro")"
  fi
}

run_pkg_app() {
  local app="$1"
  pkg_install "$(pkg_name_for "$app")"
  apply_fixlink "$app"
}

# Script path (relative to install/) for source=script records. An explicit
# script= field wins; otherwise the phase implies the directory.
script_rel_for() {
  local app="$1"
  if [ -n "${APP_SCRIPT[$app]:-}" ]; then
    printf '%s\n' "${APP_SCRIPT[$app]}"
    return 0
  fi
  case "${APP_PHASE[$app]}" in
    foundation | cli) printf 'apps/cli/%s.sh\n' "$app" ;;
    agents | post-stow) printf 'apps/agents/%s.sh\n' "$app" ;;
    languages) printf 'languages/%s.sh\n' "$app" ;;
    *) return 1 ;;
  esac
}

run_app() {
  local app="$1"
  if [ "${APP_SOURCE[$app]:-pkg}" = "pkg" ]; then
    info "$app"
    if run_pkg_app "$app"; then
      ok "$app"
    else
      warn "$app failed"
      INSTALL_FAILURES+=("$app")
    fi
    return
  fi

  local script
  script="$DOTFILES_DIR/install/$(script_rel_for "$app")"
  if [ "${APP_MODE[$app]:-tolerant}" = "required" ]; then
    run_required_script "$app" "$script"
  else
    run_tolerant_script "$app" "$script"
  fi
}

verify_all() {
  section "Verifying installed state"
  local app snippet
  for app in "${APP_ORDER[@]}"; do
    snippet="${APP_VERIFY[$app]:-}"
    if [ "$snippet" = "none" ]; then
      continue
    fi
    if [ -z "$snippet" ]; then
      snippet="command -v '${APP_BIN[$app]:-$app}' >/dev/null 2>&1"
    fi
    if bash -c "$snippet" >/dev/null 2>&1; then
      ok "verify $app"
    else
      warn "verify $app failed"
      INSTALL_FAILURES+=("verify $app")
    fi
  done
}

github_latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/$repo/releases/latest" |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' |
    head -1
}

download_to_temp() {
  local url="$1"
  local output="$2"
  curl -fL --retry 3 --retry-delay 2 -o "$output" "$url"
}

install_binary_from_tarball() {
  local url="$1"
  local binary="$2"
  local strip_components="${3:-0}"
  local tmp
  tmp="$(mktemp -d)"
  (
    trap 'rm -rf -- "$tmp"' EXIT
    download_to_temp "$url" "$tmp/archive.tar.gz"
    tar -xzf "$tmp/archive.tar.gz" -C "$tmp" --strip-components "$strip_components"
    install -m 0755 "$tmp/$binary" "$HOME/.local/bin/$binary"
  )
}

record_config_backup() {
  CONFIG_BACKUPS+=("$1 -> $2")
}

print_final_summary() {
  section "Summary"
  ok "Platform: ${PLATFORM:-unknown} (${PKG_MANAGER:-unknown})"

  if [ "${#CONFIG_BACKUPS[@]}" -gt 0 ]; then
    warn "Configs backed up before stowing:"
    local backup
    for backup in "${CONFIG_BACKUPS[@]}"; do
      printf '     %s\n' "$backup"
    done
    ok "Repo configs were stowed in their place"
  else
    ok "No config conflicts needed backups"
  fi

  if [ "${#INSTALL_FAILURES[@]}" -gt 0 ]; then
    warn "Some non-critical installers failed:"
    local failure
    for failure in "${INSTALL_FAILURES[@]}"; do
      printf '     %s\n' "$failure"
    done
    return 1
  fi

  ok "Install completed"
}
