#!/usr/bin/env bash
set -euo pipefail

if command -v gemini &>/dev/null; then
  echo "gemini already installed"
  exit 0
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/lib"
mise use --global node@lts 2>/dev/null || true
mise exec node@lts -- npm install -g --prefix "$HOME/.local" "@google/gemini-cli"
echo "gemini installed"
