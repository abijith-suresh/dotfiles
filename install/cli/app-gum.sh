#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

if command -v gum >/dev/null 2>&1; then
  echo "gum already installed: $(gum --version)"
  exit 0
fi

case "$(detect_pkg_manager)" in
  apt)
    cd /tmp
    GUM_VERSION="0.17.0"
    wget -qO gum.deb "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_amd64.deb"
    sudo apt-get install -y --allow-downgrades ./gum.deb
    rm gum.deb
    ;;
  brew)
    brew install gum
    ;;
  dnf)
    GUM_VERSION="0.17.0"
    wget -qO /tmp/gum.rpm "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_x86_64.rpm"
    sudo dnf install -y /tmp/gum.rpm
    rm /tmp/gum.rpm
    ;;
  pacman)
    pkg_install gum
    ;;
esac

echo "gum installed: v${GUM_VERSION:-latest}"
