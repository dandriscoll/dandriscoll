#!/usr/bin/env bash
# install.sh - Install distracto to a standard location
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_DIR="${HOME}/.local/bin"

mkdir -p "$INSTALL_DIR"

cp "${REPO_DIR}/distracto/distracto" "${INSTALL_DIR}/distracto"
chmod +x "${INSTALL_DIR}/distracto"

echo "Installed distracto to ${INSTALL_DIR}/distracto"

if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
    echo ""
    echo "Add to your PATH if not already present:"
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
fi

echo ""
echo "Run 'distracto init' to configure your shell."
