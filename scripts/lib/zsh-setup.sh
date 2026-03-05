#!/usr/bin/env bash

zsh_setup() {
  local source="$ROOT_DIR/.zshrc"
  local target="$HOME/.zshrc"

  if [[ ! -f "$source" ]]; then
    log_error "Missing repo zshrc: $source"
    exit 1
  fi

  ln -sfn "$source" "$target"
  log_info "Linked $target -> $source"
}
