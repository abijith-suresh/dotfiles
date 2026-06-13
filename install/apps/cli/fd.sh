#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: distro package; Debian/Ubuntu package is fd-find with fdfind binary.
case "$PKG_MANAGER" in
  apt) pkg_install fd-find ;;
  *) pkg_install fd ;;
esac

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
