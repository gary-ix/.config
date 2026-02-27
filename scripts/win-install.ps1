$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

# AutoHotkey
& (Join-Path $Root "ahk/win-ahk-setup.ps1")

Write-Host "windows install complete"
