# Test Assessment Framework

## 1. Purpose and Scope

This document defines a standardized framework for assessing the comprehensiveness and quality of test suites across a product suite. It provides uniform criteria, definitions, and evaluation standards that allow an assessor to determine what is tested, what is not tested, how thoroughly tested components are validated, and where tests fail to fulfill their intended purpose.

This framework is evaluative. It defines how to judge the state of testing. It does not prescribe how teams should write, organize, or improve tests. It does not define review processes or remediation workflows.

The intended audience is any agent, reviewer, or auditor tasked with assessing the adequacy of a test suite against the code it is meant to validate.

---

## 2. Definitions and Terminology

**Assertion.** A statement within a test that evaluates whether an observed outcome matches an expected outcome. An assertion is the mechanism by which a test renders a verdict.

**Dependency.** Any object, service, schema, data store, or configuration that a test requires but does not create and manage entirely within its own execution scope. A dependency exists when setup must occur outside the test execution itself.

**External dependency.** A dependency that requires network connectivity off the local machine. A local container or local process that the test runner can start, control, and terminate is not an external dependency. The defining criterion is whether the test runner controls the full lifecycle of the dependency.

**Mock.** A substitute for a real dependency that simulates its behavior within a test. Mocks allow a test to execute without requiring the real dependency to be present or operational.

**Test subject.** The specific function, method, class, module, component, or workflow that a test is designed to validate.

**Test boundary.** The perimeter around the test subject that defines what is real and what is simulated within a given test. The boundary determines the test's category.

**Testable surface area.** The set of all behaviors, conditions, paths, and states within a body of code that warrant test validation. This is an assessed property, not an intrinsic measurement.

**Completeness definition.** A statement of what full coverage looks like for a given coverage dimension applied to a given test category in a given context. The completeness definition is the denominator in coverage ratio calculations. It is a definition, not a measurement.

**Total possible scope.** The union of completeness definitions across all applicable coverage dimensions for a given unit of evaluation. Represents the full testable surface area as determined by the assessor.

**False positive (test).** A test that passes when the system under test is in a faulty state. The test reports success despite the presence of a defect it should detect.

**False negative (test).** A test that fails due to causes unrelated to the behavior it is designed to validate. The test reports failure despite the system under test being correct.

**Determinism.** The property of a test that produces identical results across repeated executions given identical code, without dependence on timing, ordering, environmental state, or external systems.

**Coverage ratio.** The proportion of scenarios within a completeness definition that have corresponding tests with meaningful assertions. Expressed as tested scenarios divided by total scenarios in the completeness definition.

**Experience.** A distinct user-facing product surface through which users interact with the system. Each experience has its own runtime, dependency chain, and deployment artifact. Examples: a mobile app (React Native on device), a web app (SPA in a browser), an admin portal (separate SPA), a CLI tool, a public API consumed by third parties. Two experiences that serve the same user goal (e.g., "sign in") are distinct if they execute different code paths through different runtimes. The experience is the top-level organizing unit for scenario enumeration (Section 4.1.3.1).

**Intermediate document.** A structured artifact produced by the assessor during evaluation that records findings, reasoning, and conclusions at a specific phase of the assessment process. Intermediate documents make the assessment auditable and provide the basis for final conclusions.

---

## 3. Standardized Test Categories

Tests are classified by their degree of mocking. This is the primary classification axis. The mocking profile of a test—how many of its dependencies are real versus simulated—determines the category.

### 3.1 Unit Tests

All dependencies are mocked. A unit test validates a single function, method, or class in complete isolation from every external concern. The test must be runnable in an IDE with no external process, service, or container. It must not require network access, a running database, or filesystem state not created by the test itself.

**Qualifies as a unit test:** A test that calls a function with mocked dependencies injected and asserts on the return value or observable side effects, where no real dependency participates in execution.

**Does not qualify as a unit test:** A test that requires a running database (even a local one), makes HTTP calls to any service (even a local mock server managed outside the test), or reads from filesystem paths not created within the test's own setup.

### 3.2 Integration Tests

Some dependencies are mocked; some are real. An integration test validates a slice of the system where components interact with at least one real dependency. Integration tests exist as a necessary compromise when end-to-end testing is prohibitively slow, complex, or fragile for validating specific interaction paths.

An integration test must include at least one real dependency whose lifecycle the test runner controls. It must not require network access to systems outside the local machine.

**Qualifies as an integration test:** A test that exercises a service layer against a real local database started by the test runner, with external API clients mocked. A test that validates message serialization and deserialization across two real components with a mocked message broker.

**Does not qualify as an integration test:** A test where all dependencies are mocked (that is a unit test). A test that requires connectivity to a staging environment or third-party API (that has external dependencies and must be evaluated accordingly).

### 3.3 End-to-End Tests

No dependencies are mocked. An end-to-end test validates complete user-facing workflows through the full real stack. It must exercise the system as a user would. No component in the execution path is mocked, stubbed, or simulated.

An end-to-end test must not require external network access to systems whose lifecycle the test runner does not control. If the test requires the entire stack to be running, the test runner or test infrastructure must manage that stack.

**Qualifies as an end-to-end test:** A test that drives a browser against a locally running application with a real database, real backend services, and real message queues, all managed by the test infrastructure.

**Does not qualify as an end-to-end test:** A test that mocks the database layer while exercising the rest of the stack (that is an integration test). A test that calls a staging API not controlled by the test runner (that has uncontrolled external dependencies).

**Unique defect detection role.** End-to-end tests are the only test category that reliably detects cross-component contract failures—defects that arise when two or more components hold independent, incompatible assumptions about their shared interface. When components are tested in isolation (via unit tests) or against mocked interfaces (via contract tests), each side's mocks encode that side's assumptions. If both sides independently misunderstand the contract—for example, one component sends a token lifetime in seconds while the consuming component interprets the same field as minutes—unit and contract tests on both sides will pass because each side's mocks confirm its own assumptions. Only an end-to-end test, which exercises both components through their real interface without mocks, will expose the mismatch. This class of defect is invisible to any test category that substitutes mocks for the real cross-component interaction.

### 3.4 Contract Tests

Contract tests validate that interfaces between services conform to agreed-upon schemas or API specifications. A contract test must validate against an explicit contract definition—an OpenAPI specification, a Protobuf schema, a Pact file, or equivalent formal artifact. It must be runnable by either the producer or consumer independently.

Contract tests are orthogonal to the mocking-profile axis. A contract test may internally operate as a unit test (mocking everything except the interface layer), an integration test (using a real service with some mocks), or an end-to-end test (validating the contract through the live system). The mocking profile is noted but the primary classification is by purpose.

### 3.5 Performance and Load Tests

Performance and load tests validate system behavior under stress against defined, measurable thresholds. These tests assert on quantitative metrics: response time percentiles, throughput rates, error rates under load, resource utilization ceilings, or degradation curves.

Performance tests are orthogonal to the mocking-profile axis. A performance test may exercise a single component in isolation, a subset of the system, or the full stack. The mocking profile is noted but the primary classification is by purpose.

### 3.6 Smoke and Sanity Tests

Smoke tests validate that critical paths function at a baseline level, typically executed post-deployment as a gate check. A smoke test confirms operational viability—the system starts, core endpoints respond, critical workflows complete—without attempting exhaustive validation.

Smoke tests are orthogonal to the mocking-profile axis. They typically operate at the end-to-end level but may operate at any level. The mocking profile is noted but the primary classification is by purpose.

### 3.7 Mandatory Test Category Requirements

Certain classes of scenario require end-to-end tests as a matter of framework rule, not assessor judgment. For these scenarios, unit tests, integration tests, and contract tests—regardless of their quality or quantity—cannot substitute for an end-to-end test that exercises the real integrated system with no mocks. The rationale is structural: mocked tests encode each side's assumptions independently and cannot detect mismatches between those assumptions (see Section 3.3, "Unique defect detection role").

The following three rules are mandatory. Scenarios that fall under any of these rules must have at least one end-to-end test. Their absence is classified as a Critical severity gap (Section 9.4) regardless of coverage achieved at other test category levels.

**Rule 1: Cross-component user workflows require E2E tests.** Any scenario where a user action traverses multiple components—a client calling an API, a frontend submitting a form processed by a backend, a mobile app exchanging tokens with an auth service—must have at least one end-to-end test with no mocks. Unit tests that mock the API response and contract tests that validate response shape independently do not substitute. Each side's mocks encode that side's assumptions separately; only an end-to-end test exercises the real interface and can detect contract mismatches between components.

**Rule 2: Incident-linked scenarios require E2E tests.** Any scenario that is tagged as originating from a production incident, a pre-production environment (PPE) incident, or a post-mortem finding must have an end-to-end test that reproduces the conditions under which the incident occurred. Production and PPE incidents are by definition failures of the integrated system—they occurred despite whatever unit, integration, and contract tests existed at the time. A test that mocks the components involved in the incident cannot verify that the integrated fix works, because the incident itself demonstrated that the components' independent assumptions were wrong. The E2E test must exercise the same cross-component path that failed in production.

**Rule 3: Authentication and authorization flows require E2E tests.** Login, signup, token refresh, session management, and privilege escalation workflows are both cross-component (spanning client, API, and identity provider) and security-critical. These workflows must have end-to-end tests exercising the full path from user input to authenticated/authorized state. The security sensitivity of these flows means that a contract mismatch—such as a token lifetime field interpreted differently by producer and consumer—has outsized impact, and the cross-component nature means mocked tests on either side cannot detect it.

When the assessor evaluates scenarios in the Scope Definition Document, each scenario must be checked against these three rules. If a scenario matches any rule, the assessor must record the applicable rule and verify that a corresponding end-to-end test exists. The Test Category Coverage Plan (Section 4.1.5, item 5) must explicitly identify all scenarios subject to mandatory rules and confirm the presence or absence of the required end-to-end tests.

### 3.8 Classification Decision Procedure

When classifying a test, the assessor applies the following procedure:

1. **Determine the mocking profile.** Identify every dependency of the test subject. For each dependency, determine whether it is mocked or real within the test. All mocked = unit. Some real, some mocked = integration. None mocked = end-to-end.

2. **Check for orthogonal purpose.** If the test validates an interface contract against a formal specification, classify it as a contract test. If the test validates behavior against quantitative performance thresholds, classify it as a performance test. If the test validates baseline operational viability as a deployment gate, classify it as a smoke test.

3. **Record both classifications when applicable.** A test may be both a contract test and an integration test. In such cases, record both: the mocking-profile category and the purpose category. Assessment against coverage dimensions uses the appropriate column from the Canonical Completeness Definition Matrix based on the primary purpose served.

4. **Verify mandatory category requirements.** After classification, check every scenario subject to the mandatory rules in Section 3.7 against the classified test inventory. A scenario that is covered by unit and contract tests but requires an end-to-end test under Section 3.7 is not adequately covered until the required end-to-end test exists. Record any scenario where the mandatory test category is absent—this is a Critical severity gap regardless of coverage at other levels.

---

## 4. Coverage Assessment

Coverage is assessed in two phases. First, the assessor determines what must be tested—the total possible scope. Second, the assessor measures what proportion of that scope is actually tested. Coverage is not a single number. It is a set of ratios, one per coverage dimension, each computed against a defined denominator.

### 4.1 Determining Total Possible Scope

The total possible scope is the full set of behaviors, conditions, paths, and states that warrant test validation for a given body of code. The assessor determines this scope by analyzing three inputs.

#### 4.1.1 Requirements-Informed Scope

Where formal requirements, specifications, acceptance criteria, or documented expectations exist, they are the primary input for identifying testable behaviors. Each stated requirement implies one or more testable scenarios: the system must do X when given Y, the system must reject Z, the system must transition from state A to state B under condition C.

Where formal requirements do not exist—or are incomplete—the assessor infers intended behavior from the code's apparent purpose, its naming, its documentation (including inline comments), its position within the system architecture, and its callers and consumers. The assessor records these inferences explicitly in the Scope Definition Document.

#### 4.1.2 Environment-Informed Scope

The system's operating context introduces testable behaviors that may not appear in requirements. These include:

- Failure modes inherent to external dependencies (database unavailability, network timeouts, malformed responses from upstream services).
- Configuration variability (different deployment environments, feature flags, locale settings).
- Platform constraints (filesystem permissions, memory limits, concurrency characteristics).
- Deployment topology concerns (service discovery failures, load balancer behavior, container lifecycle events).

The assessor identifies which environmental factors are relevant to the code under evaluation and includes the corresponding scenarios in the total possible scope.

#### 4.1.3 Code-Informed Scope

Analysis of the code itself reveals testable surface area that neither requirements nor environment documentation may capture. The assessor examines:

- **Branching logic.** Every conditional path implies at least two testable scenarios (the condition is true; the condition is false). Compound conditions multiply the scenario count.
- **Error handling paths.** Every catch block, error return, fallback, or retry mechanism implies a scenario where that path is exercised.
- **State transitions.** Every mutation of state implies testable scenarios for valid transitions and for rejection of invalid transitions.
- **Public interfaces.** Every public method, endpoint, or exported function implies testable scenarios for its documented and inferable contracts.
- **Data transformations.** Every transformation of input data to output data implies testable scenarios for correctness of the transformation.
- **Boundary conditions.** Every parameter with a constrained domain implies testable scenarios at the boundaries of that domain (minimum, maximum, zero, empty, null, overflow).
- **Implicit contracts.** Behavior that callers depend on but that is not formally documented—ordering guarantees, idempotency, thread safety—constitutes testable surface area if the code's consumers rely on it.

#### 4.1.3.1 Experience-Based Scenario Organization

When a product has multiple user-facing surfaces—a mobile app, a web app, an admin portal, a CLI, a public API—each surface constitutes a distinct **experience** (Section 2). The scenario list must be organized by experience as the top-level grouping, not by component, feature, or user goal alone.

The same user goal manifests as separate scenarios in each experience when the underlying code paths differ. "User signs in" on a mobile app (native keychain storage via a platform bridge) and "user signs in" on a web app (browser cookies via fetch) are two distinct scenarios with different runtimes, different dependencies, and different failure modes. A test that validates sign-in through the web app does not cover sign-in through the mobile app—they share a goal but execute entirely different code.

**Identifying experiences.** During scope determination, the assessor must identify every distinct experience the product offers. An experience is distinct if it has its own runtime environment (e.g., React Native on a device vs. a Vite SPA in a browser), its own deployment artifact, or its own dependency chain for a given user workflow. The assessor records the list of identified experiences in the Scope Definition Document.

**Filing scenarios under experiences.** Every user-facing scenario must be filed under exactly one experience. If a user goal (e.g., "sign in," "create account," "upload media") is available through multiple experiences, it appears as a separate scenario entry under each experience. Each entry must record the experience-specific code path that implements that goal. A scenario filed under one experience cannot satisfy coverage for another experience.

**E2E test targets per experience.** Each identified experience implies its own E2E test target—a runtime environment in which end-to-end tests for that experience execute. A mobile app experience requires a mobile test runner (e.g., Detox, Maestro, or Expo web). A web app experience requires a browser automation tool (e.g., Playwright, Cypress). An admin portal with a separate SPA requires its own browser automation project. The E2E test infrastructure must include a test target for every identified experience; an experience with no E2E test target has zero E2E coverage by construction.

**Non-user-facing components.** Components that are not directly user-facing (shared libraries, internal services, database layers) do not have their own experience. Their scenarios are organized by component as before. Experience-based organization applies only to the user-facing surface through which workflows are exercised.

#### 4.1.4 Principles for Scope Determination

Scope determination involves judgment. The assessor applies the following principles to maintain consistency:

**Err toward inclusion.** When a behavior carries meaningful risk of failure—where a defect would cause user-visible harm, data corruption, security exposure, or system instability—include it in scope. The cost of testing a scenario that turns out to be trivial is low; the cost of missing a scenario that harbors a defect is high.

**Exclude the trivially correct.** Simple property accessors (getters/setters) with no logic, purely declarative configuration with no conditional behavior, and mechanically generated code (e.g., ORM-generated boilerplate with no custom logic) may be excluded from scope. The assessor records exclusions and their rationale.

**Exclude framework guarantees.** Behavior guaranteed by the framework or language runtime—such as type enforcement in a statically typed language, or HTTP routing in a well-tested framework—need not be re-validated unless the code under test customizes or overrides that behavior.

**Derive scope independently of existing tests.** The total possible scope must be determined from requirements, environment, and code analysis—not from the structure or categories of tests that already exist. If the existing test suite contains only unit tests, this must not lead the assessor to define scope only in terms of unit-testable scenarios. The assessor must evaluate the full scenario space across all test categories defined in Section 3—unit, integration, end-to-end, contract, and any other applicable category—as part of a single, unified scope determination. The absence of an entire test category in the current suite is itself a finding, not a boundary on the assessment. Begin by enumerating what the system needs validated at every level, then assess what exists against that enumeration. Never use existing test files, directory structures, or test runner configurations as the starting point for scope. Start from the product's behaviors and work outward to what tests must exist.

**Apply mandatory test category requirements.** Section 3.7 defines three classes of scenario that require end-to-end tests as a matter of framework rule: cross-component user workflows, incident-linked scenarios, and authentication/authorization flows. When the assessor identifies scenarios subject to these rules during scope determination, the scenarios must be flagged as requiring E2E tests in the Scope Definition Document. Unit tests and contract tests with mocks cannot substitute for end-to-end tests for these scenarios, because mocked tests validate each component's assumptions in isolation and cannot detect the class of cross-component contract failures described in Section 3.3. If a feature's Scope Definition Document identifies scenarios subject to mandatory rules and the test suite contains no end-to-end tests for those scenarios, the feature cannot be classified as Fully Covered regardless of the coverage ratios achieved by unit, integration, or contract tests alone.

**Record everything.** Every inclusion and exclusion decision is recorded in the Scope Definition Document with sufficient reasoning for another assessor to evaluate the judgment.

#### 4.1.5 Required Intermediate Document: Scope Definition Document

The assessor must produce a **Scope Definition Document** for each component under evaluation before proceeding to coverage measurement. This document contains:

1. **Component identification.** The name, location, and boundaries of the component under assessment.
2. **Experience inventory.** A list of every distinct user-facing experience identified for this product (Section 4.1.3.1). For each experience, record the runtime environment, deployment artifact, and the E2E test target (or an explicit statement that no E2E test target exists, which constitutes a finding). Non-user-facing components note "N/A — not a user-facing experience."
3. **Requirements inventory.** A list of all requirements, specifications, or acceptance criteria consulted, or an explicit statement that none exist with a description of how intended behavior was inferred.
4. **Environmental factors.** A list of environmental concerns identified as relevant to this component.
5. **Testable scenario enumeration.** For each coverage dimension (Section 4.2), a list of every concrete testable scenario identified. For user-facing scenarios, the list must be organized by experience as the top-level grouping (Section 4.1.3.1): each scenario is filed under exactly one experience, and a user goal available through multiple experiences appears as a separate entry under each. Each entry must record the experience-specific code path. Each scenario is a single, specific, verifiable behavior (e.g., "mobile app: user signs in via react-native-keychain → native bridge → OS keychain" rather than "user signs in").
6. **Test category coverage plan.** For each test category defined in Section 3 (unit, integration, end-to-end, contract, performance, smoke), a determination of whether that category is applicable to the component under evaluation and what scenarios it must address. If a category is not applicable, the rationale must be recorded. For E2E tests, the plan must confirm that an E2E test target exists for each identified experience; an experience with no E2E test target has zero E2E coverage by construction. This enumeration must be derived from the component's architecture and user-facing behavior, not from what test categories happen to exist in the current codebase. The absence of end-to-end tests, integration tests, or any other category in the existing suite does not exempt the assessor from evaluating whether that category is needed.
7. **Exclusions.** A list of behaviors or code paths explicitly excluded from scope with the rationale for each exclusion.
8. **Source attribution.** For each scenario, an indication of whether it was derived from requirements, environment analysis, or code analysis.

This document is the foundation for all subsequent evaluation. Coverage ratios cannot be computed without it.

### 4.2 Coverage Dimensions

Every test suite is assessed against five independent dimensions. A high ratio in one dimension does not compensate for absence in another. Each dimension represents a distinct axis of validation, and gaps in any single dimension represent a distinct category of risk.

#### 4.2.1 Functional / Behavioral Coverage

Validates whether the test confirms correct outputs for defined inputs. This is the most fundamental dimension: does the code do what it is supposed to do under normal operating conditions?

Functional coverage addresses the primary purpose of the code—its core transformations, decisions, and outputs when given valid, expected inputs within its designed operating parameters.

#### 4.2.2 Edge Case / Boundary Coverage

Validates whether the test exercises boundary conditions and unusual but valid inputs. Boundary values are the points at which behavior is most likely to change or break: the minimum and maximum of a valid range, the transition between one behavioral regime and another, empty collections, single-element collections, maximum-length strings, zero, negative numbers where positive are expected, and similar threshold values.

Edge case coverage is distinct from negative case coverage. Edge cases are valid inputs that happen to sit at the margins of the input domain. They should produce correct results, not errors.

#### 4.2.3 Negative / Failure Case Coverage

Validates whether the test confirms correct handling of invalid inputs, errors, and intentional misuse. Negative cases are inputs or conditions that the code must reject, handle gracefully, or respond to with appropriate error signaling.

This dimension covers: invalid input values, unauthorized access attempts, malformed data, out-of-sequence operations, violated preconditions, and any scenario where the code must say "no" or "that's wrong" rather than producing a successful result.

#### 4.2.4 Error Handling Coverage

Validates whether the test confirms that system-level failures are caught, propagated, logged, or surfaced correctly. Error handling coverage is distinct from negative case coverage. Negative cases are about invalid inputs the code should reject. Error handling is about failures that arise from the environment or from dependencies: a database connection drops, an HTTP request times out, a file cannot be read, memory allocation fails, a downstream service returns an unexpected status.

This dimension validates that the code's error handling machinery—try/catch blocks, error callbacks, circuit breakers, retry logic, fallback paths—functions as designed when failures occur.

#### 4.2.5 State Transition Coverage

Validates whether the test confirms correct movement between states and rejection of invalid transitions. Any code that maintains state—whether in a local variable, a database record, a session, a workflow engine, or a UI component—has testable state transition behavior.

This dimension covers: all valid state transitions (A → B under condition X), rejection of invalid transitions (A → C is not permitted), behavior at terminal states, behavior when transitions are attempted out of sequence, and consistency of state after interrupted or partially completed transitions.

### 4.3 Canonical Completeness Definition Matrix

The following matrix is the core reference for determining what "complete" means for each combination of test category and coverage dimension. When assessing a test or test suite, the assessor identifies the test's category (column) and evaluates it against each coverage dimension (row). The cell defines the completeness standard for that combination.

| Dimension | Unit | Integration | End-to-End | Contract |
|---|---|---|---|---|
| **Functional / Behavioral** | All defined input-output mappings for the function | All interaction paths between real components | All user-facing scenarios and workflows | All defined interface operations and response shapes |
| **Edge Case / Boundary** | All parameters exercised at boundary values | Boundary conditions at component interfaces | Boundary conditions at user input surfaces | Schema boundary values (min/max lengths, nullable fields, type limits) |
| **Negative / Failure Case** | All invalid input combinations and expected error responses | Failure modes at each real dependency (timeouts, rejections, malformed responses) | User-facing error paths and recovery flows | Invalid payloads and expected rejection behavior |
| **Error Handling** | All catch/throw paths exercised with correct propagation | Error propagation across component boundaries | Errors surfaced correctly to the user with appropriate messaging | Error response schemas conform to contract |
| **State Transition** | All valid and invalid state transitions for stateful functions | State consistency across interacting components | Complete workflow state progressions including interruption and resumption | Stateful protocol sequences (e.g., auth flows, pagination) |

For performance and smoke tests, completeness definitions are derived from the specific thresholds or critical paths those tests are designed to validate, rather than from this matrix.

### 4.4 Measuring Coverage Ratio

Coverage is expressed as a ratio per dimension per unit of evaluation:

```
coverage ratio = tested scenarios / completeness definition
```

The **completeness definition** (denominator) is the count of concrete scenarios enumerated in the Scope Definition Document for the relevant dimension. The **tested scenarios** (numerator) is the count of those scenarios that have corresponding tests with meaningful assertions, subject to the quality criteria in Section 6.

#### 4.4.1 Counting Rules

**One test, multiple scenarios.** A single test may cover more than one scenario from the completeness definition. Each covered scenario counts independently toward the numerator. However, the assessor must verify that the test contains assertions that actually validate each claimed scenario, not merely that it executes code paths that happen to touch multiple scenarios.

**Partial validation.** If a test exercises a scenario but its assertions do not fully validate the expected outcome—for example, it checks that a function returns a list but does not validate the list's contents—the scenario is counted as partially covered. Partially covered scenarios count as 0.5 toward the numerator. The assessor records the deficiency in the Coverage Mapping Document.

**Quality-excluded tests.** A test that fails the quality criteria defined in Section 6—for instance, a test with no meaningful assertions, or a test that is non-deterministic—does not count toward the numerator for any scenario it nominally covers. The assessor records the exclusion and the reason in the Coverage Mapping Document.

**Redundant tests.** Multiple tests that cover the same scenario do not increase the numerator beyond 1 for that scenario. Redundancy does not improve coverage. Only breadth across the completeness definition contributes to the ratio.

#### 4.4.2 Required Intermediate Document: Coverage Mapping Document

The assessor must produce a **Coverage Mapping Document** for each component under evaluation. This document contains:

1. **Dimension-by-dimension mapping.** For each coverage dimension, a table or list that maps each scenario from the Scope Definition Document to the specific test(s) that cover it, or explicitly records that no corresponding test exists.
2. **Quality-adjusted status.** For each mapped test, a notation of whether it meets quality thresholds (Section 6). Tests that fail quality thresholds are flagged, and the scenario is marked as not effectively covered.
3. **Partial coverage annotations.** Where a test partially validates a scenario, the assessor records what is validated and what is missing.
4. **Computed ratios.** The coverage ratio for each dimension, computed per the counting rules above.
5. **Assessor reasoning.** Where mapping is ambiguous—where it is unclear whether a test truly covers a given scenario—the assessor records the reasoning behind the judgment.

---

## 5. Comprehensiveness Classification

Each unit of evaluation (function, module, feature, endpoint) is assigned a comprehensiveness tier based on the coverage ratios computed in Section 4.4. Classification is applied per unit, not to the test suite as a whole.

### 5.1 Fully Covered

A unit is classified as **Fully Covered** when all of the following conditions are met:

1. The coverage ratio equals 1.0 across every applicable coverage dimension. Every scenario in the completeness definition has a corresponding test with meaningful assertions that meets quality thresholds.
2. No coverage dimension has a ratio of zero.
3. All tests contributing to coverage meet the quality criteria defined in Section 6.
4. The Scope Definition Document has been produced and no material gaps in scope determination have been identified.

Fully Covered does not mean "every conceivable scenario is tested." It means every scenario the assessor identified as warranting validation in the Scope Definition Document is validated by a test that meets quality standards.

### 5.2 Partially Covered

A unit is classified as **Partially Covered** when all of the following conditions are met:

1. At least one coverage dimension has a ratio greater than zero.
2. At least one coverage dimension has a ratio less than 1.0, or at least one test contributing to coverage fails quality thresholds.

Partial coverage exists on a spectrum. The assessor distinguishes between:

- **High partial coverage.** Most dimensions have ratios above 0.7, with gaps concentrated in edge cases or less critical scenarios. Core functional behavior is well tested.
- **Low partial coverage.** Multiple dimensions have ratios below 0.3, or the Functional / Behavioral dimension—the most fundamental—has significant gaps. Core behavior has meaningful blind spots.

When classifying a unit as Partially Covered, the assessor must document:
- Which dimensions have gaps and what the specific missing scenarios are.
- Whether the gaps are concentrated in a particular dimension or distributed across dimensions.
- The assessed risk associated with each gap (see Section 9.4).

### 5.3 Not Covered

A unit is classified as **Not Covered** when:

1. The coverage ratio is zero across all applicable dimensions. No test exists that validates any scenario in the completeness definition, OR
2. Tests exist but every one fails quality thresholds so severely that no scenario is effectively covered (e.g., all tests have no meaningful assertions).

A unit that has tests nominally associated with it but whose tests validate no scenario in the completeness definition is classified as Not Covered, not Partially Covered. The existence of a test file is not coverage.

### 5.4 Classification Matrix

The following matrix summarizes the classification criteria:

| Criterion | Fully Covered | Partially Covered | Not Covered |
|---|---|---|---|
| Coverage ratio (all dimensions) | 1.0 | >0 in at least one dimension | 0 in all dimensions |
| Any dimension at zero | Not permitted | Permitted (but cannot be Fully Covered) | All dimensions are zero |
| Quality thresholds | All contributing tests pass | At least some contributing tests pass | None pass or no tests exist |
| Scope Definition Document | Produced, no material gaps | Produced | Produced (may note absence of tests) |

---

## 6. Test Quality Criteria

Quality determines whether a test fulfills its purpose. A test that executes code but does not meaningfully validate behavior provides false assurance. The following criteria define what constitutes a high-quality test. Tests are evaluated individually against each criterion.

Quality assessment feeds directly into coverage measurement: tests that fail quality thresholds do not count toward coverage ratios (Section 4.4.1).

### 6.1 Assertion Robustness

A high-quality test contains assertions that validate meaningful expected outcomes specific to the behavior under test.

**Meets the standard:** Assertions verify that the test subject produces the correct output, modifies the correct state, calls the correct dependencies with the correct arguments, or raises the correct exception under the tested condition. Assertions are specific enough that a defect in the tested behavior would cause the assertion to fail.

**Fails the standard:** Assertions verify only that the function returned without throwing, that the result is not null, that the result is of the expected type, or other superficial properties that would remain true even if the core behavior were broken. Assertions are absent entirely.

The assessor asks: "If I introduced a subtle but meaningful defect in the behavior this test targets, would the assertions catch it?" If the answer is no, the test fails this criterion.

### 6.2 Condition Validation

A high-quality test establishes and verifies necessary preconditions, postconditions, and invariants.

**Meets the standard:** The test sets up a known initial state, exercises the test subject, and then verifies that the expected final state holds. Where applicable, the test verifies that state that should not have changed remains unchanged. Preconditions are explicit in the test setup, not assumed.

**Fails the standard:** The test relies on implicit or inherited state from previous tests or external setup. The test verifies the primary output but ignores side effects, state mutations, or invariants that the test subject is responsible for maintaining.

### 6.3 Regression Detection Capability

A high-quality test would fail if the behavior it targets were broken or altered.

**Meets the standard:** The test's assertions are tightly coupled to the specific behavior being validated, such that a change to that behavior—intentional or accidental—would cause the test to fail. The test effectively serves as a regression guard for its targeted behavior.

**Fails the standard:** The test's assertions are so loose or so peripheral to the core behavior that significant changes to the behavior would not cause the test to fail. The test would continue to pass even if the specific behavior it ostensibly validates were modified or removed.

### 6.4 Resistance to False Positives

A high-quality test does not pass when the system is in a faulty state.

**Meets the standard:** The test's assertions are specific enough and its setup is controlled enough that a defect in the tested behavior would cause the test to fail. The test does not suppress, catch, or ignore exceptions that indicate failure. The test does not use overly permissive assertions (e.g., asserting that a result contains a substring when an exact match is required).

**Fails the standard:** The test passes despite the presence of defects because its assertions are too loose, because it catches exceptions without re-raising or asserting on them, or because it validates a proxy for correctness rather than correctness itself.

### 6.5 Resistance to False Negatives

A high-quality test does not fail for reasons unrelated to the behavior it validates.

**Meets the standard:** The test is isolated from environmental factors it does not intend to test. It does not depend on network availability, clock time, filesystem state not created by the test, execution order relative to other tests, or the internal implementation details of its test subject (as opposed to its observable behavior). When the test fails, the failure reliably indicates a defect in the behavior under test.

**Fails the standard:** The test fails intermittently due to timing assumptions, shared mutable state, dependency on execution order, sensitivity to unrelated code changes (e.g., refactoring internals without changing behavior), or reliance on external resources outside the test's control.

### 6.6 Clarity of Intent

A high-quality test communicates what behavior it validates and under what conditions.

**Meets the standard:** A reader can determine from the test's name, structure, and content what scenario is being tested, what the expected outcome is, and why. Test setup clearly establishes the relevant conditions. Assertions clearly relate to the stated or implied purpose of the test.

**Fails the standard:** The test's purpose is ambiguous. Its name does not describe a behavior or scenario. The setup contains configuration whose relevance is unclear. Assertions appear arbitrary or disconnected from an identifiable behavioral claim. A reader must trace through implementation code to understand what the test is checking.

### 6.7 Determinism and Reliability

A high-quality test produces consistent results across repeated executions without dependence on external timing, ordering, or environmental state.

**Meets the standard:** The test produces the same pass/fail result every time it is run against the same code. It controls all sources of nondeterminism: random number generators are seeded, clocks are mocked or constrained, concurrent operations are synchronized or serialized within the test, and external state is created and torn down by the test itself.

**Fails the standard:** The test produces inconsistent results across runs (a "flaky" test). It depends on wall-clock time, on the ordering of other tests, on the availability of external services, on race conditions in concurrent code, or on environmental state that may vary between test environments.

### 6.8 Required Intermediate Document: Quality Assessment Document

The assessor must produce a **Quality Assessment Document** for each component under evaluation. This document contains:

1. **Per-test evaluation.** For every test examined, a record of which quality criteria (6.1 through 6.7) the test satisfies and which it does not.
2. **Specific observations.** For each criterion that a test fails, the specific evidence: what the assertion checks, why it is insufficient, what defect would go undetected, or what environmental dependency introduces unreliability.
3. **Quality-excluded tests.** Tests that fail quality thresholds sufficiently to be excluded from coverage counts are explicitly flagged with the disqualifying criteria identified.
4. **Impact on coverage.** For each quality-excluded test, a notation of which scenarios in the Coverage Mapping Document are affected and how the exclusion changes the coverage ratio.

---

## 7. Test Failure Patterns

This section catalogs specific, identifiable patterns where tests fail to fulfill their validation purpose. Each pattern is defined with diagnostic indicators that an assessor can look for during evaluation and the risk the pattern introduces to test suite integrity.

When the assessor identifies an instance of any pattern during evaluation, it must be recorded in the Failure Pattern Log (Section 7.12).

### 7.1 Assertion-Free Execution

**Description.** Tests that execute code paths but contain no assertions, or contain only framework-generated assertions (such as "no exception was thrown") that do not validate behavior.

**Diagnostic indicators.** Test methods with no assert/expect/verify statements. Tests whose only assertion is that the function completes without error. Tests that call the test subject and then end.

**Risk.** The test provides the illusion of coverage. It will pass regardless of whether the code behaves correctly, incorrectly, or not at all (as long as it does not throw). Defects in the tested code will not be detected.

### 7.2 Tautological Assertions

**Description.** Tests that assert conditions guaranteed to be true regardless of system behavior. The assertion cannot fail under any circumstance, making the test unfalsifiable.

**Diagnostic indicators.** Assertions that compare a variable to itself. Assertions that check a hardcoded value against the same hardcoded value. Assertions that verify a mock returns what the mock was configured to return, without validating that the test subject interacted with the mock correctly. Assertions on properties that are invariant by construction.

**Risk.** Identical to assertion-free execution: the test cannot detect defects. The presence of assertion syntax creates a false impression of validation.

### 7.3 Overly Broad Scope

**Description.** A single test attempts to validate too many behaviors, paths, or scenarios simultaneously. When the test fails, it is unclear which specific behavior is broken. When one behavior is broken, the test may fail before reaching assertions for other behaviors, leaving them effectively untested.

**Diagnostic indicators.** Tests with many assertions covering unrelated behaviors. Tests with long, complex setup that exercises multiple features. Tests whose names describe multiple behaviors ("test_create_update_and_delete"). Tests where a single failure in the middle prevents subsequent assertions from executing.

**Risk.** Failures become difficult to diagnose. Behaviors validated later in the test are silently skipped when an earlier behavior fails. The test's actual coverage is fragile and contingent on the success of unrelated code.

### 7.4 Implementation Coupling

**Description.** Tests assert on internal implementation details rather than observable behavior. The test breaks when the implementation is refactored—even if external behavior is preserved—because it validates how the code works rather than what the code does.

**Diagnostic indicators.** Assertions on private method calls, internal variable values, or specific sequences of internal operations. Mock verifications that assert on the exact number and order of internal calls rather than on the observable outcome. Tests that break when a function is refactored to produce the same output through different means.

**Risk.** Refactoring becomes costly because it requires updating tests that validate unchanged behavior. The test provides a false sense of coverage: it validates implementation, which may change, rather than behavior, which should be stable. The test's failure signal becomes unreliable because failures may indicate refactoring rather than defects.

### 7.5 Missing Negative Validation

**Description.** The test suite validates that the code works correctly with valid inputs but does not validate that the code correctly rejects, handles, or signals errors for invalid inputs, unauthorized access, or violated preconditions.

**Diagnostic indicators.** All tests in a suite use valid, "happy path" inputs. No tests supply invalid, malformed, unauthorized, or out-of-range inputs. No tests assert on error responses, exception types, or validation messages. The Negative / Failure Case coverage dimension has a ratio of zero.

**Risk.** The code may silently accept invalid input, produce corrupt output, or expose security vulnerabilities. Defects in input validation, authorization checks, and error signaling will go undetected.

### 7.6 Missing Boundary Validation

**Description.** The test suite does not exercise inputs at the boundaries of their valid domains—the values where behavior is most likely to change or where off-by-one errors are most likely to occur.

**Diagnostic indicators.** Tests use "typical" mid-range values exclusively. No tests use zero, empty collections, single-element collections, maximum-length inputs, minimum valid values, or values at transition points between behavioral regimes. The Edge Case / Boundary coverage dimension has a ratio of zero or near zero.

**Risk.** Off-by-one errors, overflow conditions, empty-input handling bugs, and boundary-adjacent logic errors will go undetected. These are among the most common classes of defects in software.

### 7.7 Environmental Dependency

**Description.** The test's outcome depends on external state, timing, or infrastructure that is not controlled by the test or test runner.

**Diagnostic indicators.** Tests that require network access to external services. Tests that depend on wall-clock time or time zones. Tests that assume specific filesystem state not created by the test. Tests that fail in CI but pass locally (or vice versa). Tests that assume the availability of specific ports, environment variables, or system configurations.

**Risk.** The test becomes unreliable ("flaky"), and its failure signal is degraded. Teams learn to ignore or retry failures, which erodes trust in the test suite and allows real defects to pass unnoticed.

### 7.8 Silent Failure Tolerance

**Description.** Tests catch or suppress exceptions without validating that the correct exception occurred for the correct reason. The test handles failures silently rather than asserting on them.

**Diagnostic indicators.** Try/catch blocks in tests that catch broad exception types. Catch blocks that contain no assertions. Tests that use exception suppression to prevent test failure rather than to validate error behavior. Assertions that check "an exception was thrown" without verifying the exception type, message, or causal condition.

**Risk.** The test may pass when the code throws the wrong exception, throws an exception for the wrong reason, or throws an exception that indicates a defect rather than expected error behavior. Error handling defects are masked.

### 7.9 Incomplete State Verification

**Description.** Tests verify one aspect of the test subject's output or effect while ignoring other critical state changes, side effects, or return value components.

**Diagnostic indicators.** Tests that check a return value but not a database write that should have occurred. Tests that verify a function was called but not with the correct arguments. Tests that check the primary output but not secondary effects (logging, metrics, event emission, cache updates). Tests that verify the "what" but not the "how much" or "in what order."

**Risk.** The test may pass while side effects are incorrect, state is inconsistent, or secondary behaviors are broken. The test validates a partial view of correctness, leaving other aspects unguarded.

### 7.10 Hard-Coded Expectations Without Traceability

**Description.** Tests contain magic numbers, string literals, or other hard-coded expected values that are not clearly traceable to requirements, specifications, or the logic of the test subject.

**Diagnostic indicators.** Assertions comparing against literal values whose origin is unclear. Expected values that do not appear in requirements documentation, test data setup, or derivable calculations. Tests where changing the expected value would make the test pass regardless of correctness because there is no independent source of truth for what the value should be.

**Risk.** The expected value may be wrong—copied from a buggy implementation rather than derived from requirements. There is no way to verify independently that the expected value is correct. The test validates consistency with a historical output rather than correctness against a specification.

### 7.11 Happy Path Redundancy

**Description.** The test suite contains many tests covering the same successful execution path with minor variations (different valid inputs that exercise the same logic branch) while other coverage dimensions remain unaddressed.

**Diagnostic indicators.** Multiple tests with similar structure and assertions that differ only in the specific valid input values used. A high test count for a function or feature combined with zero or near-zero coverage ratios in the Edge Case / Boundary, Negative / Failure Case, or Error Handling dimensions. Test names that suggest variation ("test_with_small_input," "test_with_medium_input," "test_with_large_input") for scenarios that exercise identical code paths.

**Risk.** Test count creates a false impression of thoroughness. The suite is highly redundant in one dimension while blind in others. The inflated test count may discourage further test development because the function "already has many tests."

### 7.12 Redundancy-Inflated Coverage

**Description.** A large number of tests are concentrated on a narrow behavioral slice. While related to Happy Path Redundancy, this pattern is broader: the redundancy may occur in any dimension, not only functional/behavioral. The defining characteristic is that many tests validate already-covered scenarios without expanding the set of tested scenarios.

**Diagnostic indicators.** A function or feature has a disproportionately large number of tests relative to its complexity and testable surface area. Removing half the tests would not decrease the coverage ratio because the remaining tests cover the same scenarios. The ratio of tests to unique covered scenarios is greater than 2:1 across the suite.

**Risk.** Duplicate validation of already-covered scenarios does not increase the numerator of any coverage ratio. The large test count slows test execution and increases maintenance burden without providing additional defect-detection capability. It creates a misleading impression of comprehensive coverage.

### 7.13 Required Intermediate Document: Failure Pattern Log

Where the assessor identifies instances of any failure pattern during evaluation, these must be recorded in a **Failure Pattern Log**. Each entry contains:

1. **Pattern identified.** The name of the pattern from this section (7.1 through 7.12).
2. **Test(s) exhibiting the pattern.** Specific test names, file locations, and line numbers.
3. **Evidence.** The specific observations supporting the classification: what the test asserts (or fails to assert), what dependency it relies on, what redundancy exists.
4. **Risk assessment.** The assessed impact on test suite integrity: what category of defect would go undetected, what false assurance is created, and the severity of the gap.

---

## 8. Intermediate Document Requirements

The assessment process produces six intermediate documents. These documents are mandatory artifacts of the evaluation. They serve two purposes: they make the assessor's reasoning transparent and auditable, and they provide structured records that can be reviewed, challenged, or compared across assessments.

The assessor must produce these documents as a required part of the evaluation process. They are not optional supplementary output. The final assessment conclusions must be traceable to the evidence and reasoning recorded in these documents.

### 8.1 Scope Definition Document

**Produced during:** Section 4.1 (Determining Total Possible Scope).

**Purpose:** Defines the testable surface area for a component—the denominator against which all coverage ratios are computed.

**Required contents:**

- Component identification (name, location, boundaries).
- Experience inventory: every distinct user-facing experience, with runtime, deployment artifact, and E2E test target (Section 4.1.3.1). An experience with no E2E test target is a finding.
- Requirements inventory: all requirements, specifications, or acceptance criteria consulted. Where none exist, an explicit statement of how intended behavior was inferred.
- Environmental factors identified as relevant to this component.
- Testable scenario enumeration: for each of the five coverage dimensions, a list of every concrete testable scenario. User-facing scenarios must be organized by experience as the top-level grouping—a user goal available through multiple experiences appears as a separate entry under each, with the experience-specific code path recorded. Each scenario must be specific and verifiable (e.g., "mobile app: user signs in via react-native-keychain → native bridge" rather than "user signs in").
- Test category coverage plan: for each test category in Section 3, a determination of applicability and required scenarios, derived from the component's architecture and user-facing behavior—not from what test categories currently exist. For E2E tests, must confirm an E2E test target exists per experience. The absence of an entire test category in the existing suite must not be treated as evidence that the category is inapplicable.
- Exclusions: behaviors or code paths explicitly excluded from scope, with rationale.
- Source attribution: for each scenario, whether it was derived from requirements, environment analysis, or code analysis.

### 8.2 Coverage Mapping Document

**Produced during:** Section 4.4 (Measuring Coverage Ratio).

**Purpose:** Maps each scenario in the Scope Definition Document to its corresponding test(s) and computes coverage ratios.

**Required contents:**

- Dimension-by-dimension mapping of each scenario to its covering test(s), or an explicit record that no corresponding test exists.
- Quality-adjusted status for each mapped test, indicating whether it meets quality thresholds.
- Partial coverage annotations where a test validates some but not all aspects of a scenario.
- Computed coverage ratio for each dimension.
- Assessor reasoning for ambiguous mappings.

### 8.3 Quality Assessment Document

**Produced during:** Section 6 (Test Quality Criteria).

**Purpose:** Records the quality evaluation of every test examined, identifies tests that fail quality thresholds, and notes the impact on coverage.

**Required contents:**

- Per-test evaluation against criteria 6.1 through 6.7.
- Specific observations justifying each determination.
- Explicit flagging of quality-excluded tests with disqualifying criteria identified.
- Impact notation showing which scenarios in the Coverage Mapping Document are affected by quality exclusions and how coverage ratios change.

### 8.4 Failure Pattern Log

**Produced during:** Section 7 (Test Failure Patterns).

**Purpose:** Records every identified instance of a failure pattern, with evidence and risk assessment.

**Required contents:**

- Pattern identified (by name and section reference).
- Specific test(s) exhibiting the pattern (name, file, location).
- Evidence supporting the classification.
- Risk assessment: what defect category would go undetected, severity of the gap.

### 8.5 Component Assessment Summary

**Produced as:** The final per-component synthesis of all preceding documents.

**Purpose:** Synthesizes findings from the Scope Definition Document, Coverage Mapping Document, Quality Assessment Document, and Failure Pattern Log into a single evaluative conclusion for the component.

**Required contents:**

- Comprehensiveness classification (Fully Covered, Partially Covered, or Not Covered) with the coverage ratios that support the classification.
- Per-dimension coverage summary with specific gap identification.
- Overall quality assessment summarizing the prevalence and severity of quality deficiencies.
- Failure pattern summary listing all patterns identified and their aggregate impact.
- Prioritized gap list ordering all identified deficiencies by assessed severity and risk.

### 8.6 Gap Reconciliation Document

**Produced during:** Section 9.6 (Gap Reconciliation), Phase 6 of the Assessment Sequence.

**Purpose:** Ensures every uncovered scenario identified during the assessment is explicitly assigned a disposition—implemented, deferred, or excluded—so that no findings are silently dropped. Enforces exact count matching between the complete gap set and the reconciliation table to prevent silent omission of entire scenario categories.

**Required contents:**

- The reconciliation table: one row per entry in the complete gap set, with the scenario, its severity, and its disposition (implemented, deferred, or excluded).
- For each implemented gap: the test file path and test name, confirmed at the required test category level.
- For each deferred gap: the severity classification, the implementation artifact reference (ticket, plan, work package), and the required test category level. Critical and High severity deferrals require decision-maker approval beyond the assessor.
- For each excluded gap: the rationale for exclusion or risk acceptance. Critical and High severity exclusions require decision-maker approval.
- Exact count comparison: the total number of entries in the complete gap set versus the number of rows in the reconciliation table, with explicit confirmation that they match. Any discrepancy is a process failure.
- Verification that no applicable test category from the Scope Definition Document's Test Category Coverage Plan has been omitted from the implementation plan.
- Verification that all scenarios subject to mandatory rules (Section 3.7) are addressed at the required test category level (E2E).
- A list of any unreconciled gaps (gaps with no assigned disposition). An assessment with unreconciled gaps is incomplete.

---

## 9. Assessment Application Guide

This section defines the procedure an assessor follows when evaluating a test suite. The procedure is organized around the production of the intermediate documents defined in Section 8, following a sequence from scope determination through final synthesis.

### 9.1 Assessment Sequence

The assessor executes the following phases in order. Each phase depends on the output of the preceding phase.

**Phase 1: Scope Determination.** For each component under evaluation, the assessor analyzes requirements, environment, and code to identify the total possible scope. The assessor must first identify all distinct user-facing experiences (Section 4.1.3.1) and organize user-facing scenarios by experience—a user goal available through multiple experiences (e.g., sign-in on mobile vs. web) must appear as a separate scenario under each experience. The assessor must enumerate needed scenarios across all test categories defined in Section 3—including end-to-end tests—regardless of what categories currently exist in the codebase. The assessor produces the Scope Definition Document (Section 8.1), which must include the Experience Inventory (Section 8.1, item 2) and the Test Category Coverage Plan (Section 8.1, item 6). No coverage measurement occurs until this document is complete.

**Phase 2: Test Classification.** The assessor classifies every existing test by its mocking profile and purpose, following the procedure in Section 3.8. Classification determines which column of the Canonical Completeness Definition Matrix (Section 4.3) applies to each test.

**Phase 3: Coverage Mapping.** The assessor maps each scenario in the Scope Definition Document to its corresponding test(s), applying the counting rules in Section 4.4.1. The assessor produces the Coverage Mapping Document (Section 8.2), including coverage ratios per dimension.

**Phase 4: Quality Evaluation.** The assessor evaluates every test that contributes to coverage against the quality criteria in Section 6. Tests that fail quality thresholds are flagged, and coverage ratios are adjusted. The assessor produces the Quality Assessment Document (Section 8.3).

**Phase 5: Failure Pattern Identification.** The assessor scans all tests—including those that contribute to coverage and those that do not—for the failure patterns defined in Section 7. Each identified instance is recorded in the Failure Pattern Log (Section 8.4).

**Phase 6: Gap Reconciliation.** Before synthesis, the assessor performs a reconciliation check to ensure that every uncovered scenario identified during the assessment is accounted for. This phase must occur before synthesis so that reconciliation findings—including any unreconciled gaps or omitted test categories—are incorporated into the final classification. See Section 9.6 for the full reconciliation procedure.

**Phase 7: Synthesis and Classification.** The assessor synthesizes findings from all preceding documents—including the Gap Reconciliation Document—assigns the comprehensiveness classification per Section 5, and produces the Component Assessment Summary (Section 8.5). Synthesis must reflect reconciliation outcomes: a component with unreconciled gaps or with mandatory test categories (Section 3.7) absent from the remediation plan cannot be classified as Fully Covered.

### 9.2 Per-Function/Unit Assessment Checklist

When evaluating tests at the function or unit level, the assessor applies the following checklist:

**Scope:**
- [ ] Have all input-output mappings been identified?
- [ ] Have boundary values for all parameters been identified?
- [ ] Have all invalid input cases been identified?
- [ ] Have all error handling paths been identified?
- [ ] Have all state transitions (if applicable) been identified?
- [ ] Have exclusions been recorded with rationale?

**Coverage (per dimension):**
- [ ] Has the completeness definition been enumerated using the canonical matrix?
- [ ] Has each scenario been mapped to a specific test or recorded as uncovered?
- [ ] Has the coverage ratio been computed?

**Quality (per test):**
- [ ] Do assertions validate meaningful expected outcomes (6.1)?
- [ ] Are preconditions and postconditions verified (6.2)?
- [ ] Would the test fail if the targeted behavior were broken (6.3)?
- [ ] Is the test resistant to false positives (6.4)?
- [ ] Is the test resistant to false negatives (6.5)?
- [ ] Is the test's intent clear from its name, structure, and assertions (6.6)?
- [ ] Is the test deterministic and reliable (6.7)?

**Failure Patterns:**
- [ ] Has each test been checked against the patterns in Section 7?
- [ ] Have all identified instances been recorded in the Failure Pattern Log?

### 9.3 Per-Feature/Module Assessment Checklist

When evaluating tests at the feature or module level, the assessor aggregates unit-level findings and additionally evaluates:

**Experience coverage:**
- [ ] Have all distinct user-facing experiences been identified (Section 4.1.3.1)?
- [ ] Are user-facing scenarios organized by experience, with each experience's scenarios listed separately—not collapsed across experiences?
- [ ] Does each identified experience have its own E2E test target (runtime environment)?
- [ ] For user goals available through multiple experiences (e.g., sign-in), does each experience have its own scenario entry with the experience-specific code path?

**Integration and E2E coverage:**
- [ ] Are integration tests present that validate interactions between the module's components and its real dependencies?
- [ ] Do integration tests cover the interaction paths identified in the Scope Definition Document?
- [ ] Are end-to-end tests present that validate the feature's user-facing workflows? **Mandatory:** If the Scope Definition Document identifies scenarios subject to mandatory rules (Section 3.7)—cross-component workflows, incident-linked scenarios, or auth flows—end-to-end tests for those scenarios are required per experience. Unit and contract tests with mocks cannot substitute (Section 3.3). Their absence is a Critical severity gap (Section 9.4).
- [ ] Do end-to-end tests cover all workflow scenarios identified in the Scope Definition Document, including cross-component interaction paths where contract mismatches between independently mocked components would otherwise go undetected?
- [ ] Have all scenarios subject to mandatory test category rules (Section 3.7) been verified to have tests at the required category level, per experience?

**Contract and distribution:**
- [ ] Are contract tests present where the module exposes or consumes external interfaces?
- [ ] Is the distribution of test categories appropriate for the module's architecture and risk profile?
- [ ] Are there coverage gaps that exist at the unit level and are not compensated by tests at other levels?
- [ ] Has a Component Assessment Summary been produced?

### 9.4 Severity Classification for Gaps

When the assessor identifies a gap—a scenario in the completeness definition that lacks adequate test coverage—the gap is classified by severity using the following scale:

**Critical.** The untested scenario involves a primary functional path, a security-sensitive operation, a data integrity concern, or a failure mode that could cause system-wide impact. A defect in this scenario would be high-severity in production. Any scenario subject to the mandatory test category rules in Section 3.7 that lacks the required end-to-end test is automatically classified as Critical. Examples: authentication bypass, data corruption, unhandled exception in a critical path, missing validation on financial calculations, cross-component workflow without E2E test, incident-linked scenario without E2E regression test.

**High.** The untested scenario involves an important but non-primary path, error handling for a likely failure mode, or a boundary condition on a high-traffic function. A defect would be noticeable to users and require prompt remediation. Examples: missing timeout handling for a frequently called external service, untested boundary condition on a search function, missing validation on a commonly used input field.

**Medium.** The untested scenario involves edge cases, less common error paths, or state transitions that occur infrequently. A defect would affect a subset of users or scenarios and could be addressed in a normal development cycle. Examples: missing test for a rarely used configuration option, untested state transition for an uncommon workflow, missing boundary test for a low-traffic endpoint.

**Low.** The untested scenario involves cosmetic behavior, logging, non-critical metadata, or paths that are unlikely to contain defects due to their simplicity. A defect would have minimal user impact. Examples: missing test for a log message format, untested tooltip text, missing boundary test on a display-only field with no downstream logic.

### 9.5 Suite-Level Summary Assessment

When the assessor has completed per-component evaluations, a suite-level summary aggregates findings across all components:

1. **Component classification distribution.** Count and list components by comprehensiveness tier (Fully Covered, Partially Covered, Not Covered).
2. **Dimension coverage summary.** For each coverage dimension, report the average coverage ratio across all components, the minimum, and the number of components with zero coverage in that dimension.
3. **Quality summary.** Report the prevalence of quality deficiencies across the suite: what percentage of tests meet all quality criteria, what are the most common quality failures.
4. **Failure pattern prevalence.** Report the frequency of each failure pattern across the suite, identifying systemic patterns versus isolated instances.
5. **Critical gap inventory.** A consolidated list of all Critical and High severity gaps across the suite, ordered by severity.
6. **Overall assessment.** A narrative synthesis characterizing the test suite's strengths, systemic weaknesses, and areas of greatest risk.

### 9.6 Gap Reconciliation

After the assessment is complete, the assessor must verify that every uncovered scenario identified in the Scope Definition Document has been explicitly accounted for. The purpose of this phase is to prevent entire categories of findings from being silently dropped between assessment and remediation planning.

The assessor performs the following reconciliation procedure:

1. **Extract the full gap inventory.** From the Coverage Mapping Document, enumerate every scenario that was recorded as uncovered or partially covered. From the Quality Assessment Document, enumerate every scenario whose coverage was invalidated by quality exclusions. This combined list is the **complete gap set**. Record the total count.

2. **Build the reconciliation table.** Create a table with one row per entry in the complete gap set. Every entry must be assigned exactly one of the following dispositions:
   - **Implemented.** The gap has been addressed by a specific test. Record the test file path and test name. The test must exist and must be classified at the required test category level—a scenario requiring an E2E test under Section 3.7 is not resolved by a unit test.
   - **Deferred.** The gap is acknowledged and assigned to a specific implementation plan, task, or backlog item. The assignment must reference a concrete artifact (a ticket, a plan document, a named work package)—not a vague intention to address it later. The severity classification (Section 9.4) must be recorded. Critical and High severity gaps require escalation to a decision-maker; the assessor alone cannot defer these.
   - **Excluded.** The assessor's inclusion of the scenario in scope is contested or the scenario is accepted as a known risk. The rationale must be recorded. For risk acceptance, the severity must be recorded and Critical and High severity exclusions require decision-maker approval beyond the assessor. For scope disputes, the contesting party's rationale is recorded and the scenario remains in the gap set until the dispute is resolved.

3. **Verify exact count match.** The number of rows in the reconciliation table must exactly equal the number of entries in the complete gap set. Every uncovered scenario must appear in the table with a disposition. Any discrepancy between the gap set count and the reconciliation table count is a process failure—it indicates that scenarios were silently dropped. The assessor must resolve all discrepancies before proceeding. An assessment where the reconciliation count does not match the gap count is incomplete.

4. **Verify completeness by test category.** The assessor must verify that no entire test category (unit, integration, end-to-end, contract) identified as applicable in the Scope Definition Document's Test Category Coverage Plan has been omitted from the remediation plan. Specifically: if the Scope Definition Document identified uncovered E2E scenarios, the implementation plan must include E2E test work items. An implementation plan that addresses unit test gaps but omits an entire test category present in the scope definition fails reconciliation. Additionally, all scenarios subject to the mandatory rules in Section 3.7 must be verified: if a mandatory-rule scenario is deferred, the deferred work item must specify a test at the required category level (E2E), not a lower-level substitute.

5. **Produce the Gap Reconciliation Document.** The assessor produces a document containing the reconciliation table and the following summary:
   - The total count of gaps in the complete gap set, by severity (Critical, High, Medium, Low).
   - The count and list of gaps with disposition "Implemented," with test file paths and test names.
   - The count and list of gaps with disposition "Deferred," with their severity classifications and implementation artifact references.
   - The count and list of gaps with disposition "Excluded," with rationales and approval records where required.
   - An explicit count comparison: complete gap set count versus reconciliation table row count, with confirmation that they match or a flagged discrepancy.
   - Verification that no applicable test category has been omitted from the implementation plan, or a flagged exception if one has.
   - A specific check that all scenarios subject to mandatory rules (Section 3.7) have been addressed at the required test category level.
   - Any gaps that have no disposition assigned are flagged as **unreconciled**. An assessment with unreconciled gaps is incomplete.

The Gap Reconciliation Document is added to the set of required intermediate documents. An assessment that does not include gap reconciliation permits uncovered scenarios to be lost between the assessment's findings and any subsequent action, defeating the purpose of the assessment.

---

## 10. Documentation Alignment

When assessment findings lead to the creation of new test infrastructure—new test suites, new test categories, new test runners, or new CI/CD stages—the assessor or implementer must identify and update any project documentation that defines completion criteria, lists runnable commands, or describes CI/CD stages. Tests that exist but are not referenced in project documentation will be bypassed by future contributors.

### 10.1 Documents That Commonly Require Updates

The following types of project documents commonly define what tests exist, how to run them, and when they are expected to pass. When new test infrastructure is introduced, each of these must be checked and updated if present:

- **Workflow guides.** Documents that describe development workflows, including which test commands to run before submitting code.
- **Contribution guides.** Documents (e.g., CONTRIBUTING.md) that instruct contributors on how to validate their changes, including which test suites to execute.
- **Onboarding documents.** Documents that orient new team members on the project's testing practices, tooling, and expectations.
- **Agent instruction files.** Documents (e.g., CLAUDE.md, .cursorrules, or equivalent) that instruct AI agents or automated tools on project conventions, including test commands and validation steps.
- **CI/CD pipeline definitions.** Configuration files that define which tests run in continuous integration. A new test suite that is not added to the CI pipeline will not gate merges.
- **Completion criteria or definition of done.** Any document that defines what "done" means for a task, feature, or pull request, including which tests must pass.

### 10.2 The Documentation Alignment Check

When new test infrastructure is introduced as a result of assessment findings, the implementer must:

1. **Inventory project documentation.** Identify all documents in the repository that reference test commands, test suites, CI stages, or completion criteria.
2. **Evaluate each document for staleness.** For each document identified, determine whether it reflects the new test scope. If the document lists test commands, does it include the new commands? If it describes CI stages, does it include the new stage? If it defines completion criteria, does it include the new tests?
3. **Update stale documents.** Bring each document into alignment with the new test infrastructure. Add new test commands, new suite descriptions, new CI stage references, and new completion criteria as appropriate.
4. **Record updates made.** The list of documents updated—and the specific changes made—must be recorded as part of the implementation deliverables.

If project documentation is not updated to reflect new test infrastructure, the tests exist but nothing tells contributors to run them. Future work will bypass the new tests, and the coverage gains from the assessment will erode silently.

---

## 11. Framework Compliance Checklist

This checklist provides a single-pass verification that an assessment satisfies all framework requirements. Each item references the section containing the full specification. An assessment is compliant when every applicable item is checked.

### 11.1 Scope Determination

- [ ] Scope Definition Document produced for each component (Section 4.1.5, Section 8.1)
- [ ] All distinct user-facing experiences identified, with runtime and E2E test target recorded (Section 4.1.3.1)
- [ ] User-facing scenarios organized by experience — a user goal available through multiple experiences listed separately under each (Section 4.1.3.1)
- [ ] Each experience-specific scenario records its own code path, not a generic description
- [ ] Testable scenarios enumerated across all five coverage dimensions (Section 4.2)
- [ ] Scope derived independently of existing test structure (Section 4.1.4)
- [ ] Test Category Coverage Plan included: each test category evaluated for applicability; E2E test target confirmed per experience (Section 4.1.5, item 6)
- [ ] All scenarios checked against mandatory test category rules (Section 3.7)
- [ ] Mandatory-rule scenarios flagged with the applicable rule and required test category level
- [ ] Exclusions recorded with rationale (Section 4.1.4)

### 11.2 Test Classification

- [ ] Every existing test classified by mocking profile (Section 3.8, step 1)
- [ ] Orthogonal-purpose tests identified (Section 3.8, steps 2-3)
- [ ] Mandatory category requirements verified against classified test inventory (Section 3.8, step 4)

### 11.3 Coverage Mapping

- [ ] Coverage Mapping Document produced for each component (Section 4.4.2, Section 8.2)
- [ ] Each scenario mapped to a specific test or recorded as uncovered (Section 4.4.2)
- [ ] Counting rules applied: partial coverage scored at 0.5, quality-excluded tests not counted (Section 4.4.1)
- [ ] Coverage ratio computed for each dimension (Section 4.4)

### 11.4 Quality Evaluation

- [ ] Quality Assessment Document produced for each component (Section 6.8, Section 8.3)
- [ ] Every test evaluated against all seven quality criteria (Sections 6.1-6.7)
- [ ] Quality-excluded tests flagged with disqualifying criteria (Section 6.8)
- [ ] Coverage ratios adjusted to reflect quality exclusions (Section 4.4.1)

### 11.5 Failure Pattern Identification

- [ ] Every test checked against failure patterns 7.1 through 7.12 (Section 7)
- [ ] Failure Pattern Log produced with evidence and risk assessment for each instance (Section 7.13, Section 8.4)

### 11.6 Gap Reconciliation

- [ ] Complete gap set extracted from Coverage Mapping and Quality Assessment Documents (Section 9.6, step 1)
- [ ] Reconciliation table built with one row per gap (Section 9.6, step 2)
- [ ] Every gap assigned a disposition: implemented, deferred, or excluded (Section 9.6, step 2)
- [ ] Reconciliation table row count exactly matches complete gap set count (Section 9.6, step 3)
- [ ] No applicable test category omitted from the implementation plan (Section 9.6, step 4)
- [ ] All mandatory-rule scenarios (Section 3.7) addressed at the required test category level (Section 9.6, step 4)
- [ ] Critical and High severity deferrals/exclusions approved by a decision-maker (Section 9.6, step 2)
- [ ] Gap Reconciliation Document produced (Section 9.6, step 5; Section 8.6)

### 11.7 Synthesis and Classification

- [ ] Component Assessment Summary produced for each component (Section 8.5)
- [ ] Comprehensiveness classification assigned per Section 5 criteria
- [ ] Classification reflects reconciliation outcomes — unreconciled gaps or absent mandatory test categories prevent Fully Covered (Section 9.1, Phase 7)
- [ ] Severity assigned to every gap per Section 9.4

### 11.8 Suite-Level Summary (if applicable)

- [ ] Component classification distribution reported (Section 9.5)
- [ ] Per-dimension coverage summary reported (Section 9.5)
- [ ] Critical gap inventory consolidated (Section 9.5)

### 11.9 Documentation Alignment (if new test infrastructure introduced)

- [ ] Project documentation inventoried for test references (Section 10.2)
- [ ] Stale documents updated to reflect new test commands, CI stages, and completion criteria (Section 10.2)
- [ ] Updates recorded as part of implementation deliverables (Section 10.2)
