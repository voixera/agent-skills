---
name: debugging-root-cause
description: Reproduce, gather evidence, form a hypothesis, apply a minimal fix, add a regression test, and verify. Use when diagnosing a bug or a failing test rather than guessing at changes.
metadata:
  category: testing
  version: 1.0.0
  agents: all
---

# Debugging and Root Cause Analysis

## Core principle

Do not change code until you can explain the failure. Editing until the error
disappears is guesswork: it often masks the symptom, introduces new bugs, and leaves the
real cause in place.

## Operating procedure

1. **Reproduce the problem reliably.** Find the smallest, most deterministic trigger.
   A nondeterministic reproduction is itself a clue (a race, ordering, or state issue).
   If you cannot reproduce it, gather more information instead of guessing.

2. **Collect evidence before changing anything.**
   - Read the full stack trace / error, not just the first line.
   - Inspect the actual values at the point of failure (logs, a debugger, a temporary
     print), not what you assume they are.
   - Check recent changes, configuration, and environment differences.
   - Establish the facts: what happens, where, under what conditions, and what changed.

3. **Form a hypothesis and test it.** State the suspected cause in one sentence and
   predict what you would observe if it were true. Then check. If the prediction is
   wrong, discard the hypothesis rather than bending it to fit.

4. **Apply a minimal, targeted fix.** Change the smallest thing that addresses the root
   cause. Avoid refactoring, renaming, or "cleaning up" in the same change, which muddies
   the diff and makes the fix impossible to evaluate.

5. **Add a regression test.** Write a test that fails before the fix and passes after.
   This is what stops the bug from returning. If the bug is not testable in the current
   setup, say so and explain why.

6. **Verify the fix.**
   - The original reproduction now succeeds.
   - The new regression test passes.
   - The existing test suite still passes (no new breakage).
   - Edge cases adjacent to the fix behave correctly.

7. **Report remaining uncertainty.** If you are not fully certain of the root cause, say
   what you know, what you suspect, and what would confirm it. Do not present a guess as
   a proven diagnosis.

## Quality criteria

- The problem was reproduced before it was fixed.
- Evidence (not assumption) identified the cause.
- The fix is minimal and targeted; unrelated changes are separated.
- A regression test exists, or its absence is explicitly explained.
- Verification includes the original case and the full suite.
- Uncertainty is stated honestly.

## Anti-patterns to avoid

- Randomly adding logs, changing values, and re-running until the error vanishes.
- Fixing a symptom (catching and swallowing the exception) instead of the cause.
- Large refactors mixed into a bug fix.
- Claiming "fixed" without reproducing the original failure and re-testing it.
- Leaving no regression test when one was feasible.
- Presenting a hypothesis as a proven root cause.

## Validation strategy

- Before the fix: the reproduction fails. After: it passes.
- The regression test fails on the pre-fix code (verify this by reverting).
- The full existing test suite passes after the fix.
- State explicitly which verifications were run and which were not possible here.

## Reference

- General debugging practice (reproduce, isolate, hypothesize, verify).
