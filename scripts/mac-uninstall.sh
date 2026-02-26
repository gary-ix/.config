#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KANATA_SCRIPT="$ROOT_DIR/kanata/kanata.sh"

if [[ ! -x "$KANATA_SCRIPT" ]]; then
  echo "Kanata controller not executable: $KANATA_SCRIPT" >&2
  exit 1
fi

bash "$KANATA_SCRIPT" uninstall

echo "mac uninstall complete"
