#!/usr/bin/env bash
# Stow helpers

stow_restow() {
  local pkg="$1"

  stow --restow "$pkg" \
    2> >(grep -vE 'BUG in find_stowed_path\? Absolute/relative mismatch between Stow dir .*\.aws|BUG in find_stowed_path\? Absolute/relative mismatch between Stow dir .*\.azure' >&2)
}

stow_packages() {
  local dotfiles_dir="$1"
  shift
  local packages=("$@")

  if [ "${#packages[@]}" -eq 0 ]; then
    return 0
  fi

  cd "$dotfiles_dir/configs"
  for pkg in "${packages[@]}"; do
    if [ -d "$pkg" ]; then
      stow_restow "$pkg"
      printf "  ✓ Stowed %s\n" "$pkg"
    else
      printf "  ! Missing stow package: %s\n" "$pkg"
    fi
  done
}
