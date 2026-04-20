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
    $proj = if ($env:DISTRACTO_PROJECT) { $env:DISTRACTO_PROJECT } else { "" }
    $goal = if ($env:DISTRACTO_GOAL) { $env:DISTRACTO_GOAL } else { "" }
    $task = if ($env:DISTRACTO_TASK) { $env:DISTRACTO_TASK } else { "" }

    if (-not $proj -and -not $goal -and -not $task) { return "" }

    $cols = $Host.UI.RawUI.WindowSize.Width
    if (-not $cols -or $cols -lt 1) { $cols = 80 }

    $count = 0
    if ($proj) { $count++ }
    if ($goal) { $count++ }
    if ($task) { $count++ }
    $seps = if ($count -gt 0) { $count - 1 } else { 0 }
    $budget = $cols - 2 - ($seps * 3)
    if ($budget -lt 1) { $budget = 1 }

    # Shrink the longest field one char at a time until the total fits.
    # A short project donates space to a long task without fixed caps.
    $lp = $proj.Length; $lg = $goal.Length; $lt = $task.Length
    while ($lp + $lg + $lt -gt $budget) {
        if ($lp -ge $lg -and $lp -ge $lt)      { $lp-- }
        elseif ($lg -ge $lt)                   { $lg-- }
        else                                   { $lt-- }
        if ($lp + $lg + $lt -le 0) { break }
    }
    if ($lp -lt 0) { $lp = 0 }
    if ($lg -lt 0) { $lg = 0 }
    if ($lt -lt 0) { $lt = 0 }
    $proj = $proj.Substring(0, $lp)
    $goal = $goal.Substring(0, $lg)
    $task = $task.Substring(0, $lt)

    $esc      = [char]27
    $cProj    = "$esc[1;38;5;81m"   # bold light cyan
    $cGoal    = "$esc[38;5;222m"    # soft yellow
    $cTask    = "$esc[38;5;156m"    # light green
    $cSep     = "$esc[38;5;244m"    # dim gray
    $fgReset  = "$esc[39m"          # default fg, preserves bg

    $colored = ""
    if ($proj) { $colored += "$cProj$proj$fgReset" }
    if ($goal) {
        if ($colored) { $colored += "$cSep | $fgReset" }
        $colored += "$cGoal$goal$fgReset"
    }
    if ($task) {
        if ($colored) { $colored += "$cSep | $fgReset" }
        $colored += "$cTask$task$fgReset"
    }
    return $colored
}

# --- Commands ---

$script:DistractoFlagMap = @{
    "-p" = "project"; "--project" = "project"
    "-g" = "goal";    "--goal"    = "goal"
    "-t" = "task";    "--task"    = "task"
}

function Parse-FlagArguments {
    param([string[]]$Arguments)
    $result = @{}
    $i = 0
    while ($i -lt $Arguments.Count) {
        $flag = $Arguments[$i]
        if (-not $script:DistractoFlagMap.ContainsKey($flag)) {
            throw "Unknown option: $flag"
        }
        $key = $script:DistractoFlagMap[$flag]
        $i++
        $values = @()
        while ($i -lt $Arguments.Count -and -not $script:DistractoFlagMap.ContainsKey($Arguments[$i])) {
            $values += $Arguments[$i]
            $i++
        }
        $result[$key] = ($values -join " ")
    }
    return $result
}

function Apply-ParsedArguments {
    param([hashtable]$Parsed)
    if ($Parsed.ContainsKey("project")) { $env:DISTRACTO_PROJECT = $Parsed["project"] }
    if ($Parsed.ContainsKey("goal"))    { $env:DISTRACTO_GOAL    = $Parsed["goal"]    }
    if ($Parsed.ContainsKey("task"))    { $env:DISTRACTO_TASK    = $Parsed["task"]    }
}

function Cmd-Set {
    param([string[]]$Arguments)
    Load-State
    try { $parsed = Parse-FlagArguments $Arguments } catch { Write-Error $_.Exception.Message; return }
    Apply-ParsedArguments $parsed
    Save-State
}

function Cmd-Update {
    param([string[]]$Arguments)
    Load-State
    try { $parsed = Parse-FlagArguments $Arguments } catch { Write-Error $_.Exception.Message; return }
    Apply-ParsedArguments $parsed
    Save-State
}

function Cmd-Done {
    param([string[]]$Arguments)
    Load-State
    if ($Arguments.Count -gt 0) {
        $env:DISTRACTO_TASK = ($Arguments -join " ")
    } elseif ($env:DISTRACTO_TASK) {
        $env:DISTRACTO_TASK = ""
    } elseif ($env:DISTRACTO_GOAL) {
        $env:DISTRACTO_GOAL = ""
    } elseif ($env:DISTRACTO_PROJECT) {
        $env:DISTRACTO_PROJECT = ""
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

function global:__distracto_draw_bar {
    `$line = __distracto_render
    `$rows = `$Host.UI.RawUI.WindowSize.Height
    Write-Host -NoNewline "`e[2;`${rows}r"
    if (`$line) {
        Write-Host -NoNewline "`e[1;1H`e[48;5;17m`e[K `$line`e[0m"
    }
}

# Override prompt to include status line
`$global:__distracto_original_prompt = if (Test-Path Function:\prompt) { Get-Content Function:\prompt } else { `$null }

function global:prompt {
    # Save cursor BEFORE DECSTBM (homes cursor on xterm/vte), draw bar,
    # restore cursor last.
    Write-Host -NoNewline "`e[s"
    __distracto_draw_bar
    Write-Host -NoNewline "`e[u"
    "PS `$(`$executionContext.SessionState.Path.CurrentLocation)`$('>' * (`$nestedPromptLevel + 1)) "
}

function global:Clear-Host {
    [Console]::Write("`e[2J`e[H")
    __distracto_draw_bar
    Write-Host -NoNewline "`e[2;1H"
}
Set-Alias -Name cls -Value Clear-Host -Scope Global -Option AllScope -Force

# Clear screen, set scroll margin to reserve top line, park cursor below bar
try {
    `$rows = `$Host.UI.RawUI.WindowSize.Height
    Write-Host -NoNewline "`e[2J`e[H`e[2;`${rows}r`e[2;1H"
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
    Write-Host "Restart your PowerShell session or run: . '$profilePath'"
}

function Cmd-Help {
    Write-Output @"
distracto $DistractoVersion - persistent task reminder for terminal sessions

Values may span multiple tokens; quoting is optional.

Usage:
  distracto init                                    Setup for current environment
  distracto set -p <proj> -g <goal> -t <task>       Set all values
  distracto update [-p <proj>] [-g <goal>] [-t <task>]  Partial update
  distracto done [<next task>...]                   Pop one level: task -> goal -> project (or replace task)
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
    "done"    { Cmd-Done -Arguments $remaining }
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
