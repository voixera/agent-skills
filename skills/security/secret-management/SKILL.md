---
name: secret-management
description: Keep credentials out of code, logs, fixtures, and docs, and load them from the environment or a secret store. Use when handling API keys, tokens, passwords, or connection strings.
metadata:
  category: security
  version: 1.0.0
  agents: all
---

# Secret Management

## Core principle

A secret that exists in source control, a log file, a test fixture, or a screenshot is
compromised. Treat secrets as values that live only in a secret store and reach the code
at runtime through the environment or an injector.

## Operating procedure

1. **Never commit secrets.**
   - No keys, tokens, passwords, or connection strings in source, tests, fixtures,
     notebooks, or documentation.
   - Provide a `.env.example` with placeholder values, and add `.env` and similar to
     `.gitignore`.
   - Use obviously fake placeholders in docs (`YOUR_API_KEY_HERE`), never a real value.

2. **Load secrets at runtime** from the environment or a secret manager (Vault, cloud
   secret services, CI secret stores). Do not bake them into images or artifacts.

3. **Validate presence at startup, not usage.** Fail fast if a required secret is missing,
   and fail with a message that names the variable, not its value.

4. **Never log secrets.** Redact tokens, authorization headers, passwords, and set-cookie
   values in logs and error output. Be careful with request/response body logging, which
   often carries credentials.

5. **Scope and rotate.** Give each secret the least privilege it needs, separate secrets
   per environment, and rotate on a schedule and immediately on suspected exposure.

6. **Handle exposure correctly.** If a secret was committed, deleting it in a new commit
   is not enough - it remains in history. Rotate the secret first, then purge history and
   audit for misuse.

7. **Guard against accidental leakage in tools.** Ensure test fixtures, example files, and
   generated documentation use placeholders. Be cautious with dumps, seed data, and
   screenshots.

## Quality criteria

- No secrets in the repository, including history-sensitive places like fixtures and docs.
- Secrets come from the environment or a secret store.
- Startup validates required secrets and fails clearly without printing values.
- Logs and errors redact secret-bearing fields.
- Secrets are scoped per environment and rotatable.

## Anti-patterns to avoid

- Committing a `.env` file, even once.
- Using a real key in an example or test for "convenience".
- Logging the full request including the `Authorization` header.
- One shared secret across all environments.
- Relying on deleting a leaked secret from the latest commit to fix the exposure.
- Hardcoding a fallback secret "just for development" that ships to production.

## Validation strategy

- Grep the tree (and templates) for common secret patterns; investigate every hit.
- Confirm `.gitignore` excludes secret files and that a placeholder example exists.
- Confirm logs redact sensitive fields (read the logging configuration).
- Confirm startup fails clearly when a required secret is absent, without printing its value.
- If a secret is suspected to have leaked, verify rotation occurred, not just deletion.

## Reference

- OWASP Secrets Management Cheat Sheet; provider guidance on secret rotation.
