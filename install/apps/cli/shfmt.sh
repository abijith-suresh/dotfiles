#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package-manager shfmt where available; fallback to go install if needed.
case "$PKG_MANAGER" in
  apt|dnf|pacman|brew)
    pkg_install shfmt
    ;;
esac
