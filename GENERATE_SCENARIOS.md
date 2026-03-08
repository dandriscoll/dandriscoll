You are an agent performing a **one-time setup** to create the project’s **living scenario list**.

## Goal

Create a comprehensive document that itemizes the application’s scenarios so future agents/implementers can consult it to keep the implementation and tests aligned with intended behavior.

The scenario list is the **primary reference**. If code/tests conflict with the scenario list later, code/tests should be changed to match the scenario list. However, in this one-time setup you are **describing** the system as you infer it; do not invent unspecified behavior.

## Output

1. Create a new document in a sensible location under `docs/` (choose the path and state it at the top of the document).
2. The document must:

   * Cover **all experiences** (grouped by Experience as the top-level framing).
   * Include scenarios written as **descriptive prose contracts** (not a rigid schema; no required fields, no fixed template).
   * Focus on **externally observable behaviors**. Include internal behaviors only when they materially affect correctness, user/API-visible outcomes, or observability.
   * Include **only the guidance necessary** to maintain and adhere to the descriptions (keep this guidance brief).
   * Include a **Direct Conflicts** section that lists only direct contradictions found between sources (docs vs code vs tests vs UI copy). Do not list “missing/underspecified” items as conflicts.

## Critical rules

* **Do not impose or prescribe a specific format.** Use Experience grouping, but otherwise keep structure lightweight and natural.
* **Do not be directive about stable IDs.** If you choose to include identifiers, treat them as incidental and non-prescriptive; do not require or emphasize them.
* **Do not fill in blanks.** Some behaviors are intentionally not specified because they are not intrinsic to how the app operates, even if implementers will later make decisions about them (e.g., exact debounce timing, retry backoff specifics, microcopy wording, precise latency thresholds unless already specified). Do not add such details to scenarios unless the repo explicitly defines them.
* If you encounter ambiguity or missing intent, prefer to:

  * describe what you can confidently infer, and
  * avoid adding speculative requirements.

## How to build the scenario list

1. Crawl the repo and extract scenario candidates from:

   * user-facing surfaces (pages, flows, UI states, dialogs)
   * public APIs/endpoints and their observable contracts
   * CLI commands or integrations, if present
   * tests that assert user-visible behavior
   * documentation/product notes, if present
2. For each Experience, write scenarios as short prose like:
   “<Surface> allows <actor> to <goal>. When <trigger>, the system <observable behavior>. If <condition>, the system <observable alternate>.”
   Include confirmations, error behaviors, and state/side-effect expectations **only when they are observable or explicitly defined**.
3. Keep scenario granularity to “one coherent behavior contract.” Split scenarios when:

   * the user-visible behavior differs meaningfully, or
   * the runtime/dependency chain differs by Experience.
4. After drafting, do a pass to ensure coverage:

   * each Experience has its key user-visible surfaces and main workflows represented
   * major error/edge behaviors are included where they are explicitly present in code/tests/docs

## Direct Conflicts section

At the end, list only direct contradictions, each with:

* the conflicting statements (briefly paraphrased)
* where each came from (file/path or test name)
* what is contradictory (one sentence)
  Do not resolve conflicts; just surface them.

## Deliverable

Write the document, then report:

* the file path you created
* a very short note on what you used as primary evidence sources (e.g., “code + tests + docs”).
