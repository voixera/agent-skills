---
name: frontend-architecture
description: Understand and respect existing frontend structure before changing code, and keep components, state, and data access appropriately separated. Use when adding a feature to an existing frontend, refactoring a UI module, or deciding where new code belongs.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# Frontend Architecture

## When to use this skill

Use this before writing frontend code in an existing project, or when a change
touches more than one component, when deciding where logic belongs, or when asked
to "clean up" or "restructure" part of the UI.

## Operating procedure

1. **Map the project before editing.** Read the existing tree, the entry points,
   the routing setup, the state layer if any, and at least two existing
   components that resemble what you are about to build. Do not design in the
   abstract when a working example already exists.

2. **Identify the project's conventions and state them back.** Note:
   - Component file layout and naming (folder-per-component vs flat).
   - Styling approach (CSS modules, Tailwind, styled-components, plain CSS).
   - State management (local state, context, a store library).
   - Data fetching (route loaders, a query library, hand-written effects).
   - TypeScript usage and strictness.

3. **Place new code according to those conventions.** If the project co-locates
   tests and styles with components, do the same. Do not introduce a new pattern
   for a single feature.

4. **Separate four concerns explicitly:**
   - **Presentation** - rendering and layout only.
   - **Application logic** - orchestration, event handling, derived state.
   - **State** - where data lives and who owns it.
   - **Data access** - how the app talks to APIs or storage.

   A component may reasonably own more than one of these when it is small. Split
   only when a concern genuinely has a second consumer or is genuinely testable
   in isolation.

5. **Reuse before inventing.** Search for an existing component, hook, utility, or
   type before adding a new one. Prefer extending an existing primitive over
   creating a near-duplicate.

6. **Preserve behavior.** Unless the request is explicitly to change behavior,
   the diff should not alter unrelated screens, request shapes, or user flows.

## Quality criteria

- New code sits where a maintainer would expect to find it.
- No new architectural pattern is introduced for a single use.
- State has a single clear owner; no duplicated source of truth.
- Data access is not embedded in presentational components.
- The change does not rewrite unrelated functionality.

## Anti-patterns to avoid

- Introducing a global store, context, or service layer for a feature that only
  one component needs.
- Copying a component and editing the copy instead of parameterizing the original.
- "While I was here" refactors that expand the diff beyond the request.
- Abstraction layers with a single implementation and no second caller.
- Rewriting a working module because the code style differs from your preference.

## Validation strategy

- Diff review: confirm every changed file relates to the request.
- Grep for new duplicate modules that overlap with existing ones.
- Confirm at least one existing component was read before the new one was written.
- Run the project's existing lint and type checks if present.

## Reference

- React docs, "Thinking in React" (mirrors the component/state/data split used here).
