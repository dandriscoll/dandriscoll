# Adds a shell alias "groot" that cd's to the git repo root.
# Source this file or add the alias line to your ~/.bashrc or ~/.zshrc.
grep -qxF 'alias groot='"'"'cd "$(git rev-parse --show-toplevel)"'"'"'' ~/.bashrc 2>/dev/null || \
  echo 'alias groot='"'"'cd "$(git rev-parse --show-toplevel)"'"'"'' >> ~/.bashrc
