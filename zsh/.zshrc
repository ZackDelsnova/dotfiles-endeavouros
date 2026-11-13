# PATH — ensure ~/.local/bin is available (Claude, Starship, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Starship prompt
eval "$(starship init zsh)"

# Basic aliases
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'
