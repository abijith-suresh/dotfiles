# ~/.config/zsh/.zshrc
# ============================
# Zsh Configuration for Abijith
# Organized, documented, and optimized for performance & usability.
# ============================

# A home rc may source this file again. Stop that loop while loading.
[[ ${_DOTFILES_ZSHRC_LOADING:-} == 1 ]] && return
typeset -g _DOTFILES_ZSHRC_LOADING=1

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
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
HISTFILE="${XDG_STATE_HOME}/zsh/history"
HISTSIZE=10000
SAVEHIST=10000

# --- Completions ---
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# --- Plugins ---
ZSH_PLUGIN_DIR="${XDG_DATA_HOME}/zsh/plugins"
if [[ -t 0 && -t 1 && -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# --- Initialize zoxide ---
if command -v zoxide &>/dev/null; then
  zoxide_init="$(zoxide init zsh 2>/dev/null)" && eval "$zoxide_init"
  unset zoxide_init
fi

# --- Prompt (Starship) ---
# https://starship.rs/
if command -v starship &>/dev/null; then
  starship_init="$(starship init zsh 2>/dev/null)" && eval "$starship_init"
  unset starship_init
fi

# --- mise (language/runtime version manager) ---
# Replaces NVM, SDKMAN, and other version managers
# https://mise.jdx.dev/
if command -v mise &>/dev/null && mise hook-env -s zsh >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# --- fzf ---
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
if [[ -t 0 && -t 1 ]] && command -v fzf &>/dev/null && [[ -f "$XDG_CONFIG_HOME/fzf/fzf.zsh" ]]; then
  source "$XDG_CONFIG_HOME/fzf/fzf.zsh"
fi

# --- opencode ---
export PATH="$HOME/.opencode/bin:$PATH"

# --- Source Aliases and Functions ---
source "$ZDOTDIR/.zsh_aliases"
for f in "$ZDOTDIR"/functions/*.zsh(N); do
  source "$f"
done

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Third-party installers often append to ~/.zshrc. Read an existing regular
# file while keeping it out of Stow and avoiding same-file or recursive reads.
if [[ -f "$HOME/.zshrc" && -r "$HOME/.zshrc" && ! -L "$HOME/.zshrc" &&
      ! "$HOME/.zshrc" -ef "$ZDOTDIR/.zshrc" ]]; then
  source "$HOME/.zshrc"
fi

# zsh-syntax-highlighting must be sourced at the end of .zshrc.
if [[ -t 0 && -t 1 && -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Local customizations (gitignored)
if [[ -r "$ZDOTDIR/.zshrc.local" ]]; then
  source "$ZDOTDIR/.zshrc.local"
fi

unset _DOTFILES_ZSHRC_LOADING
