# OpenCode adapter

Installs `SKILL.md` skills into OpenCode's skills directory.

| Property | Value |
| --- | --- |
| Agent id | `opencode` |
| Support level | `native` |
| Evidence | `verified` |
| Format | `skill-md` |
| Scopes | project, user |

## Output paths

- Project: `.opencode/skills/<skillId>/SKILL.md`
- User: `~/.config/opencode/skills/<skillId>/SKILL.md`

## How OpenCode discovers skills

OpenCode discovers discrete skills under its `skills/` directory, one folder per
skill containing a `SKILL.md`. It also reads `AGENTS.md` project instructions.

## Verification

**Verified against a real installation.** On the authoring machine:

- `~/.config/opencode/skills/` exists and holds per-skill `SKILL.md` folders.
- Installing a skill with this tool wrote
  `~/.config/opencode/skills/<skillId>/SKILL.md`, and uninstall removed it.

## Limitations

- `AGENTS.md` is also the Universal Markdown convention; only the `skills/`
  directory is used here so skills stay discrete.

## References

- <https://opencode.ai/docs/rules/>
