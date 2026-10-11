---
name: authorization-review
description: Verify that every protected action enforces ownership and role server-side, not just in the client. Use when reviewing access control or auditing endpoints that return or modify user data.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# Authorization Review

## Core principle

Authentication tells you who is acting. Authorization decides whether that actor may
perform this specific operation on this specific object, and it must be enforced on the
server for every request. Anything the client decides is a UI convenience, not a control.

## Operating procedure

1. **Enumerate every protected operation.** List all endpoints/actions that read, modify,
   or delete non-public data, or that perform privileged actions.

2. **For each, find the server-side authorization check.** Look for:
   - Authentication required (a valid session/token resolves the actor).
   - **Function-level** check: the actor's role/permission permits this operation.
   - **Object-level** check: the actor is permitted to access *this* specific object
     (ownership or explicit grant).

   If any of the three is missing, it is a finding.

3. **Hunt for insecure direct object references (IDOR).** For every endpoint that takes an
   object id, confirm the server verifies the current actor may access that id. Fetching
   `GET /invoices/123` must check that invoice 123 belongs to (or is shared with) the
   caller - not merely that the caller is logged in.

4. **Verify deny-by-default.** Confirm that a request with no valid identity is rejected,
   and that an unknown/ambiguous permission resolves to denied rather than allowed.

5. **Check for client-only enforcement.** Confirm that hiding UI, disabling buttons, or
   client-side route guards are never the *only* protection. The same request sent
   directly must be rejected by the server.

6. **Check privilege escalation paths.** Can a user change their own role, assign
   themselves permissions, or modify another user's data by passing an id? Can a mass
   assignment update a `role` field from the request body?

7. **Check listing endpoints for leakage.** Collection endpoints must filter by the
   caller's access, not return everything and rely on the client to filter.

## Quality criteria

- Every protected operation has function-level and object-level checks server-side.
- Object access verifies ownership or explicit grant for the specific id.
- Access is denied by default for unauthenticated or unknown-permission requests.
- No client-only enforcement; direct requests are rejected too.
- No mass-assignment or privilege-escalation path.

## Anti-patterns to avoid

- `GET /resource/:id` with no ownership check.
- Relying on an unguessable id as the only protection (IDs leak).
- Assigning all request body fields to a model (allowing `role`/`ownerId` to be set).
- Filtering collections in the client instead of the query.
- A single blanket "is logged in" check used for all operations.

## Validation strategy

- For each endpoint, locate and cite the authorization check, or record its absence.
- With authorization, test cross-user access to another user's object id and confirm denial.
- Test an unauthenticated request to a protected endpoint and confirm rejection.
- Test whether a request body can set a privileged field on the caller's own record.
- If you cannot execute these tests here, mark them **not performed**, not passed.

## Reference

- OWASP Top 10 A01 Broken Access Control; OWASP Authorization Cheat Sheet.
