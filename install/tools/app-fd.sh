#!/usr/bin/env bash
# Install fd (Ubuntu package name: fd-find)

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

apt_install_if_missing fd-find
ensure_dir "$HOME/.local/bin"
if [ ! -e "$HOME/.local/bin/fd" ]; then
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
  ok "fd symlink created in ~/.local/bin"
else
  ok "fd symlink already present"
fi
