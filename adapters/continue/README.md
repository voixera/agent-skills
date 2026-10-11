# Continue adapter

Emits Continue **rules** as markdown documents.

| Property | Value |
| --- | --- |
| Agent id | `continue` |
| Support level | `rules` |
| Evidence | `documented` |
| Format | `markdown-rules` |
| Scopes | project, user |

## Output paths

- Project: `.continue/rules/<skillId>.md`
- User: `~/.continue/rules/<skillId>.md`

## Transform

One markdown document per skill, with a generated header recording the source.

## Evidence

`documented`: the `~/.continue` directory was observed locally, but rule-file
discovery was not exhaustively verified. Treat the rule-file discovery location
as documented rather than verified.

## Limitations

- Rule-file discovery location should be confirmed against your Continue version.

## References

- <https://docs.continue.dev/customize/deep-dives/rules>
