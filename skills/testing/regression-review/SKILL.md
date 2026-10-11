---
name: regression-review
description: Check a change for unintended effects on existing behavior before declaring it done. Use after making a change, especially one touching shared code, shared data, or widely used components.
metadata:
  category: testing
  version: 1.0.0
  agents: all
---

# Regression Review

## Core principle

Most damage from a change is not the change itself but what it breaks elsewhere. Before
calling work done, deliberately look for the unintended consequences - especially in
shared code, shared data, and shared UI.

## Operating procedure

1. **Enumerate what the change touches.**
   - Which functions/components/modules changed? Who else calls them?
   - Which shared data structures or schema shapes changed? Who reads the old shape?
   - Which API contracts changed? Who consumes them?
   - Which shared UI components changed? Where else do they render?

2. **Trace the blast radius.** For each changed symbol, grep for its usages. A change to
   a widely used utility or component can affect screens that were never part of the task.
   This is the step that catches most regressions and the one most often skipped.

3. **Check the categories that commonly regress:**
   - **Behavior** - default values, null/empty handling, error messages, ordering.
   - **Contracts** - request/response shapes, function signatures, event payloads.
   - **Data** - migrations that alter existing rows; serialization that drops fields.
   - **UI** - layout shifts, a component that now looks wrong in a different context,
     a previously optional prop that is now required.
   - **Performance** - a new query or render path on a hot route.
   - **Accessibility** - a changed component that lost its label or focus handling.

4. **Run the full existing test suite**, not just the tests for the changed area. A
   passing subset is not evidence the change is safe.

5. **Compare behavior before and after** for the flows most likely to be affected.

6. **Document residual risk.** If some area could not be verified (no tests, cannot run
   here, needs manual QA), state it explicitly rather than implying full coverage.

## Quality criteria

- Changed symbols were traced to their other usages.
- Shared contracts and data shapes were checked for old-shape consumers.
- The full test suite passes after the change.
- Affected flows were compared before and after.
- Unverifiable areas are documented as residual risk.

## Anti-patterns to avoid

- Running only the test file for the changed module.
- Assuming a widely used component is "only used here".
- Changing a default or a shape without searching for consumers.
- Declaring success with failing or unrun tests.
- Making a schema change without considering existing rows.

## Validation strategy

- Grep for every changed public symbol and list its call sites.
- Run the entire test suite and report the real result.
- Diff the behavior of the top affected flows.
- List explicitly which areas were verified and which were not.

## Reference

- General change-impact analysis practice; the code-review and debugging skills.
