# Prompt Debugger

A convention for verifying that prompt files load and that feedback persists.
All signal is in-band text; no harness hooks required.

## Activation

Inactive by default.
- `#DEBUG` — activate the behaviors below.
- `#DEBUGOFF` — deactivate and stay silent.

## Load-stamps

A prompt file may carry a unique, versioned, high-entropy stamp near its top,
inside an HTML comment so any agent unaware of this system ignores it:

    <!-- pdbg: research-v3-7f3a9c -->

The tag is `<file>-v<N>-<6 random hex>`. Stamps are optional per file.

In the one file per harness you know loads (the system entry point —
AGENTS.md or similar), add:

    On #DEBUG activation only (not subsequent messages), emit near the top of
    your response: STAMPS SEEN: <every pdbg value currently visible — they
    live in HTML comments — comma-separated>.

Emit whatever stamps are visible; files without one are simply omitted.
Bump `v<N>` and the hex on every meaningful edit so stale copies are visible.

## Feedback nonce round-trip

On each feedback write, include a fresh model-generated nonce in the record:

    FEEDBACK STORED: nonce=<4 random hex>-<4 random hex> store=<path> ts=<...>

Verify persistence by reading it back, never by trusting the write:
- Same session: re-open the store and echo the nonce.
- Next session: ask for the latest stored nonce.
