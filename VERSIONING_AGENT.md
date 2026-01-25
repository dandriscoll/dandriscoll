# Versioning Setup Agent Prompt

Paste this prompt to a coding agent to set up versioning in your project.

---

## Prompt

I need you to set up build-time versioning for this project.

First, fetch and read the versioning spec at:
https://github.com/dandriscoll/dandriscoll/blob/main/VERSIONING.md

Then follow these tasks:

### Tasks

1. **Detect the project type** (Python, JavaScript/TypeScript, C#/.NET, Go, or other) by examining the codebase.

2. **Create a version loader module** following the language examples in the spec:
   - Place it in the project's existing utility/lib directory to match conventions
   - Read from the `BUILD_VERSION` environment variable
   - Default to `"development"` if not set
   - No git logic in this file
   - For frontend frameworks (Next.js, Vite, etc.), check if the version needs to be exposed client-side

3. **Ask me:** Do you want fallback logic that calculates the version from git when `BUILD_VERSION` is not set?

   - If yes: Create a **separate dedicated code** following the spec examples, and update build/run scripts (package.json, Makefile, etc.) to include a convenience command for local dev.
   - If no: Skip the fallback code.

4. **Verify** the setup works:
   - Show me how to test it locally
   - Confirm the version is accessible where it's needed (API routes, UI, logs, etc.)

### Constraints

- Do NOT commit generated version values to source control
- Keep the version loader minimal - no git commands or subprocess calls
- Git fallback logic (if requested) must live in a dedicated script file, not in the main codebase
- Follow existing code style and conventions in the project
