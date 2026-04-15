#!/bin/bash
# install/terminal/required/app-gum.sh
# Install gum — TUI tool for interactive menus (needed for dotfiles CLI)

if ! command -v gum &>/dev/null; then
  echo "Installing gum..."
  sudo apt install -y gum
  echo "gum installed."
else
  echo "gum already installed."
fi
