#!/usr/bin/env bash
set -euo pipefail

if command -v gemini >/dev/null 2>&1; then
  echo "gemini already installed"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to install gemini"
  exit 1
fi

npm install -g @google/gemini-cli
