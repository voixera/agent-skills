---
name: release-notes
description: Write release notes that describe real user-visible changes, breaking changes, and migration steps. Use when preparing a release or tagging a version.
metadata:
  category: devops
  version: 1.0.0
  agents: all
---

# Release Notes

## Core principle

Release notes are for the people who use and operate the software, not for the team that
wrote it. Describe what changed for them, not the internal refactors nobody can observe.
Never claim a change exists that did not ship.

## Operating procedure

1. **Gather the actual changes.** Review the commits/tags since the last release. Group
   them by kind. Discard internal-only churn that has no user-visible effect (unless it
   matters operationally).

2. **Categorize clearly**, for example:
   - **Added** - new capabilities.
   - **Changed** - behavior changes to existing features.
   - **Fixed** - bugs resolved (describe the user-visible symptom that is now fixed).
   - **Removed** - features or endpoints removed.
   - **Deprecated** - still works but will be removed; say when.
   - **Security** - security-relevant fixes (without disclosing exploitable detail before
     users can patch).

3. **Lead with breaking changes.** Anything that requires the user to act must be at the
   top, with the exact migration steps. Do not bury a breaking change in a bullet.

4. **Write for the reader.** Describe the impact: "Fixed a bug where saving a draft
   cleared the title" beats "refactored the save handler". Include the version, the date,
   and what to do if upgrading.

5. **Give actionable migration steps.** For breaking changes, provide the before/after:
   what changed, what to change in their code/config, and any deadline (e.g. a deprecated
   endpoint removal date).

6. **Be accurate about scope.** If a version includes a partial feature, say so. Do not
   list a roadmap item as shipped. Do not fabricate download counts, adoption, or dates.

7. **Follow the version scheme.** Use semantic versioning: breaking = major, additive =
   minor, fix = patch. Keep the changelog consistent with the tags.

## Quality criteria

- Notes describe user-visible impact, not internal changes.
- Breaking changes are first and include migration steps.
- Security fixes are mentioned without premature exploit detail.
- Every listed change actually shipped in this version.
- Versions follow semantic versioning and match the tags.

## Anti-patterns to avoid

- A raw commit log pasted as release notes.
- Burying a breaking change in the middle of a list.
- Claiming a feature shipped when it is partial or unreleased.
- Fabricated metrics, dates, or adoption numbers.
- Omitting a breaking change because it was "minor internally".
- Revealing exploit details before users can update.

## Validation strategy

- Diff the notes against the actual commit range; every claim maps to a real change.
- Confirm each breaking change has migration steps.
- Confirm the version number matches the semantic-versioning rules for the changes present.
- Confirm nothing in the notes is a roadmap item presented as shipped.

## Reference

- Keep a Changelog; Semantic Versioning.
