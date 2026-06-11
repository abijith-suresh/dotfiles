#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

if command -v mise >/dev/null 2>&1; then
  echo "mise already installed: $(mise --version)"
  exit 0
fi

case "$(detect_pkg_manager)" in
  apt)
    pkg_update
    pkg_install gpg wget curl
    sudo install -dm 755 /etc/apt/keyrings
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
    pkg_update
    pkg_install mise
    ;;
  brew)
    brew install mise
    ;;
  dnf)
    pkg_install gpg wget curl
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo
    pkg_install mise
    ;;
  pacman)
    pkg_install gpg wget curl
    pkg_install mise
    ;;
esac

echo "mise installed"
