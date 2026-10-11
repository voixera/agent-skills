# Claude Code adapter

Transforms canonical `SKILL.md` files into the layout Claude Code discovers.

| Property | Value |
| --- | --- |
| Agent id | `claude-code` |
| Support level | `native` |
| Evidence | `verified` |
| Format | `skill-md` |
| Scopes | project, user |

## Output paths

- Project: `.claude/skills/<skillId>/SKILL.md`
- User: `~/.claude/skills/<skillId>/SKILL.md`

## Transform

Same native format as the canonical source. The adapter re-emits the frontmatter
from the registry and preserves the body verbatim. The directory name is the
skill id, which is guaranteed kebab-case by the registry schema.

## Verification

The path and format were observed in a real Claude Code installation in the
authoring environment, hence `verified`.

## Limitations

- The directory name must be kebab-case and the file must be exactly `SKILL.md`
  (case-sensitive). The registry schema enforces the kebab-case id pattern.
- Frontmatter must not contain XML angle brackets. The validator emits a `WARN`
  when a description contains `<` or `>`.

## References

- <https://docs.claude.com/en/docs/claude-code>
