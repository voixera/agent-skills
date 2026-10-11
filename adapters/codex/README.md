# Codex adapter

Transforms canonical `SKILL.md` files into the layout OpenAI Codex discovers.

| Property | Value |
| --- | --- |
| Agent id | `codex` |
| Support level | `native` |
| Evidence | `verified` |
| Format | `skill-md` |
| Scopes | project, user |

## Output paths

- Project: `.codex/skills/<skillId>/SKILL.md`
- User: `~/.codex/skills/<skillId>/SKILL.md`

## Transform

The canonical file is already in the native shape, so the adapter does not copy
it blindly: it re-emits the frontmatter from the registry (`name`, `description`,
`metadata.category`, `metadata.version`) and preserves the body verbatim. This
keeps installed files consistent with the registry even if a source file's
frontmatter drifts.

## Verification

The path and format were observed in a real Codex installation in the authoring
environment, hence `verified`.

## Limitations

- Only `<dir>/SKILL.md` with `name` and `description` frontmatter is discovered.
- A new session or turn is required before an installed skill becomes available.

## References

- <https://github.com/openai/codex>
