# ~/.config/zsh/.zshrc
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
HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000

# --- Zinit Plugin Manager ---
# https://github.com/zdharma-continuum/zinit
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"
if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"
else
  echo "Zinit not found. Please install it at $ZINIT_HOME"
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

# --- Docker Completions (via Zinit — avoids WSL vendor-completions breakage) ---
zinit snippet "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker"

# --- Initialize zoxide ---
eval "$(zoxide init zsh)"

# --- Prompt (Starship) ---
# https://starship.rs/
eval "$(starship init zsh)"

# --- fzf ---
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
[[ -f "$XDG_CONFIG_HOME/fzf/fzf.zsh" ]] && source "$XDG_CONFIG_HOME/fzf/fzf.zsh"

# --- NVM ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- Bun ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- opencode ---
export PATH="$HOME/.opencode/bin:$PATH"

# --- Source Aliases and Functions ---
source "$ZDOTDIR/.zsh_aliases"
source "$ZDOTDIR/.zsh_functions"

# --- Source Local Overrides ---
# Allows custom user additions without touching main config
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
