#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

. "$LIB_DIR/logging.sh"

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

install_cask() {
  local cask_name="$1"

  if brew list --cask "$cask_name" >/dev/null 2>&1; then
    log_info "$cask_name already installed."
    return
  fi

  log_info "Installing $cask_name..."
  brew install --cask "$cask_name"
  log_info "$cask_name installed."
}

ensure_brew_available() {
  load_homebrew

  if ! command -v brew >/dev/null 2>&1; then
    log_error 'Homebrew is required to install Mac software.'
    log_error 'Run scripts/mac-install.sh first to install Homebrew.'
    exit 1
  fi
}

main() {
  run_step 'Validate Homebrew' ensure_brew_available
  run_step 'Install Ghostty' install_cask ghostty
  run_step 'Install Raycast' install_cask raycast
  run_step 'Install Google Chrome' install_cask google-chrome
  run_step 'Install Firefox' install_cask firefox
  run_step 'Install Visual Studio Code' install_cask visual-studio-code
  run_step 'Install Cursor' install_cask cursor
}

main "$@"
