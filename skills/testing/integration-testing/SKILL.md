---
name: integration-testing
description: Test real boundaries including databases, HTTP APIs, authentication flows, and third-party failures. Use when verifying that components work together, especially across a database or an external service.
metadata:
  category: testing
  version: 1.0.0
  agents: all
---

# Integration Testing

## Core principle

Unit tests prove a function is correct in isolation. Integration tests prove the parts
work together - which is where most real failures live: wiring, serialization,
transactions, and how the code reacts when a dependency misbehaves.

## Operating procedure

1. **Test at real boundaries with real dependencies where feasible.**
   - Use a real database instance, ideally containerized or an ephemeral test database,
     rather than mocking the data layer for critical paths.
   - Exercise the actual HTTP stack (the real router, middleware, and serialization),
     not a bypass that skips the layer you want to verify.
   - The point is to catch wiring mistakes that unit tests structurally cannot.

2. **Cover the important integration points:**
   - **Database** - reads/writes, constraints, transactions, rollback on error, and
     migration compatibility.
   - **API boundaries** - status codes, request validation, error shapes, pagination.
   - **Authentication/authorization** - real login/session/token flow; verify that an
     unauthorized caller is actually rejected end to end.
   - **External services** - use a fake server, recorded fixtures, or a sandbox; verify
     the client's behavior against realistic responses.
   - **Failure handling** - timeouts, `5xx`, connection refused, and malformed responses.

3. **Isolate test data.** Each test creates and cleans up its own data. Do not depend on
   seed data that another test may mutate. Run against a throwaway database when possible.

4. **Control nondeterminism.** Freeze time, stub randomness, and set fixed ids where the
   assertions depend on them.

5. **Test failure paths explicitly.** Deliberately make the dependency fail (stop the
   service, return an error, delay the response) and assert the code handles it as
   designed - retry, rollback, or a clear error.

6. **Keep them runnable in CI.** Provide a scripted, reproducible way to start the
   dependencies (compose file, testcontainers, or documented setup). A test nobody can
   run is not a test.

## Quality criteria

- Critical paths use real dependencies, not mocks that hide wiring bugs.
- Database, API, auth, and failure paths are each covered.
- Tests are isolated, deterministic, and repeatable in CI.
- Unauthorized access is verified to be actually rejected.
- External dependencies have a reproducible test substitute.

## Anti-patterns to avoid

- Mocking the exact layer you are trying to test.
- Shared mutable seed data across tests.
- Testing only the happy path; no failure/timeout/timeout coverage.
- Tests that require a manually prepared database, so they never run in CI.
- Treating a mocked external service's success as proof of integration correctness.

## Validation strategy

- Confirm the integration suite starts its dependencies via a scripted, documented path.
- Confirm at least one test makes each dependency fail and asserts the handling.
- Confirm an unauthorized request to a protected endpoint returns denial.
- Report which integrations were tested against a real dependency vs. a fake.

## Reference

- Testcontainers-style ephemeral dependency patterns; provider sandbox documentation.
