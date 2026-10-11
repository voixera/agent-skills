# Windsurf adapter

Emits Windsurf **rules** as markdown documents.

| Property | Value |
| --- | --- |
| Agent id | `windsurf` |
| Support level | `rules` |
| Evidence | `documented` |
| Format | `markdown-rules` |
| Scopes | project, user |

## Output paths

- Project: `.windsurf/rules/<skillId>.md`
- User: `~/.codeium/windsurf/memories/global_rules.md`

## Transform

Project rules are one markdown document per skill, with a short generated header
recording the source skill id and version. At user scope, Windsurf aggregates
rules into a single `global_rules.md`; the adapter appends a delimited managed
block so uninstall removes only its own content.

## Evidence

`documented`: based on Windsurf's public documentation, not verified against a
Windsurf installation in the authoring environment.

## Limitations

- User-level rules are aggregated, not per-skill.
- Rule activation metadata behavior may vary by Windsurf version.

## References

- <https://docs.windsurf.com/windsurf/cascade/memories>
