---
name: responsive-design
description: Build layouts that work across viewport sizes, handle overflow and text wrapping, and keep mobile navigation usable. Use when creating or reviewing layouts, navigation, tables, or any component that must work on small and large screens.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Responsive Design

## Operating procedure

1. **Design mobile-first unless the product is genuinely desktop-only.** Write base
   styles for the smallest supported viewport, then progressively add complexity at
   larger breakpoints. If the product is desktop-only, say so and skip this.

2. **Use the project's existing breakpoints.** Read the design tokens or theme
   first. Do not invent new breakpoints alongside existing ones.

3. **Test at real sizes, not just one "mobile" number.** Check at least:
   - ~320 px (small phone, narrowest realistic)
   - ~768 px (tablet / narrow window)
   - ~1024-1440 px (desktop)
   Confirm the layout does not break *between* these, not only at them.

4. **Handle the hard cases explicitly:**
   - **Long words and URLs** - allow wrapping (`overflow-wrap: anywhere`) where
     content is user-supplied.
   - **Overflow** - decide per element whether it wraps, scrolls, or truncates; do
     not let content push the page horizontally.
   - **Tables** - on narrow screens, either scroll the table horizontally or switch
     to a stacked card layout; never let columns squish into unreadable slivers.
   - **Images** - constrain with `max-width: 100%` and preserve aspect ratio to
     avoid layout shift; use responsive `srcset` when the asset pipeline supports it.
   - **Flex/grid children** - watch for `min-width: auto` issues that prevent
     shrinking; set `min-width: 0` where a child must shrink.

5. **Touch targets.** Interactive elements should be at least ~44x44 px on touch
   devices. Check icon buttons, close buttons, and dense list rows.

6. **Mobile navigation.** Ensure the primary navigation is reachable on small
   screens, the open/closed state is clear, and it is keyboard and screen-reader
   accessible (see the accessibility skill).

7. **Layout stability.** Reserve space for images, banners, and async content so
   elements do not jump as content loads.

## Quality criteria

- No horizontal page scrollbar at any supported width (except intentional table
  scroll containers).
- Text does not overlap or clip at the smallest supported width.
- Navigation is usable and reachable on mobile.
- Touch targets meet the minimum size on touch layouts.
- No layout shift from un-reserved media or late content.

## Anti-patterns to avoid

- Fixed pixel widths that assume a desktop viewport.
- `overflow: hidden` used to hide a layout bug instead of fixing it.
- Hiding essential content on mobile with `display: none` when it is still needed.
- A single breakpoint that flips between two desktop-ish layouts.
- Assuming the viewport equals the device width without a viewport meta tag.

## Validation strategy

- Resize the browser (or use device emulation) through the supported range and
  watch for overflow, overlap, and clipping.
- Check the smallest supported width specifically.
- Tab through interactive elements to confirm touch/click targets and focus order.
- If you cannot render the UI in this environment, state that visual verification
  was not performed.

## Reference

- MDN: Responsive design; CSS flexible box and grid layout.
