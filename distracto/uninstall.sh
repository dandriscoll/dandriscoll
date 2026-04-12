#!/usr/bin/env bash
# uninstall.sh - Remove distracto hooks and state
set -euo pipefail

MARKER="# >>> distracto >>>"
END_MARKER="# <<< distracto <<<"

for rcfile in "${HOME}/.bashrc" "${HOME}/.zshrc" "${HOME}/.tmux.conf"; do
    if [[ -f "$rcfile" ]] && grep -q "$MARKER" "$rcfile" 2>/dev/null; then
        sed -i.distracto-bak "/$MARKER/,/$END_MARKER/d" "$rcfile"
        echo "Removed distracto hooks from $rcfile"
    fi
done

PS_PROFILE="${HOME}/.config/powershell/Microsoft.PowerShell_profile.ps1"
if [[ -f "$PS_PROFILE" ]] && grep -q "$MARKER" "$PS_PROFILE" 2>/dev/null; then
    sed -i.distracto-bak "/$MARKER/,/$END_MARKER/d" "$PS_PROFILE"
    echo "Removed distracto hooks from $PS_PROFILE"
fi

if [[ -d "${HOME}/.distracto" ]]; then
    rm -rf "${HOME}/.distracto"
    echo "Removed state directory ~/.distracto"
fi

rm -f "${HOME}/.local/bin/distracto"
echo "Uninstall complete."
