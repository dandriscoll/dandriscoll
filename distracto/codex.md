# distracto integration for OpenAI Codex CLI

Add the following to your Codex CLI configuration or instructions:

---

## Task Tracking with distracto

Codex should use distracto to maintain visible task context in the terminal.

### Startup check:
Run `distracto show` at the beginning of each session. If values are empty, prompt the user:

1. PROJECT (≤10 chars) - e.g., "api", "frontend", "infra"
2. GOAL (≤30 chars) - the session objective
3. TASK (≤30 chars) - the immediate next step

Set with: `distracto set --project "<p>" --goal "<g>" --task "<t>"`

### Progress updates:
As you complete tasks and move to the next step:
```bash
distracto update --task "Implementing validation layer"
distracto update --task "Writing unit tests"
distracto update --task "Reviewing changes"
```

### Machine-readable state:
For programmatic access to the current state:
```bash
# Export as JSON
distracto export
# Output: {"project":"api","goal":"Add rate limiting","task":"Writing tests"}

# Import from JSON
echo '{"project":"api","goal":"Add rate limiting","task":"Deploy"}' | distracto import
```

### Session end:
```bash
distracto clear
```

### Guardrail:
Always verify that proposed changes serve the stated GOAL. If scope creep is detected, update the GOAL or pause to realign with the user.
