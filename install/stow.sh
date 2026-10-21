#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DOTFILES_DIR:-}" ]; then
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export DOTFILES_DIR
fi

# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/lib.sh"

STOW_PACKAGES=(
  bat
  btop
  fastfetch
  fzf
  git
  lazydocker
  lazygit
  nvim
  ripgrep
  starship
  tmux
  vim
  zellij
  zsh
)

# The one ignore policy lives in configs/ignore as POSIX ERE, matched
# unanchored against every stowed path - the same semantics Stow applies
# to its .stowrc ignore rules. .stowrc and the managed .gitignore block
# are generated from that file by scripts/sync-ignore.sh.
ignore_regex() {
  local file="$DOTFILES_DIR/configs/ignore"
  [ -f "$file" ] || die "Missing ignore policy: $file"
  grep -vE '^[[:space:]]*(#|$)' "$file"
}

package_entries() {
  local package_dir="$1"
  local combined
  combined="$(ignore_regex | paste -sd '|' -)"
  (
    cd "$package_dir"
    if [ -n "$combined" ]; then
      find . -mindepth 1 \( -type f -o -type l \) -print |
        grep -Ev "$combined" || true
    else
      find . -mindepth 1 \( -type f -o -type l \) -print
    fi
  )
}

package_target_dirs() {
  local package_dir="$1"
  (
    cd "$package_dir"
    find . -mindepth 1 -type d -print
  )
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

  if [ -d "$source" ] && [ -d "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  backup="$(next_backup_path "$target")"
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  record_config_backup "$target" "$backup"
}

backup_blocking_parent_dirs() {
  local package="$1"
  local package_dir="$DOTFILES_DIR/configs/$package"
  local rel source target

  while IFS= read -r rel; do
    rel="${rel#./}"
    source="$package_dir/$rel"
    target="$HOME/$rel"
    if [ -L "$target" ] && ! path_resolves_to_source "$target" "$source"; then
      backup_unmanaged_target "$target" "$source"
    elif [ -e "$target" ] && [ ! -d "$target" ]; then
      backup_unmanaged_target "$target" "$source"
    fi
  done < <(package_target_dirs "$package_dir")
}

backup_package_conflicts() {
  local package="$1"
  local package_dir="$DOTFILES_DIR/configs/$package"
  local rel source target

  [ -d "$package_dir" ] || die "Missing Stow package: $package"

  backup_blocking_parent_dirs "$package"

  while IFS= read -r rel; do
    rel="${rel#./}"
    source="$package_dir/$rel"
    target="$HOME/$rel"
    backup_unmanaged_target "$target" "$source"
  done < <(package_entries "$package_dir")
}

stow_package() {
  local package="$1"

  backup_package_conflicts "$package"
  (
    cd "$DOTFILES_DIR/configs"
    stow --dir "$DOTFILES_DIR/configs" --target "$HOME" --stow --no-folding "$package"
  )
}

stow_all() {
  local package
  for package in "${STOW_PACKAGES[@]}"; do
    info "stow $package"
    stow_package "$package"
  done
  verify_deployment
}

# End-state check: every tracked config file must exist in $HOME and
# resolve back into this checkout. Fails loudly instead of trusting the
# stow exit code alone.
verify_deployment() {
  local package package_dir rel source target bad=0

  for package in "${STOW_PACKAGES[@]}"; do
    package_dir="$DOTFILES_DIR/configs/$package"
    [ -d "$package_dir" ] || continue
    while IFS= read -r rel; do
      rel="${rel#./}"
      source="$package_dir/$rel"
      target="$HOME/$rel"
      if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        warn "deployment missing: ~/$rel"
        bad=1
      elif ! path_resolves_to_source "$target" "$source"; then
        warn "deployment not linked to repo: ~/$rel"
        bad=1
      fi
    done < <(package_entries "$package_dir")
  done

  [ "$bad" -eq 0 ] || die "Stow deployment verification failed"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  detect_platform
  ensure_xdg_dirs
  stow_all
  print_final_summary
fi
