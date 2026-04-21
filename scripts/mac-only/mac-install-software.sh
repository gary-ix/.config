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

install_formula() {
  local formula_name="$1"

  if brew list --formula "$formula_name" >/dev/null 2>&1; then
    log_info "$formula_name already installed."
    return
  fi

  log_info "Installing $formula_name..."
  brew install "$formula_name"
  log_info "$formula_name installed."
}

install_tailscale_service() {
  if brew list --cask tailscale-app >/dev/null 2>&1; then
    log_info 'Removing tailscale-app so the boot-time daemon can be used instead.'
    brew uninstall --cask tailscale-app
  fi

  install_formula tailscale

  if sudo brew services list | grep -Eq '^tailscale\s+started\b'; then
    log_info 'tailscale service already started.'
    return
  fi

  log_info 'Starting tailscale system service...'
  sudo brew services start tailscale
  log_info 'tailscale system service started.'
  log_info 'Run sudo tailscale up to authenticate this Mac if it is not already connected.'
}

install_opencode_desktop() {
  if brew list --cask opencode-desktop >/dev/null 2>&1; then
    log_info 'opencode-desktop already installed.'
    return
  fi

  if [[ -d /Applications/OpenCode.app || -d "$HOME/Applications/OpenCode.app" ]]; then
    log_info 'OpenCode.app already present; skipping Homebrew install.'
    return
  fi

  install_cask opencode-desktop
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
  run_step 'Install Karabiner-Elements' install_cask karabiner-elements
  run_step 'Install BetterDisplay' install_cask betterdisplay
  run_step 'Install Tailscale' install_tailscale_service
  run_step 'Install balenaEtcher' install_cask balenaetcher
  run_step 'Install Raycast' install_cask raycast
  run_step 'Install Visual Studio Code' install_cask visual-studio-code
  run_step 'Install VSCodium' install_cask vscodium
  run_step 'Install Codex' install_cask codex-app
  run_step 'Install OpenCode Desktop' install_opencode_desktop
  run_step 'Install Docker Desktop' install_cask docker-desktop
  run_step 'Install Google Chrome' install_cask google-chrome
  run_step 'Install Firefox' install_cask firefox
  run_step 'Install Zen Browser' install_cask zen
  run_step 'Install Discord' install_cask discord
}

main "$@"
