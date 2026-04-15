#!/usr/bin/env bash
# WSL profile delegates to the WSL-aware full install category

set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

bash "$install_dir/categories/install-everything.sh"
