# Cursor adapter

Emits Cursor **project rules** (`.mdc`) rather than discrete skills.

| Property | Value |
| --- | --- |
| Agent id | `cursor` |
| Support level | `rules` |
| Evidence | `documented` |
| Format | `mdc-frontmatter` |
| Scopes | project, user |

## Output paths

- Project: `.cursor/rules/<skillId>.mdc`
- User: `~/.cursor/rules/<skillId>.mdc`

## Transform

Each skill becomes one `.mdc` rule with frontmatter:

```text
---
description: <skill description>
globs:
alwaysApply: false
---
```

The body is the skill body under a level-1 heading. `alwaysApply: false` means
the rule is available to be pulled in by relevance rather than applied to every
request. This is a deliberate default: silently applying every installed skill
to every request would be surprising and noisy.

## Evidence

`documented`: the path/format is based on Cursor's public documentation but was
**not** verified against a Cursor installation in the authoring environment.

## Limitations

- Cursor consumes rules, not skills. There is no per-skill discovery command.
- Verify that `alwaysApply: false` matches your intended behavior.

## References

- <https://docs.cursor.com/context/rules>
