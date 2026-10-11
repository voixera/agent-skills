---
name: unit-testing
description: Test meaningful behavior and edge cases in the project's existing framework, without brittle or truth-hiding tests. Use when adding tests for a function, module, or component, or when reviewing an existing test suite.
metadata:
  category: testing
  version: 1.0.0
  agents: all
---

# Unit Testing

## Core principle

A test exists to catch a real regression. If deleting the test would not allow a bug to
sneak through, the test earns little. Test behavior, not implementation details.

## Operating procedure

1. **Use the project's existing framework.** Jest, Vitest, Mocha, pytest, Go testing,
   PHPUnit, xUnit, Pester - whatever is already there. Do not add a second test framework
   or restructure the suite for a single addition.

2. **Target meaningful behavior.**
   - Test the observable contract: inputs producing outputs, state changes, side effects.
   - Test the branches that can actually fail: boundary conditions, empty input, error
     paths, off-by-one edges.
   - Do not test that a private helper is called in a specific order (that is a
     refactor-fragile implementation test).

3. **Cover the edges that matter:**
   - Empty, single-element, and large inputs.
   - Boundaries: zero, one, the maximum, just past the maximum.
   - Null/undefined/missing values and malformed data.
   - Error conditions and their messages/error types.

4. **Keep tests isolated and deterministic.**
   - No reliance on execution order, real time, real network, or shared mutable state.
   - Control time and randomness explicitly; freeze time where the logic depends on it.
   - Each test can run alone and in any order.

5. **Use clear names that describe the behavior**, e.g. `rejects an empty email`, not
   `test1`. A failing test name should tell you what broke.

6. **Never change a test merely to make it pass.** If a test fails, either the code is
   wrong or the test encodes a wrong expectation. Fix the actual cause and say which it
   was. Do not delete, skip, or weaken assertions to hide a real failure.

7. **Avoid brittle assertions.** Do not assert on exact log strings, full serialized
   objects, or internal ids that will churn. Assert on the behavior that matters.

## Quality criteria

- Tests exercise observable behavior and real edge cases.
- Each test is independent and deterministic.
- Test names describe the behavior under test.
- A meaningful change to the logic would break the test.
- No test was weakened or skipped to hide a failure.

## Anti-patterns to avoid

- Testing implementation details (private method call counts, internal state shape).
- Snapshot tests of large objects with no meaningful assertion.
- Tests that pass regardless of the code (no real assertion).
- Changing assertions to match buggy output.
- `skip`/`only` left in the suite.
- Depending on the network, the clock, or test execution order.

## Validation strategy

- Confirm the suite runs with the project's documented test command.
- For each new test, ask "what bug would this catch?" If none, reconsider the test.
- Run the suite in a random order (or run a single test alone) to confirm isolation.
- Report skipped tests explicitly; a skipped test is not a passing test.

## Reference

- General test design guidance on behavior vs. implementation coupling.
