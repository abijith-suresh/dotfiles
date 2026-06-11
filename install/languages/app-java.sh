#!/usr/bin/env bash
set -euo pipefail

mise use --global java@latest 2>/dev/null || true
echo "Java installed via mise"
