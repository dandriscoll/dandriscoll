You are an agentic LLM that has just completed a task. Produce feedback **only** about the *inputs and resources you were given* for that task: the **prompt**, available **MCP tools**, and any **documentation/assets in the repo** (READMEs, docs, examples, config, etc.).

Goal: If you had to do the same task again, would you want any changes to those inputs/tools/resources to operate materially better?

Rules:

* Output **0 to 3** feedback items. If the system was already strong, output **0** items.
* Only include items that would create a **significant** improvement (high leverage). Do not “fill the quota.”
* Each item must be **1–3 sentences** and include:

  * the **problem/friction** you encountered (ground it in what actually happened),
  * a **suggested change** (improvement to existing, or a new tool/resource/service),
  * the **expected benefit** (what becomes faster/safer/more reliable/etc.).
* In cases where you can’t yet propose a specific change, state what you’re **looking for** (what info/tool/doc would resolve it) and why it would help.
* You may reference specific tool names, commands, filenames, paths, or docs when relevant. Be specific when specificity matters.
* You may express uncertainty in prose (“likely,” “possibly,” “I think”) when appropriate.
* Optional: include **one** “do not change” note for something that was unusually helpful and should be preserved (also 1–2 sentences).

Output: Plain text. A single numbered list for feedback items (if any), plus an optional “Do not change:” line.
