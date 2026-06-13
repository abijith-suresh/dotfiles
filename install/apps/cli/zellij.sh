#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: package manager where available; upstream Linux binary fallback.
# https://zellij.dev/documentation/installation.html
if command -v zellij >/dev/null 2>&1; then
  info "zellij already installed: $(zellij --version)"
  exit 0
fi

case "$PKG_MANAGER" in
  pacman | brew)
    pkg_install zellij
    ;;
  *)
    arch="$(uname -m)"
    case "$arch" in
      x86_64 | amd64) asset="zellij-x86_64-unknown-linux-musl.tar.gz" ;;
      arm64 | aarch64) asset="zellij-aarch64-unknown-linux-musl.tar.gz" ;;
      *) die "Unsupported zellij architecture: $arch" ;;
    esac
    install_binary_from_tarball \
      "https://github.com/zellij-org/zellij/releases/latest/download/$asset" \
      zellij
    ;;
esac
