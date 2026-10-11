# Gemini CLI adapter

Aggregates skills into the hierarchical `GEMINI.md` context file.

| Property | Value |
| --- | --- |
| Agent id | `gemini-cli` |
| Support level | `instructions` |
| Evidence | `documented` |
| Format | `aggregated-instructions` |
| Scopes | project, user |

## Output paths

- Project: `GEMINI.md`
- User: `~/.gemini/GEMINI.md`

## Transform

Gemini CLI has no discrete skill mechanism, so all skills are written into a
single delimited managed block inside `GEMINI.md`:

```text
<!-- agent-skills:begin -->
... installed skills ...
<!-- agent-skills:end -->
```

Installing a second skill **merges** into the existing block rather than
replacing it, so previously installed skills survive. Existing content outside
the markers is preserved untouched. Uninstalling one skill regenerates the block
with the survivors; the file is removed only when the last skill is removed and
the file would otherwise be empty.

## Evidence

`documented`: based on Gemini CLI's public documentation, not verified against a
Gemini CLI installation in the authoring environment.

## Limitations

- Content is aggregated, not a discrete skill.
- Only content between the managed markers is ever modified.

## References

- <https://github.com/google-gemini/gemini-cli>
