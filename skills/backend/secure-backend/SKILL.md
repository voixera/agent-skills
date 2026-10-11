---
name: secure-backend
description: Validate input, encode output, prevent injection, limit rates, and handle secrets, uploads, and errors safely. Use when writing or reviewing server-side request handling, data access, file handling, or integrations.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Secure Backend

## Core principle

Everything from the client is untrusted until validated at the server boundary.
Assume an attacker controls every header, parameter, body field, and file.

## Operating procedure

1. **Validate input at the boundary** (see the data validation skill). Reject
   unexpected shapes and unknown fields. Enforce type, range, length, and format.

2. **Prevent injection.**
   - Use parameterized queries / prepared statements for all database access. Never
     concatenate untrusted input into SQL, NoSQL filters, or shell commands.
   - For shelling out, avoid string interpolation; pass an argv array to an exec
     API that does not invoke a shell.
   - For LDAP, XML, or template engines, use the safe APIs and disable external
     entity/DOM resolution where applicable.

3. **Encode output for its context.** Escape HTML, attribute, URL, JS, and CSS
   contexts appropriately. Prefer a framework that auto-escapes, and avoid raw-HTML
   escape hatches unless the content is sanitized.

4. **Handle SSRF risk.** When the server fetches a user-supplied URL, restrict
   schemes, block internal address ranges and metadata endpoints, and prefer an
   allow-list of hosts. Do not fetch a URL provided directly by an untrusted caller
   without these controls.

5. **Rate-limit and bound resources.** Apply rate limits to authentication,
   expensive operations, and anything an attacker can amplify. Cap request body
   sizes, upload sizes, query complexity, and timeouts.

6. **Secure file uploads.** Validate content type by inspecting content, not just the
   extension or the client-declared header. Store outside the web root or in object
   storage. Rename to a generated name. Never trust the client filename for a path
   (see secure file handling).

7. **Manage secrets safely.** Secrets come from the environment or a secret manager,
   never from source or the registry. Never log them (see secret management).

8. **Handle errors safely.** Return generic messages to clients and detailed ones to
   logs. Do not leak stack traces, SQL, or internal identifiers (see safe error handling).

9. **Review dependencies** for known vulnerabilities and remove unused ones.

10. **Log without sensitive data.** Log identifiers, not payloads containing
    credentials, tokens, or personal data.

## Quality criteria

- No string-built SQL/shell commands from untrusted input.
- Output encoding matches the rendering context.
- Outbound fetches of user URLs apply SSRF controls.
- Rate limits and size/time caps exist on abusable endpoints.
- Uploads validated by content and stored safely.
- No secrets in code or logs; errors do not leak internals.

## Anti-patterns to avoid

- `db.query("... WHERE id = " + req.query.id)`.
- `child_process.exec("convert " + filename)`.
- Reflecting a user URL into a server-side fetch without restriction.
- Trusting `Content-Type`/file extension as proof of a file's type.
- `catch (e) { res.status(500).send(e.stack) }`.

## Validation strategy

- Grep for query/command construction from request data; each hit needs review.
- Grep for outbound fetch helpers and confirm SSRF controls.
- Check that error responses do not include stack traces or query text.
- Run a dependency audit if a tool is available; state clearly if it was skipped.

## Limitations

These checks reduce common classes of issues but do not prove an application is
secure. Absence of findings is not evidence of safety. State this rather than
claiming the backend "is secure".

## Reference

- OWASP Top 10; OWASP Cheat Sheet Series (Injection Prevention, SSRF Prevention, File Upload).
