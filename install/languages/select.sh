#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "$0")/.." && pwd)/lib/ui.sh"

base_dir="$(cd "$(dirname "$0")" && pwd)"
choices=("Node.js" "Java" "Python" "Go" "Rust" "Ruby" "PHP" "Elixir")
selected=$(ui_choose_many "Select programming languages" "${choices[@]}")

[ -z "$selected" ] && exit 0

while IFS= read -r choice; do
  case "$choice" in
    "Node.js") bash "$base_dir/app-node.sh" ;;
    Java) bash "$base_dir/app-java.sh" ;;
    Python) bash "$base_dir/app-python.sh" ;;
    Go) bash "$base_dir/app-go.sh" ;;
    Rust) bash "$base_dir/app-rust.sh" ;;
    Ruby) bash "$base_dir/app-ruby.sh" ;;
    PHP) bash "$base_dir/app-php.sh" ;;
    Elixir) bash "$base_dir/app-elixir.sh" ;;
  esac
done <<< "$selected"
