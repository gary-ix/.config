$ErrorActionPreference = "Stop"

# AHK-specific uninstall module.
#
# This script intentionally contains only AutoHotkey teardown logic so it can be
# composed by higher-level uninstall entrypoints without mixing concerns.
#
# Responsibilities:
# 1) remove startup shortcut created by ahk/win-ahk-setup.ps1
# 2) stop only AutoHotkey processes running the managed script

$Root = Split-Path -Parent $PSScriptRoot
$AhkOutput = Join-Path $Root "ahk/keyboard-shortcuts.ahk"
$StartupShortcut = Join-Path ([Environment]::GetFolderPath("Startup")) "keyboard-shortcuts.lnk"

if (Test-Path $StartupShortcut) {
    Remove-Item -Path $StartupShortcut -Force
}

$escapedPath = [Regex]::Escape($AhkOutput)
$processes = Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe' OR Name='AutoHotkey.exe'" -ErrorAction SilentlyContinue

foreach ($process in @($processes)) {
    if ($null -ne $process.CommandLine -and $process.CommandLine -match $escapedPath) {
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "ahk uninstall complete"
