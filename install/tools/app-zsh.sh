#!/usr/bin/env bash
# Set zsh as default shell and install Zinit

set -euo pipefail

zsh_path="$(command -v zsh || true)"
if [ -z "$zsh_path" ]; then
  echo "zsh not found. Install it first."
  exit 1
fi

if [ "$SHELL" != "$zsh_path" ]; then
  chsh -s "$zsh_path"
  echo "Default shell changed to zsh. Log out and back in for it to take effect."
else
  echo "zsh is already the default shell"
fi

zinit_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ -d "$zinit_dir" ]; then
  echo "Zinit already installed"
  exit 0
fi

git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_dir"

echo "Zinit installed"
