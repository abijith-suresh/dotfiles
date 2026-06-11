#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

pkg_install zsh
cd "$DOTFILES_DIR/configs" && stow --restow zsh

zsh_path="$(command -v zsh || true)"
if [ -z "$zsh_path" ]; then
  echo "zsh not found. Install it first."
  exit 1
fi

current_shell="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$current_shell" != "$zsh_path" ]; then
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
