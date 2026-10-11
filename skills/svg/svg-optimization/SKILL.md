---
name: svg-optimization
description: Reduce SVG size and noise without destroying semantics, accessibility, or intended rendering. Use when optimizing an existing SVG or preparing assets for production.
metadata:
  category: svg
  version: 1.0.0
  agents: all
  tools: svgo
---

# SVG Optimization

## Core principle

Optimization must be non-destructive. Smaller is worthless if the graphic renders
differently, loses its accessible name, or becomes unmaintainable. Verify rendering
and accessibility after optimizing, not just the byte count.

## Operating procedure

1. **Keep a copy first.** Never optimize in place without a backup or version control.
   Optimization is a transformation that can be wrong.

2. **Remove what is genuinely unnecessary:**
   - Editor metadata (`<metadata>`, comments, Inkscape/Illustrator namespaces).
   - Unused `<defs>` entries (gradients, filters, symbols, clip paths never referenced).
   - Redundant markup (empty groups, no-op transforms, repeated identical attributes).

3. **Reduce precision carefully.** Coordinate precision is a size/quality trade-off.
   Two decimal places is often enough; zero or one may visibly change curves. Never
   round so aggressively that shapes visibly change. Decide per asset, not globally.

4. **Do not destroy semantics or behavior:**
   - Keep `<title>` and `<desc>` used for accessibility (see svg-accessibility).
   - Keep `id`s referenced by animation, CSS, scripts, `use`, gradients, or masks.
   - Keep `role`, `aria-*`, and `focusable` attributes.
   - Keep fill/stroke and any attributes that affect rendering.
   - Do not merge paths in a way that changes how strokes or fills render.

5. **Use a real optimizer when available.** `svgo` is the common choice, but configure
   it - the aggressive defaults can strip accessibility elements and ids. Consider:
   - Keep `viewBox` (do not remove it).
   - Preserve ids (`cleanupIds` can break references).
   - Preserve `<title>`/`<desc>` if the asset is accessible.
   Run the optimizer on a copy and diff the rendered output.

6. **Re-verify after optimizing.** Parse the result, re-render it, and confirm it is
   identical to the eye and still accessible.

## Quality criteria

- Output is well-formed and renders identically to the input.
- Accessibility elements (title/desc/role) preserved.
- Referenced ids preserved.
- `viewBox` preserved.
- Size reduction is measured, not assumed.

## Anti-patterns to avoid

- Running the optimizer with defaults on an accessible SVG and silently deleting
  `<title>`/`<desc>`.
- Over-rounding coordinates and changing the shape.
- Removing "unused" defs that are actually referenced via CSS or `use`.
- Optimizing without a backup and without re-verification.
- Merging paths that changes stroke/fill appearance.

## Validation strategy

- Parse input and output; both must be well-formed XML.
- Render both and compare (if a renderer is available); otherwise state that visual
  comparison was not performed.
- Diff the accessibility-relevant elements before and after.
- Report the size before and after as measured numbers.

## Reference

- SVGO documentation (`viewBox`, `cleanupIds`, `removeTitle`/`removeDesc` options and
  their accessibility implications).
