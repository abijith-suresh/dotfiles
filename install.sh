#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/lib.sh"
# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/manifest.bash"

[ "$#" -eq 0 ] || die "install.sh takes no arguments"

detect_platform
path_prepend_local_bin

section "Detected platform"
ok "$PLATFORM using $PKG_MANAGER"

section "Bootstrapping"
run_required_script "base packages" "$DOTFILES_DIR/install/bootstrap/$PKG_MANAGER.sh"
ensure_xdg_dirs
ok "XDG directories"

declare -A PHASE_LABEL=(
  [foundation]="Foundation"
  [cli]="CLI and TUI apps"
  [agents]="Agent CLIs"
  [languages]="Languages and editor tooling"
)

current_phase=""
for app in "${APP_ORDER[@]}"; do
  phase="${APP_PHASE[$app]}"
  [ "$phase" = "post-stow" ] && continue
  if [ "$phase" != "$current_phase" ]; then
    current_phase="$phase"
    section "${PHASE_LABEL[$phase]:-$phase}"
  fi
  run_app "$app"
done

section "Configuration"
# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/stow.sh"
stow_all

for app in "${APP_ORDER[@]}"; do
  [ "${APP_PHASE[$app]}" = "post-stow" ] || continue
  run_app "$app"
done

verify_all
print_final_summary
