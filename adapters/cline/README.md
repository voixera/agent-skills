# Cline adapter

Emits Cline **rules** into the `.clinerules` directory.

| Property | Value |
| --- | --- |
| Agent id | `cline` |
| Support level | `rules` |
| Evidence | `documented` |
| Format | `markdown-rules` |
| Scopes | project |

## Output paths

- Project: `.clinerules/<skillId>.md`

## Transform

One markdown document per skill, with a generated header recording the source.

## Evidence

`documented`: based on Cline's public documentation, not verified against a Cline
installation in the authoring environment.

## Limitations

- Cline reads the `.clinerules` directory (or a single `.clinerules` file) as
  rule context; it has no discrete skill mechanism.
- Project scope only in this adapter.

## References

- <https://docs.cline.bot/features/cline-rules>
