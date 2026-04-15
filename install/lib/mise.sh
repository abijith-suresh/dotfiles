#!/usr/bin/env bash
# mise helpers for language and Node-based CLI installs

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ensure_mise() {
  if command_exists mise; then
    return 0
  fi

  local install_dir
  install_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  bash "$install_dir/tools/app-mise.sh"
}

trust_mise_global_config() {
  local global_config="${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml"

  [ -f "$global_config" ] || return 0
  mise trust "$global_config" >/dev/null 2>&1 || true
}

ensure_mise_tool() {
  local tool="$1"

  ensure_mise
  trust_mise_global_config
  mise use --global "$tool"
  trust_mise_global_config
}

ensure_local_npm_prefix() {
  ensure_dir "$HOME/.local/bin"
  ensure_dir "$HOME/.local/lib"
}

node_cli_path() {
  local bin_name="$1"
  printf '%s\n' "$HOME/.local/bin/$bin_name"
}

install_node_cli() {
  local package="$1"
  local bin_name="$2"
  local tool_spec="${3:-node@lts}"
  local target

  ensure_mise_tool "$tool_spec"
  ensure_local_npm_prefix

  target="$(node_cli_path "$bin_name")"
  if [ -x "$target" ]; then
    echo "$bin_name already installed: $target"
    return 0
  fi

  if command_exists "$bin_name"; then
    warn "$bin_name found outside ~/.local/bin at $(command -v "$bin_name"); reinstalling under ~/.local/bin"
  fi

  mise exec "$tool_spec" -- npm install -g --prefix "$HOME/.local" "$package"

  if [ ! -x "$target" ]; then
    echo "Failed to install $bin_name to $target"
    return 1
  fi

  echo "$bin_name installed: $target"
}
