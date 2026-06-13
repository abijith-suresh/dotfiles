#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package-manager tmux plus TPM runtime plugin manager.
pkg_install tmux

tpm_dir="$HOME/.tmux/plugins/tpm"
if [ -d "$tpm_dir" ]; then
  info "TPM already installed"
else
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins" "$tpm_dir/bin/install_plugins" >/dev/null 2>&1 || true
