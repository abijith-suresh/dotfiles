#!/usr/bin/env bash
set -euo pipefail

install_dir="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck disable=SC1091
source "$install_dir/lib/mise.sh"

ensure_mise_tool "erlang@latest"
ensure_mise_tool "elixir@latest"
mise exec elixir@latest -- mix local.hex --force >/dev/null

echo "Elixir and Erlang installed via mise"
