#!/usr/bin/env bash

# Run a command suppressing stdout and stderr.
# Usage: if silent command -v brew; then ...
silent() {
  "$@" >/dev/null 2>&1
}

# Check if a command exists in PATH.
# Usage: if has_command brew; then ...
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# Check if a Homebrew cask is installed.
# Usage: if brew_has_cask tailscale-app; then ...
brew_has_cask() {
  brew list --cask "$1" >/dev/null 2>&1
}

# Check if a Homebrew formula is installed.
# Usage: if brew_has_formula tailscale; then ...
brew_has_formula() {
  brew list --formula "$1" >/dev/null 2>&1
}
