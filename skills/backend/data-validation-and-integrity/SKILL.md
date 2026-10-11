---
name: data-validation-and-integrity
description: Validate at trust boundaries, distinguish syntactic from business-rule checks, and keep updates transactional. Use when accepting input, parsing external data, or enforcing domain constraints.
metadata:
  category: backend
  version: 1.0.0
  agents: all
---

# Data Validation and Integrity

## Core distinction

- **Syntactic validation** - is this well-formed? (types, required fields, lengths, formats).
- **Business-rule validation** - is this allowed? (uniqueness, referential existence,
  state transitions, permissions, quotas).

Both belong on the server. They may live in different layers and often need different
data (business rules frequently need a database read).

## Operating procedure

1. **Validate at trust boundaries.** Any data crossing from an untrusted source into
   trusted code must be validated: HTTP requests, messages, webhooks, files, third-party
   responses, and environment/config at startup. Internal call-to-call data is already
   trusted once it has crossed a boundary.

2. **Use a schema for shape.** Define the expected shape and validate against it,
   rejecting unknown fields explicitly. Do not rely on ad-hoc checks scattered through
   the handler. Fail with a clear, field-level error (see the API design skill).

3. **Enforce constraints at the right layer.**
   - DB constraints (NOT NULL, FK, UNIQUE, CHECK) for invariants that must never break.
   - Application checks for user-facing, contextual rules that need friendly messages.
   Both are useful; the DB constraint is the last line of defense against races.

4. **Parse safely.** Do not use unsafe deserializers that can construct arbitrary
   objects (e.g. language-specific "unsafe" YAML/pickle loaders). Prefer strict,
   schema-typed parsers. Bound the size of what you parse.

5. **Model domain constraints explicitly.** Use types that encode valid states
   (enums, branded types, value objects) instead of passing raw strings around that
   must be re-checked everywhere.

6. **Keep multi-step updates transactional.** If two writes must both succeed or both
   fail, wrap them in one transaction. Re-check invariants that a concurrent request
   could have changed (consider unique constraints or row locks rather than
   read-then-write races).

7. **Guard state transitions.** A record that can move `draft -> published -> archived`
   should reject invalid transitions (`archived -> draft`), enforced server-side.

## Quality criteria

- Every trust boundary validates shape and rejects unknown fields.
- Syntactic and business-rule validation are both present and clearly separated.
- Critical invariants are also enforced by DB constraints, not only in code.
- Parsers are safe and input size is bounded.
- Multi-step writes are transactional; races are handled by constraints or locks.

## Anti-patterns to avoid

- Trusting client-side validation as the only validation.
- Using an unsafe deserializer on untrusted input.
- Read-then-write uniqueness checks without a unique constraint (race permits duplicates).
- Storing an enum as a free string with no constraint.
- Partial writes left committed when a later step fails.

## Validation strategy

- For each boundary, confirm shape validation exists and unknown fields are rejected.
- Confirm DB constraints back the stated invariants (grep the migrations).
- Test an invalid state transition and confirm rejection.
- Test a concurrent duplicate creation where feasible and confirm only one succeeds.

## Reference

- OWASP Input Validation Cheat Sheet; database constraint documentation.
