# Versioning Setup Agent Prompt

Paste this prompt to a coding agent to set up versioning in your project.

---

## Prompt

I need you to set up build-time versioning for this project following the spec in `VERSIONING.md`.

**Version format:** `<branch>-<timestamp>` (e.g., `main-20260125-143022`)

### Tasks

1. **Detect the project type** (Python, JavaScript/TypeScript, C#/.NET, Go, or other) by examining the codebase.

2. **Create a version loader module** that exposes the version string. This should be minimal:
   - Read from the `BUILD_VERSION` environment variable
   - Default to `"development"` if not set
   - No git logic in this file

3. **Ask me:** Do you want fallback logic that calculates the version from git when `BUILD_VERSION` is not set?

   If yes, create a **separate dedicated script** (e.g., `scripts/git-version.sh` or `scripts/git_version.py`) that:
   - Runs these git commands:
     ```bash
     BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/-/g')
     TIMESTAMP=$(TZ=UTC git show -s --format=%cd --date=format:'%Y%m%d-%H%M%S' HEAD)
     VERSION="${BRANCH}-${TIMESTAMP}"
     ```
   - Appends `-dirty` if there are uncommitted changes
   - Outputs the version string to stdout
   - Document usage: `BUILD_VERSION=$(./scripts/git-version.sh) <run-command>`

   If no, skip creating the fallback script.

4. **Update build/run scripts** (package.json, Makefile, etc.) to include a convenience command for local dev with the fallback.

5. **Verify** the setup works by showing me how to test it locally.

### Constraints

- Do NOT commit generated version values to source control
- Keep the version loader minimal - no git commands or subprocess calls
- Git fallback logic must live in a dedicated script file, not in the main codebase
- Follow existing code style and conventions in the project
