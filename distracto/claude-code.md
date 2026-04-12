# distracto integration for Claude Code

Add the following to your CLAUDE.md or project instructions:

---

## Task Tracking with distracto

At the start of every task:

1. Run `distracto show` to check the current task context.
2. If no values are set, ask the user to define:
   - **PROJECT** (≤10 chars): short project identifier
   - **GOAL** (≤30 chars): what we're trying to achieve this session
   - **TASK** (≤30 chars): the current specific task
3. Set the values: `distracto set --project "<project>" --goal "<goal>" --task "<task>"`

As work progresses:

- When moving to a new sub-task, update: `distracto update --task "<new task>"`
- When the goal shifts, update: `distracto update --goal "<new goal>"`
- When finishing, clear: `distracto clear`

Before any significant action, check that your work aligns with the displayed GOAL and TASK. If you find yourself diverging, pause and confirm with the user.

Example flow:
```
$ distracto show
PROJECT: <not set>
GOAL:    <not set>
TASK:    <not set>

# Agent asks user for context, then:
$ distracto set --project "webapp" --goal "Fix auth token refresh bug" --task "Reading auth middleware"

# Later:
$ distracto update --task "Writing token refresh logic"

# On completion:
$ distracto clear
```
