# Adapter fixtures

These files show the **exact output shape** each adapter produces for the same
input skill, so contributors can review transforms without running the installer
and integration tests can assert against a known-good reference.

The canonical input is the frontmatter and body of
`skills/svg/icon-design/SKILL.md` (abridged below for readability).

## Expected outputs

- `codex.expected.md` and `claude-code.expected.md` — native `SKILL.md` with
  normalised frontmatter (`skill-md`).
- `cursor.expected.mdc` — Cursor rule with `description`/`globs`/`alwaysApply`
  frontmatter (`mdc-frontmatter`).
- `copilot.expected.instructions.md` — Copilot instruction with `applyTo`
  frontmatter (`instructions-md`).
- `markdown-rule.expected.md` — shared by Cline, Roo Code, Windsurf, and
  Continue (`markdown-rules`).
- `aggregated-block.expected.md` — the managed block used by Gemini CLI,
  OpenCode, and Universal Markdown (`aggregated-instructions`).

The fixtures use an abbreviated body; the real output preserves the full body.
They exist to pin the *shape*, not the content. If you change an adapter, update
the corresponding fixture and explain why in the pull request.
