#!/usr/bin/env bash
# Shared shell helpers for install/update scripts

set -euo pipefail

# Pull in UI helpers (colour palette, gum wrappers, status printers).
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# ── Status primitives — delegate to ui.sh ─────────────────────────────────────

step()  { ui_section "$@"; }
ok()    { ui_ok "$@"; }
warn()  { ui_warn "$@"; }
info()  { ui_info "$@"; }

# ── Directory helpers ─────────────────────────────────────────────────────────

ensure_dir() {
  [ -d "$1" ] || mkdir -p "$1"
}

ensure_sudo_access() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  ui_info "Sudo access is required for the next step."
  sudo -v
}

apt_install_if_missing() {
  local package
  for package in "$@"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
      ui_ok "$package already installed"
    else
      ui_info "Installing $package..."
      sudo apt install -y "$package"
      ui_ok "$package installed"
    fi
  done
}

repo_root() {
  local script_path
  script_path="$(readlink -f "${BASH_SOURCE[0]}")"
  cd "$(dirname "$script_path")/../.." && pwd
}

# ── Task runner ───────────────────────────────────────────────────────────────
# Wraps a command in a gum spinner while it runs.
# Spinner type is controlled by DOTFILES_SPINNER (default: moon).
# Set DOTFILES_SPINNER=globe for network-heavy operations,
#     DOTFILES_SPINNER=dot  for quick/local operations.

run_task() {
  local title="$1"
  shift
  local spinner="${DOTFILES_SPINNER:-moon}"

  if command_exists gum; then
    gum spin --spinner "$spinner" --title "$title" --show-error -- "$@"
  else
    local log_file status
    log_file="$(mktemp)"
    if "$@" >"$log_file" 2>&1; then
      rm -f "$log_file"
      return 0
    fi

    status=$?
    ui_warn "$title failed"
    cat "$log_file" >&2
    rm -f "$log_file"
    return "$status"
  fi
}

run_script() {
  local script="$1"
  shift || true

  if [ ! -f "$script" ]; then
    ui_warn "Missing script: $script"
    return 1
  fi

  bash "$script" "$@"
}

run_named_script() {
  local title="$1"
  local script="$2"
  shift 2 || true

  if [ ! -f "$script" ]; then
    ui_warn "Missing script: $script"
    return 1
  fi

  run_task "$title" bash "$script" "$@"
  ui_ok "$title"
}
