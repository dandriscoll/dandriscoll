# Test Philosophy

This document defines the philosophical foundation for what constitutes acceptable testing. It is intended to guide critical evaluation of test adequacy, not to prescribe tools, workflows, or implementation.

---

## Core Premise

The existence of tests is not evidence of anything. Tests that exist but do not cover the right behaviors are false security. Tests that cover the right behaviors but cannot run are lies. Tests that can run but do not run in real workflows are dead weight. Only tests that cover the right things, can run, and do run provide any guarantee about system correctness.

A test suite must be evaluated at every level of this hierarchy. Failure at any level negates all levels below it.

---

## Principles

### Level 1: Existence Is Not Evidence

1. The presence of test files, test cases, or test infrastructure does not constitute evidence of adequacy. A well-structured or comprehensive-looking test suite is not evidence of correctness. Only demonstrable validation of the behaviors that matter constitutes evidence.

2. A behavior is not known to be correct unless it is actively validated by a test that exercises that behavior and asserts on its outcome. Code that is "covered" by a test that does not assert on the relevant behavior is not validated.

3. No single test category — unit tests, integration tests, end-to-end tests, or any other — can establish adequacy on its own, regardless of how thorough it is within that category. Unit tests with 100% code coverage that mock all dependencies provide no assurance that the system works when assembled. A test suite that consists of only one category of test is inherently inadequate.

### Level 2: Coverage Must Be Real

4. Coverage is not a single number. It is the intersection of multiple independent dimensions, each of which represents a distinct axis of risk:

    - **Scenario coverage.** Are all meaningful behaviors validated — not just happy paths, but error handling, failure modes, and recovery?
    - **Edge case and boundary coverage.** Are boundary values, empty inputs, maximums, and transition points exercised?
    - **Negative case coverage.** Is the system tested for correct rejection of invalid inputs, unauthorized access, and violated preconditions?
    - **State transition coverage.** Are all valid state changes, invalid transitions, and interrupted transitions tested?
    - **Topology coverage.** Is the system tested across the environments where it must actually work — local, CI, staging, production-like?
    - **End-to-end experience coverage.** Are complete user workflows validated through the real, assembled system with no mocks?

    A high ratio in one dimension does not compensate for absence in another. Each dimension represents a distinct category of defect that the others cannot detect.

5. Each test result is a truth claim. A **pass** asserts that the intended behavior has been validated. A **fail** asserts that the intended behavior is not satisfied. A **skip** asserts that the test could not validly execute. The correctness of these assertions must itself be evaluated. A passing test that does not actually validate its stated intent is a false claim, not evidence of correctness.

6. Deterministic test cases may only produce three outcomes: pass, fail, or skip. No other state is meaningful. A skipped test must be evaluated on whether the decision to skip is correct and whether the skip accurately represents the test's status. An incorrect or misrepresented skip is itself a gap.

### Level 3: Tests Must Be Runnable

7. A test that cannot execute in its intended environment is not a test. It is an aspiration. Test adequacy requires that the infrastructure, data, mocks, fixtures, and environment configuration necessary for each test to execute are in place and functional.

8. Test environments exist in distinct topologies: **mocked**, **fully local**, **hybrid** (local and remote), and **fully remote**. A test pass validates only the environment topology in which it executes. No assumptions may be made about other topologies.

9. Data handling within tests must fall into one of the following categories:

    - **Immutable data** — no mutation occurs.
    - **Resettable data** — mutation is allowed, but a reliable mechanism exists to restore state both automatically and manually.

    Data setup may be required and may be shared across tests, but must conform to the same categories.

10. Mocks and fake data narrow the scope of validation in exchange for control, speed, or isolation. The question is not whether substitution is present, but whether what is lost in scope is acceptable given what is gained. This principle does not discourage mocks. It requires that the tradeoff be explicitly understood and justified.

### Level 4: Tests Must Actually Run

11. A test that can run but does not run in any real workflow provides no value. Tests must be wired into the workflows where they matter: CI pipelines, pre-commit hooks, deployment gates, or manual checkpoints in the development process.

12. The design of workflows — development, testing, deployment, or otherwise — inherently defines what is validated. A test that exists outside every workflow is equivalent to a test that does not exist, because no process ensures it executes.

13. A test must be possible to run, easy to run, and mandated to run. **Possible** means the infrastructure and dependencies are in place. **Easy** means a developer or CI system can execute it without heroics — complex manual setup, fragile environment configuration, or undocumented prerequisites make a test effectively unrunnable. **Mandated** means some workflow requires its execution as a gate or checkpoint, so it cannot be silently skipped.

14. A test pass validates only the workflow in which it executes. If end-to-end tests exist but are not included in the CI pipeline, they do not gate deployments. If integration tests require a local database that CI does not provision, they do not run in CI. The assessment must evaluate not just what tests exist, but where each test actually runs.

### Tradeoffs and Limits

15. Every test validates some behaviors and is inherently unable to validate others. The assessor must evaluate both what a test proves and what it can never prove, and whether that tradeoff is acceptable.

16. Structural layering of tests (unit, integration, end-to-end) is an implementation strategy. Each layer offers different efficiencies and different limitations on what it can validate. The question is not whether layers exist, but whether the total validated behavior across all layers is sufficient.

17. The acceptability of overlap, redundancy, or independence between tests is not predefined. It is only knowable in the context of the full test suite and the behaviors it must validate.

### Test Design

18. Each test case must be cohesive and reflect a single, clear behavior that requires validation.

19. Each test case must have a clearly stated purpose, expressed directly in the test case name. Additional context may be provided in comments only where the name alone is insufficient.

### Gaps

20. Any regression not caught by tests is direct evidence of a gap in validated behavior.

21. Gaps in testing may also be identified through inspection, but such inspection must be methodical and grounded in defined rules or procedures. The goal of inspection is to surface what is not validated and to evaluate whether that absence is acceptable.

22. Three distinct categories of gap must be distinguished:

    - A required behavior has **no test at all**.
    - A test exists but **is not runnable or is not run** in the relevant workflow (the test exists but provides no actual validation).
    - A test **cannot exist** because no available topology supports the required validation (a structural capability gap).

    The distinction between these categories is the most actionable finding an assessment can produce.

### Scope of This Document

23. This document defines philosophy only. It does not prescribe specific workflows, tools, or implementation steps.
