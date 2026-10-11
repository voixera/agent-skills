---
name: Adapter compatibility report
about: Report whether an agent's install path/format matches what we document.
title: '[adapter] '
labels: adapter, compatibility
assignees: ''
---

Use this to help turn a `documented` adapter into a `verified` one.

## Agent

- Agent name and id (e.g. Cursor, `cursor`):
- Agent version:
- Tested on (OS):

## What we document

- Support level:
- Format:
- Path (project):
- Path (user):

## What you observed

- Actual path used:
- Actual file format / frontmatter:
- Did the agent discover the installed skill or rule? (yes / no / partial)

## Evidence

Paste a redacted example of the file the agent reads, or a screenshot of the
agent recognizing the skill. Remove anything sensitive.

```text
(paste here)
```

## Verdict

- [ ] Matches our documentation
- [ ] Differs (explain above)
- [ ] Could not verify

## Notes

Anything else that would help confirm or correct the adapter.
