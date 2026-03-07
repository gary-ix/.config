#!/usr/bin/env bash

run_privileged() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

zsh_setup() {
  local home_dir="${HOME:-}"
  local zshrc_source="$ROOT_DIR/.zshrc"
  local oh_my_zsh_dir="$home_dir/.oh-my-zsh"
  local plugin_dir="$oh_my_zsh_dir/custom/plugins"
  local theme_dir="$oh_my_zsh_dir/custom/themes"
  local theme_source_dark="$ROOT_DIR/custom-themes/output/oh-my-zsh/gtheme-dark.zsh-theme"
  local theme_source_light="$ROOT_DIR/custom-themes/output/oh-my-zsh/gtheme-light.zsh-theme"
  local zsh_path

  if [[ -z "$home_dir" ]]; then
    log_error 'HOME is not set; cannot configure zsh.'
    exit 1
  fi

  if ! command -v zsh >/dev/null 2>&1; then
    log_info 'Installing zsh with Homebrew...'
    brew install zsh
  else
    log_info 'zsh already installed.'
  fi

  if ! command -v git >/dev/null 2>&1; then
    log_info 'Installing git with Homebrew...'
    brew install git

    if ! command -v git >/dev/null 2>&1; then
      log_error 'git is required for zsh setup but is not installed.'
      exit 1
    fi
  fi

  if [[ ! -d "$oh_my_zsh_dir" ]]; then
    log_info 'Cloning oh-my-zsh...'
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$oh_my_zsh_dir"
  elif [[ ! -s "$oh_my_zsh_dir/oh-my-zsh.sh" ]]; then
    local temp_dir
    temp_dir="$(mktemp -d)"
    log_info 'Repairing incomplete oh-my-zsh install...'
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$temp_dir/oh-my-zsh"
    cp -R "$temp_dir/oh-my-zsh/." "$oh_my_zsh_dir/"
    rm -rf "$temp_dir"
  else
    log_info 'oh-my-zsh already installed.'
  fi

  mkdir -p "$plugin_dir"

  if [[ ! -d "$plugin_dir/zsh-autosuggestions" ]]; then
    log_info 'Installing plugin zsh-autosuggestions...'
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir/zsh-autosuggestions"
  else
    log_info 'Plugin zsh-autosuggestions already installed.'
  fi

  if [[ ! -d "$plugin_dir/zsh-syntax-highlighting" ]]; then
    log_info 'Installing plugin zsh-syntax-highlighting...'
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir/zsh-syntax-highlighting"
  else
    log_info 'Plugin zsh-syntax-highlighting already installed.'
  fi

  if [[ ! -f "$theme_source_dark" || ! -f "$theme_source_light" ]]; then
    log_error "Theme sources not found in repo. Expected: $theme_source_dark and $theme_source_light"
    exit 1
  fi

  mkdir -p "$theme_dir"
  cp "$theme_source_dark" "$theme_dir/gtheme-dark.zsh-theme"
  cp "$theme_source_light" "$theme_dir/gtheme-light.zsh-theme"
  log_info 'Installed custom zsh themes.'

  if [[ ! -f "$zshrc_source" ]]; then
    log_error "Missing repo zshrc: $zshrc_source"
    exit 1
  fi

  ln -sfn "$zshrc_source" "$home_dir/.zshrc"
  log_info "Linked $home_dir/.zshrc -> $zshrc_source"

  zsh_path="$(command -v zsh)"
  if [[ -f /etc/shells ]] && ! /usr/bin/grep -qxF "$zsh_path" /etc/shells; then
    if run_privileged /bin/sh -c "printf '%s\n' '$zsh_path' >> /etc/shells"; then
      log_info "Added $zsh_path to /etc/shells"
    else
      log_info "Could not update /etc/shells automatically. Add this line manually: $zsh_path"
    fi
  fi

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    if chsh -s "$zsh_path" >/dev/null 2>&1; then
      log_info "Set default shell to $zsh_path"
    else
      log_info "Could not set default shell automatically. Run: chsh -s \"$zsh_path\""
    fi
  fi
}
