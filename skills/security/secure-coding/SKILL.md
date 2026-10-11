---
name: secure-coding
description: Apply defensive coding habits such as validating untrusted input, encoding output, avoiding injection, and failing safely. Use as a baseline mindset for any code that handles untrusted data.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# Secure Coding

## Core principle

Assume every input from outside the trusted boundary is hostile. The job is not to
sanitize malicious intent (impossible) but to enforce a strict, well-defined contract so
that hostile input simply fails to be valid.

## Operating procedure

1. **Identify trust boundaries.** Data is untrusted until it crosses into trusted code
   through validation: HTTP requests, messages, webhooks, uploaded files, third-party
   responses, environment/config at startup, and CLI arguments.

2. **Validate with an allow-list, not a deny-list.** Define what is valid and reject
   everything else. Deny-lists miss variants; allow-lists do not.

3. **Encode output for its destination context.** HTML, attributes, URLs, JavaScript,
   CSS, and SQL each need different treatment. The context decides the encoding, not the
   convenience of the moment.

4. **Prefer safe APIs over string manipulation.**
   - Parameterized queries instead of concatenated SQL.
   - Arguments arrays instead of shell string interpolation.
   - A templating engine with auto-escaping instead of manual string building.

5. **Apply the principle of least privilege.** Run with the minimum permissions needed.
   Do not connect to the database as an admin user for routine application queries.

6. **Fail safely.** On error, deny by default. Do not fall through to a permissive state
   because a check threw an exception. Do not reveal internal details in error output.

7. **Keep dependencies minimal and current.** Every dependency is attack surface; remove
   unused ones and update deliberately (see dependency-auditing).

8. **Never hardcode secrets.** Read them from the environment or a secret store (see
   secret-management).

9. **Be explicit about limits.** No single check makes code secure. State which
   protections exist and which were not verified.

## Quality criteria

- Trust boundaries are identified and inputs are validated with an allow-list.
- Output is encoded per context; queries are parameterized; shell calls avoid interpolation.
- Errors fail closed and do not leak internals.
- Least privilege is applied to credentials and roles.
- No secrets in source; dependencies are minimal.

## Anti-patterns to avoid

- Concatenating untrusted values into SQL, shell, HTML, or URLs.
- Validating with a regex deny-list and calling it done.
- Catching an authorization error and continuing anyway.
- A shared "god" database credential used everywhere.
- Trusting a client-provided flag to set a server-side permission.

## Validation strategy

- For each boundary, confirm an allow-list validation exists.
- Grep for concatenated queries/commands and template injection points.
- Grep for secrets in source; confirm they are read from the environment.
- Report which behaviors were verified and which were assumed.

## Limitations

Secure coding reduces common vulnerability classes; it does not prove security. The
absence of findings is not a clean bill of health. Say so.

## Reference

- OWASP Top 10; OWASP Cheat Sheet Series.
