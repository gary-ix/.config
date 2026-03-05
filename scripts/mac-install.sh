#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

log_section() {
  printf '\n==> %s\n' "$1"
}

log_info() {
  printf ' - %s\n' "$1"
}

log_error() {
  printf 'ERROR: %s\n' "$1" >&2
}

run_step() {
  local label="$1"
  shift
  log_section "$label"
  "$@"
}

ensure_macos() {
  if [[ "${OSTYPE:-}" != darwin* ]]; then
    log_error 'This installer only supports macOS.'
    exit 1
  fi
}

ensure_not_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    log_error 'Do not run this script with sudo.'
    log_error 'Run as your normal user so Homebrew can request sudo when needed.'
    exit 1
  fi
}

load_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

ensure_homebrew() {
  load_homebrew
  if command -v brew >/dev/null 2>&1; then
    log_info 'Homebrew already installed.'
    return
  fi

  log_info 'Installing Homebrew...'
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew

  if ! command -v brew >/dev/null 2>&1; then
    log_error 'Homebrew install completed, but brew was not found in PATH.'
    log_error 'Run one of these and retry:'
    log_error '  eval "$(/opt/homebrew/bin/brew shellenv)"'
    log_error '  eval "$(/usr/local/bin/brew shellenv)"'
    exit 1
  fi

  log_info 'Homebrew installed.'
}

ensure_github_cli() {
  if command -v gh >/dev/null 2>&1; then
    log_info 'GitHub CLI already installed.'
    return
  fi

  log_info 'Installing GitHub CLI with Homebrew...'
  brew install gh
  log_info 'GitHub CLI installed.'
}

load_nvm() {
  export NVM_DIR="$HOME/.nvm"

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
  fi
}

ensure_nvm() {
  load_nvm
  if command -v nvm >/dev/null 2>&1; then
    log_info 'nvm already installed.'
    return
  fi

  log_info 'Installing nvm...'
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  load_nvm

  if ! command -v nvm >/dev/null 2>&1; then
    log_error 'nvm install completed, but nvm is not available in this shell.'
    log_error 'Open a new terminal and run: nvm install --lts'
    exit 1
  fi

  log_info 'nvm installed.'
}

ensure_node_and_npm() {
  ensure_nvm

  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    log_info 'Node.js and npm already installed.'
    return
  fi

  log_info 'Installing Node.js LTS with nvm...'
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use --lts
  log_info 'Node.js and npm installed.'
}

link_repo_zshrc() {
  local source="$ROOT_DIR/.zshrc"
  local target="$HOME/.zshrc"

  if [[ ! -f "$source" ]]; then
    log_error "Missing repo zshrc: $source"
    exit 1
  fi

  ln -sfn "$source" "$target"
  log_info "Linked $target -> $source"
}

main() {
  run_step 'Validating platform' ensure_macos
  run_step 'Validating user' ensure_not_root
  run_step 'Ensuring Homebrew' ensure_homebrew
  run_step 'Ensuring GitHub CLI' ensure_github_cli
  run_step 'Ensuring Node.js and npm' ensure_node_and_npm
  run_step 'Linking shell config' link_repo_zshrc
  log_section 'Done'
  log_info 'mac install complete'
}

main "$@"
