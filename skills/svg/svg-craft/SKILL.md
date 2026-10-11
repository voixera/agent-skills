---
name: svg-craft
description: Construct SVG deliberately with a correct viewBox, intentional geometry, consistent strokes, and no pointless decoration. Use when creating or reviewing any hand-authored SVG, illustration, icon, or vector graphic.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# SVG Craft

## Core principle

An SVG is a designed object, not a list of shapes. Decide what it is for, how big it
will be seen, and what the reader should notice first - before writing any coordinates.

## Operating procedure

1. **State the intent before drawing.** Write one sentence: what is this graphic, where
   will it appear, and at what size? A 24 px icon, a 400 px empty-state illustration,
   and a 1200 px hero have different detail budgets. If the display size is unknown,
   ask or assume the most demanding case and note the assumption.

2. **Set a correct `viewBox`.** The `viewBox` defines the coordinate system and is the
   single most important line in the file.
   - Choose a coordinate system that matches the design (`0 0 24 24` for icons,
     larger for illustrations). Integers where possible.
   - Include a small margin in the viewBox so strokes near the edge are not clipped;
     a stroke of width `w` centered on the boundary needs `w/2` of room.
   - Omit `width`/`height` (or set them separately) so the graphic scales; use CSS for
     final sizing. Do not hardcode one size if it must scale.

3. **Establish visual hierarchy.** Decide the dominant shape, the supporting shapes,
   and the details. The eye should have one clear entry point. Detail density should
   follow importance - most detail on the focal element, least on the background.

4. **Choose geometry intentionally.**
   - Prefer a small number of well-placed paths and primitives over many overlapping
     fragments.
   - Use `path` for organic or compound shapes; use `rect`/`circle`/`line`/`polygon`
     when they express the form exactly (they are clearer and often smaller).
   - Use `transform` to position repeated or rotated elements instead of recomputing
     coordinates, but flatten transforms when exporting for maximum compatibility if
     the target requires it.

5. **Keep strokes consistent.** Decide the stroke width up front and reuse it for like
   elements. Set `stroke-linecap` and `stroke-linejoin` deliberately (`round` for
   friendly/organic, `miter`/`butt` for technical). Do not mix three stroke widths
   that mean the same thing.

6. **Consider negative space and optical alignment.** Equal spacing by measurement can
   look wrong; optical centering (e.g. a triangle or a play icon shifted slightly) reads
   as more balanced. Use the space around the subject, not just the subject.

7. **Avoid excessive nodes.** Let a curve be a curve. Exporting a traced bitmap can
   produce hundreds of nodes that are impossible to maintain and blur at small sizes.

8. **Use gradients and filters only when they serve the design.** A gradient should do
   a job (implying light or depth), not decorate by default. Filters (blur, drop-shadow)
   are expensive to render and can blur the intent; use them sparingly and test them.

9. **No decoration without purpose.** Every element should contribute to meaning,
   composition, or legibility. Remove "filler" stars, dots, and waves that exist only
   to fill space.

## Quality criteria

- The graphic has a stated purpose and target size.
- `viewBox` is correct and nothing is clipped at the edges.
- One clear focal point; detail follows importance.
- Stroke widths, joins, and caps are consistent across like elements.
- Path node count is reasonable for the detail level.
- Gradients/filters, if any, serve the design.
- The graphic reads correctly at its smallest intended size.

## Anti-patterns to avoid

- Missing or wrong `viewBox`, causing clipping or inconsistent scaling.
- Strokes flush against the viewBox edge and therefore cut off.
- A traced bitmap with thousands of nodes for a simple shape.
- Three unrelated stroke widths.
- Decorative gradients, shadows, and sparkles added by default.
- Random circles and blobs used as "design" with no compositional role.

## Validation strategy

- Parse the XML (well-formedness) - see the validator.
- Run the SVG security scan (see the svg-security skill).
- Check accessibility where the graphic conveys meaning (see the svg-accessibility skill).
- **Render** at the intended size and inspect, if a renderer is available; otherwise
  state that rendering and visual review were not performed.
- Count nodes in the main paths for unexpectedly complex shapes.

## Reference

- SVG 2 / SVG 1.1 specification (`viewBox`, presentation attributes); MDN SVG element reference.
