#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOME_DIR="${HOME:-}"

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

if [[ -z "$HOME_DIR" ]]; then
  log_error 'HOME is not set'
  exit 1
fi

ZSHRC_SOURCE="$ROOT_DIR/.zshrc"
OH_MY_ZSH_DIR="$HOME_DIR/.oh-my-zsh"
PLUGIN_DIR="$OH_MY_ZSH_DIR/custom/plugins"
THEME_DIR="$OH_MY_ZSH_DIR/custom/themes"

THEME_SOURCE_DARK="$ROOT_DIR/custom-themes/output/oh-my-zsh/gtheme-dark.zsh-theme"
THEME_SOURCE_LIGHT="$ROOT_DIR/custom-themes/output/oh-my-zsh/gtheme-light.zsh-theme"

run_privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

install_pkg() {
  local pkg="$1"

  if command -v apt-get >/dev/null 2>&1; then
    run_privileged apt-get install -y "$pkg"
  elif command -v dnf >/dev/null 2>&1; then
    run_privileged dnf install -y "$pkg"
  elif command -v yum >/dev/null 2>&1; then
    run_privileged yum install -y "$pkg"
  elif command -v pacman >/dev/null 2>&1; then
    run_privileged pacman -S --noconfirm "$pkg"
  elif command -v zypper >/dev/null 2>&1; then
    run_privileged zypper --non-interactive install "$pkg"
  elif command -v apk >/dev/null 2>&1; then
    run_privileged apk add "$pkg"
  else
    log_error "No supported package manager found. Install $pkg manually."
    exit 1
  fi
}

ensure_prerequisites() {
  if ! command -v git >/dev/null 2>&1; then
    log_info 'Installing git...'
    install_pkg git
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log_info 'Installing curl...'
    install_pkg curl
  fi

  if command -v zsh >/dev/null 2>&1; then
    return
  fi

  if [[ "${OSTYPE:-}" == darwin* ]]; then
    if command -v brew >/dev/null 2>&1; then
      log_info 'Installing zsh with Homebrew...'
      brew install zsh
    else
      log_error 'Homebrew is required on macOS to auto-install zsh. Install brew and retry.'
      exit 1
    fi
  else
    if command -v apt-get >/dev/null 2>&1; then
      log_info 'Running apt-get update...'
      run_privileged apt-get update
    fi
    log_info 'Installing zsh...'
    install_pkg zsh
  fi
}

ensure_oh_my_zsh() {
  if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    log_info 'Cloning oh-my-zsh...'
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
  else
    log_info 'oh-my-zsh already installed.'
  fi
}

clone_plugin() {
  local name="$1"
  local repo="$2"
  local target="$PLUGIN_DIR/$name"

  if [[ ! -d "$target" ]]; then
    log_info "Installing plugin $name..."
    git clone "$repo" "$target"
  else
    log_info "Plugin $name already installed."
  fi
}

install_custom_plugins() {
  mkdir -p "$PLUGIN_DIR"
  clone_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
  clone_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
}

install_themes() {
  mkdir -p "$THEME_DIR"

  if [[ ! -f "$THEME_SOURCE_DARK" || ! -f "$THEME_SOURCE_LIGHT" ]]; then
    log_error "Theme sources not found in repo. Expected: $THEME_SOURCE_DARK and $THEME_SOURCE_LIGHT"
    exit 1
  fi

  cp "$THEME_SOURCE_DARK" "$THEME_DIR/gtheme-dark.zsh-theme"
  cp "$THEME_SOURCE_LIGHT" "$THEME_DIR/gtheme-light.zsh-theme"
}

link_zshrc() {
  if [[ ! -f "$ZSHRC_SOURCE" ]]; then
    log_error "Missing repo zshrc: $ZSHRC_SOURCE"
    exit 1
  fi

  ln -sfn "$ZSHRC_SOURCE" "$HOME_DIR/.zshrc"
  log_info "Linked $HOME_DIR/.zshrc -> $ZSHRC_SOURCE"
}

print_next_steps() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  log_section 'Done'
  log_info "zsh path: $zsh_path"
  log_info "linked: $HOME_DIR/.zshrc -> $ZSHRC_SOURCE"

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    log_section 'Next step'
    log_info "Set zsh as default shell: chsh -s \"$zsh_path\""
  fi

  log_section 'Next step'
  log_info 'Start a zsh session: zsh'
}

main() {
  run_step 'Ensuring prerequisites' ensure_prerequisites
  run_step 'Ensuring oh-my-zsh' ensure_oh_my_zsh
  run_step 'Ensuring custom plugins' install_custom_plugins
  run_step 'Installing themes' install_themes
  run_step 'Linking shell config' link_zshrc
  print_next_steps
}

main "$@"
