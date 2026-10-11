# Hermes adapter (Nous Research)

Installs `SKILL.md` skills into Hermes Agent's skills directory.

| Property | Value |
| --- | --- |
| Agent id | `hermes` |
| Support level | `native` |
| Evidence | `documented` |
| Format | `skill-md` |
| Scopes | project, user |

## Output paths

- Project: `.hermes/skills/<skillId>/SKILL.md`
- User: `~/.hermes/skills/<skillId>/SKILL.md`

## Transform

Hermes uses the open [agentskills.io](https://agentskills.io/specification)
`SKILL.md` standard, which is the same canonical format this project ships. The
adapter writes one `<dir>/<skillId>/SKILL.md` per skill, with `name`,
`description`, and `metadata` frontmatter.

## How Hermes discovers skills

- **User skills**: `~/.hermes/skills/` is the primary directory (source of truth).
- **Project skills**: `<project-root>/.hermes/skills/` and
  `<project-root>/.agents/skills/` (the cross-tool convention).
- Project skills are **not auto-loaded** until the repository is trusted:

  ```bash
  hermes skills trust
  ```

## Evidence

`documented`: based on the official Hermes docs
(<https://hermes-agent.nousresearch.com/docs/user-guide/features/skills>), which
state that skills live in `~/.hermes/skills/` and follow the agentskills.io
standard. It was **not** verified against a real Hermes installation in this
environment.

## Limitations

- Project skills require `hermes skills trust` before Hermes loads them.
- Hermes also scans `.agents/skills/`; installing to more than one location may
  create duplicate names. Whichever has higher precedence wins.

## References

- <https://hermes-agent.nousresearch.com/docs/user-guide/features/skills>
- <https://agentskills.io/specification>
