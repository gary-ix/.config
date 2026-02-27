$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

# AutoHotkey
& (Join-Path $Root "ahk/win-ahk-uninstall.ps1")

Write-Host "windows uninstall complete"
