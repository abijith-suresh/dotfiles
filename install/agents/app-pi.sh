#!/usr/bin/env bash
set -euo pipefail

if command -v pi >/dev/null 2>&1; then
  echo "pi already installed"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm is required to install pi"
  exit 1
fi

npm install -g @mariozechner/pi-coding-agent
