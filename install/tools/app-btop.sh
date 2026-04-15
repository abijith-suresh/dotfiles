#!/usr/bin/env bash
# Install btop

set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

apt_install_if_missing btop
