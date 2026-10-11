---
name: migration-review
description: Review schema migrations for lock risk, backward compatibility, data backfill, and rollback. Use before applying a migration to a shared or production database.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# Database Migration Review

## Core principle

A migration on a live database can lock a table, drop data, or break the running
application. Review it against the real database's behavior before applying it, and make
it compatible with the code versions that will run alongside it.

## Operating procedure

1. **Assume rolling deployment.** During rollout, old and new code run at the same time
   against the same schema. Therefore migrations must be backward-compatible: the schema
   change must not break the code that is still running the old version.

2. **Use the expand/contract pattern for risky changes.**
   - **Expand**: add the new column/table/index (nullable, or with a strategy that does
     not rewrite the whole table under lock).
   - **Migrate**: backfill existing rows in batches; keep both old and new readable.
   - **Switch**: update the code to use the new shape.
   - **Contract**: remove the old column/table in a later, separate migration once nothing
     reads it.

3. **Assess lock risk.** For the specific database engine:
   - Adding a column: some engines rewrite the table (locking it); others do not.
   - Creating an index: can lock writes; use a concurrent/online index creation where
     supported.
   - Altering a column type or adding a constraint: often rewrites/validates under lock;
     validate constraints without a full lock where the engine supports it.
   State the concrete lock behavior for the target engine, not a generic assumption.

4. **Backfill in batches, not one statement.** A single `UPDATE` over millions of rows can
   hold a long transaction and lock. Batch by id range with pauses, and make the backfill
   idempotent so it can resume.

5. **Make it reversible or explicitly irreversible.**
   - Dropping a column/table loses data: provide a rollback, or state clearly that it is
     irreversible and requires a backup.
   - Test the reverse migration if one is claimed.

6. **Ensure a backup exists.** Before any destructive change, confirm a recent, restorable
   backup. "We can restore from backup" is only true if it has been tested.

7. **Keep migrations small and single-purpose.** One concern per migration so a failure
   is isolated and a rollback is clean.

8. **Test against production-shaped data volume** where possible; a migration that is fast
   on a 100-row dev table may lock a production table for minutes.

## Quality criteria

- Migration is backward-compatible with concurrently running old code.
- Lock behavior is assessed concretely for the target engine.
- Large backfills are batched and resumable.
- Reversibility is provided or explicitly declared with a backup requirement.
- A recent, restorable backup exists before destructive changes.

## Anti-patterns to avoid

- Dropping a column while the old code still reads it.
- A single `UPDATE` over a huge table.
- Adding a NOT NULL column with a default that rewrites a locked table.
- Creating an index non-concurrently on a busy table.
- Claiming "reversible" without testing the down migration.
- Applying a destructive migration with no verified backup.

## Validation strategy

- State the engine and the concrete lock behavior for each change.
- Dry-run against data shaped like production; measure duration and lock time.
- Test the down migration if one is claimed.
- Confirm a recent backup exists before a destructive step.
- List steps that could not be verified here.

## Reference

- Engine-specific documentation on `ALTER TABLE` locking and concurrent index creation;
  expand-and-contract migration practice.
