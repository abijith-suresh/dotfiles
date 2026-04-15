#!/bin/bash
# install/terminal/app-neovim.sh
# Install catppuccin theme for vim (fallback editor)

if [ ! -d "$HOME/.vim/pack/vendor/start/catppuccin" ]; then
  echo "Installing catppuccin theme for Vim..."
  mkdir -p ~/.vim/pack/vendor/start
  git clone https://github.com/catppuccin/vim.git ~/.vim/pack/vendor/start/catppuccin
  echo "catppuccin/vim installed."
else
  echo "catppuccin/vim already installed."
fi
