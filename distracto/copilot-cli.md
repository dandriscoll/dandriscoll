# distracto integration for GitHub Copilot CLI

Add the following to your Copilot CLI instructions or system prompt:

---

## Task Tracking with distracto

When assisting the user in terminal sessions, maintain task context using distracto.

### On session start:
```bash
distracto show
```
Review the output. If PROJECT, GOAL, and TASK are not set, ask the user:
- "What project are we working on?" (keep to ≤10 characters)
- "What's the goal for this session?" (≤30 characters)
- "What's the first task?" (≤30 characters)

Then run:
```bash
distracto set --project "<project>" --goal "<goal>" --task "<task>"
```

### During work:
When the current task changes, update the status:
```bash
distracto update --task "<new task description>"
```

### On completion:
```bash
distracto clear
```

### Key principle:
Before suggesting commands or code changes, verify alignment with the current GOAL and TASK. If your suggestion would serve a different goal, flag this to the user before proceeding.
