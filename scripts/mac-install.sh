#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ensure_macos() {
  if [[ "${OSTYPE:-}" != darwin* ]]; then
    printf 'This installer only supports macOS.\n' >&2
    exit 1
  fi
}

ensure_not_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    printf 'Do not run this script with sudo.\n' >&2
    printf 'Run as your normal user so Homebrew can request sudo when needed.\n' >&2
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
    printf 'Homebrew already installed.\n'
    return
  fi

  printf 'Installing Homebrew...\n'
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew

  if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew install completed, but brew was not found in PATH.\n' >&2
    printf 'Run one of these and retry:\n' >&2
    printf '  eval "$(/opt/homebrew/bin/brew shellenv)"\n' >&2
    printf '  eval "$(/usr/local/bin/brew shellenv)"\n' >&2
    exit 1
  fi
}

ensure_github_cli() {
  if command -v gh >/dev/null 2>&1; then
    printf 'GitHub CLI already installed.\n'
    return
  fi

  printf 'Installing GitHub CLI with Homebrew...\n'
  brew install gh
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
    printf 'nvm already installed.\n'
    return
  fi

  printf 'Installing nvm...\n'
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  load_nvm

  if ! command -v nvm >/dev/null 2>&1; then
    printf 'nvm install completed, but nvm is not available in this shell.\n' >&2
    printf 'Open a new terminal and run: nvm install --lts\n' >&2
    exit 1
  fi
}

ensure_node_and_npm() {
  ensure_nvm

  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    printf 'Node.js and npm already installed.\n'
    return
  fi

  printf 'Installing Node.js LTS with nvm...\n'
  nvm install --lts
  nvm alias default 'lts/*'
  nvm use --lts
}

ensure_macos
ensure_not_root
ensure_homebrew
ensure_github_cli
ensure_node_and_npm

printf 'mac install complete\n'
