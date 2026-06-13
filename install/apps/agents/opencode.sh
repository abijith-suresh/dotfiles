#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: opencode recommended curl installer.
# https://opencode.ai/install
if command -v opencode >/dev/null 2>&1; then
  info "opencode already installed"
  exit 0
fi

case "$PKG_MANAGER" in
  pacman)
    pkg_install opencode
    ;;
  brew)
    brew install anomalyco/tap/opencode
    ;;
  *)
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
    ;;
esac
