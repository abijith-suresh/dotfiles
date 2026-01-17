# ~/.zshrc
# ============================
# Zsh Configuration for Abijith
# Organized, documented, and optimized for performance & usability.
# ============================

# --- Environment Variables ---
export EDITOR="nvim"
export VISUAL="$EDITOR"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# --- Zsh Behavior Options ---
setopt autocd                 # Enter a directory just by typing its name
setopt interactive_comments   # Allow comments in the terminal
setopt hist_ignore_space      # Ignore commands starting with space in history
setopt hist_reduce_blanks     # Remove superfluous blanks from history
setopt share_history          # Share command history across all sessions
setopt extended_glob          # Enable extended globbing
setopt correct                # Auto-correct command names
setopt nocaseglob             # Case-insensitive globbing

# --- History Configuration ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# --- Zinit Plugin Manager ---
# https://github.com/zdharma-continuum/zinit
if [[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
else
  echo "Zinit not found. Please install it at ~/.local/share/zinit"
fi

# --- Plugins ---
# Use `light` for minimal plugin loading
# Use `wait` to defer loading after shell prompt shows

zinit light zsh-users/zsh-autosuggestions       # Suggests commands as you type
zinit light zsh-users/zsh-syntax-highlighting   # Highlights syntax errors
zinit light zsh-users/zsh-completions           # Adds more completions
zinit light djui/alias-tips                     # Reminds you of defined aliases
zinit wait lucid for \
  zdharma-continuum/fast-syntax-highlighting    # Faster highlighting

# --- Initialize zoxide ---
eval "$(zoxide init zsh)"

# --- Prompt (Starship) ---
# https://starship.rs/
eval "$(starship init zsh)"

# --- Aliases ---
alias ls='eza --color=auto'   
alias ll='eza -l --color=auto'
alias la='eza -A --color=auto'
alias grep='grep --color=auto'
alias cat='bat'  
alias mkdir='mkdir -pv'
alias please='sudo'
alias cd='z'

# Git
alias gs='git status'
alias gco='git checkout'
alias gl='git pull'
alias gp='git push'
alias ga='git add'
alias gc='git commit -m'
alias gb='git branch'

# Directory shortcut aliases
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias v='nvim'
alias :q='exit'

# --- Functions ---
# Make directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# --- Update Function ---
# Update Zinit plugins and Starship
update-env() {
  echo "Updating Zinit plugins..."
  zinit self-update && zinit update --all
  echo "Updating Starship..."
  if command -v starship &>/dev/null; then
    starship upgrade
  fi
}

# Reload the .zshrc file
reload-zsh() {
  source ~/.zshrc
  echo ".zshrc reloaded!"
}

# --- Source Local Overrides ---
# Allows custom user additions without touching main config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# --- End ---

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/abijith/.bun/_bun" ] && source "/home/abijith/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH=/home/abijith/.opencode/bin:$PATH
