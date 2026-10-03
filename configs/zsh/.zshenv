# zsh reads this first, including in non-interactive shells.
export ZDOTDIR="$HOME/.config/zsh"

if [ -r "$ZDOTDIR/.zshenv" ]; then
  source "$ZDOTDIR/.zshenv"
fi
