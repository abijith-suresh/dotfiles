#!/usr/bin/env bash
# Install all supported coding agents

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

bash "$install_dir/agents/all.sh"
