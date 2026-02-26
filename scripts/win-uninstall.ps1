$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

# Uninstall Kanata
$KanataScript = Join-Path $Root "kanata/kanata.ps1"
if (-not (Test-Path -LiteralPath $KanataScript)) {
    throw "Kanata controller not found: $KanataScript"
}
& $KanataScript uninstall

Write-Host "windows uninstall complete"
