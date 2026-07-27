# Learning systems for LLM agents

A generalized design for how LLM agents receive feedback and organize, store, maintain, and apply learned **insights** over time.

This document defines the management of learning. It does not define the source mechanisms that produce feedback or observations; those are inputs to the learning system. A brief appendix on feedback sources appears at the end.

The key words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** in this document are to be interpreted as described in RFC 2119.

---

## 1. Purpose

A learning system exists to help agents:

- Prevent future errors.
- Improve future performance.
- Preserve useful learning across work, across sessions, and across time.

A learning system **MUST NOT** be used as a substitute for remediation. If feedback reveals an existing error, defect, missed requirement, bad output, or broken artifact, that problem **MUST** be fixed or routed to whoever can fix it. The agent **MAY** capture an insight to prevent recurrence, but capturing an insight does not discharge the obligation to correct the current problem.

A learning system **SHOULD** be evaluated by whether agents using it behave better over time — not by the volume of insights it accumulates.

---

## 2. Core concepts

### 2.1 Insight

An **insight** is a reusable, actionable learning that can guide future agent behavior.

An insight **MUST**:

- Be written so a future reader can apply it without re-reading the original feedback.
- Carry enough context (when, where, why) to be operationally useful.
- Express guidance, not raw observation.
- Be as compact as possible while still producing the desired effect. Explanations and restatements that do not change behavior are excess; context that gates when the insight applies is not.

An insight **MUST NOT** merely restate feedback. Feedback says *what happened*; an insight says *what to do differently or keep doing*. Synthesis is required to cross that gap.

An insight **SHOULD** be specific enough to act on and general enough to apply more than once. A learning that can only ever apply to the exact original situation is usually a reference, not an insight.

### 2.2 Reference

A **reference** is source material that led to an insight: feedback text, a transcript excerpt, a review comment, an observation, an incident record, an example, or any other supporting evidence.

Feedback is logged as it arrives. When an insight is formed, references are created back to the feedback (or other evidence) that produced it: logged material becomes a reference when an insight cites it.

The learning system **MUST** keep insights separate from their references. Insights are the operational artifact agents read and apply. References are the evidentiary record behind them.

References serve two purposes:

1. **Inspection** — a future reader can verify where an insight came from and judge whether it is still well-supported.
2. **Faithful revision** — when an insight is generalized, reconstituted, consolidated, or otherwise changed, the change can be checked against the originating evidence so the revised insight has not drifted away from what was actually observed.

Every durable insight **SHOULD** be traceable to at least one reference. An insight with no traceable evidence **MAY** still exist, but it **SHOULD** be marked as such so a future agent can weigh it accordingly.

### 2.3 Granularity

The learning system distills. An agent performs many actions: outputs, documents, decisions. Feedback distills those actions — sampling and generalizing rather than recording each one. Insights distill feedback the same way, concentrating many records into few rules.

Neither step is 1:1. The agent **MUST NOT** convert feedback item-for-item into insights: a learning system that does so accumulates restatements rather than learning. The synthesis requirements in §5 enforce this distillation.

---

## 3. Scope of insights

Insights apply at different scopes. A scope describes *for whom and in what context* an insight is relevant.

Examples of scopes (illustrative, not exhaustive):

- General practice (e.g., software engineering in general).
- Project or repository scope.
- Person-specific scope.
- Organization, team, domain, or workflow scope.

The learning system **MUST NOT** impose a fixed universal list of scopes. Environments and use cases vary, and the set of meaningful scopes varies with them. The learning system **MUST** support storing insights at the appropriate scope for the environment in which it operates.

Different scopes **MAY** use different storage locations. For example:

- A repository-specific insight **MAY** live inside that repository so it travels with the code.
- A person-specific insight **SHOULD NOT** live inside a shared repository where it would be exposed to others.
- An organization-wide insight **MAY** live in a shared knowledge area accessible to that organization.

When storing an insight, the agent **MUST** decide the appropriate scope based on:

- The content of the insight.
- The intended audience.
- The sensitivity of the information.
- Expected reuse across contexts.
- The exposure characteristics of available storage locations (see §4).

The agent **SHOULD** make its best judgment from these factors. When the uncertainty is about exposure, the agent **SHOULD NOT** ask; it **SHOULD** default to the more restricted location (see §4). For other scope uncertainty, if the correct scope is genuinely unclear and the choice has meaningful consequences, the agent **MAY** ask for clarification. The agent **SHOULD NOT** overuse clarification when the scope is reasonably inferable.

---

## 4. Exposure control

Exposure control is a core principle of the learning system.

Every learning repository, learning area, or storage location has an **exposure level**: who can see it, where it can travel, what systems can access it, and what future contexts may reuse it.

Before storing any insight or reference, the agent **MUST** consider exposure. Specifically:

- The agent **MUST NOT** place information into a learning area whose exposure exceeds the appropriate audience for that information.
- The agent **MUST NOT** copy person-specific, organization-specific, confidential, or sensitive content into broadly visible locations.
- The agent **SHOULD** prefer the narrowest location that still makes the insight reachable by everyone who legitimately needs it.

Exposure is not only about humans. It also includes: which agents will read this location in the future, which projects will pull it in, and which external systems may ingest it. An insight written into a globally loaded file has effectively been published to every future session that loads that file.

When exposure is uncertain, the agent **SHOULD** default to the more restricted location. A correctly placed insight at a narrow scope can be promoted later; a leaked insight cannot be unsent.

---

## 5. Synthesizing insights

The agent **MUST** synthesize logged feedback and observations into insights. Synthesis is what turns raw material into reusable guidance. The obligation is to run synthesis, not to promote everything: leaving material as a reference or a candidate insight (see §5.4) is a legitimate outcome of synthesis.

Synthesis includes:

- **Clustering** — grouping related feedback before generalizing.
- **Consolidation** — merging overlapping or duplicative learnings.
- **Generalization** — extracting the reusable principle from specific instances.

The goal is a set of insights that is **appropriately generalized**: neither a pile of overly specific one-off corrections nor a set of vague principles too abstract to act on.

### 5.1 Clustering

The agent **SHOULD** cluster feedback by the behavior it would change, not by surface similarity — arriving on the same day, touching the same file, or sharing wording does not make feedback related. A cluster is the unit of synthesis: it usually yields one insight, and yields none while its evidence is still too thin (see §5.4).

New feedback that fits an existing insight's class belongs to that insight's cluster. The agent **SHOULD** revise or reconfirm the existing insight rather than writing a sibling; parallel insights covering the same behavior are duplication that consolidation must later undo.

### 5.2 Specificity control

Specificity is a property of generalization. The agent **SHOULD** preserve enough context for the insight to be useful while removing incidental details that do not matter for future application. The test is operational: can a future agent, reading the insight cold, decide whether and how to apply it?

The level of distillation has its own two-part test: an insight is distilled to the right level when it would have prevented the original incident and would also prevent the next, different instance of the same class. Failing the first means it generalized past its evidence; failing the second means it never left the incident.

### 5.3 Variations within an insight

Feedback in a cluster rarely agrees perfectly: a rule can hold in general while certain conditions demand different handling. The agent **SHOULD** express this as one insight — a general rule with explicit conditions for its edge cases — rather than flattening the rule until the edge cases disappear, or scattering sibling insights that each carry a fragment of the rule. Contradictory feedback often marks a missing condition; finding that condition is synthesis working, not failing.

Conditions face the same compactness bar as the rest of the insight (§2.1): a condition earns its place only when it changes behavior. When conditions multiply until no general rule remains, the cluster holds more than one class — split it into separate insights.

### 5.4 Avoiding overfitting

A single correction **MUST NOT** automatically become a universal rule. The evidence must support the generalization.

Where evidence is insufficient to support a durable insight, the agent **MAY**:

- Preserve the feedback as a reference.
- Record it as a candidate insight.
- Defer promotion until more evidence accumulates or a clear pattern emerges.

A candidate insight is not a weakness; it is an honest representation of partial evidence. Promoting too eagerly produces a learning system full of brittle rules.

### 5.5 Faithfulness to references

When synthesizing, the agent **MUST** stay faithful to the underlying references. After generalization, the resulting insight **MUST** be checked back against its references to confirm it still describes what actually happened.

---

## 6. Evidence and bookkeeping

The learning system **MUST** have a clear, concise, and consistent way of managing the data that flows through it. This covers:

- New feedback.
- References.
- Insights, including their scope and storage location.
- Updates, revisions, consolidations, and removals.
- Links between insights and the references that support them.

This document does not prescribe a storage schema. Different environments will need different formats, file layouts, or backing stores. What matters is that the bookkeeping is consistent enough that a future agent can:

- Find relevant insights.
- Inspect the references behind them.
- Update or remove insights without losing traceability.
- Trust that the recorded state reflects reality.

Trust is the operative property. An inconsistent or unreliable bookkeeping layer makes the entire learning system unsafe to act on.

---

## 7. Maintaining insight quality

An insight is good when it is relevant, trustworthy, and useful. Whether the stored insights stay that way over time determines whether future agents can act on them safely.

This document does not require a formal lifecycle, but insights are not fixed. The agent:

- **MAY** revise an insight when better understanding or new evidence emerges.
- **MAY** consolidate insights into a broader or better insight.
- **MAY** remove an insight when it is obsolete, misleading, unsupported, redundant, too vague, too narrow, or no longer useful.

Removal is not a failure; it is hygiene. A stale insight that contradicts current reality is worse than no insight at all, because agents will act on it.

### 7.1 Drift control during revision and consolidation

Consolidation in particular can introduce drift: combining several insights into one can quietly lose constraints, conditions, or scope information from the originals.

When an insight is revised or consolidated, the agent **MUST** compare the result against the original references. If the revised insight no longer fairly represents what those references show, the agent **MUST** either:

- Adjust the revised insight to remain faithful, or
- Preserve the original insight(s) separately.

---

## 8. Output artifacts

The learning system is judged at the point of reading. Whatever form its outputs take — insight files, or edits to the skills, prompts, and instructions that govern behavior — the agent **MUST** produce artifacts that are effective and efficient at helping a future reader adhere to the insights, not merely at archiving them.

Three consequences:

- **Absorb insights into the artifact that produced the feedback.** When feedback traces to an instruction, skill, or prompt, the most effective output is often an edit to that artifact itself. The agent **SHOULD** apply the change there rather than recording a separate insight that says what the artifact should have said; the separate record is a second copy to load and a second copy to maintain. Traceability (§2.2) still applies to the absorbed change. Where no such artifact exists, or the artifact cannot be edited, the agent records an insight instead. Where the feedback applies significantly beyond the artifact, the agent **MAY** record an insight in addition to the edit — but only when the artifact is narrowly scoped and there are many foreseeable scenarios outside it where the insight would apply.
- **Arrange insights so a reader knows when to load them.** Group them by the context in which they fire — a scope (§3), a task, a tool — and make that context legible without reading the insights themselves; the arrangement exists so the right set is found at the moment it applies.
- **Keep every loadable set compact and focused.** A set **MUST** stay compact enough to be internalized whole: each insight in it spends the reader's attention and dilutes the others. This is also why removal (§7) matters: an obsolete insight in a loaded set costs the same attention as a current one.

---

## 9. Application of insights

A learning system is only useful if agents actually consult and apply relevant insights during future work. An insight that is never read is indistinguishable from one that does not exist.

Therefore agents **SHOULD**:

- Surface relevant insights at the start of and during tasks where they could apply.
- Treat applicable insights as inputs to their reasoning, not as decorative notes.
- Notice when current work contradicts an existing insight, and either follow the insight or revise it with new evidence.

This document deliberately does **not** define precedence rules for resolving conflicts between insights from overlapping scopes (e.g., a person-specific insight vs. a repository-specific one). Precedence is a judgment made by the agent applying the insights in context, and it depends on the situation. It is out of scope for the core learning-system definition.

---

## Appendix A: Feedback

Feedback is the primary raw material that flows into the learning system. This appendix gives a compact vocabulary and a short set of best practices. It is intentionally brief; the body of the document handles what to do with feedback once it exists.

### A.1 Three sources of feedback

1. **Explicit feedback**
   Direct feedback intentionally given to the agent: corrections, comments, evaluations, reviews, acceptance or rejection signals, bug reports, stated preferences.

2. **Implicit feedback**
   Guidance revealed during the course of work: steering, edits to the agent's output, repeated clarifications, overridden assumptions, observed constraints, and patterns in what humans accept, reject, or redirect.

3. **Reflective feedback**
   Feedback the agent generates by observing its own work: identified failure modes, repeated friction, avoidable errors, missing context, inefficient process, operational improvements.

### A.2 Relative importance

- **Human feedback** (explicit and implicit) is usually the most **directionally** relevant. It is the strongest source for learning what the agent should optimize toward and for converging with user, team, or organizational expectations.
- **Reflective feedback** is often the most **operationally** relevant. It tends to drive improvements in the agent's internal process, reduces repeat operational errors, and is especially valuable for tuning performance in a specific operating environment.

Not all feedback is equally important. Broad capture is useful, but depth of treatment **SHOULD** be reserved for feedback that is recurring, high-impact, surprising, safety-relevant, or especially significant in the current operating environment.

### A.3 Best practices

- Preserve enough context for feedback to be interpretable later.
- Distinguish raw feedback from inferred meaning. Keep both; do not let inference overwrite the original.
- Do not prematurely convert feedback into durable insights.
- Cluster related feedback before generalizing, when possible.
- Preserve contradictory feedback rather than forcing false consistency; contradictions often mark a missing distinction.
- Respect exposure control for all feedback and references, not just for finished insights.
- Use feedback to create insights, but do not confuse feedback with insight.
