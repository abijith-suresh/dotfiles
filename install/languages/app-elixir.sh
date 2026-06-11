#!/usr/bin/env bash
set -euo pipefail

mise use --global elixir@latest 2>/dev/null || true
echo "Elixir installed via mise"
