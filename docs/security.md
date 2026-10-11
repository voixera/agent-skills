# Security model

This page describes what Agent Skills does and does not guarantee. The root
[SECURITY.md](../SECURITY.md) covers vulnerability reporting.

## Threat model

Agent Skills runs **locally**, **offline**, and writes **instruction and
configuration files**. It does not execute skill content, phone home, or require
credentials.

In-scope assets:

- The files in the selected installation scope (the user's project or config).
- The integrity of the registry and skill content.

Out of scope:

- The behavior of third-party agents after skills are installed.
- Optional external tools (a renderer, an optimizer, a linter) when you invoke
  them.
- Any guarantee about SVGs produced by an AI agent using these skills.

## Safety controls

### Scope confinement

Every write is checked against the selected scope root. A destination that
escapes the scope (for example via `..`) is refused with a `FAIL`. This is
enforced by `Test-AgentSkillsPathInsideRoot` in
`src/AgentSkills/Private/FileOps.ps1` and covered by tests in
`tests/unit/PathSafety.Tests.ps1`.

### No silent overwrites

If a destination exists but is **not tracked** by the manifest, the installer
refuses to overwrite it and exits with code `3`. Pass `-Force` to overwrite
explicitly; a backup of the original is written to `.agent-skills/backups/`
first.

Managed-block merges (aggregated instruction files) are the exception: only the
content between the `agent-skills:begin`/`agent-skills:end` markers is touched,
so a pre-existing file is not a conflict.

### Safe uninstall

Uninstall only removes files recorded in the manifest. Files outside the managed
block are never modified, and untracked files are never deleted. Shared managed
blocks are regenerated with the surviving skills rather than deleted.

### No code execution

The installer never runs skill content. Installing a skill writes files; it does
not evaluate them.

### SVG handling

The validator parses SVG with DTD processing **disabled** and external entity
resolution **off**, so validating an untrusted SVG does not expose the machine to
XXE. The security scan is pattern-based and documented as non-exhaustive.

## Secret hygiene

- The registry must never contain credentials or API keys.
- Skills must not instruct agents to log secrets or embed them in fixtures.
- CI includes a secret-scan step as a first line of defense. It is not a
  substitute for reporting a leaked secret privately.

## Reporting a vulnerability

See [SECURITY.md](../SECURITY.md). Report privately; do not open a public issue
with exploit details.

## Residual risks

- **Documented adapters can drift.** A vendor may change a path or format.
  Re-verify against your installed version.
- **`-Force` is powerful.** It overwrites untracked files. A backup is taken, but
  review `-Preview` output first.
- **The SVG scan is not exhaustive.** It reduces risk; it does not eliminate it.
- **User scope writes to your home directory.** Ensure `~` resolves as you
  expect before installing at user scope.
