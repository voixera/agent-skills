---
name: microinteractions
description: Design hover, focus, loading, transition, and feedback behavior that stays keyboard-friendly and reduced-motion aware. Use when adding interactive feedback to controls, lists, or stateful components.
metadata:
  category: ui-ux
  version: 1.0.0
  agents: all
---

# Microinteractions

## Core principle

A microinteraction should tell the user something: that a control is interactive, that
an action is in progress, that it succeeded, or that it failed. If it communicates
nothing, it is decoration.

## The four parts of a microinteraction

1. **Trigger** - what starts it (hover, focus, click, load, error).
2. **Rules** - what happens and in what order.
3. **Feedback** - what the user perceives (visual, motion, text).
4. **Loop / end state** - how it settles, and what happens if it repeats.

Design all four. Most defects come from designing only the trigger and feedback, with
no defined end state.

## Operating procedure

1. **Give every interactive control the standard states** and make them visible:
   - **Hover** - affordance that the element is interactive (pointer environments only).
   - **Focus** - clear, visible focus ring. Non-negotiable for keyboard users; never
     remove it without a visible replacement.
   - **Active/pressed** - immediate feedback that the press registered.
   - **Disabled** - visibly unavailable, and the reason clear where it matters.
   - **Loading** - the action is in progress; prevent duplicate triggering.

2. **Provide feedback for actions that take time.** Show a spinner or progress on the
   trigger itself, and keep the rest of the layout stable. For actions over a second or
   two, prefer progress over an indefinite spinner.

3. **Confirm outcomes.** Success should be visible (a state change, a check, a toast for
   non-local actions). Failure must be visible and actionable (see the ui-ux-design skill).

4. **Respect keyboard and reduced motion.**
   - Hover-only affordances must have a keyboard equivalent; a control discoverable only
     by mouse is a defect.
   - Honor `prefers-reduced-motion`; provide a non-motion equivalent for decorative
     transitions (see the animation-and-interaction skill).

5. **Keep durations short.** Interaction feedback should feel immediate (commonly
   ~120-200 ms). Long easing on frequent actions feels laggy.

6. **Avoid over-feedback.** Do not animate everything; do not show a toast for a state
   change already visible on screen; do not play a sound by default.

## Quality criteria

- Every interactive control has defined hover, focus, active, disabled, and (where
  relevant) loading states.
- Focus is always visible and is not replaced by hover styling.
- Actions with latency show progress and block duplicate triggering.
- Outcomes (success and failure) are perceivable.
- Reduced-motion preference is honored.

## Anti-patterns to avoid

- Removing the focus outline with no replacement.
- Hover-only reveal of essential actions or information.
- A submit button that stays enabled and clickable during submission, allowing duplicates.
- Toasts for changes already visible on screen (feedback noise).
- Micro-animations on every element "to feel alive".
- Loading states with no end state (spinner that never resolves into a result).

## Validation strategy

- Tab through and confirm focus visibility and reachability independent of the mouse.
- Trigger a slow action and confirm loading state plus duplicate-prevention.
- Trigger failure and confirm the failure is perceivable and actionable.
- Enable reduced motion and confirm the interface remains usable.

## Reference

- General interaction design practice (Saffer's microinteractions model); WCAG focus and
  motion criteria.
