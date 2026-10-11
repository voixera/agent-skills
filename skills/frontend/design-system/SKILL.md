---
name: design-system
description: Define and reuse color, type, spacing, radius, shadow, and state tokens instead of scattering arbitrary values. Use when establishing or extending a visual language, or when a codebase contains many inconsistent hard-coded values.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Design System

## Operating procedure

1. **Inspect what already exists.** Find the tokens, theme file, CSS variables, or
   Tailwind config. Reuse them. Only introduce new tokens when there is a genuine
   gap, and add them to the same source of truth.

2. **Define the token layers:**
   - **Color** - base palette plus semantic roles (`surface`, `border`, `text`,
     `danger`, `success`). Components should reference semantic roles, not raw hex.
   - **Typography** - a small type scale (size + line-height + weight) rather than
     ad-hoc font sizes.
   - **Spacing** - one spacing scale (e.g. 4/8-based). Spacing should come from the
     scale, not from arbitrary pixel values.
   - **Radius** - a few named radii (none, small, medium, large, full).
   - **Shadows/elevation** - a named set of elevation levels.
   - **Breakpoints** - one set, shared across the app.

3. **Define component states as part of the system.** Every interactive component
   should have defined default, hover, focus, active, disabled, and (where relevant)
   loading and error states - consistently across components.

4. **Model variants explicitly.** Use the project's variant mechanism (props,
   class maps, cva-style helpers) so variants are enumerable and documented rather
   than assembled inline at each call site.

5. **Constrain layout.** Provide standard container widths, grid columns, and
   responsive rules so pages do not invent their own.

## Quality criteria

- Colors referenced through semantic roles wherever practical.
- Spacing and sizing drawn from the shared scales.
- Component states handled consistently across the system.
- Variants enumerated in one place, not re-implemented per call site.
- A new contributor can find "the right value" without guessing.

## Anti-patterns to avoid

- Arbitrary hex values sprinkled through components when a token exists.
- One-off spacing values (`margin-top: 13px`) that break the rhythm.
- Three different radius values that mean the same thing.
- Copy-pasting a component to make a "variant" instead of adding a real variant.
- A token file that exists but is bypassed everywhere.

## Validation strategy

- Grep the codebase for raw color literals and arbitrary pixel values; each hit is
  either a justified exception or a defect.
- Confirm new tokens were added to the same source of truth, not a local file.
- Check that every interactive component defines focus and disabled states.

## Scope note

Not every project needs a full token system. For a small, single-screen tool, a
lightweight set of CSS variables is often enough. Match the system's weight to the
project; do not impose a large token architecture on a tiny app.

## Reference

- W3C Design Tokens Community Group format; common semantic token conventions.
