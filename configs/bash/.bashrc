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

# >>> Environment
export EDITOR=nvim
export PAGER=less
