#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official GitHub CLI repos on apt, package manager elsewhere.
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
if command -v gh >/dev/null 2>&1; then
  info "gh already installed: $(gh --version | head -1)"
  exit 0
fi

case "$PKG_MANAGER" in
  apt)
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg |
      sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
      sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    pkg_update
    pkg_install gh
    ;;
  *)
    pkg_install gh
    ;;
esac
