---
name: authentication-authorization
description: Separate authentication from authorization, enforce least privilege and ownership checks, and handle sessions and tokens safely. Use when implementing login, sessions, tokens, roles, permissions, or any access control decision.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Authentication and Authorization

## Core distinction

- **Authentication** answers "who is this?" (login, session, token identity).
- **Authorization** answers "is this identity allowed to do this, to this object?"

They are separate concerns. A valid login is not permission for anything specific.

## Operating procedure

1. **Authenticate once, centrally.** Implement a single mechanism (session cookie or
   token) and a single middleware/guard that resolves the current identity. Do not
   scatter ad-hoc identity parsing across handlers.

2. **Handle passwords safely** (when passwords are used).
   - Store only a salted, slow hash (Argon2id, scrypt, or bcrypt with a sufficient
     work factor). Never store or log plaintext or reversible encryption.
   - Compare with a constant-time comparison where applicable, via the library's API.
   - Do not cap password length to something short; do allow long passphrases.

3. **Sessions.**
   - Use opaque session identifiers with high entropy; store server-side.
   - Set cookie flags: `HttpOnly`, `Secure`, `SameSite` (usually `Lax` or `Strict`).
   - Regenerate the session id on login; invalidate on logout.
   - Enforce an idle and absolute expiry.

4. **Tokens** (JWT or opaque).
   - Keep access tokens short-lived; use a refresh mechanism if the UX requires it.
   - Verify signature and standard claims (`exp`, `iss`, `aud`) on every use; never
     trust a token body without verification.
   - Do not put secrets in token payloads - the payload is readable.
   - Support revocation or short expiry for logout/compromise.
   - Store tokens where script cannot read them for web clients (avoid `localStorage`
     for session tokens when a cookie is viable).

5. **Authorize on the server, always.** Client-side checks are UX only. Every
   protected action re-checks permission server-side. Never treat a hidden button as
   authorization.

6. **Enforce ownership (IDOR protection).** For object access, verify that the current
   identity owns or is permitted to access the specific object id in the request - do
   not assume an id only appears in the UI if the user should see it.

7. **Apply least privilege.** Grant the minimum role/permission needed. Model roles as
   sets of explicit permissions rather than burying branch logic in handlers. Deny by
   default.

8. **Expire and log out correctly.** Logout invalidates the session/token. Expiry is
   enforced server-side, not only by the client deleting a token.

## Quality criteria

- One central place resolves the current identity.
- Passwords hashed with a slow algorithm; nothing sensitive logged.
- Cookie/token flags set correctly; expiry enforced server-side.
- Every protected route has an explicit authorization check.
- Ownership is verified per object, not assumed from the UI.
- Logout and expiry actually invalidate access.

## Anti-patterns to avoid

- `if (user.role === 'admin')` checks missing on the server, present only in the client.
- Fetching an object by id without checking ownership.
- Tokens stored in `localStorage` and sent as `Authorization` from untrusted script.
- Long-lived access tokens with no revocation.
- Rolling your own crypto or password hashing.
- Logging tokens, passwords, or session ids.

## Validation strategy

- For each protected endpoint, find the server-side authorization check. If absent, it
  is a defect.
- Attempt to access another user's object id with a valid session for a different user
  (in a test environment with authorization) and confirm denial.
- Confirm logout invalidates the session/token server-side.
- If you cannot execute these tests, mark them as not performed rather than passed.

## Reference

- OWASP Authentication and Authorization Cheat Sheets; OWASP Top 10 Broken Access Control.
