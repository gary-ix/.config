param(
    [Parameter(Position = 0)]
    [ValidateSet("install", "run", "uninstall")]
    [string]$Command
)

$ErrorActionPreference = "Stop"

$TaskName = "Garrett-Kanata"
$Root = Split-Path -Parent $PSScriptRoot
$DefaultCfgPath = Join-Path $PSScriptRoot "kanata.kbd"
$CfgPath = if ($env:KANATA_CFG_PATH) { $env:KANATA_CFG_PATH } else { $DefaultCfgPath }

function Require-Config {
    if (-not (Test-Path -LiteralPath $CfgPath)) {
        throw "Config not found: $CfgPath"
    }
}

function Get-KanataPath {
    $cmd = Get-Command kanata -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Kanata with winget..."
        winget install --id jtroo.kanata --exact --source winget --accept-package-agreements --accept-source-agreements | Out-Null
        $cmd = Get-Command kanata -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    throw "Kanata not found on PATH. Install Kanata and re-run."
}

function Install-Task {
    Require-Config
    $kanataPath = Get-KanataPath

    $arg = "--cfg `"$CfgPath`" --systray"
    $action = New-ScheduledTaskAction -Execute $kanataPath -Argument $arg
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName

    Write-Host "kanata installed as scheduled task"
    Write-Host "task: $TaskName"
    Write-Host "config: $CfgPath"
}

function Run-Foreground {
    Require-Config
    $kanataPath = Get-KanataPath
    & $kanataPath --cfg $CfgPath
}

function Uninstall-Task {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "kanata scheduled task removed"
}

switch ($Command) {
    "install" { Install-Task }
    "run" { Run-Foreground }
    "uninstall" { Uninstall-Task }
    default {
        Write-Error "Usage: .\kanata.ps1 {install|run|uninstall}"
    }
}
