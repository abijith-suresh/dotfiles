#!/usr/bin/env bash
# Remove backup files created next to known dotfiles-managed Stow targets.

set -euo pipefail

SELF="$(readlink -f "$0")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"

# shellcheck disable=SC1090,SC1091
source "$DOTFILES_DIR/install/stow.sh"

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
    --dry-run) dry_run=1 ;;
    --yes) auto_yes=1 ;;
    -h | --help)
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

backup_patterns_for_target() {
  local target="$1"
  local backup_dir backup_name

  backup_dir="$(dirname "$target")"
  backup_name="$(basename "$target")"
  [ -d "$backup_dir" ] || return 0

  find "$backup_dir" -maxdepth 1 \( -type f -o -type l -o -type d \) \
    \( -name "$backup_name.backup" -o -name "$backup_name.backup.*" \)
}

backups=()
for pkg in "${STOW_PACKAGES[@]}"; do
  package_dir="$DOTFILES_DIR/configs/$pkg"
  [ -d "$package_dir" ] || continue

  while IFS= read -r rel_path; do
    rel_path="${rel_path#./}"
    target="$HOME/$rel_path"
    while IFS= read -r backup; do
      backups+=("$backup")
    done < <(backup_patterns_for_target "$target")
  done < <(package_entries "$package_dir")
done

if [ "${#backups[@]}" -gt 0 ]; then
  mapfile -t backups < <(printf '%s\n' "${backups[@]}" | awk 'NF && !seen[$0]++')
fi

if [ "${#backups[@]}" -eq 0 ]; then
  info "No dotfiles backups found."
  exit 0
fi

if [ "$dry_run" -eq 1 ]; then
  warn "Dry run - would remove the following backups:"
  for b in "${backups[@]}"; do
    printf '     %s\n' "$b"
  done
  exit 0
fi

printf '\nThe following backups will be removed:\n'
for b in "${backups[@]}"; do
  printf '     %s\n' "$b"
done
echo ""

if [ "$auto_yes" -ne 1 ]; then
  printf 'Delete these backup files? [y/N] '
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]] || {
    info "Aborted."
    exit 0
  }
fi

count=0
for backup in "${backups[@]}"; do
  rm -rf -- "$backup"
  count=$((count + 1))
done

printf '\nRemoved %d backup(s)\n' "$count"
echo ""
