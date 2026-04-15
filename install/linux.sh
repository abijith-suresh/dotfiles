#!/usr/bin/env bash
# Compatibility wrapper for old Linux installer entrypoint

set -euo pipefail

base_dir="$(cd "$(dirname "$0")" && pwd)"

bash "$base_dir/bootstrap/linux-apt.sh"
