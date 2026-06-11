#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
source "$DOTFILES_DIR/install/pkg.sh"

if command -v gh >/dev/null 2>&1; then
  echo "gh already installed: $(gh --version | head -1)"
  exit 0
fi

case "$(detect_pkg_manager)" in
  apt)
    if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
      [ -f /usr/share/keyrings/githubcli-archive-keyring.gpg ] && sudo rm /usr/share/keyrings/githubcli-archive-keyring.gpg
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg status=none
      sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    fi
    pkg_update
    ;;
  brew)
    brew tap github/gh ;; # gh is in core, this is just for latest
esac

pkg_install gh

echo "gh installed"
