---
name: task-planning
description: Turn a complex requirement into small, ordered, independently testable steps before writing code. Use at the start of any non-trivial feature, refactor, or migration.
metadata:
  category: anti-slop
  version: 1.0.0
  agents: all
---

# Task Planning

## Core principle

Large, vague tasks produce large, vague, unreviewable changes. Break the work into small
steps that can each be implemented, tested, and reviewed on their own. The plan is a tool
for reducing risk, not paperwork.

## Operating procedure

1. **Restate the goal and the constraints.** In one or two sentences, what outcome is
   wanted, and what is out of scope? Naming what is excluded prevents scope creep.

2. **Inspect before planning.** Read the relevant code, tests, and data model so the plan
   reflects the real system, not an imagined one.

3. **Decompose into independently verifiable steps.** Each step should:
   - Be small enough to complete and review in one pass.
   - Have a clear definition of done.
   - Have a way to verify it (a test, a check, a manual observation).
   - Be ordered so dependencies come first and the system stays working between steps
     where possible.

4. **Identify the riskiest unknown early.** Put the step that could invalidate the plan
   (an uncertain API, a migration, a performance question) near the front, so you learn
   early instead of after building everything around an assumption.

5. **Sequence for a shippable increment.** Prefer steps that leave the system in a working
   state (behind a feature flag if needed) over a big-bang change that is broken until the
   final step.

6. **Call out assumptions and unknowns.** State what you are assuming and what you would
   need to confirm. Do not silently guess.

7. **Revise the plan as you learn.** The plan is a living artifact; update it when reality
   contradicts it rather than forcing the original.

## Output format

A short, ordered list, for example:

```text
Goal: Add CSV export to the orders list. Out of scope: scheduling exports.
1. Add a serializer for order rows. Verify: unit test on 3 cases. [ ]
2. Add the export endpoint (streaming, auth-checked). Verify: integration test. [ ]
3. Add the UI export button with loading/disabled states. Verify: manual + e2e. [ ]
4. Add a large-dataset test (10k rows). Verify: timing under limit. [ ]
Assumptions: the orders table has an indexed created_at for range queries.
```

## Quality criteria

- Each step is small, ordered, and independently verifiable.
- The riskiest unknown is addressed early.
- The plan names scope exclusions and assumptions.
- The system is intended to stay working between steps.
- The plan is updated as understanding changes.

## Anti-patterns to avoid

- A single step that is "implement the feature".
- Steps with no verification method.
- Ignoring the existing code and planning against an imagined architecture.
- A plan that is never revised when reality disagrees.
- Ordering that leaves the system broken until the very last step for no reason.

## Validation strategy

- For each step, confirm there is a stated way to verify it.
- Confirm the first steps de-risk the biggest unknown.
- Confirm the plan could be paused after any step without leaving the app broken (or note
  where it cannot).

## Reference

- Incremental-delivery and test-driven planning practice.
