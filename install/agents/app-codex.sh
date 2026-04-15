#!/usr/bin/env bash
set -euo pipefail

if command -v codex >/dev/null 2>&1; then
  echo "codex already installed"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to install codex"
  exit 1
fi

npm install -g @openai/codex
