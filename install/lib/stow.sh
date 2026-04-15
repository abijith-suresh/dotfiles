#!/usr/bin/env bash
# Stow helpers

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
      stow --restow "$pkg"
      printf "  ✓ Stowed %s\n" "$pkg"
    else
      printf "  ! Missing stow package: %s\n" "$pkg"
    fi
  done
}
