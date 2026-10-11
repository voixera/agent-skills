---
name: icon-design
description: Design icons on a consistent grid with readable silhouettes, coherent corners, and no detail that disappears at small sizes. Use when creating or reviewing icon sets and individual UI icons.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# Icon Design

## Core principle

An icon must be recognizable in a glance at its real size. Small sizes punish
detail; consistency across a set matters more than any single icon.

## Operating procedure

1. **Choose a grid and a canonical size.** A 24x24 grid with a matching `viewBox="0 0 24 24"`
   is common; 16, 20, and 32 are also used. Pick one and use it for the whole set.
   Include a consistent padding (a "safe area") so icons do not touch the edge.

2. **Choose a style and hold it.** Line, solid/filled, or duotone. Do not mix styles
   within a family. Define:
   - **Stroke style**: width (commonly 1.5 or 2 at 24px), `stroke-linecap` and
     `stroke-linejoin` (`round` for a friendly set, else square/butt).
   - **Fill style**: filled shapes with defined corners, or outline only.
   - **Corner treatment**: a consistent radius on rounded rectangles and joins.

3. **Design the silhouette first.** A good icon is identifiable by its outline with
   the interior removed. If it is not, the shape is too generic or too detailed.

4. **Align optically, not just numerically.** Equal padding by number can look off
   (circles look smaller than squares of the same size). Nudge elements to look aligned.
   Center by visual weight, not by bounding box alone.

5. **Keep detail density low.** At 24px, hairlines and tiny gaps disappear or alias.
   Prefer fewer, clearer strokes. Remove any detail that is not readable at the target
   size. For 16px variants, remove detail rather than shrinking it.

6. **Use the grid for consistency.** Snap major strokes and shapes to grid increments
   so icons line up when placed side by side in a toolbar.

7. **Mind the perimeter.** Decide whether the icon is "optical size" (fills the box)
   or "measured size" (consistent bounding box), and apply it consistently.

## Quality criteria

- Consistent grid, safe area, and stroke width across the set.
- Silhouette is recognizable at the smallest target size.
- Corner and join treatment is coherent.
- No detail that disappears or aliases at target size.
- Icons read consistently when placed in a row.

## Anti-patterns to avoid

- Mixed stroke widths or cap styles within one set.
- Detail that only exists at 96px but is meaningless at 24px.
- Overly literal, busy depictions of simple concepts.
- Icons that touch or overflow the viewBox edge.
- Inconsistent optical weight (one icon looks bold, its neighbor thin).

## Validation strategy

- Render every icon in the set at 16px, 24px, and 32px side by side; compare weight,
  alignment, and legibility. If no renderer is available, state that visual
  verification was not performed.
- Confirm a single stroke width and one cap/join style across the set.
- Confirm the viewBox and safe area are identical across icons.

## Reference

- Common iconography guidelines on grid, stroke, and optical alignment.
