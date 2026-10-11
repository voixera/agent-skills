---
name: pull-request-review
description: Review changes for correctness, scope, tests, and risk, and give specific, actionable feedback. Use when reviewing a pull request or diff.
metadata:
  category: devops
  version: 1.0.0
  agents: all
  tools: gh
---

# Pull Request Review

## Core principle

A review determines whether the change is correct, safe, in scope, and maintainable. It
is not a style referendum. Feedback should be specific and actionable, and should
distinguish blocking problems from optional suggestions.

## Operating procedure

1. **Understand intent first.** Read the PR description and linked issue. What problem
   does this solve? A change you cannot connect to a purpose is hard to review well.

2. **Review in passes, not line-by-line only:**
   - **Correctness** - Does it do what it claims? Are there logic errors, missing cases,
     or off-by-one problems?
   - **Security** - Does it handle untrusted input, authorization, and secrets correctly?
   - **Scope** - Does the diff stay within the stated purpose? Unrelated changes should
     be split out.
   - **Tests** - Are the new behaviors covered? Do the tests actually assert something
     meaningful? Were any tests weakened?
   - **Maintainability** - Is it understandable, consistent with the codebase, and free
     of unnecessary complexity?
   - **Compatibility** - Does it break existing contracts, data, or clients?

3. **Check the diff against the description.** Confirm the described change matches what
   was actually done; note anything described but missing or done but undescribed.

4. **Verify claims where possible.** If the PR says "fixes X", check that it does. If it
   says tests pass, run them if you can. Do not accept a test-pass claim you cannot verify
   as verified.

5. **Give specific feedback.** Cite the file and line, explain the concern, and suggest a
   direction. Distinguish:
   - **Blocking** - must change before merge (bugs, security, broken tests).
   - **Non-blocking** - improvement worth considering, not required.
   - **Question** - you need clarification to judge.

6. **Do not personally criticize.** Comment on the code and the trade-offs, not the author.

7. **Keep the review proportionate.** Match scrutiny to risk. A one-line doc fix needs a
   sanity check; a new auth flow needs careful review.

## Quality criteria

- Review covers correctness, security, scope, tests, and maintainability.
- Feedback is specific, actionable, and labelled by severity.
- Claims in the description are verified or explicitly marked unverified.
- Style opinions are separated from correctness/security issues.

## Anti-patterns to avoid

- Approving without reading the diff.
- Nitpicking formatting while missing a logic error.
- Demanding personal preferences as blocking changes.
- Accepting "tests pass" without checking whether they ran.
- Reviewing a 2000-line mixed-purpose PR as if it were one change.

## Validation strategy

- Confirm the diff matches the stated scope.
- Confirm new behavior has tests that would fail without the change.
- Confirm no secrets, debug code, or commented-out blocks were committed.
- If you cannot run the tests, say the test result is unverified.

## Reference

- The repository's PULL_REQUEST_TEMPLATE and CONTRIBUTING guidelines.
