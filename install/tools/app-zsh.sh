#!/usr/bin/env bash
# Install zsh, stow config, set it as default shell, and install Zinit

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

apt_install_if_missing zsh
manage_stow_packages "$dotfiles_dir" zsh

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
