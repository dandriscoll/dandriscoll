#!/usr/bin/env pwsh
# distracto.ps1 - persistent task reminder for terminal sessions (pure PowerShell)
# Works on Windows without Bash/WSL dependency

$ErrorActionPreference = "Stop"
$DistractoVersion = "1.0.0"
$DistractoStateDir = if ($env:DISTRACTO_STATE_DIR) { $env:DISTRACTO_STATE_DIR } else { Join-Path $HOME ".distracto" }

# --- Helpers ---

function Ensure-StateDir {
    if (-not (Test-Path $DistractoStateDir)) {
        New-Item -ItemType Directory -Path $DistractoStateDir -Force | Out-Null
    }
}

function Get-SessionFile {
    $sid = if ($env:DISTRACTO_SESSION_ID) { $env:DISTRACTO_SESSION_ID } else { $PID }
    return Join-Path $DistractoStateDir "session_$sid.json"
}

function Load-State {
    $sf = Get-SessionFile
    if (Test-Path $sf) {
        $data = Get-Content $sf -Raw | ConvertFrom-Json
        if ($data.project -and -not $env:DISTRACTO_PROJECT) { $env:DISTRACTO_PROJECT = $data.project }
        if ($data.goal -and -not $env:DISTRACTO_GOAL) { $env:DISTRACTO_GOAL = $data.goal }
        if ($data.task -and -not $env:DISTRACTO_TASK) { $env:DISTRACTO_TASK = $data.task }
    }
}

function Save-State {
    Ensure-StateDir
    $sf = Get-SessionFile
    $state = @{
        project = if ($env:DISTRACTO_PROJECT) { $env:DISTRACTO_PROJECT } else { "" }
        goal    = if ($env:DISTRACTO_GOAL) { $env:DISTRACTO_GOAL } else { "" }
        task    = if ($env:DISTRACTO_TASK) { $env:DISTRACTO_TASK } else { "" }
    }
    $state | ConvertTo-Json -Compress | Set-Content $sf
}

function Truncate-String([string]$str, [int]$max) {
    if ($str.Length -gt $max) {
        return $str.Substring(0, $max - 1) + [char]0x2026
    }
    return $str
}

function Render-Line {
    $proj = Truncate-String (if ($env:DISTRACTO_PROJECT) { $env:DISTRACTO_PROJECT } else { "" }) 10
    $goal = Truncate-String (if ($env:DISTRACTO_GOAL) { $env:DISTRACTO_GOAL } else { "" }) 30
    $task = Truncate-String (if ($env:DISTRACTO_TASK) { $env:DISTRACTO_TASK } else { "" }) 30

    if (-not $proj -and -not $goal -and -not $task) { return "" }

    $line = $proj
    if ($goal) { $line += " | $goal" }
    if ($task) { $line += " | $task" }

    $cols = $Host.UI.RawUI.WindowSize.Width
    if ($cols -and $line.Length -gt $cols) {
        $line = $line.Substring(0, $cols - 1) + [char]0x2026
    }
    return $line
}

# --- Commands ---

function Cmd-Set {
    param([string[]]$Arguments)
    Load-State
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        switch ($Arguments[$i]) {
            { $_ -in "--project", "-p" } { $i++; $env:DISTRACTO_PROJECT = $Arguments[$i] }
            { $_ -in "--goal", "-g" }    { $i++; $env:DISTRACTO_GOAL = $Arguments[$i] }
            { $_ -in "--task", "-t" }    { $i++; $env:DISTRACTO_TASK = $Arguments[$i] }
            default { Write-Error "Unknown option: $($Arguments[$i])"; return }
        }
    }
    Save-State
}

function Cmd-Update {
    param([string[]]$Arguments)
    Load-State
    for ($i = 0; $i -lt $Arguments.Count; $i++) {
        switch ($Arguments[$i]) {
            { $_ -in "--project", "-p" } { $i++; $env:DISTRACTO_PROJECT = $Arguments[$i] }
            { $_ -in "--goal", "-g" }    { $i++; $env:DISTRACTO_GOAL = $Arguments[$i] }
            { $_ -in "--task", "-t" }    { $i++; $env:DISTRACTO_TASK = $Arguments[$i] }
            default { Write-Error "Unknown option: $($Arguments[$i])"; return }
        }
    }
    Save-State
}

function Cmd-Clear {
    $env:DISTRACTO_PROJECT = ""
    $env:DISTRACTO_GOAL = ""
    $env:DISTRACTO_TASK = ""
    $sf = Get-SessionFile
    if (Test-Path $sf) { Remove-Item $sf -Force }
}

function Cmd-Show {
    Load-State
    $p = if ($env:DISTRACTO_PROJECT) { $env:DISTRACTO_PROJECT } else { "<not set>" }
    $g = if ($env:DISTRACTO_GOAL) { $env:DISTRACTO_GOAL } else { "<not set>" }
    $t = if ($env:DISTRACTO_TASK) { $env:DISTRACTO_TASK } else { "<not set>" }
    Write-Output "PROJECT: $p"
    Write-Output "GOAL:    $g"
    Write-Output "TASK:    $t"
}

function Cmd-Export {
    Load-State
    $state = @{
        project = if ($env:DISTRACTO_PROJECT) { $env:DISTRACTO_PROJECT } else { "" }
        goal    = if ($env:DISTRACTO_GOAL) { $env:DISTRACTO_GOAL } else { "" }
        task    = if ($env:DISTRACTO_TASK) { $env:DISTRACTO_TASK } else { "" }
    }
    $state | ConvertTo-Json -Compress
}

function Cmd-Import {
    Load-State
    $json = $input | Out-String
    $data = $json | ConvertFrom-Json
    if ($data.project) { $env:DISTRACTO_PROJECT = $data.project }
    if ($data.goal) { $env:DISTRACTO_GOAL = $data.goal }
    if ($data.task) { $env:DISTRACTO_TASK = $data.task }
    Save-State
}

function Cmd-Render {
    Load-State
    $line = Render-Line
    if ($line) { Write-Output $line }
}

function Cmd-Init {
    Ensure-StateDir
    Write-Host "distracto init - detecting environment..."
    Write-Host "  OS: Windows (PowerShell)"
    Write-Host "  Shell: PowerShell $($PSVersionTable.PSVersion)"

    $distractoBin = $MyInvocation.ScriptName
    if (-not $distractoBin) { $distractoBin = $PSCommandPath }
    Write-Host "  Script: $distractoBin"

    # Determine PowerShell profile path
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (-not $profilePath) { $profilePath = $PROFILE }
    $profileDir = Split-Path $profilePath -Parent

    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    if (-not (Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $marker = "# >>> distracto >>>"
    $endMarker = "# <<< distracto <<<"

    # Remove existing hook
    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($content -and $content.Contains($marker)) {
        $pattern = "(?s)$([regex]::Escape($marker)).*?$([regex]::Escape($endMarker))"
        $content = [regex]::Replace($content, $pattern, "")
        $content = $content.Trim()
        Set-Content $profilePath -Value $content
        Write-Host "  Removed existing hook from $profilePath"
    }

    $hookCode = @"

$marker
# distracto: persistent task reminder
`$env:DISTRACTO_SESSION_ID = if (`$env:DISTRACTO_SESSION_ID) { `$env:DISTRACTO_SESSION_ID } else { `$PID }

function global:__distracto_render {
    & "$distractoBin" render 2>`$null
}

# Override prompt to include status line
`$global:__distracto_original_prompt = if (Test-Path Function:\prompt) { Get-Content Function:\prompt } else { `$null }

function global:prompt {
    `$line = __distracto_render
    if (`$line) {
        `$cols = `$Host.UI.RawUI.WindowSize.Width
        `$padded = `$line.PadRight(`$cols)
        Write-Host -NoNewline "`e[s`e[1;1H`e[K`e[7m `$padded`e[0m`e[u"
    }
    return "PS> "
}

# Set scroll margin to reserve top line
try {
    `$rows = `$Host.UI.RawUI.WindowSize.Height
    Write-Host -NoNewline "`e[2;`${rows}r"
} catch {}
$endMarker
"@

    Add-Content $profilePath -Value $hookCode
    Write-Host "  Installed hook in $profilePath"

    # Clean old session files (older than 7 days)
    Get-ChildItem $DistractoStateDir -Filter "session_*" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "distracto initialized successfully!"
    Write-Host "Restart your PowerShell session or run: . `$PROFILE"
}

function Cmd-Help {
    Write-Output @"
distracto $DistractoVersion - persistent task reminder for terminal sessions

Usage:
  distracto init                                    Setup for current environment
  distracto set -p <proj> -g <goal> -t <task>       Set all values
  distracto update [-p <proj>] [-g <goal>] [-t <task>]  Partial update
  distracto clear                                   Clear all values
  distracto show                                    Display current values
  distracto export                                  Output values as JSON
  distracto import                                  Read JSON from stdin and apply
  distracto render                                  Output the status line (used by hooks)
  distracto version                                 Show version
"@
}

# --- Main ---

$command = if ($args.Count -gt 0) { $args[0] } else { "help" }
$remaining = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

switch ($command) {
    "init"    { Cmd-Init }
    "set"     { Cmd-Set -Arguments $remaining }
    "update"  { Cmd-Update -Arguments $remaining }
    "clear"   { Cmd-Clear }
    "show"    { Cmd-Show }
    "export"  { Cmd-Export }
    "import"  { Cmd-Import }
    "render"  { Cmd-Render }
    "version" { Write-Output "distracto $DistractoVersion" }
    { $_ -in "help", "--help", "-h" } { Cmd-Help }
    default   {
        Write-Error "Unknown command: $command"
        Write-Output "Run 'distracto help' for usage."
    }
}
