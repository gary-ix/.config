# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Platform detection
is_macos=false
[[ "$OSTYPE" == darwin* ]] && is_macos=true

# Theme
ZSH_THEME="gtheme-dark"

# Plugins
plugins=(
  git
  docker
  kubectl
  node
  npm
  yarn
  python
  pip
  golang
  rust
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-substring-search
  colored-man-pages
  extract
  web-search
)

if [[ "$is_macos" == true ]]; then
  plugins+=(brew macos copypath copyfile)
fi

# Oh My Zsh
if [[ -s "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt EXTENDED_HISTORY

# Key bindings for history search
if (( ${+widgets[history-substring-search-up]} )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi
bindkey '^R' history-incremental-search-backward

# Aliases
if command grep --help 2>&1 | command grep -q -- '--color'; then
  alias grep='grep --color=auto'
fi
alias cls='clear'
alias h='history'
alias reload='source ~/.zshrc'

# Env vars
if [[ "$is_macos" == true ]] && command -v security >/dev/null 2>&1; then
  token="$(security find-generic-password -s "GITHUB_TOKEN" -w 2>/dev/null || true)"
  [[ -n "$token" ]] && export GITHUB_TOKEN="$token"
elif [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null 2>&1; then
  token="$(gh auth token 2>/dev/null || true)"
  [[ -n "$token" ]] && export GITHUB_TOKEN="$token"
fi
unset token

export AWS_PROFILE=tradester-test
export AWS_REGION=us-east-1

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"
