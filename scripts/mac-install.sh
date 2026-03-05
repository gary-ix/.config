#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

. "$LIB_DIR/logging.sh"
. "$LIB_DIR/node-dev-setup.sh"
. "$LIB_DIR/zsh-setup.sh"

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

main() {
  run_step 'Validating platform' ensure_macos
  run_step 'Validating user' ensure_not_root
  run_step 'Ensuring Homebrew' ensure_homebrew
  run_step 'Ensuring GitHub CLI' ensure_github_cli
  run_step 'Node Dev Setup' node_dev_setup
  run_step 'ZSH Setup' zsh_setup
  log_section 'Done'
  log_info 'mac install complete'
}

main "$@"
