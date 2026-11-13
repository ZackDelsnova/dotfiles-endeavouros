# Allow # comments on the interactive command line — set first so it's active from the top
setopt INTERACTIVE_COMMENTS

# PATH — ~/bin, ~/.local/bin (Claude, Starship, etc.), and Bun's bin dir
typeset -U path
export BUN_INSTALL="$HOME/.bun"
path=("$HOME/bin" "$HOME/.local/bin" "$BUN_INSTALL/bin" $path)

# History — large, shared across sessions, no duplicate entries saved
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_SAVE_NO_DUPS INC_APPEND_HISTORY

# Directory navigation — bare dir name cds; cd pushes onto a quiet, deduped stack
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# Emacs keymap — set before plugins so their bindings land in the right keymap
bindkey -e

# 1. zsh-completions — ships no .zsh; its functions live in site-functions, must be in fpath before compinit
[[ ${fpath[(Ie)/usr/share/zsh/site-functions]} -eq 0 ]] && fpath=(/usr/share/zsh/site-functions $fpath)

# 2. compinit — builds the completion system from fpath, so it runs after fpath is final
autoload -Uz compinit && compinit

# 3. autosuggestions — wraps ZLE widgets, so it loads after compinit
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 4. history-substring-search — defines its widgets before syntax-highlighting wraps them
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# 5. syntax-highlighting — must be the last plugin so it can wrap every widget defined above
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Aliases — color for ls/grep, plus ls shortcuts
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias l='ls -lah'
alias la='ls -lAh'
alias ll='ls -lh'

# 6. Starship — very last so its precmd/zle hooks wrap the final state
eval "$(starship init zsh)"
