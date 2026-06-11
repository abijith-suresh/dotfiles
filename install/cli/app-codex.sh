#!/usr/bin/env bash
set -euo pipefail

if command -v codex &>/dev/null; then
  echo "codex already installed"
  exit 0
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/lib"
mise use --global node@lts 2>/dev/null || true
mise exec node@lts -- npm install -g --prefix "$HOME/.local" "@openai/codex"
echo "codex installed"
