$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Full Windows bootstrap for keyboard shortcuts:
# 1) ensure Node toolchain and repo deps
# 2) generate AHK from Karabiner config
# 3) ensure AutoHotkey is installed
# 4) register startup and launch now
#
# Design goals:
# - single-command setup on a fresh Windows machine
# - idempotent reruns (safe to execute multiple times)
# - minimal user interaction (silent installers where possible)

# Resolve key repo paths once and pass them through the workflow.
$Root = Split-Path -Parent $PSScriptRoot
$Generator = Join-Path $Root "ahk/karabiner-to-ahk.ts"
$AhkOutput = Join-Path $Root "ahk/keyboard-shortcuts.ahk"
$StartupShortcut = Join-Path ([Environment]::GetFolderPath("Startup")) "keyboard-shortcuts.lnk"

function Test-CommandExists {
    param([string]$Name)

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    # After winget installs, current shell PATH can be stale.
    # Rehydrating machine+user PATH avoids requiring a new shell.
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Install-WithWinget {
    param(
        [string]$PackageId,
        [string]$FriendlyName
    )

    # winget is the single package manager dependency for unattended setup.
    if (-not (Test-CommandExists "winget")) {
        throw "winget is required to install $FriendlyName automatically. Install App Installer from Microsoft Store and re-run."
    }

    Write-Host "installing $FriendlyName..."
    winget install --id $PackageId --exact --silent --accept-source-agreements --accept-package-agreements

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install $FriendlyName with winget (exit code $LASTEXITCODE)."
    }

    Refresh-Path
}

function Ensure-NodeToolchain {
    # The generator script is TypeScript and runs via npx tsx.
    # We require node/npm/npx to be present before continuing.
    if ((Test-CommandExists "node") -and (Test-CommandExists "npm") -and (Test-CommandExists "npx")) {
        return
    }

    Install-WithWinget -PackageId "OpenJS.NodeJS.LTS" -FriendlyName "Node.js LTS"

    if (-not ((Test-CommandExists "node") -and (Test-CommandExists "npm") -and (Test-CommandExists "npx"))) {
        throw "Node.js tools (node/npm/npx) were not found after installation. Open a new shell and re-run."
    }
}

function Ensure-RepoDependencies {
    # tsx is required to run the TypeScript generator script.
    # Checking the local binary keeps this fast for repeat runs.
    $tsxCommand = Join-Path $Root "node_modules/.bin/tsx.cmd"
    if (Test-Path $tsxCommand) {
        return
    }

    Write-Host "installing npm dependencies..."
    Push-Location $Root
    try {
        # npm ci gives deterministic installs based on package-lock.json.
        npm ci
        if ($LASTEXITCODE -ne 0) {
            throw "npm ci failed (exit code $LASTEXITCODE)."
        }
    }
    finally {
        Pop-Location
    }
}

function Get-AhkExecutable {
    # Try PATH lookups first.
    $commands = @("AutoHotkey64.exe", "AutoHotkey.exe", "autohotkey")
    foreach ($name in $commands) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command -and (Test-Path $command.Source)) {
            return $command.Source
        }
    }

    # Then check common installation folders for AutoHotkey v2.
    $paths = @(
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey.exe",
        "$env:ProgramFiles\AutoHotkey\AutoHotkey64.exe",
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe",
        "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey.exe"
    )

    foreach ($candidate in $paths) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Ensure-AutoHotkey {
    # Skip install if already present.
    $existing = Get-AhkExecutable
    if ($null -ne $existing) {
        return $existing
    }

    Install-WithWinget -PackageId "AutoHotkey.AutoHotkey" -FriendlyName "AutoHotkey v2"

    $installed = Get-AhkExecutable
    if ($null -eq $installed) {
        throw "AutoHotkey executable was not found after installation."
    }

    return $installed
}

function Ensure-StartupShortcut {
    param(
        [string]$AhkExe,
        [string]$AhkScriptPath
    )

    # Startup link ensures shortcuts are active after sign-in.
    # Rewriting the .lnk each run keeps it in sync with path changes.
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($StartupShortcut)
    $shortcut.TargetPath = $AhkExe
    $shortcut.Arguments = "`"$AhkScriptPath`""
    $shortcut.WorkingDirectory = Split-Path -Parent $AhkScriptPath
    $shortcut.IconLocation = "$AhkExe,0"
    $shortcut.Save()
}

function Restart-AhkScript {
    param(
        [string]$AhkExe,
        [string]$AhkScriptPath
    )

    # Stop only the managed script instance, then launch the latest output.
    # We match command line text to avoid killing unrelated AHK scripts.
    $escapedPath = [Regex]::Escape($AhkScriptPath)
    $processes = Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe' OR Name='AutoHotkey.exe'" -ErrorAction SilentlyContinue

    foreach ($process in @($processes)) {
        if ($null -ne $process.CommandLine -and $process.CommandLine -match $escapedPath) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }

    Start-Process -FilePath $AhkExe -ArgumentList "`"$AhkScriptPath`"" -WorkingDirectory (Split-Path -Parent $AhkScriptPath)
}

# Bootstrap pipeline.
Ensure-NodeToolchain
Ensure-RepoDependencies

Write-Host "syncing ahk shortcuts from karabiner..."
Push-Location $Root
try {
    npx tsx $Generator
    if ($LASTEXITCODE -ne 0) {
        throw "AHK generation failed (exit code $LASTEXITCODE)."
    }
}
finally {
    Pop-Location
}

if (-not (Test-Path $AhkOutput)) {
    # Hard guard: setup should never continue without generated hotkeys.
    throw "Expected generated file missing: $AhkOutput"
}

$ahkExe = Ensure-AutoHotkey
Ensure-StartupShortcut -AhkExe $ahkExe -AhkScriptPath $AhkOutput
Restart-AhkScript -AhkExe $ahkExe -AhkScriptPath $AhkOutput

Write-Host "ahk setup complete"
Write-Host "generated: $AhkOutput"
Write-Host "startup shortcut: $StartupShortcut"
