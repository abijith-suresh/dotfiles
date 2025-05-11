# Load Starship Prompt
eval "$(starship init bash)"

# Aliases
alias ll='ls -lh --color=auto'
alias la='ls -A'
alias ..='cd ..'
alias g='git'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --all'

# Use bat for better cat command
alias cat='bat'

# Use eza (eza is an alternative to ls)
alias ls='eza --icons'   # You can customize eza flags based on your preference

# Fuzzy file finding with fzf
alias f='fzf'  # Launch fzf for quick file search
alias ff='fzf --preview "bat --style=numbers --color=always --line-range :500 {}"'  # Preview files in fzf

# zoxide (advanced cd command)
alias z='zoxide'
alias zz='zoxide query'  # Quickly query your zoxide history

# >>> Environment
export EDITOR=nvim
export PAGER=less

# Fzf init
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# zoxide init
eval "$(zoxide init bash)"
