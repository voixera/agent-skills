---
name: svg-visual-review
description: Review SVG output against a structured checklist covering composition, balance, spacing, contrast, and fidelity to the brief. Use after generating or receiving an SVG, before shipping it.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# SVG Visual Review

## Core principle

A syntactically valid SVG is not a good SVG. Visual review is a separate step, and it
must be performed on a rendered image - not inferred from the source text. If you
cannot render, say so; do not pretend the visual review happened.

## The acceptance pipeline

Report each stage independently. Do not collapse them into a single "valid" verdict.

1. **XML parsing** passed - the file is well-formed.
2. **Security checks** passed - the scan found no obvious unsafe patterns (with its
   stated limits; see svg-security).
3. **Accessibility checks** passed where applicable - title/desc/role handled per the
   graphic's classification (see svg-accessibility).
4. **Rendered successfully** - a renderer produced an image without error.
5. **Visual review completed** - a human or model inspected the rendered image against
   the checklist below.

If no renderer is available, stages 4 and 5 are **not performed** - report that plainly.

## Visual review checklist

For each item, give a concrete observation, not a vague "looks good".

- **Composition** - Is there a clear focal point? Is the arrangement intentional
  relative to the brief?
- **Balance** - Is visual weight distributed sensibly, or does it lean to one side?
- **Alignment** - Do related elements line up on shared axes, or is placement arbitrary?
- **Negative space** - Is the empty space deliberate, or does it look like an accident?
- **Shape consistency** - Same corner radii, same level of geometric vs organic form,
  consistent treatment of like elements?
- **Contrast** - Does the subject separate clearly from its background and from its
  own parts? Check the value contrast at small sizes, including the very smallest.
- **Detail density** - Right amount of detail for the size? Does it turn to mush when small?
- **Scalability** - Does it still read at 16px? At 4x? Are strokes proportionate?
- **Rendering artifacts** - Clipping at edges, gaps between supposedly touching shapes,
  aliasing on thin strokes, unintended overlaps, stroke crawl?
- **Fidelity to the request** - Does it actually depict what was asked, matching the
  brief (subject, meaning, style, palette)?

## Operating procedure

1. Render the SVG at the intended use size and at a small size if it will be used small.
2. Walk the checklist, noting concrete observations and specific defects with locations.
3. Separate objective defects (clipping, misalignment, missing content) from subjective
   preferences (color choice, style taste). Label which is which.
4. For each defect, state a specific fix, or mark it as "recommend change" if it is a
   preference.
5. Summarize with the five-stage status.

## Quality criteria

- Each check has an observation, not a superlative.
- Objective defects and subjective preferences are distinguished.
- The five stages are reported separately and honestly.
- If rendering was not possible, that limitation is stated, not implied away.

## Anti-patterns to avoid

- "The SVG looks great" with no specifics.
- Marking the visual review as done when nothing was rendered.
- Reporting a subjective taste difference as an objective bug without labeling it.
- Claiming pixel fidelity to a reference when no measurement was made.
- Skipping small-size checks and declaring scalability fine.

## Renderer availability

When a renderer exists in the environment (a browser, `rsvg-convert`, ImageMagick,
or an SVG-capable tool), use it and inspect the output. When none exists, report:
"Rendering and visual review were not performed: no renderer available in this
environment." Do not substitute source-code inspection for visual review.

## Reference

- General visual design critique practice; the other svg-* skills for the technical stages.
