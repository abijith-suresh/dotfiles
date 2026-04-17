#!/usr/bin/env bash
# Remove dotfiles-managed backup files created next to known stow targets.

set -euo pipefail

SELF="$(readlink -f "$0")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"

# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/ui.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/install/lib/stow.sh"

usage() {
  cat <<'EOF'
Usage: clean-backups.sh [--dry-run] [--yes]

Delete .backup files that sit next to known dotfiles-managed targets.
EOF
}

dry_run=0
auto_yes=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --yes)
      auto_yes=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
  shift
done

packages=()
for package_dir in "$DOTFILES_DIR"/configs/*; do
  [ -d "$package_dir" ] || continue
  packages+=("$(basename "$package_dir")")
done

backups=()
while IFS= read -r -d '' target; do
  if [ -e "$target.backup" ] || [ -L "$target.backup" ]; then
    backups+=("$target.backup")
  fi

  backup_dir="$(dirname "$target")"
  backup_name="$(basename "$target")"
  if [ -d "$backup_dir" ]; then
    while IFS= read -r numbered_backup; do
      backups+=("$numbered_backup")
    done < <(find "$backup_dir" -maxdepth 1 \( -type f -o -type l -o -type d \) -name "$backup_name.backup.*" | sort)
  fi
done < <(list_target_paths "$DOTFILES_DIR" "${packages[@]}")

if [ "${#backups[@]}" -eq 0 ]; then
  echo "No dotfiles backups found."
  exit 0
fi

mapfile -t backups < <(printf '%s\n' "${backups[@]}" | awk '!seen[$0]++')

if [ "$dry_run" -eq 1 ]; then
  echo "Would remove the following backups:"
  printf '  %s\n' "${backups[@]}"
  exit 0
fi

if [ "$auto_yes" -ne 1 ]; then
  echo "The following backups will be removed:"
  printf '  %s\n' "${backups[@]}"
  echo ""
  if ! ui_confirm "Delete these backup files?"; then
    echo "Aborted."
    exit 0
  fi
fi

count=0
for backup in "${backups[@]}"; do
  rm -rf -- "$backup"
  count=$((count + 1))
done

echo "Removed $count backup(s)."
