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

# --- Minimal Aliases ---
# File Listing (eza)
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --git --group-directories-first'
alias la='eza -lah --icons --git --group-directories-first'
alias lt='eza --tree --icons --level=2 --long --git'

# Replacements
alias cat='bat'
alias mkdir='mkdir -pv'
alias cd='z'
alias grep='grep --color=auto'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Shortcuts
alias c='clear'
alias please='sudo'
alias :q='exit'

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias gp='git push'
alias gl='git pull'

# Tools
alias lzg='lazygit'
alias lzd='lazydocker'
alias n='nvim'

# --- Functions ---
# Open nvim with current dir if no args
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

mkcd() {
  mkdir -p "$1" && cd "$1"
}

compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

webm2mp4() {
  input_file="$1"
  output_file="${input_file%.webm}.mp4"
  ffmpeg -i "$input_file" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output_file"
}

# --- fzf Initialization ---
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# --- OpenCode ---
export PATH="$HOME/.opencode/bin:$PATH"

# --- mise (language/runtime version manager) ---
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

# --- Starship Prompt ---
eval "$(starship init bash)"

# --- zoxide Initialization ---
eval "$(zoxide init bash)"
