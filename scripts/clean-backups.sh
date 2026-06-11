#!/usr/bin/env bash
# Remove dotfiles-managed backup files created next to known stow targets.

set -euo pipefail

SELF="$(readlink -f "$0")"
DOTFILES_DIR="$(cd "$(dirname "$SELF")/.." && pwd)"

_RST=$'\e[0m'
_GREEN=$'\e[38;2;166;227;161m'
_YELLOW=$'\e[38;2;249;226;175m'
_RED=$'\e[38;2;243;139;168m'
_MUTED=$'\e[38;2;108;112;134m'
_BLUE=$'\e[38;2;137;180;250m'
_ACCENT=$'\e[38;2;203;166;247m'

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
    --yes)     auto_yes=1 ;;
    -h|--help) usage; exit 0 ;;
    *)         usage >&2; exit 1 ;;
  esac
  shift
done

backups=()
for package_dir in "$DOTFILES_DIR"/configs/*/; do
  pkg="$(basename "$package_dir")"
  [ "$pkg" = ".stowrc" ] && continue

  while IFS= read -r -d '' rel_path; do
    rel_path="${rel_path#./}"
    target="$HOME/$rel_path"

    if [ -e "$target.backup" ] || [ -L "$target.backup" ]; then
      backups+=("$target.backup")
    fi

    backup_dir="$(dirname "$target")"
    backup_name="$(basename "$target")"
    if [ -d "$backup_dir" ]; then
      while IFS= read -r numbered_backup; do
        backups+=("$numbered_backup")
      done < <(find "$backup_dir" -maxdepth 1 \( -type f -o -type l -o -type d \) \
        -name "$backup_name.backup.*" | sort)
    fi
  done < <(cd "$package_dir" && { find . -mindepth 1 -type d -print0; find . -mindepth 1 \( -type f -o -type l \) -print0; })
done

mapfile -t backups < <(printf '%s\n' "${backups[@]}" | awk '!seen[$0]++')

if [ "${#backups[@]}" -eq 0 ]; then
  printf '%s     No dotfiles backups found.%s\n' "$_MUTED" "$_RST"
  exit 0
fi

if [ "$dry_run" -eq 1 ]; then
  printf '%s  Dry run — would remove the following backups:%s\n' "$_YELLOW" "$_RST"
  for b in "${backups[@]}"; do
    printf '%s     %s%s\n' "$_MUTED" "$b" "$_RST"
  done
  exit 0
fi

printf '\n%s  The following backups will be removed:%s\n' "$_MUTED" "$_RST"
for b in "${backups[@]}"; do
  printf '%s     %s%s\n' "$_MUTED" "$b" "$_RST"
done
echo ""

if [ "$auto_yes" -ne 1 ]; then
  printf '%s? Delete these backup files? [y/N] %s' "$_ACCENT" "$_RST"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]] || { printf '%s     Aborted.%s\n' "$_MUTED" "$_RST"; exit 0; }
fi

count=0
for backup in "${backups[@]}"; do
  rm -rf -- "$backup"
  count=$((count + 1))
done

printf '\n%s  ✓  Removed %d backup(s)%s\n' "$_GREEN" "$count" "$_RST"
echo ""
