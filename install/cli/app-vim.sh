#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

pkg_install vim
cd "$DOTFILES_DIR/configs" && stow --restow vim

if [ -d "$HOME/.vim/pack/vendor/start/catppuccin" ]; then
  echo "catppuccin/vim already installed"
  exit 0
fi

mkdir -p "$HOME/.vim/pack/vendor/start"
git clone https://github.com/catppuccin/vim.git "$HOME/.vim/pack/vendor/start/catppuccin"

echo "catppuccin/vim installed"
