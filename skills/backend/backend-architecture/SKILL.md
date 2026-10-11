---
name: backend-architecture
description: Place domain logic, boundaries, configuration, and error handling sensibly without over-engineering small applications. Use when structuring a backend service, adding a module, or deciding where logic should live.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Backend Architecture

## Core principle

Architecture should reduce real complexity. A layered, heavily abstracted design on
a small application adds cost without benefit. Match structure to the problem.

## Operating procedure

1. **Understand the current structure and its scale.** A single-process app with
   three routes does not need the same structure as a service with multiple bounded
   contexts. Read the tree and the entry points first.

2. **Separate concerns along real seams:**
   - **Transport / HTTP layer** - parse request, validate input, call application
     logic, format response. No business rules here.
   - **Application / domain layer** - the rules of the business, independent of
     HTTP and the database where practical.
   - **Persistence layer** - data access behind a narrow interface.

   Introduce a repository or service boundary when there is a second caller, a
   testing need, or a real substitution point. Do not create one "for the future".

3. **Place domain logic in the domain layer**, not in controllers or ORM models
   where it becomes untestable and tangled with framework details.

4. **Manage configuration centrally.** Read configuration once at startup, validate
   it, and expose typed values. Do not scatter `process.env.X` reads through the code
   (see environment configuration).

5. **Handle errors consistently.** Define a small set of error types/kinds and map
   them to transport responses in one place. Do not let infrastructure errors become
   domain errors or vice versa.

6. **Manage dependencies explicitly.** Prefer constructor/parameter injection of
   collaborators over reaching for globals, so units can be tested in isolation.

7. **Define maintainable module boundaries.** A module owns its data and exposes a
   narrow interface. Do not let other modules reach into its internals.

## Quality criteria

- Business rules live in the domain layer and are testable without HTTP or DB.
- Configuration is read and validated in one place.
- Errors are mapped to responses in one place.
- New abstractions have a real second use, not a hypothetical one.
- Module boundaries are respected (no reaching into another module's internals).

## Anti-patterns to avoid

- Controllers containing business logic and SQL.
- A "service" and a "repository" and a "manager" for a task with one caller.
- `process.env` reads sprinkled throughout the codebase.
- God objects that everything imports.
- Errors swallowed and returned as `null`/falsy without a reason.
- Copying a large architectural template into a small app.

## Scope note

Start simple. Add layering when a real seam appears (a second consumer, a test
boundary, a substitution point). Document any layering you add and why.

## Validation strategy

- Confirm domain logic can be unit-tested without spinning up the transport layer.
- Confirm configuration is validated at startup and fails fast on missing values.
- Grep for `process.env` / config reads outside the config module.
- Confirm each abstraction has more than one caller or a clear substitution role.

## Reference

- Common layered/hexagonal architecture descriptions; "A Philosophy of Software Design"
  (matching complexity to need).
