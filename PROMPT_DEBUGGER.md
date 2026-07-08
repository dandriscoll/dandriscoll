# Prompt Debugger

A convention for verifying that prompt files load and that feedback persists.
All signal is in-band text; no harness hooks required.

## Activation

Inactive by default.
- `^PDBG` — activate the behaviors below.
- `^PDBGOFF` — deactivate and stay silent.

## Load-stamps

A prompt file may carry a unique, versioned, high-entropy stamp near its top,
inside an HTML comment so any agent unaware of this system ignores it:

    <!-- pdbg: research-v3-7f3a9c -->

The tag is `<file>-v<N>-<6 random hex>`. Stamps are optional per file.

In the one file per harness you know loads (the system entry point,
AGENTS.md or similar), add:

    On ^PDBG activation only (not subsequent messages), emit near the top of
    your response a STATUS report of anything you know but have not already
    surfaced this session, each on its own line:
    - STAMPS SEEN: <every pdbg value currently visible; they live in HTML
      comments; comma-separated>.
    - FEEDBACK WRITTEN: <number of feedback records you wrote this session>.
      Report the count only, never the individual records.
    - Any other loaded state worth noting (stores or documents opened, active
      mode, pending tasks): one short line each, or omit the line if none.

Emit whatever is known; lines with nothing to report are simply omitted.
Bump `v<N>` and the hex on every meaningful edit so stale copies are visible.

## Feedback nonce round-trip

On each feedback write, include a fresh model-generated nonce in the record:

    FEEDBACK STORED: nonce=<4 random hex>-<4 random hex> store=<path> ts=<...>

Verify persistence by reading it back, never by trusting the write:
- Same session: re-open the store and echo the nonce.
- Next session: ask for the latest stored nonce.

## Wiring it into a harness

The stamps and behaviors above are inert until one file the harness always
loads carries the activation instruction and points here. To turn it on:

1. **Add the activation snippet to a loaded entry point** (`AGENTS.md`, a
   global instructions file, or whatever your harness reads on every session).
   Keep it short: name the verbs, state the one-time STATUS behavior, and link
   back to this guide for the full convention. For example:

        ## Prompt debugger

        `^PDBG` activates prompt-load diagnostics; `^PDBGOFF` deactivates and
        stays silent. On activation only, emit a one-time STATUS report near
        the top of your reply: the `pdbg` load-stamps visible in context, a
        count (not a list) of feedback records written this session, and any
        other loaded state not yet surfaced. Full convention:
        [`PROMPT_DEBUGGER.md`](<path\to\PROMPT_DEBUGGER.md>).

2. **Stamp the files you want to verify.** Add a `pdbg` load-stamp near the top
   of each prompt file whose loading you want to confirm (see Load-stamps
   above). Stamps are optional per file; a file with no stamp is simply absent
   from the STATUS report.

The snippet lives in the harness; the convention lives here. Point the snippet
at this file with an absolute path so the link resolves from wherever the entry
point sits.
