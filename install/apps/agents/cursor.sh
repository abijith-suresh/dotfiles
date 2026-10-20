#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official Cursor CLI installer, checked 2026-10-20.
# https://cursor.com/docs/cli/installation
if command -v cursor-agent >/dev/null 2>&1; then
  info "cursor cli already installed"
  exit 0
fi

case "$PKG_MANAGER" in
  brew)
    pkg_install_cask cursor-cli
    ;;
  *)
    curl -fsSL https://cursor.com/install | bash
    ;;
esac
