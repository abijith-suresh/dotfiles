#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official Claude Code native installer, checked 2026-06-12.
# https://claude.ai/install.sh
if command -v claude >/dev/null 2>&1; then
  info "claude already installed"
  exit 0
fi

case "$PKG_MANAGER" in
  brew)
    pkg_install_cask claude-code
    ;;
  *)
    curl -fsSL https://claude.ai/install.sh | bash
    ;;
esac
