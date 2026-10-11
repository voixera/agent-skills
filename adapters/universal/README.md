# Universal Markdown adapter

Fallback adapter for agents and workflows that read the `AGENTS.md` convention.

| Property | Value |
| --- | --- |
| Agent id | `universal` |
| Support level | `instructions` |
| Evidence | `documented` |
| Format | `aggregated-instructions` |
| Scopes | project |

## Output paths

- Project: `AGENTS.md`

## Transform

Writes skills into a delimited managed block inside `AGENTS.md`. Merge and
uninstall semantics match the Gemini CLI adapter.

## Evidence

`documented`: this is an interoperability convention, not a guarantee that any
specific agent reads it. Verify your agent's behavior.

## Limitations

- `AGENTS.md` is shared with OpenCode; the installer deduplicates identical
  writes.
- No user scope.

## References

- <https://agents.md>
