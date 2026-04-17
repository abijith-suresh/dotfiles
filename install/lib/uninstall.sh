#!/usr/bin/env bash
# Shared helpers for safe, repo-focused uninstall flows.

set -euo pipefail

install_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$install_lib_dir/../.." && pwd)"

# shellcheck disable=SC1091
source "$install_lib_dir/ui.sh"
# shellcheck disable=SC1091
source "$install_lib_dir/stow.sh"

stow_remove() {
  local package="$1"

  if [ ! -d "$repo_dir/configs/$package" ]; then
    ui_warn "Missing stow package: $package"
    return 0
  fi

  if ! command -v stow >/dev/null 2>&1; then
    ui_warn "stow not found — could not remove package: $package"
    return 0
  fi

  (
    cd "$repo_dir/configs"
    stow -D "$package" 2>/dev/null || true
  )
  ui_ok "Removed stow package: $package"
}

remove_bin() {
  local binary_name="$1"
  local target="$HOME/.local/bin/$binary_name"

  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -f "$target"
    ui_ok "Removed binary: $target"
  else
    ui_info "Binary not present: $target"
  fi
}

remove_path() {
  local target="$1"

  if [ -e "$target" ] || [ -L "$target" ]; then
    rm -rf "$target"
    ui_ok "Removed path: $target"
  else
    ui_info "Path not present: $target"
  fi
}

remove_config_dir() {
  local target="$1"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    ui_info "Config path not present: $target"
    return 0
  fi

  if ui_confirm "Remove config path $target?"; then
    rm -rf "$target"
    ui_ok "Removed config path: $target"
  else
    ui_warn "Skipped config path: $target"
  fi
}
