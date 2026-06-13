#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: upstream GitHub release for Ubuntu/Debian/Fedora; package manager for Arch/Homebrew.
# https://github.com/jesseduffield/lazygit
if command -v lazygit >/dev/null 2>&1; then
  info "lazygit already installed: $(lazygit --version | head -1)"
  exit 0
fi

case "$PKG_MANAGER" in
  pacman|brew)
    pkg_install lazygit
    ;;
  *)
    arch="$(uname -m)"
    case "$arch" in
      x86_64|amd64) asset_arch="x86_64" ;;
      arm64|aarch64) asset_arch="arm64" ;;
      *) die "Unsupported lazygit architecture: $arch" ;;
    esac
    tag="$(github_latest_tag jesseduffield/lazygit)"
    version="${tag#v}"
    install_binary_from_tarball \
      "https://github.com/jesseduffield/lazygit/releases/download/${tag}/lazygit_${version}_Linux_${asset_arch}.tar.gz" \
      lazygit
    ;;
esac
