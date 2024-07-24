# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Update PATH
export PATH="$HOME/.local/bin:/opt/nvim-linux64/bin:$PATH"

# Zsh theme
ZSH_THEME=""

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
  web-search
  copyfile
  nvm
  npm
  zoxide
  zsh-bat
  zsh-eza
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User configuration
eval "$(starship init zsh)"

# Aliases 
alias cd='z'
alias c='clear'
