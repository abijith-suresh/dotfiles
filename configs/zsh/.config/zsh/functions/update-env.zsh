# Environment update helpers

update-env() {
  echo "Updating Zinit plugins..."
  zinit self-update && zinit update --all

  echo "Updating Starship..."
  if command -v starship &>/dev/null; then
    starship upgrade
  fi
}
