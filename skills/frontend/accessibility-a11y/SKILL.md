---
name: accessibility-a11y
description: Use semantic HTML, keyboard support, accessible names, and correct ARIA only where native semantics are insufficient. Use when building or reviewing any user-facing interface element, form, or interactive widget.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Accessibility (a11y)

## Core principle

Prefer native semantics. The best ARIA is usually no ARIA, because a correct
element already carries the right role, state, and keyboard behavior.

## Operating procedure

1. **Start from semantic HTML.** Use `button`, `a`, `input`, `label`, `nav`,
   `main`, `header`, `footer`, `ul`/`li`, `table`, `h1`-`h6` as intended. Reach for
   `div` only when no element fits.

2. **Make everything reachable and operable by keyboard.**
   - Every interactive element is focusable and activatable with keyboard alone.
   - Focus order follows a sensible reading order; avoid positive `tabindex`.
   - If you build a custom widget (menu, combobox, tabs, dialog), follow the
     relevant WAI-ARIA Authoring Practices pattern, including key handling.

3. **Show focus.** Never remove focus indication without a visible replacement.
   `outline: none` without a substitute is a defect.

4. **Provide accessible names.**
   - Icon-only buttons need an accessible name (`aria-label` or visually hidden
     text).
   - Images that convey meaning need meaningful `alt`; decorative images use
     `alt=""`.
   - Form inputs are associated with a `label`; placeholders are not labels.

5. **Forms and validation.**
   - Associate errors with inputs (`aria-describedby`) and announce them.
   - Do not rely on color alone to signal an error.
   - Mark required fields programmatically, not just visually.

6. **Color and contrast.** Body text should meet WCAG AA contrast (4.5:1 normal
   text, 3:1 large text); UI components and focus indicators at least 3:1. Check
   against the actual background, including hover and disabled states.

7. **Respect user preferences.** Honor `prefers-reduced-motion` for non-essential
   animation, and do not autoplay media with sound.

8. **Use ARIA only to fill genuine gaps**, and then correctly:
   - Do not add `role="button"` to a `button`.
   - Do not put `aria-hidden="true"` on a focusable element.
   - Keep `aria-*` state in sync with the visual state (e.g. `aria-expanded`).

## Quality criteria

- Interactive elements are operable by keyboard and show visible focus.
- Every control has an accessible name.
- Form errors are programmatically associated and not color-only.
- Contrast meets AA for the actual rendered colors.
- Reduced-motion preference is honored.
- ARIA is used only where native semantics are insufficient, and correctly.

## Anti-patterns to avoid

- Click handlers on `div`/`span` used as buttons.
- `aria-label` on a `div` that is not, and should not be, interactive.
- `aria-hidden` on content that is still tabbable.
- Placeholder text used as the only label.
- Relying on hover alone to reveal essential information.
- Duplicated, contradictory roles (e.g. `role="button"` on an `<a>` doing navigation).

## Validation strategy

- Keyboard-only pass: reach and operate every control with Tab/Shift+Tab/Enter/Space/Escape/Arrows.
- Run an automated checker (axe, eslint-plugin-jsx-a11y) if available; treat results as
  a floor, not a ceiling.
- Automated tools cannot judge meaning, focus order quality, or whether a name is
  *good*. State that these were manually reviewed or not reviewed.
- Check contrast for the real color pairings.

## Reference

- WAI-ARIA Authoring Practices; WCAG 2.2 success criteria.
