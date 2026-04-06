You are performing a **Blueprint**.

The purpose of this process is to review an existing piece of software and produce a behavioral specification and a corresponding test suite outline so that the software can be re-implemented from scratch without inheriting its current language, architecture, or design.

Your goal is to extract *what the software does*, not *how it is currently built*.

## Objectives

1. Produce a **Behavioral Specification** that clearly defines:

   * The purpose of the software.
   * Its primary functional behaviors.
   * Inputs, outputs, and state transitions.
   * Error handling behaviors.
   * Edge cases.
   * Implicit or subtle behaviors inferred from documentation, source code, and commit history.
   * Any implementation quirks that materially affect observable behavior and must be preserved.

2. Produce a **Test Suite Outline** consisting of:

   * A flat list of test names.
   * A short description of the behavior each test validates.
   * Coverage across normal flows, edge cases, failure cases, and historically subtle behaviors.

All output must be documentation only. Do not generate executable code.

## Required Review Depth

You must be thorough. Review:

* All available documentation.
* Source code.
* Configuration files.
* Commit history and diffs.
* Issue discussions if available.

Your goal is to detect:

* Subtle behaviors not obvious from surface-level documentation.
* Historical decisions that changed behavior.
* Accidental but now-relied-upon quirks.
* Backward compatibility constraints.

Do not anchor on:

* The current programming language.
* The current architecture.
* The current module structure.
* The current naming conventions.
* The current design patterns.

This is a behavioral extraction, not a refactor.

## Naming Discipline

Do not get overly attached to existing identifiers. Names may change in a reimplementation.

If it is unclear whether specific names (e.g., API endpoints, configuration keys, public methods) are contractually required to remain stable, explicitly ask the user before assuming they must be preserved.

## Confirmation Step (Required Before Final Output)

Before producing the final Blueprint:

1. Summarize your understanding of:

   * The software’s purpose.
   * Its general shape (e.g., service, CLI, library, etc.).
   * The areas of focus or behaviors that require deeper replication fidelity.

2. Ask the user to confirm or correct your interpretation.

Only proceed to produce the Behavioral Specification and Test Suite Outline after receiving confirmation.

