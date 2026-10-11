# Skill development

This guide explains how to add or change a skill in Agent Skills.

## Canonical format

Every skill is one file: `skills/<category>/<skill-id>/SKILL.md`. The directory
name **must** equal the skill id, and the id must be kebab-case matching
`^[a-z0-9]+(-[a-z0-9]+)*$`.

```markdown
---
name: my-skill
description: One or two sentences describing what the skill does and when to use it.
metadata:
  category: svg
  version: 1.0.0
  agents: all
---

# My Skill

## Core principle

...
```

### Frontmatter rules

- `name` must equal the skill id.
- `description` should be actionable and describe *when* to use the skill. It is
  reused verbatim as the Cursor/Copilot rule description, so it must stand alone.
- Some agents reject `<` and `>` inside frontmatter. The validator emits a `WARN`
  if the description contains them.
- Keep `metadata.category` equal to the directory's category.

## Registering the skill

Add an entry to [`registry/skills.json`](../registry/skills.json):

```json
{
  "id": "my-skill",
  "name": "My Skill",
  "description": "A description of at least twenty characters.",
  "category": "svg",
  "version": "1.0.0",
  "path": "skills/svg/my-skill/SKILL.md",
  "agents": ["codex", "claude-code", "cursor", "github-copilot", "windsurf", "cline", "roo-code", "gemini-cli", "continue", "opencode", "universal"],
  "depends": [],
  "tools": []
}
```

Field notes:

- `agents` lists the agent ids the skill supports. `universal` means the skill
  is generic. It does **not** mean every agent was tested.
- `depends` lists skill ids installed alongside this one. Dependencies form a
  directed graph that must stay acyclic; the validator enforces this.
- `tools` lists optional external tools the skill can use when available. They
  are never required and are never invoked automatically.

## Writing a good skill

A skill is instructions for an agent, not an essay. Follow the existing style:

1. **Core principle** — one short paragraph framing the problem.
2. **Operating procedure** — a numbered, actionable sequence.
3. **Quality criteria** — what "done well" looks like.
4. **Anti-patterns to avoid** — concrete failure modes.
5. **Validation strategy** — how to verify the result.

Rules:

- **One responsibility per skill.** If it needs "and" in the title, split it.
- **Be specific and actionable.** "Use a correct `viewBox`" beats "follow best
  practices".
- **State limits honestly.** Never promise originality, safety, or correctness
  the skill cannot deliver (for example, do not claim a mark is trademark-free).
- **Avoid duplication.** Do not repeat generic advice already covered by another
  skill; reference it instead.
- **No secrets, no fabricated facts, no invented URLs.**

## Adding a preset

Presets live in [`registry/presets.json`](../registry/presets.json). Every
referenced skill id must exist; unknown references are a hard error at load time.

## Adding an agent

See [supported-agents.md](supported-agents.md). Add an entry to
`registry/agents.json` with the correct `format`. If the format is one of the
existing five, no code is required. If it is genuinely new, add a renderer to
`src/AgentSkills/Private/AdapterEngine.ps1` and a fixture under
`adapters/_fixtures/`.

## Before opening a pull request

Run both checks and make sure they pass:

```powershell
.\installer\install.ps1 validate
.\tests\run-tests.ps1
```

Checklist:

- [ ] `SKILL.md` exists and has valid frontmatter.
- [ ] The skill is registered in `registry/skills.json`.
- [ ] `validate` reports no new `FAIL`s.
- [ ] The test suite passes.
- [ ] The skill does not duplicate an existing one.
- [ ] The description is actionable and self-contained.
- [ ] No secrets or fabricated claims were added.
