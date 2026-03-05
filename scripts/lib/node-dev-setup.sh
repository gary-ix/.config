#!/usr/bin/env bash

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

node_dev_setup() {
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
