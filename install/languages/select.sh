#!/usr/bin/env bash
set -euo pipefail

base_dir="$(cd "$(dirname "$0")" && pwd)"

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

  echo "  $label"
  case "$choice" in
    "Node.js") bash "$base_dir/app-node.sh" ;;
    "Bun") bash "$base_dir/app-bun.sh" ;;
    Java) bash "$base_dir/app-java.sh" ;;
    Python) bash "$base_dir/app-python.sh" ;;
    Go) bash "$base_dir/app-go.sh" ;;
    Rust) bash "$base_dir/app-rust.sh" ;;
  esac
}

selected=()
if [ "$#" -gt 0 ]; then
  for arg in "$@"; do
    normalized="$(normalize_language "$arg")" || {
      echo "Unknown language: $arg" >&2
      echo "Available: node bun java python go rust"
      exit 1
    }

    if [ "$normalized" = "__LIST__" ]; then
      printf '%s\n' "${choices[@]}"
      exit 0
    fi

    selected+=("$normalized")
  done
else
  printf "Select programming languages (space-separated):\n"
  printf "  %s\n" "${choices[@]}"
  printf "\nLanguages: "
  read -r -a selected
fi

if [ "${#selected[@]}" -eq 0 ]; then
  echo "No languages selected."
  exit 0
fi

mapfile -t selected < <(printf '%s\n' "${selected[@]}" | awk '!seen[$0]++')

total="${#selected[@]}"
index=0

echo ""
echo "==> Installing programming languages"
for choice in "${selected[@]}"; do
  index=$((index + 1))
  run_language "$choice" "[$index/$total] Installing $choice"
done

echo ""
echo "Languages installed: ${selected[*]}"
