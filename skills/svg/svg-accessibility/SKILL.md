---
name: svg-accessibility
description: Give meaningful SVGs accessible names with title and desc, and hide decorative ones from assistive technology. Use when an SVG conveys information to users or is embedded in a page or component.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# SVG Accessibility

## Core principle

Decide first: does this SVG convey information the user needs, or is it decoration?
The answer determines the correct treatment. Getting this wrong is the most common
SVG accessibility defect.

## Operating procedure

1. **Classify the graphic.**
   - **Meaningful / informative** - it conveys information not available in text
     (a chart, a diagram, a distinctive icon that is the only label). It needs an
     accessible name, and often a longer description if it is complex.
   - **Decorative** - it is purely visual garnish, or its meaning is already provided
     by adjacent text. It must be hidden from assistive technology to avoid noise.
   - **Functional** - it is the visible part of a control (an icon button). The
     *control* needs the accessible name, not the SVG itself.

2. **For meaningful SVGs, provide an accessible name.**
   - Inline SVG: give the root `<svg>` a `role="img"` and an accessible name via
     `aria-labelledby` pointing at a `<title>`, or `aria-label`.
   - A `<title>` as the first child is the conventional way to name an SVG graphic.
   - Use `<desc>` for a longer explanation when the graphic is complex (a chart, a map).
   - Keep the `<title>` text meaningful and unique; avoid "image" or "icon".

3. **For decorative SVGs, hide them.**
   - Add `aria-hidden="true"` and `focusable="false"` to the root `<svg>`.
   - Do not give them a `<title>` or accessible name.
   - Ensure they are not focusable.

4. **For functional icons, name the control.**
   - Give the enclosing `<button>`/`<a>` an accessible name (`aria-label` or visually
     hidden text) and mark the SVG decorative.
   - Do not put the accessible name only on the SVG in a way that conflicts with the
     control's own name.

5. **Avoid duplicated descriptions.** Do not provide both an `aria-label` and a
   `aria-labelledby` that say the same thing, and do not repeat the adjacent visible
   text in the SVG's title (screen readers will read it twice).

6. **Keep it synchronized.** If the graphic's meaning changes (a chart updates), update
   the `<title>`/`<desc>`. A stale description is worse than none.

## Quality criteria

- Every SVG is deliberately classified as meaningful or decorative (or functional).
- Meaningful SVGs have a meaningful, unique accessible name; complex ones have a `desc`.
- Decorative SVGs are hidden with `aria-hidden="true"` and are not focusable.
- Functional icons do not carry a conflicting name that fights the control's name.
- No duplicated accessible descriptions.

## Anti-patterns to avoid

- Decorative background SVGs exposing "graphic" noise to screen readers.
- An icon button whose SVG has no name and whose button has none either.
- `aria-label` and `aria-labelledby` both present with conflicting text.
- A `<title>` that just repeats nearby visible text.
- Omitting `focusable="false"` on decorative SVG in environments where SVG is focusable.

## Validation strategy

- For each SVG, confirm it is classified and that the classification matches the
  attributes present.
- Automated checks can detect missing `role`/`aria-hidden`/`title`, but cannot judge
  whether the *name is good* or whether the classification is correct. State that these
  were reviewed manually or not reviewed.
- Check with a screen reader if available; otherwise state that it was not performed.

## Reference

- WAI: SVG accessibility guidance; WCAG 1.1.1 (non-text content).
