# Navigation helpers

mkcd() {
  mkdir -p "$1" && cd "$1"
}

reload-zsh() {
  source "$ZDOTDIR/.zshrc"
  echo ".zshrc reloaded!"
}
