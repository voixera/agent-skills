---
name: environment-config
description: Separate configuration from code, document required variables, and validate configuration at startup. Use when adding configuration, environment variables, or deployment settings.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# Environment Configuration

## Core principle

Configuration that varies between environments belongs in the environment, not in the
code. It should be read in one place, validated at startup, and documented so a new
deployment does not fail mysteriously.

## Operating procedure

1. **Separate the three kinds of values:**
   - **Config** - non-secret settings (feature flags, ports, URLs). From environment or
     a config file.
   - **Secrets** - credentials, keys, tokens. From a secret store or environment, never
     from source (see secret-management).
   - **Code constants** - values that truly never vary. These may live in code.

2. **Read configuration in one place.** A single config module reads and exposes typed
   values. The rest of the application imports from it. Do not scatter `process.env.X`
   or `os.environ` reads through the codebase.

3. **Validate at startup, fail fast.** Check that required values are present and
   well-formed when the application starts, with a message that names the missing
   variable. Do not discover a missing value as a runtime error three requests in.

4. **Provide a documented template.** Commit a `.env.example` (or equivalent) listing
   every variable, its purpose, and a safe placeholder value. Never commit real values.
   Document which are required and which are optional with defaults.

5. **Apply sane defaults carefully.** A default is fine for non-sensitive, non-ambiguous
   settings. Do not default a security-relevant value to the insecure option, and do not
   default a required secret to a placeholder that would "work" but be wrong.

6. **Keep environments consistent.** Dev, staging, and prod should differ only in values,
   not in the shape of the configuration. Avoid "it works in staging because staging has
   an extra variable".

7. **Support configuration without redeploys** where the platform expects it (environment
   variables injected at runtime), and do not bake environment-specific values into
   build artifacts.

## Quality criteria

- Configuration is read in one place and exposed as typed values.
- Required values are validated at startup with clear errors that do not print values.
- A `.env.example` documents every variable with safe placeholders.
- Secrets are separated from non-secret config and never committed.
- No environment-specific values are baked into build artifacts.

## Anti-patterns to avoid

- `process.env.FOO` read in dozens of files.
- A missing required variable causing a confusing runtime error.
- Defaulting a secret to a real-looking value.
- Committing a real `.env`.
- Environment-specific branches in code (`if (env === 'prod') doSomethingDifferent`) for
  pure configuration differences.
- Documenting variables that no longer exist, or omitting ones that do.

## Validation strategy

- Grep for environment reads outside the config module.
- Start the application with a required variable removed and confirm a clear startup error.
- Confirm `.env.example` lists every variable the code reads.
- Confirm no real values are committed.

## Reference

- The Twelve-Factor App, "Config"; language-specific configuration library docs.
