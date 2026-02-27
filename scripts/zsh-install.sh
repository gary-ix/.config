#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOME_DIR="${HOME:-}"

if [[ -z "$HOME_DIR" ]]; then
  printf 'HOME is not set\n' >&2
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
    printf 'No supported package manager found. Install %s manually.\n' "$pkg" >&2
    exit 1
  fi
}

ensure_prerequisites() {
  if ! command -v git >/dev/null 2>&1; then
    printf 'Installing git...\n'
    install_pkg git
  fi

  if ! command -v curl >/dev/null 2>&1; then
    printf 'Installing curl...\n'
    install_pkg curl
  fi

  if command -v zsh >/dev/null 2>&1; then
    return
  fi

  if [[ "${OSTYPE:-}" == darwin* ]]; then
    if command -v brew >/dev/null 2>&1; then
      printf 'Installing zsh with Homebrew...\n'
      brew install zsh
    else
      printf 'Homebrew is required on macOS to auto-install zsh. Install brew and retry.\n' >&2
      exit 1
    fi
  else
    if command -v apt-get >/dev/null 2>&1; then
      printf 'Running apt-get update...\n'
      run_privileged apt-get update
    fi
    printf 'Installing zsh...\n'
    install_pkg zsh
  fi
}

ensure_oh_my_zsh() {
  if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    printf 'Cloning oh-my-zsh...\n'
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
  fi
}

clone_plugin() {
  local name="$1"
  local repo="$2"
  local target="$PLUGIN_DIR/$name"

  if [[ ! -d "$target" ]]; then
    printf 'Installing plugin %s...\n' "$name"
    git clone "$repo" "$target"
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
    printf 'Theme sources not found in repo. Expected: %s and %s\n' "$THEME_SOURCE_DARK" "$THEME_SOURCE_LIGHT" >&2
    exit 1
  fi

  cp "$THEME_SOURCE_DARK" "$THEME_DIR/gtheme-dark.zsh-theme"
  cp "$THEME_SOURCE_LIGHT" "$THEME_DIR/gtheme-light.zsh-theme"
}

link_zshrc() {
  if [[ ! -f "$ZSHRC_SOURCE" ]]; then
    printf 'Missing repo zshrc: %s\n' "$ZSHRC_SOURCE" >&2
    exit 1
  fi

  ln -sfn "$ZSHRC_SOURCE" "$HOME_DIR/.zshrc"
}

print_next_steps() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  printf '\nDone.\n'
  printf 'zsh path: %s\n' "$zsh_path"
  printf 'linked: %s -> %s\n' "$HOME_DIR/.zshrc" "$ZSHRC_SOURCE"

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    printf '\nSet zsh as default shell with:\n'
    printf '  chsh -s "%s"\n' "$zsh_path"
  fi

  printf 'Start a zsh session with:\n'
  printf '  zsh\n'
}

ensure_prerequisites
ensure_oh_my_zsh
install_custom_plugins
install_themes
link_zshrc
print_next_steps
