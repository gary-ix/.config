$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

# Install Kanata
$KanataScript = Join-Path $Root "kanata/kanata.ps1"
if (-not (Test-Path -LiteralPath $KanataScript)) {
    throw "Kanata controller not found: $KanataScript"
}
& $KanataScript install

Write-Host "windows install complete"
