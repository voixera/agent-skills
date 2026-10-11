---
name: api-design
description: Design HTTP APIs with clear semantics, correct status codes, validation, pagination, and consistent error shapes. Use when adding or changing API endpoints, request/response shapes, or error handling.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# API Design

## Operating procedure

1. **Name resources, not actions.** Prefer nouns for resources (`/orders`,
   `/orders/{id}`) and use HTTP methods for the verb. Use action-style sub-paths
   only when an operation genuinely is not a resource change (e.g. `/orders/{id}/cancel`).

2. **Use methods and status codes correctly.**
   - `GET` read (safe, no side effects), `POST` create, `PUT` full replace,
     `PATCH` partial update, `DELETE` remove.
   - `200` OK, `201` Created (with `Location`), `204` No Content, `400` bad request,
     `401` unauthenticated, `403` authenticated but not allowed, `404` not found,
     `409` conflict, `422` semantically invalid, `429` rate limited, `500` server error.
   - Do not return `200` with an error body. Do not return `500` for user input errors.

3. **Validate input at the boundary.** Reject unknown or malformed fields explicitly
   (see the data validation skill). Return a `400`/`422` with field-level detail.

4. **Use one consistent error shape** across the whole API, for example:
   ```json
   { "error": { "code": "invalid_email", "message": "Human readable.",
                "details": [ { "field": "email", "issue": "must contain @" } ] } }
   ```
   Never leak stack traces or internal identifiers (see safe error handling).

5. **Paginate collections.** Choose one scheme and document it:
   - Cursor-based for large or frequently changing sets (stable under inserts).
   - Offset/limit for small, stable sets.
   Always return the pagination metadata the client needs (next cursor / total where cheap).
   Never return an unbounded full collection by default.

6. **Filtering, sorting, and field selection.** Define explicit, allow-listed query
   parameters. Never pass raw client-provided sort/filter strings into queries without
   allow-listing (see secure backend).

7. **Idempotency.** For unsafe operations that clients may retry (payments, order
   creation), support an idempotency key so a repeated request does not duplicate the
   effect. Document which endpoints honor it.

8. **Versioning only when justified.** Prefer additive, backward-compatible change. If
   you must break compatibility, version explicitly (`/v2`) or via a header, and
   document the deprecation path.

9. **Document the API.** Keep an OpenAPI/similar spec or a written contract in sync
   with the implementation, including error codes and pagination.

## Quality criteria

- Methods and status codes match the semantics.
- One error shape across all endpoints, including validation detail.
- Collections are paginated with a documented scheme.
- Unsafe retryable operations support idempotency.
- The contract is documented and matches the code.

## Anti-patterns to avoid

- `POST /getUserList` style RPC over nouns.
- `200 OK` wrapping an error, or `500` for a validation failure.
- Unbounded list endpoints.
- Inconsistent error shapes between endpoints.
- Breaking changes shipped without versioning or a migration path.
- Documenting an endpoint that does not exist, or omitting one that does.

## Validation strategy

- For each endpoint, check method, success status, and at least one error status
  against this list.
- Confirm error responses share one schema.
- Confirm list endpoints accept and honor pagination parameters and reject
  arbitrary sort/filter input unless allow-listed.
- If an OpenAPI spec exists, diff it against implemented routes.

## Reference

- RFC 9110 (HTTP semantics); RFC 9457 (Problem Details for HTTP APIs).
