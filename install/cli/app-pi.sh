#!/usr/bin/env bash
set -euo pipefail

if command -v pi &>/dev/null; then
  echo "pi already installed"
  exit 0
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/lib"
mise use --global node@lts 2>/dev/null || true
mise exec node@lts -- npm install -g --prefix "$HOME/.local" "@earendil-works/pi-coding-agent"
echo "pi installed"
