#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: upstream GitHub release on Linux, Homebrew tap on macOS.
# https://github.com/jesseduffield/lazydocker
if command -v lazydocker >/dev/null 2>&1; then
  info "lazydocker already installed: $(lazydocker --version | head -1)"
  exit 0
fi

case "$PKG_MANAGER" in
  brew)
    brew install jesseduffield/lazydocker/lazydocker
    ;;
  *)
    arch="$(uname -m)"
    case "$arch" in
      x86_64 | amd64) asset_arch="x86_64" ;;
      arm64 | aarch64) asset_arch="arm64" ;;
      *) die "Unsupported lazydocker architecture: $arch" ;;
    esac
    tag="$(github_latest_tag jesseduffield/lazydocker)"
    version="${tag#v}"
    install_binary_from_tarball \
      "https://github.com/jesseduffield/lazydocker/releases/download/${tag}/lazydocker_${version}_Linux_${asset_arch}.tar.gz" \
      lazydocker
    ;;
esac
