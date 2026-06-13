#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Source policy: official upstream release on Linux where distro packages lag.
# This config uses vim.pack, so Neovim 0.12+ is required.
if command -v nvim >/dev/null 2>&1; then
  version="$(nvim --version | sed -n 's/^NVIM v\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p' | head -1)"
  if [ -n "$version" ]; then
    major="${version%% *}"
    minor="${version##* }"
    if [ "$major" -gt 0 ] || [ "$minor" -ge 12 ]; then
      info "nvim already installed: $(nvim --version | head -1)"
      exit 0
    fi
  fi
fi

case "$PKG_MANAGER" in
  brew | pacman)
    pkg_install neovim
    ;;
  *)
    arch="$(uname -m)"
    case "$arch" in
      x86_64 | amd64)
        asset="nvim-linux-x86_64.tar.gz"
        extracted="nvim-linux-x86_64"
        ;;
      arm64 | aarch64)
        asset="nvim-linux-arm64.tar.gz"
        extracted="nvim-linux-arm64"
        ;;
      *) die "Unsupported neovim architecture: $arch" ;;
    esac

    tmp="$(mktemp -d)"
    download_to_temp "https://github.com/neovim/neovim/releases/latest/download/$asset" "$tmp/$asset"
    tar -xzf "$tmp/$asset" -C "$tmp"
    rm -rf "$HOME/.local/opt/nvim"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    mv "$tmp/$extracted" "$HOME/.local/opt/nvim"
    ln -sfn "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
    rm -rf "$tmp"
    ;;
esac
