# Environment update helpers

update-env() {
  local plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ -d "$plugin_dir/$plugin/.git" ]; then
      echo "Updating $plugin..."
      git -C "$plugin_dir/$plugin" pull --ff-only
    else
      echo "Skipping $plugin; not installed at $plugin_dir/$plugin"
    fi
  done

  echo "Updating Starship..."
  if command -v starship &>/dev/null; then
    starship upgrade
  fi
}
