#!/usr/bin/env bash
set -euo pipefail

VSCODIUM_BUNDLE_ID="com.vscodium"

if ! command -v duti &> /dev/null; then
    echo "duti not found, installing via Homebrew..."
    brew install duti
fi

echo "Setting VSCodium as default editor for code and config files..."

set_handler() {
    if ! duti -s "$VSCODIUM_BUNDLE_ID" "$1" all 2>/dev/null; then
        # Try editor role as fallback for protected types like .html
        if ! duti -s "$VSCODIUM_BUNDLE_ID" "$1" editor 2>/dev/null; then
            echo "  Skipped $1 (protected by macOS)"
        fi
    fi
}

# Code files
set_handler .ts
set_handler .tsx
set_handler .js
set_handler .jsx
set_handler .mjs
set_handler .cjs
set_handler .py
set_handler .rs
set_handler .go
set_handler .swift
set_handler .zig
set_handler .c
set_handler .h
set_handler .cpp
set_handler .hpp
set_handler .css
set_handler .scss
set_handler .html
set_handler .vue
set_handler .svelte

# Config files
set_handler .json
set_handler .yaml
set_handler .yml
set_handler .toml
set_handler .env
set_handler .ini
set_handler .conf
set_handler .cfg

# Shell/scripts
set_handler .sh
set_handler .zsh
set_handler .bash
set_handler .fish

# Docs/markup
set_handler .md
set_handler .mdx
set_handler .txt

echo "Done! File associations updated."
