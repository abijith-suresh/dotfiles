#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

mkdir -p "$HOME/.local/bin"
cd "$DOTFILES_DIR/configs" && stow --restow bin
