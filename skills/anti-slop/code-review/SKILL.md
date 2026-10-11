---
name: code-review
description: Review correctness, security, maintainability, and scope before proposing or approving changes. Use when reviewing a change or before proposing your own.
metadata:
  category: anti-slop
  version: 1.0.0
  agents: all
---

# Code Review

## Core principle

Review the change against four questions: Is it correct? Is it safe? Is it maintainable?
Is it in scope? Separate objective problems from personal preference, and be specific.

## Operating procedure

1. **Correctness.**
   - Does the code do what it claims for the real inputs, including edge cases
     (empty, null, boundary, error)?
   - Are there logic errors, off-by-one issues, unhandled states, or race conditions?
   - Do async/concurrency paths behave under failure?

2. **Security.**
   - Is untrusted input validated? Is output encoded for context?
   - Are authorization and ownership checks present server-side?
   - Any injection, SSRF, secret exposure, or unsafe deserialization?
   (See the security skills for the full checklist.)

3. **Maintainability.**
   - Is the naming clear and consistent with the codebase?
   - Is the abstraction justified, or is it indirection with one caller?
   - Is there duplicated logic that should be shared, or shared logic that should be
     separate?
   - Are errors handled, not swallowed?

4. **Scope.**
   - Does the diff stay within the stated purpose?
   - Are unrelated refactors or formatting sweeps mixed in? (They should be separate.)

5. **Tests.**
   - Do the new behaviors have tests that would fail without the change?
   - Were any tests weakened, skipped, or deleted to make things pass?

6. **Verify claims.** If the author says it is tested or fixed, confirm where possible.
   Do not pass along an unverified claim as verified.

7. **Give actionable feedback**, labelled:
   - **Blocking** - must change (bug, security, broken test).
   - **Non-blocking** - improvement worth considering.
   - **Question** - needs clarification.

## Quality criteria

- All four questions are answered with specifics.
- Objective problems are separated from preferences.
- Feedback is specific, actionable, and cited to a location.
- Claims are verified or explicitly marked unverified.

## Anti-patterns to avoid

- Approving a diff you did not read.
- Style nitpicks while missing a logic bug.
- Vague feedback ("this is bad", "make it cleaner").
- Presenting a preference as a blocking requirement.
- Accepting "it's tested" without checking.
- Reviewing an outsized diff as a single unit.

## Validation strategy

- Walk each of the four questions and record an answer.
- Confirm new behavior has a meaningful test, or note its absence.
- Confirm no test was weakened to pass.
- List what was verified and what was not.

## Reference

- The pull-request-review and anti-slop-review skills; security skills for the security pass.
