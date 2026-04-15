#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/mise.sh"

ensure_mise_tool "ruby@latest"
echo "Ruby installed via mise"
