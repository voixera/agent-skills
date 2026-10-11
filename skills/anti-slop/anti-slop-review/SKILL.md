---
name: anti-slop-review
description: Detect preventable quality problems such as dead code, fake tests, placeholder features, and needless abstraction. Use as a final pass before considering work complete.
metadata:
  category: anti-slop
  version: 1.0.0
  agents: all
---

# Anti-Slop Review

## Core principle

"Slop" here means preventable quality problems: code or prose that looks complete but is
not, output that pretends to be done when it is partial, and complexity that exists for
its own sake. This review finds them before they ship.

## What to look for

**Code and structure**
- Dead code: unused functions, variables, imports, files, feature flags stuck on.
- Unnecessary abstraction: interface/layer/wrapper with one implementation and no second
  caller, or indirection that adds no value.
- Overly complex solutions where a simpler one exists.
- Duplicated logic that should be shared, or shared logic that should be separate.
- Inconsistent naming that makes the same concept appear under several names.

**Claims vs. reality**
- Fake test claims: tests that assert nothing meaningful, snapshot tests of whole objects
  with no assertion, tests skipped/only-ed, or a "tests pass" claim that was never run.
- Placeholder functionality presented as complete: TODO handlers, `return true`, stubbed
  responses, hardcoded demo data shipped as features.
- Documentation describing features that do not exist.
- Unsupported factual claims (metrics, benchmarks, compatibility) with no evidence.

**Robustness**
- Incomplete error handling: swallowed exceptions, empty catch blocks, failures returned
  as success.
- Missing states: a data view with no loading/error/empty handling.
- Unused or unjustified dependencies.

**UI and prose**
- Generic UI with no clear purpose: the same template applied regardless of the brief.
- Unnecessary gradients, decorations, and effects added by default.
- Repetitive prose: the same sentence restated, filler paragraphs, adjective-heavy text
  that says nothing specific ("robust, scalable, modern solution").

## Operating procedure

1. **Review against the list**, recording concrete findings with locations.
2. **Classify each finding** as objective (a fact: dead code, an empty catch, a failed
   test) or subjective (a preference: a style choice, an aesthetic opinion). Say which.
3. **For objective findings, state the evidence** (the file, the fact). Do not assert
   without evidence.
4. **For subjective findings, phrase them as a recommendation**, not a defect.
5. **Summarize**: what must be fixed, what is worth considering, and what was reviewed.

## Quality criteria

- Findings are specific, with locations and evidence.
- Objective problems and subjective preferences are clearly separated.
- Every claim in the review is backed by an observation.
- The summary distinguishes blocking issues from suggestions.

## Anti-patterns to avoid

- Flagging a subjective style preference as a defect.
- Claiming code is "AI-generated" or "not AI-generated" (see limitation below).
- Vague findings ("this feels off") with no evidence.
- Reporting a fix as done without verifying it.
- Turning a preference into a mandate.

## Explicit limitation

This review cannot determine whether a human or an AI wrote any given code, and it does
not attempt to. It finds *preventable quality problems*, whoever wrote them. It also
cannot detect every issue; it is a checklist that improves consistency, not a proof of
quality. State this rather than implying a complete quality guarantee.

## Validation strategy

- Grep for unused imports/symbols and commented-out code.
- Confirm each claimed test actually asserts meaningful behavior.
- Confirm each documented feature exists in the code.
- Confirm no swallowed errors and no placeholder handlers remain.
- Distinguish and label objective findings from preferences.

## Reference

- The code-review, documentation, and testing skills for the deeper checks.
