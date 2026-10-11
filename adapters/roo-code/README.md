# Roo Code adapter

Emits Roo Code **rules** into `.roo/rules/`.

| Property | Value |
| --- | --- |
| Agent id | `roo-code` |
| Support level | `rules` |
| Evidence | `documented` |
| Format | `markdown-rules` |
| Scopes | project |

## Output paths

- Project: `.roo/rules/<skillId>.md`

## Transform

One markdown document per skill, with a generated header recording the source.

## Evidence

`documented`: based on Roo Code's public documentation, not verified against a
Roo Code installation in the authoring environment.

## Limitations

- Roo Code also supports `.roo/rules-<mode>/` for mode-specific rules; this
  adapter writes the general `.roo/rules/` directory.
- Project scope only.

## References

- <https://docs.roocode.com/features/custom-instructions>
