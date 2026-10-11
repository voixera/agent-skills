---
name: react-best-practices
description: Apply sound React component boundaries, hook usage, state placement, and rendering behavior while following the project's existing React version. Use when writing or reviewing React components, hooks, or state logic.
metadata:
  category: frontend
  version: 1.0.0
  agents: all
---

# React Best Practices

## Scope

This skill applies to React projects. If the project is not React (Vue, Svelte,
Solid, Angular, or plain DOM), do not apply these rules - use the framework's own
conventions instead.

## Operating procedure

1. **Confirm the React version and framework.** Check `package.json`. A React 17
   project does not get concurrent features; a Next.js project has different data
   and rendering rules than a Vite SPA. Follow what is installed.

2. **Choose component boundaries by responsibility, not by line count.** Split a
   component when it has a distinct concern, a separate reason to change, or is
   reused. Do not split for its own sake.

3. **Apply hooks correctly.**
   - Keep hooks at the top level of the component; never inside conditions, loops,
     or nested functions.
   - List real dependencies in `useEffect`; do not silence the linter to avoid
     fixing the cause.
   - Use `useEffect` for synchronization with external systems, not for derived
     state that can be computed during render.
   - Clean up subscriptions, timers, and listeners.

4. **Put state at the lowest level that needs it.** Lift state only when two
   siblings must share it. Prefer local state over context over a store; escalate
   only when there is a concrete reason.

5. **Avoid unnecessary re-renders with measurement, not superstition.**
   - Do not wrap every function in `useCallback` or every value in `useMemo` by
     default; add them when a profile or a dependency chain justifies it.
   - Memoize expensive children with `React.memo` only when profiling shows the
     render cost matters.
   - Avoid creating new object or array literals in props for components that rely
     on referential equality.

6. **Handle all four UI states** for any data-driven view: loading, error, empty,
   and success. No component should silently render nothing on error.

7. **Do not duplicate business logic.** Extract shared logic into a hook or a pure
   module rather than copy-pasting it across components.

8. **Use TypeScript when the project already uses it.** Type props explicitly and
   avoid `any`; use `unknown` plus narrowing at boundaries.

## Quality criteria

- Hook dependency arrays are honest.
- No derived state stored in state and kept in sync manually.
- Each data view has explicit loading, error, empty, and success handling.
- Keys in lists are stable and unique (not array indices for reorderable lists).
- No `useEffect` used where an event handler or derived value would do.

## Anti-patterns to avoid

- `useEffect` that sets state from props to "sync" them.
- Index keys on lists that can reorder, causing state to attach to the wrong row.
- Premature `useMemo`/`useCallback` everywhere, adding noise without impact.
- Business logic duplicated in two components instead of shared.
- Assuming React 19 APIs in a React 17 codebase.

## Validation strategy

- Run the React Hooks ESLint rule and treat warnings as real.
- Confirm the React version in `package.json` matches the APIs used.
- For each data view, verify loading/error/empty/success paths exist in the code.
- If a re-render fix is claimed, state the measurement that justified it.

## Reference

- React docs: Rules of Hooks; You Might Not Need an Effect.
