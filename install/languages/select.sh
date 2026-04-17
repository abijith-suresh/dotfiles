#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
base_dir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/ui.sh"

choices=("Node.js" "Bun" "Java" "Python" "Go" "Rust")

normalize_language() {
  case "$1" in
    node|nodejs|"node.js") echo "Node.js" ;;
    bun) echo "Bun" ;;
    java) echo "Java" ;;
    python|py) echo "Python" ;;
    go|golang) echo "Go" ;;
    rust) echo "Rust" ;;
    list|--list) echo "__LIST__" ;;
    *) return 1 ;;
  esac
}

run_language() {
  local choice="$1"
  local label="$2"

  case "$choice" in
    "Node.js") run_named_script "$label" "$base_dir/app-node.sh" ;;
    "Bun") run_named_script "$label" "$base_dir/app-bun.sh" ;;
    Java) run_named_script "$label" "$base_dir/app-java.sh" ;;
    Python) run_named_script "$label" "$base_dir/app-python.sh" ;;
    Go) run_named_script "$label" "$base_dir/app-go.sh" ;;
    Rust) run_named_script "$label" "$base_dir/app-rust.sh" ;;
  esac
}

selected=()
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    normalized="$(normalize_language "$arg")" || {
      echo "Unknown language: $arg" >&2
      echo "Available: node bun java python go rust" >&2
      exit 1
    }

    if [ "$normalized" = "__LIST__" ]; then
      printf '%s\n' "${choices[@]}"
      exit 0
    fi

    selected+=("$normalized")
  done
else
  mapfile -t selected < <(ui_choose_many "Select programming languages" "${choices[@]}" | sed '/^$/d')
fi

if [ "${#selected[@]}" -eq 0 ]; then
  info "No languages selected."
  exit 0
fi

mapfile -t selected < <(printf '%s\n' "${selected[@]}" | awk '!seen[$0]++')

total="${#selected[@]}"
index=0

step "Installing programming languages"
for choice in "${selected[@]}"; do
  index=$((index + 1))
  run_language "$choice" "[$index/$total] Installing $choice"
done
