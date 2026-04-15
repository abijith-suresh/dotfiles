#!/usr/bin/env bash
# WSL profile: Linux base plus WSL-specific cleanup

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f /usr/share/zsh/vendor-completions/_docker ]; then
  sudo rm -f /usr/share/zsh/vendor-completions/_docker
fi
rm -f "$HOME"/.zcompdump*

bash "$install_dir/profiles/base.sh"
