---
name: ui-ux-design
description: Design complete flows with clear hierarchy and explicit empty, loading, error, success, and disabled states. Use when designing a screen, flow, or feature before or during implementation.
metadata:
  category: ui-ux
  version: 1.0.0
  agents: all
---

# UI/UX Design

## Operating procedure

1. **Identify the user and their goal.** Whose problem is this, and what are they
   trying to accomplish on this screen? Every design decision should serve that goal,
   not showcase a technique.

2. **Establish information hierarchy.** Decide what the user must see first, second,
   and third. Use size, weight, color, and position to encode that order. If everything
   is emphasized, nothing is.

3. **Design the whole flow, not one screen.** Trace the path: entry point, the action,
   what happens during it, and what the user sees after success or failure. Ensure the
   user can always tell where they are and how to go back.

4. **Design every state explicitly.** For each screen or component that depends on data
   or user action, define:
   - **Empty** - not yet any data (with a helpful next step, not a blank void).
   - **Loading** - the work is happening; show progress, keep layout stable.
   - **Error** - something failed; explain in plain language and offer a way forward.
   - **Success** - the happy path, including confirmation of completed actions.
   - **Disabled** - unavailable, with a clear reason for why.

   A data view that only handles "success" is incomplete.

5. **Use meaningful labels.** Button and field labels should describe the action or
   content ("Save changes", "Email address"), not be vague ("Submit", "OK", "Field 1").
   Error messages should tell the user how to fix the problem.

6. **Reduce unnecessary friction.** Remove optional steps, unnecessary confirmations,
   and redundant data entry. Pre-fill what can be inferred. Do not add a modal for
   something that can be inline.

7. **Ensure mobile usability.** The primary task must be completable on a phone: reachable
   controls, no hover-dependent actions, adequate touch targets, and legible text (see the
   responsive design skill).

## Quality criteria

- The screen serves a stated user goal.
- Visual hierarchy makes the primary action obvious.
- Empty, loading, error, success, and disabled states are all defined.
- Labels name real actions and content; errors explain the fix.
- The primary flow is completable on a small screen with touch.

## Anti-patterns to avoid

- Building only the success state.
- A blank screen when there is no data.
- Error messages like "Error 500" with no guidance.
- Vague button labels and placeholder-only field labels.
- Confirm dialogs for low-risk, reversible actions.
- Desktop-only interactions (hover menus, drag-only) for core tasks.

## Validation strategy

- Walk each state: empty, loading, error, success, disabled - confirm each is designed.
- Attempt the flow on a small viewport with touch input.
- Confirm the primary action is visually obvious without reading all the text.
- If you cannot render, state that visual verification was not performed.

## Reference

- Nielsen's usability heuristics; WCAG guidance on clear labels and error identification.
