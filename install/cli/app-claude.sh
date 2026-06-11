#!/usr/bin/env bash
set -euo pipefail

if command -v claude &>/dev/null; then
  echo "claude already installed"
  exit 0
fi

mkdir -p "$HOME/.local/bin" "$HOME/.local/lib"
mise use --global node@lts 2>/dev/null || true
mise exec node@lts -- npm install -g --prefix "$HOME/.local" "@anthropic-ai/claude-code"
echo "claude installed"
