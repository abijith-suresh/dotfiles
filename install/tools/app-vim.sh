#!/usr/bin/env bash
# Install vim and stow its config

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

apt_install_if_missing vim
manage_stow_packages "$dotfiles_dir" vim

if [ -d "$HOME/.vim/pack/vendor/start/catppuccin" ]; then
  echo "catppuccin/vim already installed"
  exit 0
fi

mkdir -p "$HOME/.vim/pack/vendor/start"
git clone https://github.com/catppuccin/vim.git "$HOME/.vim/pack/vendor/start/catppuccin"

echo "catppuccin/vim installed"
