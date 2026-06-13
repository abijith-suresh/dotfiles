#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package-manager Vim plus Catppuccin Vim package.
pkg_install vim

catppuccin_dir="$HOME/.vim/pack/vendor/start/catppuccin"
if [ -d "$catppuccin_dir" ]; then
  info "catppuccin/vim already installed"
else
  mkdir -p "$(dirname "$catppuccin_dir")"
  git clone https://github.com/catppuccin/vim.git "$catppuccin_dir"
fi
