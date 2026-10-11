---
name: frontend-performance
description: Make evidence-based frontend performance decisions about bundles, images, fonts, caching, and rendering. Use when the user reports slowness, when adding a large dependency, or when optimizing load and interaction performance.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Frontend Performance

## Core principle

Do not add an optimization without a reason and a measurement. "It might be
faster" is not a reason. A profile, a bundle report, or a Core Web Vitals number is.

## Operating procedure

1. **Establish what is actually slow.** Identify the metric that matters: load
   time, Time to Interactive, Largest Contentful Paint, or a specific interaction.
   Do not optimize blindly.

2. **Bundle size.**
   - Inspect the bundle with the project's analyzer before adding a dependency.
   - Prefer the platform or existing code over a new library for small needs.
   - Import only what is needed (`import { x } from 'lib'` patterns, per-module imports).
   - Code-split at route boundaries and for rarely used heavy features.

3. **Images.**
   - Serve appropriately sized images; use `srcset`/`sizes` when the pipeline allows.
   - Use modern formats (WebP/AVIF) where supported, with a fallback.
   - Always set width and height (or aspect-ratio) to prevent layout shift.
   - Lazy-load images below the fold, but never lazy-load the LCP image.

4. **Fonts.**
   - Limit the number of families and weights.
   - Use `font-display: swap` (or the project's chosen strategy) to avoid invisible text.
   - Self-host or preconnect to font origins to reduce connection setup cost.
   - Reserve space to reduce layout shift when the font loads.

5. **Rendering.**
   - Avoid long synchronous work on the main thread; defer or chunk it.
   - Avoid layout thrashing (read/write style in tight loops).
   - Virtualize genuinely long lists; do not virtualize a 20-item list.
   - Avoid unnecessary re-renders (see the React skill for the measured approach).

6. **Caching.**
   - Use content-hashed asset filenames with long cache lifetimes.
   - Set correct caching for HTML (short) versus static assets (long).
   - Verify what the server actually sends; do not assume.

7. **Core Web Vitals awareness.** For each change, ask which of LCP, INP, or CLS it
   could affect, and whether the change helps or hurts.

## Quality criteria

- Every optimization is tied to a measurement or a concrete, stated hypothesis.
- No layout shift introduced by images, fonts, or async content.
- The LCP element is not lazy-loaded or blocked.
- Dependency additions are justified against their bundle cost.

## Anti-patterns to avoid

- Adding a memoization library before measuring.
- Lazy-loading above-the-fold content.
- Loading a large icon/UI library for a handful of icons.
- `preload` on everything, which competes for bandwidth.
- Claiming a speedup without measuring before and after.

## Validation strategy

- Re-measure after the change and compare against the "before" number.
- Use the bundle analyzer for size claims.
- Use Lighthouse or the browser performance panel when available.
- If no measurement tool is available in this environment, say the change is
  *unverified* rather than *faster*.

## Reference

- web.dev: Core Web Vitals; MDN: resource hints and image optimization.
