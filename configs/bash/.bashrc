# ~/.bashrc
# ============================
# Bash Configuration for Abijith
# Organized, documented, and optimized for performance & usability.
# ============================

# --- Environment Variables ---
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PAGER="less"

# --- Aliases ---
# File Management
alias ls='eza --icons --color=auto'
alias ll='eza -l --color=auto'
alias la='eza -A --color=auto'
alias mkdir='mkdir -pv'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias v='nvim'
alias :q='exit'

# Git Shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --all'
alias gco='git checkout'
alias gb='git branch'

# Tools & Enhancements
alias grep='grep --color=auto'
alias cat='bat'             # Use bat if available
alias please='sudo'

# fzf integration
alias f='fzf'
alias ff='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'

# Use zoxide for navigation
alias cd='z'

# --- Functions ---
# Make directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Update tools manually
update-env() {
  echo "Manual update for Git Bash. Consider updating tools individually."
  echo "e.g., scoop update *, or git pull for dotfiles"
}

# Reload bashrc
reload-bash() {
  source ~/.bashrc
  echo ".bashrc reloaded!"
}

# --- fzf Initialization ---
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# --- zoxide Initialization ---
eval "$(zoxide init bash)"

# --- Starship Prompt ---
eval "$(starship init bash)"
