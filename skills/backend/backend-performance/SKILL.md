---
name: backend-performance
description: Find and fix slow queries, N+1 patterns, missing caching, and connection or job bottlenecks using measurements. Use when endpoints are slow, when adding caches or background jobs, or when reviewing backend resource usage.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Backend Performance

## Core principle

Measure before optimizing. A change without a before/after number is a guess, and
guesses frequently make systems more complex without making them faster.

## Operating procedure

1. **Locate the bottleneck.** Profile or trace the slow path. Separate time spent in
   the database, in external calls, in CPU-bound code, and in serialization. Optimize
   the dominant term, not the loudest suspicion.

2. **Find and fix N+1 queries.** The classic pattern: one query to list N rows, then
   N queries to load a related field per row. Fix by:
   - Loading related data in a single query (join, `IN (...)`, or a batch loader).
   - Eager-loading where the ORM supports it, deliberately, not indiscriminately.
   Confirm via query logging/tracing that the query count dropped.

3. **Optimize queries with evidence.**
   - Use `EXPLAIN`/query plans to confirm index usage (see the database design skill).
   - Select only needed columns for wide tables; avoid `SELECT *` in hot paths.
   - Move large filter/sort work to the database where it is indexed, rather than
     loading rows and filtering in application code.

4. **Cache deliberately.**
   - Cache the expensive, frequently read, and tolerable-to-be-stale data.
   - Choose a correct invalidation strategy (TTL, key versioning, or explicit bust).
   - Cache at the right layer (response, query result, computed value).
   - Never cache per-user data under a shared key. Watch for cache stampedes on a
     popular missing key and use a lock or jittered TTL.

5. **Concurrency and pooling.**
   - Size the database connection pool to the database's capacity and the service's
     concurrency, not arbitrarily large.
   - Understand whether the runtime is single- or multi-threaded; avoid blocking the
     event loop with CPU-heavy work.
   - Guard shared mutable state; prefer immutability or explicit locks.

6. **Background jobs when justified.** Move slow, non-interactive work (emails,
   exports, image processing) out of the request path only when it genuinely exceeds
   the request budget or needs retries. Do not add a queue to a small app for its own sake.

7. **Set resource limits.** Timeouts, memory limits, maximum payload sizes, and job
   concurrency limits prevent one workload from taking down the process.

8. **Ensure observability.** Add timing and query-count metrics so regressions are
   visible. A performance fix with no measurement cannot be verified later.

## Quality criteria

- The bottleneck was identified by measurement, not assumption.
- N+1 patterns in hot paths are eliminated and verified by query count.
- Caching has a correct, stated invalidation strategy and does not leak across users.
- Pool sizes and limits are justified.
- A metric exists to detect regressions.

## Anti-patterns to avoid

- Caching everything and calling it optimization.
- A shared cache key for per-user data (data leak plus wrong results).
- Connection pools sized far beyond database capacity.
- Adding a message queue / worker tier to a small app with no latency need.
- Caching a value and never invalidating it.
- Claiming a speedup without a before/after measurement.

## Validation strategy

- Capture before/after timings and query counts for the changed path.
- Use the database's `EXPLAIN` to confirm index usage.
- Test cache miss and cache invalidation paths, not only the warm path.
- If measurement tools are unavailable here, report the change as *unverified*.

## Reference

- Database documentation on `EXPLAIN`; common caching pattern descriptions.
