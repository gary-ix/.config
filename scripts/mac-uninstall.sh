#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

log_section() {
  printf '\n==> %s\n' "$1"
}

log_info() {
  printf ' - %s\n' "$1"
}

main() {
  log_section 'Validating uninstall context'
  log_info "Using repo root: $ROOT_DIR"

  log_section 'Uninstall tasks'
  log_info 'No uninstall actions are configured yet.'

  log_section 'Done'
  log_info 'mac uninstall complete'
}

main "$@"
