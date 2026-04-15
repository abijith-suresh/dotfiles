#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"

ensure_sudo_access
apt_install_if_missing php php-curl php-intl php-mbstring php-xml php-zip

echo "PHP installed via apt"
