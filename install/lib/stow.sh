#!/usr/bin/env bash
# Stow helpers

package_entries() {
  local package_dir="$1"

  (
    cd "$package_dir"
    {
      find . -mindepth 1 -type d -print0
      find . -mindepth 1 \( -type f -o -type l \) -print0
    }
  )
}

backup_path_for_target() {
  local target="$1"
  local backup_base="${target}.backup"
  local backup="$backup_base"
  local suffix=1

  while [ -e "$backup" ] || [ -L "$backup" ]; do
    backup="${backup_base}.${suffix}"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$backup"
}

backup_unmanaged_target() {
  local target="$1"
  local backup
  backup="$(backup_path_for_target "$target")"

  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  printf "  ↺ Backed up unmanaged target: %s -> %s\n" "$target" "$backup"
}

path_matches_source() {
  local target="$1"
  local source="$2"
  local resolved_target resolved_source

  resolved_target="$(readlink -f "$target" 2>/dev/null || true)"
  resolved_source="$(readlink -f "$source" 2>/dev/null || true)"

  [ -n "$resolved_target" ] && [ -n "$resolved_source" ] && [ "$resolved_target" = "$resolved_source" ]
}

prepare_stow_package() {
  local dotfiles_dir="$1"
  local pkg="$2"
  local package_dir="$dotfiles_dir/configs/$pkg"

  [ -d "$package_dir" ] || return 0

  while IFS= read -r -d '' rel_path; do
    rel_path="${rel_path#./}"

    local source="$package_dir/$rel_path"
    local target="$HOME/$rel_path"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
      continue
    fi

    if path_matches_source "$target" "$source"; then
      continue
    fi

    if [ -d "$source" ]; then
      if [ -d "$target" ] && [ ! -L "$target" ]; then
        continue
      fi

      backup_unmanaged_target "$target"
      continue
    fi

    if [ -d "$target" ] && [ ! -L "$target" ]; then
      printf "  ! Manual resolution needed for %s: expected file target but found directory: %s\n" "$pkg" "$target"
      continue
    fi

    backup_unmanaged_target "$target"
  done < <(package_entries "$package_dir")
}

prepare_stow_packages() {
  local dotfiles_dir="$1"
  shift
  local packages=("$@")

  if [ "${#packages[@]}" -eq 0 ]; then
    return 0
  fi

  local pkg
  for pkg in "${packages[@]}"; do
    prepare_stow_package "$dotfiles_dir" "$pkg"
  done
}

list_target_paths() {
  local dotfiles_dir="$1"
  shift
  local packages=("$@")

  local pkg
  for pkg in "${packages[@]}"; do
    local package_dir="$dotfiles_dir/configs/$pkg"
    [ -d "$package_dir" ] || continue

    while IFS= read -r -d '' rel_path; do
      rel_path="${rel_path#./}"
      printf '%s\0' "$HOME/$rel_path"
    done < <(package_entries "$package_dir")
  done
}

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
