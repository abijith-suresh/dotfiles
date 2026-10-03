#!/usr/bin/env bash
# Seeds config that the owning tool rewrites at runtime.
#
# Stow deploys config as symlinks into this repository. That is wrong for a file
# the owning CLI persists its own state into: the writes land in the working
# tree, and the live file can silently diverge from the tracked copy. Two cases
# are confirmed:
#
#   pi     persists lastChangelogVersion, defaultProvider, defaultModel and
#          theme into ~/.pi/agent/settings.json
#   codex  rewrites ~/.codex/config.toml wholesale, replacing the Stow symlink
#          with a regular file so the tracked copy stops matching the live one
#
# Those files are tracked as *.template, excluded from Stow in
# configs/.stowrc, and copied into place once. Afterwards the tool owns the live
# file and nothing it writes can reach the repository.
#
# Without --refresh-runtime an existing live file is never overwritten. Templates
# change when this repository changes them; pass --refresh-runtime to install.sh
# to replace a live file from its template.

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export DOTFILES_DIR
fi

# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/stow.sh"

# <template relative to DOTFILES_DIR>|<live path relative to $HOME>
RUNTIME_CONFIGS=(
  "configs/pi/.pi/agent/settings.json.template|.pi/agent/settings.json"
  "configs/codex/.codex/config.toml.template|.codex/config.toml"
)

# True when the path is a symlink resolving inside this repository, i.e. a link
# left behind by Stow. A dangling link still resolves here, because the template
# rename removes the source file while leaving the parent directory in place.
runtime_link_points_into_dotfiles() {
  local target="$1"
  local resolved

  [ -L "$target" ] || return 1
  resolved="$(readlink -f "$target" 2>/dev/null)" || return 1

  case "$resolved" in
    "$DOTFILES_DIR"/*) return 0 ;;
    *) return 1 ;;
  esac
}

seed_runtime_config() {
  local refresh="${REFRESH_RUNTIME:-false}"
  local entry template target relative backup

  for entry in "${RUNTIME_CONFIGS[@]}"; do
    template="$DOTFILES_DIR/${entry%%|*}"
    relative="${entry##*|}"
    target="$HOME/$relative"

    if [ ! -f "$template" ]; then
      warn "missing runtime template: ${entry%%|*}"
      continue
    fi

    mkdir -p "$(dirname "$target")"

    if [ "$refresh" = "true" ] && { [ -e "$target" ] || [ -L "$target" ]; }; then
      backup="$(next_backup_path "$target")"
      mv -- "$target" "$backup"
      record_config_backup "$target" "$backup"
      info "refreshed ~/$relative (previous copy: $(basename "$backup"))"
    elif runtime_link_points_into_dotfiles "$target"; then
      # A Stow symlink from the previous layout. Its content was the tracked
      # file, so replacing it with a copy of the template loses nothing.
      rm -f -- "$target"
      info "replaced Stow symlink at ~/$relative with an owned copy"
    elif [ -e "$target" ]; then
      # Owned by the tool already. Never clobber local state.
      continue
    fi

    install -m 600 "$template" "$target"
    ok "seeded ~/$relative"
  done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  seed_runtime_config
fi
