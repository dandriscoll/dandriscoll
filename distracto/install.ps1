# install.ps1 - Install distracto on Windows (PowerShell, no Bash dependency)
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoDir = Split-Path -Parent $ScriptDir
$InstallDir = Join-Path $env:LOCALAPPDATA "distracto"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Copy the native PowerShell implementation
Copy-Item "$RepoDir\distracto\distracto.ps1" "$InstallDir\distracto.ps1" -Force

# Create a .cmd wrapper so `distracto` works from cmd.exe too
$wrapperContent = @"
@echo off
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0distracto.ps1" %*
"@
Set-Content -Path "$InstallDir\distracto.cmd" -Value $wrapperContent

# Also copy the Bash version for Git Bash / WSL users
Copy-Item "$RepoDir\distracto\distracto" "$InstallDir\distracto" -Force -ErrorAction SilentlyContinue

Write-Host "Installed distracto to $InstallDir"
Write-Host ""

# Check if in PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$InstallDir*") {
    Write-Host "Adding $InstallDir to user PATH..."
    [Environment]::SetEnvironmentVariable("PATH", "$InstallDir;$currentPath", "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Host "Added to PATH. Restart your terminal for changes to take effect."
}

Write-Host ""
Write-Host "Run 'distracto init' to configure your shell."
