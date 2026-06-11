#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

pkg_install fd-find
mkdir -p "$HOME/.local/bin"
if [ ! -e "$HOME/.local/bin/fd" ]; then
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
  printf "fd symlink created in ~/.local/bin\n"
else
  printf "fd symlink already present\n"
fi
