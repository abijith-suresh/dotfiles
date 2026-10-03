#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export DOTFILES_DIR
fi

# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/lib.sh"

STOW_PACKAGES=(
  antigravity
  bat
  btop
  claude
  codex
  copilot
  fastfetch
  fzf
  git
  lazydocker
  lazygit
  nvim
  opencode
  pi
  ripgrep
  starship
  tmux
  vim
  zellij
  zsh
)

package_entries() {
  local package_dir="$1"
  (
    cd "$package_dir"
    find . -mindepth 1 \
      \( -path './.git' -o -path './.git/*' \) -prune -o \
      \( -name '.DS_Store' -o -name '.gitignore' -o -name '.zcompdump*' -o -name '.zsh_history' \) -prune -o \
      \( -name '*.zwc' -o -name '*.zwc.old' -o -name '*.local' -o -name '*.backup' -o -name '*.backup.*' -o -name 'auth.json' \) -prune -o \
      \( -name 'sessions' -o -name 'logs' -o -name 'statsig' -o -name 'cache' \) -prune -o \
      \( -name 'node_modules' \) -prune -o \
      \( -type f -o -type l \) -print
  )
}

package_target_dirs() {
  local package_dir="$1"
  (
    cd "$package_dir"
    find . -mindepth 1 -type d -print
  )
}

is_stow_link_for_source() {
  local target="$1"
  local source="$2"

  [ -L "$target" ] || return 1
  [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]
}

path_resolves_to_source() {
  local target="$1"
  local source="$2"

  [ -e "$target" ] || [ -L "$target" ] || return 1
  [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]
}

next_backup_path() {
  local target="$1"
  local backup="$target.backup"

  if [ ! -e "$backup" ] && [ ! -L "$backup" ]; then
    printf '%s\n' "$backup"
    return
  fi

  local stamp candidate index
  stamp="$(date '+%Y%m%d-%H%M%S')"
  candidate="$backup.$stamp"
  if [ ! -e "$candidate" ] && [ ! -L "$candidate" ]; then
    printf '%s\n' "$candidate"
    return
  fi

  index=1
  while :; do
    candidate="$backup.$stamp.$index"
    if [ ! -e "$candidate" ] && [ ! -L "$candidate" ]; then
      printf '%s\n' "$candidate"
      return
    fi
    index=$((index + 1))
  done
}

backup_unmanaged_target() {
  local target="$1"
  local source="$2"
  local backup

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  if path_resolves_to_source "$target" "$source"; then
    return
  fi

  backup="$(next_backup_path "$target")"
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  record_config_backup "$target" "$backup"
}

backup_entry_conflict() {
  local target="$1"
  local source="$2"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  if path_resolves_to_source "$target" "$source"; then
    return
  fi

  if [ -d "$source" ] && [ -d "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  backup_unmanaged_target "$target" "$source"
}

backup_blocking_parent_dirs() {
  local package="$1"
  local keep="${2:-}"
  local package_dir="$DOTFILES_DIR/configs/$package"
  local rel source target

  while IFS= read -r rel; do
    rel="${rel#./}"
    source="$package_dir/$rel"
    target="$HOME/$rel"
    # Never move a parent containing settings we promised to preserve.
    if [[ -n "$keep" && "$keep" == "$rel/"* ]] &&
      { [ -L "$target" ] || { [ -e "$target" ] && [ ! -d "$target" ]; }; }; then
      die "Keeping existing ~/$keep; cannot stow through $target. Resolve this parent conflict manually."
    fi
    if [ -L "$target" ] && ! path_resolves_to_source "$target" "$source"; then
      backup_unmanaged_target "$target" "$source"
    elif [ -e "$target" ] && [ ! -d "$target" ]; then
      backup_unmanaged_target "$target" "$source"
    fi
  done < <(package_target_dirs "$package_dir")
}

backup_package_conflicts() {
  local package="$1"
  local keep="${2:-}"
  local package_dir="$DOTFILES_DIR/configs/$package"
  local rel source target

  [ -d "$package_dir" ] || die "Missing Stow package: $package"

  backup_blocking_parent_dirs "$package" "$keep"

  while IFS= read -r rel; do
    rel="${rel#./}"
    [ "$rel" != "$keep" ] || continue
    source="$package_dir/$rel"
    target="$HOME/$rel"
    backup_entry_conflict "$target" "$source"
  done < <(package_entries "$package_dir")
}

stow_package() {
  local package="$1"
  local settings="" keep="" pattern
  local stow_options=(--stow --no-folding)

  # Both CLIs can replace their settings symlink with an owned file. Keep
  # existing settings active, including trust and other state written by them.
  case "$package" in
    codex) settings=".codex/config.toml" ;;
    pi) settings=".pi/agent/settings.json" ;;
  esac
  if [ -n "$settings" ] && { [ -e "$HOME/$settings" ] || [ -L "$HOME/$settings" ]; } &&
    ! path_resolves_to_source "$HOME/$settings" "$DOTFILES_DIR/configs/$package/$settings"; then
    keep="$settings"
    pattern="${settings##*/}"
    pattern="${pattern//./\\.}"
    stow_options+=("--ignore=(^|/)$pattern\$")
    info "Keeping existing ~/$settings"
  fi

  backup_package_conflicts "$package" "$keep"
  (
    cd "$DOTFILES_DIR/configs"
    stow --dir "$DOTFILES_DIR/configs" --target "$HOME" "${stow_options[@]}" "$package"
  )
}

stow_all() {
  local package
  for package in "${STOW_PACKAGES[@]}"; do
    info "stow $package"
    stow_package "$package"
  done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  detect_platform
  ensure_xdg_dirs
  stow_all
  print_final_summary
fi
