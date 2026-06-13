#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package-manager bat; create bat symlink if distro exposes batcat.
pkg_install bat

if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
