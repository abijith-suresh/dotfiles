#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

bash "$install_dir/categories/coding-agents.sh"
