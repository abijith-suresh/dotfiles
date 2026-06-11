#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

pkg_install tmux
cd "$DOTFILES_DIR/configs" && stow --restow tmux

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  echo "TPM already installed"
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "TPM installed"
fi

TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
