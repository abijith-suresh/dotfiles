#!/usr/bin/env bash
# Ubuntu/Debian native Linux profile

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

bash "$install_dir/categories/install-everything.sh"
