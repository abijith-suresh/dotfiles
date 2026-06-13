#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: current GitHub Copilot CLI installer, not deprecated gh-copilot extension.
# https://gh.io/copilot-install
if command -v copilot >/dev/null 2>&1; then
  info "copilot already installed"
  exit 0
fi

case "$PKG_MANAGER" in
  brew)
    pkg_install copilot-cli
    ;;
  *)
    curl -fsSL https://gh.io/copilot-install | PREFIX="$HOME/.local" bash
    ;;
esac
