#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official Starship installer for latest cross-platform binary.
# https://starship.rs/guide/
if command -v starship >/dev/null 2>&1; then
  info "starship already installed: $(starship --version | head -1)"
  exit 0
fi

curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
