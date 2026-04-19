#!/usr/bin/env bash

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
