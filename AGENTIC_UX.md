# Agentic Workflow Specification

## 1. Intent

| Type | Definition |
|------|-----------|
| **Project Intent** | The desired outcome of the project |
| **User Intent** | The user's immediate goal to advance the project |

Intent may be explicit, implicit, or partially defined. The user may lack full clarity on either form of intent.

## 2. Intent Resolution

The agent evaluates two signals: clarity of user intent and dependency on project intent.

1. **User intent is clear, no project intent dependency** — Agent proceeds directly to suggestion.
2. **User intent is clear, requires project intent** — Agent enters discovery focused on project goals before suggesting.
3. **User intent is unclear** — Agent enters discovery focused on user intent. This may reveal that the user needs project-level clarity first, requiring discovery to shift focus to project intent.

## 3. Discovery

Discovery establishes alignment through agent-initiated questions. The agent uses question cards to gather the minimum information needed to take a meaningful next step.

Alignment is relative to the next action, not to the full project. Each action may itself produce new clarity.

## 4. Cards

### 4.1 Question Card

**Structure:**
- `prompt`: The question text
- `options[]`: Selectable responses (optional)
  - Each option: `{ label, value }`
- `free_text_input`: Always present; allows custom response as alternative to options

**Behavior:**
- Prefer batched options over sequential yes/no questions
- Never overload the user — a single well-framed question with a few options is ideal
- Selecting an option submits its value as the response
- Free-text submission overrides any option selection
- Multiple cards may be presented simultaneously; each is independently answerable

### 4.2 Suggestion Card

**Structure:**
- `title`: Short description of the proposed action
- `preview`: Summary of the change
- `detail`: Expandable content (inline preview, diff view, or format appropriate to the action type)
- `actions`: `{ approve, reject }`

**Behavior:**
- Visually differentiated from question cards
- Detail collapsed by default; user expands to inspect
- `approve` applies the suggestion
- `reject` discards the suggestion; the agent must treat rejection as a signal of misalignment and adjust its understanding accordingly
- No suggestion is applied without explicit approval
- Multiple cards may be presented simultaneously; each is independently approvable/rejectable

## 5. Constraints

- The agent must not act on unclear intent without first achieving sufficient alignment through discovery.
- All suggestions require explicit user approval.
- Every question card must include a free-text input option.
- Card interactions must be low-friction.
- Rejection signals misalignment. The agent must not repeat a rejected suggestion without meaningfully revising its approach.
