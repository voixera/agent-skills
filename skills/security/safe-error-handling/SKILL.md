---
name: safe-error-handling
description: Return useful errors to users and logs without leaking stack traces, queries, or internal identifiers. Use when designing error responses, logging, or exception handling.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# Safe Error Handling

## Core principle

Errors serve two audiences with different needs. The user needs a clear, actionable
message. The developer needs full diagnostic detail in the logs. These must not be the
same message: the user's copy must never contain implementation internals.

## Operating procedure

1. **Separate user-facing and internal detail.**
   - Client response: a stable error code, a plain-language message, and field-level
     detail for validation errors. Nothing more.
   - Log: the full exception, stack trace, correlation id, and context - server-side only.

2. **Never leak internals to clients.** Exclude from responses:
   - Stack traces and exception class names.
   - SQL statements, query fragments, or ORM internals.
   - File system paths, internal hostnames, and service names.
   - Framework/library version banners.
   - Secrets, tokens, and personal data.

3. **Fail closed.** An error in a check must deny access, not allow it. Do not let an
   exception in an authorization path fall through to a permissive default.

4. **Map errors to status codes consistently** in one place (see the api-design skill).
   A validation failure is a `400`/`422`, not a `500`. An unhandled error is a `500` with
   a generic message and a correlation id.

5. **Log with correlation.** Give each request a correlation/request id, include it in the
   response, and log it with the internal detail so a user report can be traced to the
   full error. Log at appropriate levels (expected validation at `info`/`warn`, unexpected
   failures at `error`).

6. **Do not swallow errors.** Catching and ignoring an exception hides failures. If an
   error is recoverable, handle it explicitly and, where appropriate, log it. If not,
   let it propagate to the central handler.

7. **Sanitize error output where it may be reflected.** If an error message includes
   user-supplied input, encode it for the output context to avoid injection through the
   error path.

## Quality criteria

- Client errors contain a code, a clear message, and field detail only - no internals.
- Full detail is logged server-side with a correlation id.
- Authorization and validation failures fail closed.
- Status codes are mapped consistently in one place.
- Errors are not silently swallowed.

## Anti-patterns to avoid

- `res.status(500).json({ error: err.stack })`.
- Echoing a raw SQL error or query back to the client.
- A catch block that returns success or an empty result on failure.
- Logging the full request body when it may contain secrets.
- Different error shapes from different handlers.

## Validation strategy

- Trigger a server error and confirm the response contains no stack trace, path, or query.
- Confirm the same error's full detail appears in the logs with a correlation id.
- Confirm a validation failure returns `400`/`422`, not `500`.
- Grep for `catch` blocks that swallow errors or return success.
- Confirm authorization failures deny access.

## Reference

- OWASP Error Handling Cheat Sheet; RFC 9457 (Problem Details).
