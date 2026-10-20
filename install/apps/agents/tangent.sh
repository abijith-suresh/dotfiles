#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1090,SC1091
source "${DOTFILES_DIR:?}/install/lib.sh"

# Pi's native installer registers the Tangent package without touching other
# settings. The tagged source is the version to install; run after Stow.
# https://pi.dev/docs/latest/packages
mise exec node@lts -- pi install git:github.com/abijith-suresh/tangent@0.0.1
