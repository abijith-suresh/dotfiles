#!/usr/bin/env bash
# Install tmux and its plugin manager, then stow config

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
dotfiles_dir="$(cd "$install_dir/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/stow.sh"

apt_install_if_missing tmux
manage_stow_packages "$dotfiles_dir" tmux

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  echo "TPM already installed"
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "TPM installed"
fi

TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1 || true
