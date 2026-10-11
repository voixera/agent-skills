# Supported agents

Agent Skills targets multiple agents through **adapters**. An adapter transforms
canonical `SKILL.md` content into the format an agent actually reads. Adapters
never blindly copy files: each emits the shape its target expects.

The authoritative machine-readable definitions are in
[`registry/agents.json`](../registry/agents.json); this page explains them.

## Compatibility matrix

| Agent | Id | Support level | Evidence | Project scope path | User scope path |
| --- | --- | --- | --- | --- | --- |
| OpenAI Codex | `codex` | native | verified | `.codex/skills/<skillId>/SKILL.md` | `~/.codex/skills/<skillId>/SKILL.md` |
| Claude Code | `claude-code` | native | verified | `.claude/skills/<skillId>/SKILL.md` | `~/.claude/skills/<skillId>/SKILL.md` |
| Cursor | `cursor` | rules | verified | `.cursor/rules/<skillId>.mdc` | `~/.cursor/rules/<skillId>.mdc` |
| GitHub Copilot | `github-copilot` | instructions | verified | `.github/instructions/<skillId>.instructions.md` | â€” |
| Windsurf | `windsurf` | rules | verified | `.windsurf/rules/<skillId>.md` | `~/.codeium/windsurf/memories/global_rules.md` |
| Cline | `cline` | rules | verified | `.clinerules/<skillId>.md` | â€” |
| Roo Code | `roo-code` | rules | verified | `.roo/rules/<skillId>.md` | â€” |
| Gemini CLI | `gemini-cli` | native | verified | `.gemini/skills/<skillId>/SKILL.md` | `~/.gemini/skills/<skillId>/SKILL.md` |
| Continue | `continue` | rules | verified | `.continue/rules/<skillId>.md` | `~/.continue/rules/<skillId>.md` |
| OpenCode | `opencode` | native | verified | `.opencode/skills/<skillId>/SKILL.md` | `~/.config/opencode/skills/<skillId>/SKILL.md` |
| Hermes (Nous Research) | `hermes` | native | verified | `.hermes/skills/<skillId>/SKILL.md` | `~/.hermes/skills/<skillId>/SKILL.md` |
| Universal Markdown | `universal` | instructions | verified | `AGENTS.md` | â€” |

## Support levels

- **native** â€” the agent has first-class discrete skill discovery.
- **rules** â€” the agent reads per-file rule documents rather than discrete
  skills.
- **instructions** â€” the agent reads a single aggregated instruction file. Skills
  are merged into a delimited managed block.

## Evidence levels

- **verified** - the config path and format are documented for the agent and
  covered by the adapter documentation under `adapters/<id>/README.md`.

All adapters in this project are marked `verified`. Confirm against your
installed agent version if a vendor changes its layout.

## Format mapping

| Format | Used by | Shape |
| --- | --- | --- |
| `skill-md` | codex, claude-code | `SKILL.md` with `name`/`description`/`metadata` frontmatter |
| `mdc-frontmatter` | cursor | `.mdc` with `description`/`globs`/`alwaysApply` |
| `instructions-md` | github-copilot | `*.instructions.md` with `applyTo` |
| `markdown-rules` | windsurf, cline, roo-code, continue | plain markdown rule doc |
| `aggregated-instructions` | gemini-cli, opencode, universal | delimited managed block in one file |

New agents that share an existing format need **no new code** â€” add an entry to
`registry/agents.json` with the matching `format` and it works.

## Detection

The installer probes each agent's `detect` markers in the current project (for
example `.codex`, `.claude`, `.cursor`). Detection is advisory: it never writes
anything and a missing marker simply skips the agent.

## Verifying an adapter yourself

Each adapter directory contains a `README.md` with the rationale and a
`adapters/_fixtures/` example showing the exact output shape. To generate output
for a skill:

```js
const { loadAndValidateRegistry, getSkill, readSkillContent } = require('agentskillsmd/dist/core/core');
const { renderForAgent } = require('agentskillsmd/dist/core/adapters');

const reg = loadAndValidateRegistry();
const skill = getSkill(reg, 'icon-design');
const agent = reg.agents.agents.find((a) => a.id === 'cursor');
console.log(renderForAgent(readSkillContent(skill), agent));
```

Then compare the output to the real file the agent reads.
