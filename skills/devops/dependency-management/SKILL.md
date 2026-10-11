---
name: dependency-management
description: Add dependencies only when justified, keep lockfiles committed, and update deliberately. Use when adding, removing, or updating packages.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# Dependency Management

## Core principle

Every dependency is code you will maintain forever but did not write. Add one when it
saves more than it costs; remove one when it does not. Prefer the platform and your own
small, tested code over a package for something trivial.

## Operating procedure

1. **Justify every addition.**
   - What does it do that the platform or existing dependencies do not?
   - Is it maintained (recent releases, responsive issues, a real maintainer)?
   - How large is it and what does it drag in transitively?
   - Is the license compatible with the project?
   If you cannot answer these briefly, do not add it yet.

2. **Prefer, in order:** the language/platform standard library, an existing dependency
   already in the project, a small focused package, then a large framework. Avoid pulling
   a framework for a single function.

3. **Keep manifests tidy.**
   - Separate runtime and development dependencies correctly.
   - Remove dependencies that are no longer imported.
   - Keep the versions of the same package consistent across the workspace.

4. **Commit lockfiles.** The lockfile pins the exact resolved tree so builds are
   reproducible. Do not ignore it, and do not edit it by hand.

5. **Update deliberately, not blindly.**
   - Read the changelog for breaking changes before a major update.
   - Update in reviewable batches, running tests after each.
   - Do not let "update everything" sweep in unrelated major versions with no review.

6. **Watch for duplication.** Multiple versions of the same package (especially in the
   frontend bundle) bloat output and can cause subtle bugs; deduplicate where possible.

7. **Audit for vulnerabilities** on a cadence (see dependency-auditing).

## Quality criteria

- Every dependency has a stated justification.
- No unused dependencies remain.
- Lockfile is committed and consistent with the manifest.
- Major updates are reviewed against changelogs, not applied blindly.
- Licenses are compatible with the project.

## Anti-patterns to avoid

- Adding a package for something the standard library does.
- Leaving an unmaintained or unused dependency in place.
- Ignoring the lockfile or hand-editing it.
- A single "update all the things" commit with no review.
- Multiple major versions of the same package coexisting unnecessarily.

## Validation strategy

- Grep for imports and cross-check against the manifest for unused dependencies.
- Confirm the lockfile is committed and matches the manifest.
- Review `git diff` on the manifest for every added package and confirm justification.
- For a major update, cite the changelog's breaking changes and how they were handled.

## Reference

- Language ecosystem docs on lockfiles and dependency classification; SPDX license list.
