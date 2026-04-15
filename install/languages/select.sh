#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"
base_dir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/common.sh"
# shellcheck disable=SC1091
source "$install_dir/lib/ui.sh"

choices=("Node.js" "Java" "Python" "Go" "Rust" "Ruby" "PHP" "Elixir")
selected=$(ui_choose_many "Select programming languages" "${choices[@]}")

[ -z "$selected" ] && exit 0

step "Installing programming languages"

index=0
total=$(printf '%s\n' "$selected" | sed '/^$/d' | wc -l | tr -d ' ')
while IFS= read -r choice; do
  [ -z "$choice" ] && continue
  index=$((index + 1))

  case "$choice" in
    "Node.js") run_named_script "[$index/$total] Installing Node.js" "$base_dir/app-node.sh" ;;
    Java) run_named_script "[$index/$total] Installing Java" "$base_dir/app-java.sh" ;;
    Python) run_named_script "[$index/$total] Installing Python" "$base_dir/app-python.sh" ;;
    Go) run_named_script "[$index/$total] Installing Go" "$base_dir/app-go.sh" ;;
    Rust) run_named_script "[$index/$total] Installing Rust" "$base_dir/app-rust.sh" ;;
    Ruby) run_named_script "[$index/$total] Installing Ruby" "$base_dir/app-ruby.sh" ;;
    PHP) run_named_script "[$index/$total] Installing PHP" "$base_dir/app-php.sh" ;;
    Elixir) run_named_script "[$index/$total] Installing Elixir" "$base_dir/app-elixir.sh" ;;
  esac
done <<< "$selected"
