# Gemini CLI adapter

Installs `SKILL.md` skills into Gemini CLI's skills directory.

| Property | Value |
| --- | --- |
| Agent id | `gemini-cli` |
| Support level | `native` |
| Evidence | `verified` |
| Format | `skill-md` |
| Scopes | project, user |

## Output paths

- Project: `.gemini/skills/<skillId>/SKILL.md`
- User: `~/.gemini/skills/<skillId>/SKILL.md`

## How Gemini discovers skills

Gemini CLI discovers discrete skills under its `skills/` directory, one folder
per skill containing a `SKILL.md` with `name` and `description` frontmatter.

## Verification

**Verified against a real installation.** On the authoring machine:

- `~/.gemini/skills/<name>/SKILL.md` exists for installed Gemini skills, using
  the same `name`/`description` frontmatter this project writes.
- Installing a skill with this tool wrote
  `~/.gemini/skills/<skillId>/SKILL.md`, and uninstall removed it cleanly.

## Limitations

- Gemini also reads hierarchical `GEMINI.md` context files; skills are the
  discrete mechanism used here.

## References

- <https://github.com/google-gemini/gemini-cli>
