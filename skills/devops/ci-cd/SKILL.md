---
name: ci-cd
description: Build pipelines that are fast, least-privilege, pinned, and that fail loudly on real problems. Use when creating or modifying CI/CD workflows.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# CI/CD

## Core principle

A pipeline exists to give trusted, fast feedback and to ship safely. It must be
reproducible, least-privilege, and must fail on real problems rather than silently pass.

## Operating procedure

1. **Trigger appropriately.** Run on the events that matter (pull requests, pushes to
   main, releases). Avoid running heavy jobs on every trivial event. Use path filters
   when a workflow only concerns part of the repository.

2. **Pipelines: fast checks first, then slow.**
   - Fast: formatting, lint, type check, unit tests.
   - Slower: integration tests, builds, security scans.
   - Slowest: end-to-end tests, release packaging.
   Fail fast so authors get feedback quickly.

3. **Least privilege.**
   - Set explicit, minimal `permissions:` on each workflow/job (default to `contents: read`).
   - Do not grant write permissions the job does not need.
   - Do not expose secrets to workflows that run untrusted code (e.g. PRs from forks).

4. **Pin dependencies.**
   - Pin third-party actions to a full commit SHA (not a mutable tag) so a hijacked tag
     cannot change what runs.
   - Pin tool and runtime versions so a runner image change does not silently break builds.

5. **Be reproducible.** Use lockfiles and pinned versions; cache dependencies where it
   helps, keyed on the lockfile.

6. **Handle secrets safely.** Use the platform's secret store; never print secrets; scope
   them to the steps that need them; never make them available to untrusted PR runs.

7. **Fail loudly, and only on real problems.**
   - A failing test must fail the pipeline.
   - Do not use `continue-on-error` or `|| true` to hide flaky or failing checks.
   - Retries on a flaky step hide nondeterminism; fix the cause where possible.

8. **Artifacts and reporting.** Upload useful artifacts on failure (logs, traces). Publish
   test results so failures are diagnosable from the PR.

9. **Release process explicitly.** Do not publish releases as a side effect of a merge
   without a documented, intentional release trigger and the required approvals.

## Quality criteria

- Workflows declare least-privilege permissions explicitly.
- Third-party actions are pinned to commit SHAs.
- Secrets are scoped and never exposed to untrusted runs.
- Real failures fail the build; nothing is swallowed with `continue-on-error`.
- Release publishing has an explicit, documented trigger.

## Anti-patterns to avoid

- Unpinned actions referenced by a moving tag.
- `permissions: write-all` when read is enough.
- Passing repository secrets to workflows triggered by forked PRs.
- `|| true` on a test or lint step.
- Retrying a flaky test indefinitely instead of fixing it.
- Auto-publishing a release on every push to main.

## Validation strategy

- Confirm each workflow sets explicit minimal permissions.
- Confirm each third-party action is pinned to a SHA.
- Confirm a deliberately introduced failure fails the pipeline.
- Confirm release workflows require an explicit trigger, not a push.

## Reference

- GitHub Actions security hardening guidance; SLSA supply-chain levels.
