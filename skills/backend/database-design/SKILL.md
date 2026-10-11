---
name: database-design
description: Choose data types, keys, indexes, and transaction boundaries deliberately, and keep migrations safe. Use when modeling data, changing a schema, writing a migration, or reviewing query performance.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Database Design

## Operating procedure

1. **Model the domain before the tables.** Identify entities, their identity, and
   their relationships. Decide cardinality (one-to-one, one-to-many, many-to-many)
   before writing DDL.

2. **Choose data types deliberately.**
   - Use the narrowest correct type (`int` vs `bigint`, `varchar(n)` only when a real
     limit exists; avoid `text` for short fixed fields without reason).
   - Use a dedicated type for timestamps with timezone. Store UTC; convert at the edge.
   - Use a proper type for money (integer minor units or a decimal type), never float.
   - Enforce enumerated values with a check constraint or a lookup table, not a free string.

3. **Enforce integrity in the database.**
   - Primary keys on every table; foreign keys with explicit `ON DELETE` behavior.
   - `NOT NULL` unless the column is genuinely optional.
   - `UNIQUE` constraints for real uniqueness rules (do not rely on application checks alone).

4. **Normalize where it reduces anomalies**, and denormalize deliberately only when a
   measured read pattern justifies it, documenting the reason and how you keep copies
   in sync.

5. **Choose indexes from query patterns, not guesses.**
   - Index columns used in `WHERE`, `JOIN`, and `ORDER BY` on real queries.
   - Consider composite index column order (most selective / equality-first).
   - Remember every index costs write time and storage; remove unused ones.
   - Verify with `EXPLAIN`/query plan rather than assuming.

6. **Keep migrations safe.**
   - Migrations are forward-only where possible, with a documented rollback.
   - For large tables, avoid long-held locks: add columns as nullable or with a
     default strategy appropriate to the engine, backfill in batches, then enforce.
   - Never combine a destructive change with an irreversible transformation in one step.

7. **Define transaction boundaries.** Group operations that must be atomic. Keep
   transactions short; do not hold one open across network calls.

8. **Plan for recovery.** Know where backups live, what the retention is, and that a
   restore has actually been tested. Document it; do not assume it.

## Quality criteria

- Types are appropriate and money/time are stored safely.
- Integrity (keys, nullability, uniqueness) is enforced in the schema.
- Indexes correspond to actual query patterns and were checked with a plan.
- Migrations are reversible or have a documented, tested rollback.
- Transaction boundaries are explicit for multi-step writes.

## Anti-patterns to avoid

- Storing money as floating point.
- Storing timestamps without timezone or in local time.
- A single giant table with nullable columns for unrelated concepts.
- Adding indexes blindly "just in case".
- Destructive migrations with no backup and no rollback plan.
- Application-only uniqueness that a race can violate.

## Validation strategy

- Run `EXPLAIN`/`EXPLAIN ANALYZE` for the hot queries and confirm index usage.
- Confirm FKs, NOT NULLs, and unique constraints exist for stated rules.
- Dry-run migrations against a copy of production-shaped data where possible.
- Verify a backup/restore path exists before any destructive change.

## Reference

- PostgreSQL documentation: indexes, concurrency, and `ALTER TABLE` locking.
