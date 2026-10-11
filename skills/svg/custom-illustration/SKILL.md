---
name: custom-illustration
description: Plan an illustration from a design brief covering subject, meaning, composition, palette, and detail level before drawing. Use when creating an illustration or scene rather than an icon or UI element.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# Custom Illustration

## Core principle

An illustration communicates a specific idea. Two unrelated requests should not
produce the same picture. Write the brief first, then design to it.

## Step 1 - Write the design brief

Produce a short brief before any coordinates. If the user did not provide the
information, make a reasonable decision and state it as an assumption.

- **Subject** - what is literally depicted.
- **Intended meaning** - the idea it should convey (e.g. "collaboration", "fast setup",
  "data is safe"). The meaning drives the composition.
- **Main silhouette** - the one shape the eye should read first.
- **Composition** - focal point, supporting elements, background, and how they are
  arranged (centered, rule-of-thirds, dynamic diagonal, balanced symmetry).
- **Visual style** - flat, line-art, geometric, isometric, textured, gradient-lit.
  Choose *one* coherent style and hold it throughout.
- **Palette** - a small set of colors with roles (dominant, secondary, accent,
  background). Derive from the product's real palette when one exists.
- **Detail level** - how much is drawn; must match the display size.
- **Intended display size** - the smallest size at which it will appear.

## Step 2 - Compose deliberately

- Build from large shapes to small: silhouette, then structure, then detail.
- Use one strong focal element; do not give three elements equal weight.
- Let the composition support the meaning (e.g. converging shapes for "coming together").
- Account for the background - an illustration on a dark UI needs different values
  than one on white.

## Step 3 - Draw with restraint

- Use as few shapes as carry the idea. Detail that does not add meaning is noise.
- Keep stroke and fill treatment consistent with the chosen style.
- Reuse a small palette; avoid introducing new colors mid-drawing without reason.
- Group and name logical parts (`<g id="figure">`) so the file is maintainable.

## Quality criteria

- A brief exists and the drawing matches it.
- One clear focal point with a supporting composition, not a random scatter.
- One coherent style and palette throughout.
- Detail level matches the intended display size.
- The illustration is distinguishable from an unrelated request's illustration.

## Anti-patterns to avoid

- The default "three floating geometric blobs with a gradient" composition applied to
  every topic regardless of meaning.
- Random circles, stars, and sparkles filling empty space.
- Generic gradients used as a substitute for composition.
- Mixing flat and 3D-lit styles in one image.
- Detail that vanishes into mush at the target size.
- A brief that describes the medium ("a nice SVG") instead of the idea.

## Note on these elements

Floating shapes, circles, and gradients are not banned. They are correct when they
serve the composition (e.g. an abstract data illustration may genuinely be geometric).
The requirement is that the choice is intentional and tied to the brief, not reflexive.

## Validation strategy

- Check the drawing against the brief point by point.
- Confirm a single focal point and a coherent style/palette.
- Render at the target size if a renderer is available; otherwise state that visual
  verification was not performed.
- Run security and accessibility checks (see the related svg skills).

## Limitation

This skill improves the intentionality and consistency of generated illustrations.
It does not guarantee originality or that the result matches a professional
illustrator's output. State this rather than overclaiming.

## Reference

- General composition principles (focal point, hierarchy, value contrast).
