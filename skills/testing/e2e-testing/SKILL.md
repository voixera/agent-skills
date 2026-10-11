---
name: e2e-testing
description: Cover critical user journeys with end-to-end tests that survive refactors and catch regressions. Use when protecting key flows such as signup, checkout, or onboarding.
metadata:
  category: testing
  version: 1.0.0
  agents: all
  tools: playwright, cypress
---

# End-to-End Testing

## Core principle

End-to-end tests are expensive to write and slow to run, so use them sparingly on the
journeys that matter most to users and revenue. Do not try to cover every branch here -
that is what unit and integration tests are for.

## Operating procedure

1. **Choose the critical journeys.** Signup/login, the primary task the product exists
   for, checkout/payment, and anything that breaks if it breaks. A handful of journeys,
   not every screen.

2. **Test as a user, through the real UI**
   - Drive the app via accessible roles and labels (`getByRole`, `getByLabel`), not CSS
     classes or test ids tied to implementation.
   - Wait for real conditions (an element appears, a request resolves), never fixed
     `sleep` delays.
   - Assert on user-visible outcomes, not internal state.

3. **Cover what only e2e can cover:**
   - Multi-page navigation and deep links.
   - Form submission through to a persisted result.
   - Authentication and session persistence across pages.
   - Responsive behavior where practical (at least one small-viewport run of a core flow).
   - The regression case for a specific bug that escaped to production.

4. **Make tests reliable.**
   - Isolate test data per run; create and clean up what the journey needs.
   - Avoid depending on other e2e tests' side effects; each journey stands alone.
   - Handle the app's real loading and error states, not just the fast path.
   - Quarantine a flaky test and fix the cause; do not paper over it with retries alone.

5. **Keep the suite fast enough to run on every change.** Run the critical subset on PRs
   and the full set on a schedule if it is slow. Configure parallelism where supported.

6. **Capture artifacts on failure** (screenshot, video, trace) so failures are diagnosable.

## Quality criteria

- A small set of high-value journeys is covered end to end.
- Selectors are role/label based and survive refactors.
- No fixed sleeps; waits are condition-based.
- Tests are isolated and do not depend on execution order.
- Failures produce artifacts that explain what went wrong.

## Anti-patterns to avoid

- Fixed `sleep`/`waitForTimeout` calls.
- Selectors on CSS classes or brittle DOM structure.
- E2E tests duplicating what a unit test already covers cheaply.
- Shared accounts or data that make tests order-dependent.
- Retrying a flaky test forever instead of fixing the race.
- Asserting on internal state the user cannot see.

## Validation strategy

- Run the e2e suite against a real build of the app.
- Confirm it starts from a clean, seeded state and cleans up.
- Run twice in a row to catch order dependence and leftover data.
- Confirm a deliberately introduced regression fails the relevant journey.

## Reference

- Playwright / Cypress documentation on locators, auto-waiting, and test isolation.
