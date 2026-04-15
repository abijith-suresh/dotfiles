#!/usr/bin/env bash
set -euo pipefail
sudo apt install -y php php-{curl,intl,mbstring,xml,zip} --no-install-recommends
echo "PHP installed via apt"