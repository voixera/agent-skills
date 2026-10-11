# OpenCode adapter

Aggregates skills into the `AGENTS.md` project instructions file.

| Property | Value |
| --- | --- |
| Agent id | `opencode` |
| Support level | `instructions` |
| Evidence | `documented` |
| Format | `aggregated-instructions` |
| Scopes | project, user |

## Output paths

- Project: `AGENTS.md`
- User: `~/.config/opencode/AGENTS.md`

## Transform

OpenCode reads `AGENTS.md` project instructions. Skills are written into a
delimited managed block; installs merge, and uninstall removes only the managed
block. See the Gemini CLI adapter for the merge/uninstall semantics, which are
shared.

## Evidence

`documented`: based on OpenCode's public documentation, not verified against an
OpenCode installation in the authoring environment.

## Limitations

- Content is aggregated, not a discrete skill.
- `AGENTS.md` is also the Universal Markdown convention; installing both the
  `opencode` and `universal` agents to the same project writes the same file.
  The installer deduplicates identical writes and never produces a conflict for
  managed-block merges.

## References

- <https://opencode.ai/docs/rules/>
