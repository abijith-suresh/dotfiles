#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: upstream installer for Ubuntu/Debian, package manager elsewhere.
# https://github.com/ajeetdsouza/zoxide
if command -v zoxide >/dev/null 2>&1; then
  info "zoxide already installed: $(zoxide --version)"
  exit 0
fi

case "$PKG_MANAGER" in
  apt)
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    ;;
  *)
    pkg_install zoxide
    ;;
esac
