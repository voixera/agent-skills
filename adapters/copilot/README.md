# GitHub Copilot adapter

Emits per-path **custom instruction** files (`*.instructions.md`).

| Property | Value |
| --- | --- |
| Agent id | `github-copilot` |
| Support level | `instructions` |
| Evidence | `documented` |
| Format | `instructions-md` |
| Scopes | project |

## Output paths

- Project: `.github/instructions/<skillId>.instructions.md`

## Transform

Each skill becomes one instruction file with `applyTo` frontmatter:

```text
---
applyTo: "**"
---
```

The body is the skill body under a level-1 heading. `applyTo: "**"` targets all
files; narrow it manually if you want a skill to apply only to certain paths.

## Evidence

`documented`: based on GitHub's public documentation for custom instructions,
not verified against a Copilot installation in the authoring environment.

## Limitations

- Copilot has no discrete skill discovery; the adapter writes one instruction
  file per skill.
- User scope is not supported for this agent (project only).

## References

- <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions>
