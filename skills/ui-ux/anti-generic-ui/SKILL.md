---
name: anti-generic-ui
description: Avoid templated, decorative UI when the brief calls for something specific; choose layout, type, and color deliberately. Use when building a new interface or when output looks like a default template regardless of the product.
metadata:
  category: ui-ux
  version: 1.0.0
  agents: all
---

# Anti-Generic UI

## Core principle

The same layout should not appear for a banking dashboard, a design tool, and a recipe
app. Generic output comes from reaching for defaults instead of making decisions that
follow the brief. This skill is about *intentionality*, not about banning any aesthetic.

## Operating procedure

1. **Look before designing.** Inspect the existing product's visual language (colors,
   type, spacing, density) and any provided references. Reuse and extend it. If nothing
   exists, choose a direction deliberately and state it.

2. **Choose the layout from the content.** Ask what this screen is *for*: a data table,
   a feed, an editor, a marketing page, a settings panel. Each has a natural structure.
   Do not pour all of them into the same centered hero-plus-three-cards mold.

3. **Set a deliberate type and spacing system.** Pick a type scale and spacing rhythm
   and apply them consistently (see the design-system skill). Default typography with no
   hierarchy is one of the strongest signals of templated output.

4. **Make a visual decision that reflects the product's identity.** Whether that is dense
   and technical, calm and spacious, editorial, or playful - the choice should be
   defensible from the brief, not from a component library's defaults.

5. **Reserve decoration for when it earns its place.** Gradients, glassmorphism, floating
   cards, big rounded corners, shadows, and background blobs are tools, not defaults.
   Use them when the brief and product identity call for them and leave them out when
   they do not.

6. **Discourage filler.** No meaningless hero headline, no generic "Lorem" copy, no
   three-icon feature row that says nothing specific, no emoji substituting for content
   in a professional interface.

## What generic output looks like (signals to check)

- A centered hero with a vague headline and a gradient button, regardless of product.
- Three "feature cards" with an icon, a bold word, and one vague sentence - on a page
  that has no features to describe.
- Rounded containers + soft shadows applied uniformly to everything.
- Accent gradients used as the only expression of "modern".
- Icon-heavy navigation where labels would be clearer.
- Emoji as decoration in a professional/enterprise context.
- The same spacing and type everywhere, for every kind of content.

## What this skill does NOT say

- It does not ban any aesthetic. Gradients, glass, rounded corners, and dark mode are all
  legitimate when the brief supports them.
- It does not demand novelty at the expense of usability. A familiar layout is often
  correct; the problem is *unconsidered* defaults, not familiarity itself.
- It does not replace product judgment. Apply the guidance according to the brief.

## Quality criteria

- The visual direction is deliberate and defensible from the brief.
- Layout is chosen for the content type, not applied generically.
- Type and spacing systems create real hierarchy.
- Decoration, if present, serves a purpose.
- Copy is specific to the product, not filler.

## Validation strategy

- Ask: could this exact screen appear unchanged in an unrelated product? If yes, why?
- Confirm type scale and spacing come from a system, not from ad-hoc values.
- Check that no element exists solely to look "designed".
- Confirm text content is specific; flag placeholder copy.

## Reference

- General visual design and typography fundamentals; the design-system and ui-ux-design skills.
