#!/usr/bin/env bash
set -euo pipefail

LABEL="com.garrett.kanata"
PLIST_PATH="/Library/LaunchDaemons/${LABEL}.plist"
CFG_PATH="${KANATA_CFG_PATH:-$HOME/.config/kanata/kanata.kbd}"

require_cfg() {
  if [[ ! -f "$CFG_PATH" ]]; then
    echo "Config not found: $CFG_PATH" >&2
    exit 1
  fi
}

ensure_kanata() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS." >&2
    exit 1
  fi

  if ! command -v kanata >/dev/null 2>&1; then
    echo "Installing kanata with Homebrew..."
    brew install kanata
  fi
}

install_launchd() {
  ensure_kanata
  require_cfg

  local kanata_bin
  local tmp_plist
  kanata_bin="$(command -v kanata)"
  tmp_plist="$(mktemp)"
  trap 'rm -f "$tmp_plist"' EXIT

  cat >"$tmp_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${kanata_bin}</string>
    <string>--cfg</string>
    <string>${CFG_PATH}</string>
    <string>--no-wait</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>UserName</key>
  <string>root</string>
  <key>StandardOutPath</key>
  <string>/tmp/kanata.out.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/kanata.err.log</string>
</dict>
</plist>
EOF

  sudo launchctl bootout "system/${LABEL}" >/dev/null 2>&1 || true
  sudo cp "$tmp_plist" "$PLIST_PATH"
  sudo chown root:wheel "$PLIST_PATH"
  sudo chmod 644 "$PLIST_PATH"
  sudo launchctl bootstrap system "$PLIST_PATH"
  sudo launchctl kickstart -k "system/${LABEL}"

  echo "kanata installed as launchd service"
  echo "service: ${LABEL}"
  echo "plist: ${PLIST_PATH}"
  echo "config: ${CFG_PATH}"
}

run_foreground() {
  ensure_kanata
  require_cfg
  exec sudo "$(command -v kanata)" --cfg "$CFG_PATH"
}

uninstall_launchd() {
  sudo launchctl bootout "system/${LABEL}" >/dev/null 2>&1 || true
  sudo rm -f "$PLIST_PATH"
  echo "kanata launchd service removed"
}

usage() {
  echo "Usage: $0 {install|run|uninstall}" >&2
}

case "${1:-}" in
  install)
    install_launchd
    ;;
  run)
    run_foreground
    ;;
  uninstall)
    uninstall_launchd
    ;;
  *)
    usage
    exit 1
    ;;
esac
