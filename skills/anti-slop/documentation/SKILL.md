---
name: documentation
description: Keep documentation consistent with verified code behavior, and never document features that do not exist. Use when writing or updating README files, API docs, guides, or comments.
metadata:
  category: anti-slop
  version: 1.0.0
  agents: all
---

# Technical Documentation

## Core principle

Documentation is a claim about what the software does. Every claim must be true of the
actual, verified behavior. Wrong documentation is worse than none, because it actively
misleads.

## Operating procedure

1. **Verify before documenting.** Run the command, call the endpoint, or read the code
   before writing that it "does X". Document observed behavior, not intended or assumed
   behavior. If you could not verify a claim, either omit it or mark it as unverified.

2. **Document the real, not the aspirational.** Do not describe planned features as if
   they exist. Do not document options that are not implemented. Do not include example
   output you did not actually get.

3. **Write for the reader's task.** Lead with what they want to do: install, configure,
   run, use the feature. Put reference detail (flags, parameters, errors) where it is
   findable, and keep it accurate.

4. **Keep examples runnable and correct.** Copy-pasteable examples must actually work.
   Use realistic placeholders (never real credentials), and test the examples where you
   can.

5. **Document the limitations honestly.** State what the software does not do, known
   limits, and unverified areas. Honest limitations build trust; hidden ones destroy it.

6. **Keep docs next to the code that changes.** Update documentation in the same change
   as the code it describes, so they do not drift. A stale doc is a bug.

7. **For code comments, explain *why*, not *what*.** The code shows what it does; a comment
   should explain the reasoning, a non-obvious trade-off, or a workaround with its reason.
   Delete comments that restate the code, and delete commented-out code.

8. **Never fabricate.** No fake badges, download counts, star counts, benchmarks, or
   adoption numbers. No invented URLs, usernames, or repo paths. If you do not know a
   value, leave it out.

## Quality criteria

- Every documented claim matches verified behavior.
- No feature is documented that is not implemented.
- Examples are correct and use safe placeholders.
- Limitations and unverified areas are stated.
- Docs live with the code and are updated with it.
- No fabricated metrics, badges, or links.

## Anti-patterns to avoid

- Documenting planned features as shipped.
- Example output that was never actually produced.
- A "Getting Started" that does not run.
- Fabricated badges, statistics, or testimonials.
- Comments that restate the code, or large blocks of commented-out code.
- Documentation that contradicts the code because it was never updated.

## Validation strategy

- For each documented command/example, run it and confirm the stated result.
- Grep the docs for claims of features; confirm each is implemented.
- Check for fabricated badges/links; remove any that cannot be verified.
- Confirm docs were updated in the same change as the code.

## Reference

- General technical-writing practice; the project's own README as the standard to match.
