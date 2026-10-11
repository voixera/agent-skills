---
name: deployment-readiness
description: Confirm the release is actually ready: migrations, rollback, config, observability, and a documented runbook. Use before deploying to production.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# Deployment Readiness

## Core principle

"Ready to deploy" is a checklist, not a feeling. Verify each item and record the real
result; a deployment that passes some checks and skips others is not verified.

## Readiness checklist

1. **Tests.** The full relevant suite passes. Report the actual result. Do not deploy on a
   claimed pass you did not see.

2. **Migrations.**
   - Migrations are reviewed for lock risk and duration (see migration-review).
   - Running the migration is safe with the current code (backward-compatible during
     rollout: old code must tolerate the new schema, and vice versa when rolling back).
   - A rollback plan exists and has been considered (schema changes are not always
     trivially reversible).

3. **Configuration.** Every new required variable is set in the target environment and
   documented. Secrets are present in the secret store. The application validates config
   at startup (see environment-config).

4. **Backward/forward compatibility.** If old and new versions run simultaneously during
   rollout, both must work against the same shared state (database, queue, cache).

5. **Observability.** Logs, metrics, and alerts cover the new code path. You can tell
   whether the deployment is healthy (see observability).

6. **Rollback path.** You know how to roll back (previous artifact, feature flag, or
   reverse migration) and have confirmed it is available.

7. **Runbook.** Document the deploy steps, the verification steps, who to contact, and
   the rollback steps. Keep it short and current.

8. **Risk and blast radius.** Note what could go wrong, how it would be detected, and how
   quickly it could be reversed. Prefer a gradual rollout (canary, percentage) for risky
   changes.

9. **Dependencies and secrets.** Confirm the deployed artifact contains no secrets baked
   in and that required external services are reachable.

## Quality criteria

- Every checklist item has a recorded, honest result (passed / not applicable / not verified).
- Migrations are compatible with concurrent old and new code.
- Configuration and secrets are present in the target environment.
- A rollback path exists and is known.
- A short runbook exists.

## Anti-patterns to avoid

- Deploying after running "some" tests and calling it verified.
- A migration that only works in one code direction during a rolling deploy.
- Discovering a missing config value after deploy.
- Big-bang rollout of a risky change with no canary.
- No rollback plan for an irreversible schema change.
- Claiming "monitored" when no alerts cover the new path.

## Validation strategy

- Run the test suite and report the real output.
- Dry-run the migration against production-shaped data where possible.
- Confirm every required config value is present in the target environment.
- Confirm the rollback artifact is available.
- List items that were not verified explicitly.

## Reference

- General release/change-management practice; expand-and-contract migration strategy.
