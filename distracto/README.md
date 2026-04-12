# distracto

A persistent task reminder line at the top of your terminal. Each terminal session represents a single task, displayed as:

```
 PROJECT | GOAL | TASK
```

## Quick Start

```bash
# Clone and install
./distracto/install.sh    # or: cp distracto/distracto ~/.local/bin/
distracto init            # configure your shell
source ~/.bashrc          # or restart your terminal

# Set your task
distracto set --project "webapp" --goal "Fix login bug" --task "Reading auth code"

# Update as you work
distracto update --task "Writing the fix"

# Done
distracto clear
```

## Commands

| Command | Description |
|---------|-------------|
| `distracto init` | Detect OS/shell and install hooks |
| `distracto set -p <proj> -g <goal> -t <task>` | Set all values |
| `distracto update [-p] [-g] [-t]` | Partial update |
| `distracto clear` | Clear all values |
| `distracto show` | Display current values |
| `distracto export` | Output as JSON |
| `distracto import` | Read JSON from stdin |

## Platform Support

- **Linux**: bash, zsh
- **macOS**: bash, zsh
- **Windows**: Native PowerShell (`distracto.ps1`), Git Bash, WSL
- **SSH sessions**: works automatically
- **tmux**: configures top status bar

## How It Works

- Shell hooks (`PROMPT_COMMAND` / `precmd`) render the status line at terminal row 1
- Scroll margins keep content below the status line
- State is stored in env vars (`DISTRACTO_PROJECT`, `DISTRACTO_GOAL`, `DISTRACTO_TASK`) and persisted to `~/.distracto/session_<id>`
- `DISTRACTO_SESSION_ID` is inherited by subshells for state continuity
- tmux uses its native status bar with `status-position top`

## Agent Integration

See the prompt files in this directory:
- `claude-code.md` - Claude Code
- `copilot-cli.md` - GitHub Copilot CLI
- `codex.md` - OpenAI Codex CLI

## Uninstall

```bash
./distracto/uninstall.sh
```
