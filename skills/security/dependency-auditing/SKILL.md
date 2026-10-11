---
name: dependency-auditing
description: Check dependencies for known advisories, unused packages, and unnecessary transitive surface. Use when adding dependencies, reviewing supply-chain risk, or responding to a vulnerability report.
metadata:
  category: security
  version: 1.0.0
  agents: all
  tools: npm, pip-audit
---

# Dependency Auditing

## Core principle

Every dependency is code you did not write but do run, and it brings transitive
dependencies with it. Treat the dependency tree as part of your attack surface and keep
it as small and current as the project allows.

## Operating procedure

1. **Inventory the dependencies.**
   - Direct dependencies from the manifest.
   - The transitive tree (most dependencies of a dependency you never chose).
   - Lockfiles, which pin the exact resolved versions.

2. **Run an audit with the ecosystem's tool where available:**
   - Node: `npm audit` (or `pnpm audit` / `yarn npm audit`).
   - Python: `pip-audit` or `safety`.
   - Other ecosystems: the language's advisory database tool.
   Report the real output. If the tool is not installed, say the audit was **skipped** -
   do not report it as passing.

3. **Triage findings by exploitability**, not by count. A known advisory in a package used
   only in dev tooling is different from one in a request-handling path. Note whether the
   vulnerable code path is reachable.

4. **Fix by updating, not by suppressing.** Prefer updating to a patched version. If a
   fix is unavailable, document the risk, the mitigation or compensating control, and a
   follow-up. Do not add a blanket ignore without a written reason.

5. **Reduce the surface.**
   - Remove dependencies that are unused.
   - Replace heavy dependencies used for one small function with a small implementation,
     when that is genuinely less risky and maintainable.
   - Prefer well-maintained, widely used packages over obscure ones for security-relevant
     functionality (crypto, auth, parsing).

6. **Handle supply-chain hygiene.**
   - Commit lockfiles so builds are reproducible.
   - Use a maintained registry and consider integrity pinning where the ecosystem supports it.
   - Review new dependencies before adding them: maintenance activity, download counts,
     recent releases, and whether the scope is appropriate.

## Quality criteria

- An audit was actually run with a named tool, and its real result reported; otherwise
  reported as skipped.
- Findings are triaged by reachability and severity, not raw count.
- Fixes prefer updating over suppressing; suppressions have written reasons.
- Unused dependencies are removed.
- Lockfile is committed and consistent.

## Anti-patterns to avoid

- Reporting "dependencies are secure" without running any audit.
- Adding a blanket ignore rule to silence an audit.
- Adding a dependency for something the platform already does.
- Ignoring transitive dependencies because they were not directly chosen.
- Updating a major version blindly as a "fix" without checking for breaking changes.

## Validation strategy

- Run the audit tool and paste the real summary and count.
- Confirm the lockfile is committed and matches the manifest.
- Grep for imports to find dependencies declared but unused.
- For each suppression, confirm a reason is recorded.

## Reference

- Ecosystem advisory databases (npm advisories, OSV, PyPI advisories); SLSA and
  supply-chain guidance.
