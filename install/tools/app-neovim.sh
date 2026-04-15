#!/usr/bin/env bash
# Install vim fallback theme dependencies

set -euo pipefail

if [ -d "$HOME/.vim/pack/vendor/start/catppuccin" ]; then
  echo "catppuccin/vim already installed"
  exit 0
fi

mkdir -p "$HOME/.vim/pack/vendor/start"
git clone https://github.com/catppuccin/vim.git "$HOME/.vim/pack/vendor/start/catppuccin"

echo "catppuccin/vim installed"
