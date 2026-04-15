#!/usr/bin/env bash
# Install alacritty when supported and stow its config

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/os.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

if [ "$(detect_os)" = "wsl" ]; then
  info "Skipping alacritty package install on WSL"
else
  apt_install_if_missing alacritty
fi

manage_stow_packages "$dotfiles_dir" alacritty
