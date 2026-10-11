---
name: animation-and-interaction
description: Add purposeful transitions and feedback while respecting reduced-motion preferences and avoiding distraction. Use when adding motion, transitions, hover effects, or interactive feedback to an interface.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Animation and Interaction

## Core principle

Motion exists to explain a change, direct attention, or confirm an action. If it
does none of these, it is noise. Every animation should be answerable with "what
does this communicate?"

## Operating procedure

1. **Justify each animation.** Typical valid purposes: showing where an element came
   from, confirming a save, drawing attention to an error, indicating progress. If
   the purpose is "it looks nice", reconsider.

2. **Keep it fast and short.** Interface transitions are commonly in the ~120-300 ms
   range. Long transitions on frequent actions (navigation, typing feedback) feel
   sluggish. Reserve longer durations for rare, large movements.

3. **Animate the cheap properties.** Prefer `transform` and `opacity`, which the
   compositor can often handle. Avoid animating layout properties (`width`, `height`,
   `top`, `left`) that trigger reflow, unless the movement is inherently layout-based
   and measured.

4. **Respect reduced motion.**
   ```css
   @media (prefers-reduced-motion: reduce) {
     * { animation-duration: 0.01ms !important; animation-iteration-count: 1 !important;
         transition-duration: 0.01ms !important; scroll-behavior: auto !important; }
   }
   ```
   Or scope reduced motion per component. Essential motion (e.g. a progress spinner
   that conveys state) may remain, but as an alternative rather than a flashy one.

5. **Never let motion block interaction.** Do not gate navigation or actions on an
   animation completing. Users with slow devices or reduced motion must still get
   the result immediately.

6. **Hover and focus are separate concerns.** Hover reveals affordance; focus must be
   visible for keyboard users. Do not implement hover-only states that are the only
   way to discover an action.

7. **Avoid gratuitous effects.** Parallax, autoplaying loops, bouncing, and infinite
   decorations draw attention from the task and cost frames.

## Quality criteria

- Each animation has a stated purpose.
- Durations are short and consistent with the rest of the interface.
- Reduced-motion users get a non-motion equivalent.
- Motion never blocks the task or hides state.
- Focus states remain visible and are not replaced by hover-only styling.

## Anti-patterns to avoid

- Animating `height: auto` transitions that thrash layout.
- Infinite decorative loops.
- Scroll-jacking and forced smooth-scroll that fights the user.
- Long intro animations that delay first meaningful interaction.
- Using animation as the only signal for a state change (accessibility risk).

## Validation strategy

- Enable the OS "reduce motion" setting and confirm the interface stays usable and
  clear.
- Watch for dropped frames during the animation (devtools performance panel).
- Confirm focus is visible independent of hover.
- If you cannot render in this environment, state that visual verification was not
  performed.

## Reference

- MDN: `prefers-reduced-motion`; web.dev: high-performance animations.
