# Agent Skills

**Multi-agent skills manager and anti-slop engineering toolkit.**

One command installs a curated set of engineering rules into your AI coding
agents - so they write better frontend, backend, tests, security, and SVG
instead of generic, same-as-everything output.

```bash
npx agentskillsmd
```

![Agent Skills installer](docs/assets/AgentSkills.png)

<!-- Badges: fill in the npm/CI links once published. -->

## Why

AI coding agents are fast but sloppy in predictable ways. Agent Skills fights
that with **explicit, testable rules** - not vibes:

- **Generic UI** - the same hero sections, gradients, and floating cards no
  matter the brief.
- **Missing states** - loading, empty, error, and disabled states forgotten
  until they cause a bug.
- **Weak boundaries** - validation scattered, authorization client-only, secrets
  in logs.
- **Brittle tests** - asserting implementation details, then edited to hide
  failures.
- **Hand-waved SVG** - "syntactically valid" but clipped, inaccessible, unsafe,
  or visually incoherent.

> **Honest scope.** This does not make an AI infallible and does not eliminate
> "AI slop". It reduces a specific class of *preventable* problems with explicit
> instructions, deterministic checks, and clearly reported limits. No check is
> ever reported as passed unless it actually ran.

## Quick start

Run it in an interactive terminal. It opens the installer immediately - there is
no subcommand to type.

```bash
npx agentskillsmd
```

```text
   █████╗  ██████╗ ███████╗███╗   ██╗████████╗  ███████╗██╗  ██╗██╗██╗     ██╗     ███████╗
  ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝  ██╔════╝██║ ██╔╝██║██║     ██║     ██╔════╝
  ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║     ███████╗█████╔╝ ██║██║     ██║     ███████╗
  ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║     ╚════██║██╔═██╗ ██║██║     ██║     ╚════██║
  ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║     ███████║██║  ██╗██║███████╗███████╗███████║

  Anti-slop rules for AI coding agents.
  Multi-agent skills manager  •  v2.0.0
  55 skills  •  12 agents  •  7 presets

? What would you like to do?
❯ Install skills into your agent setup
  Uninstall skills
  Exit
```

Then walk through the wizard:

1. **Agents** - multi-select; support level and evidence shown.
2. **Skills** - pick a preset (it preselects its skills), then customise.
3. **Preview** - files to create/update, conflicts, dependencies. Nothing is
   written until you confirm.
4. **Install** - real progress for real work.
5. **Complete** - an accurate report.

Skills are always installed into the current project. **Uninstall** lists the
skills currently installed so you can pick which to remove.

**Keys:** `↑`/`↓` move, `space` toggles, `a` toggles all, `enter` confirms,
`esc` goes back, `ctrl+c` quits safely. No mouse required.

### Requirements

- **Node.js 18+** - provides `npx` and runs the TUI.
- An interactive terminal (Windows Terminal, PowerShell, CMD, macOS/Linux).

That is the entire requirement list - no PowerShell, Python, or other runtime.

## What it does

- **Writes instruction files, nothing else.** The installer only creates
  instruction/config files and a manifest; it never executes skill content.
- **Never overwrites your files silently.** A destination that exists but was
  not created by Agent Skills is refused; you can overwrite explicitly, and a
  backup is taken first.
- **Uninstalls cleanly.** Only files recorded in the manifest are removed. For
  shared instruction files it removes only its own managed block.
- **Idempotent.** Re-running reports "unchanged" and writes nothing.
- **Validates up front.** The registry is checked (schema, references,
  dependency cycles) before the menu appears.

## Supported agents

| Agent | Id | Support level | Evidence | Scope |
| --- | --- | --- | --- | --- |
| OpenAI Codex | `codex` | native | verified | project, user |
| Claude Code | `claude-code` | native | verified | project, user |
| Cursor | `cursor` | rules | documented | project, user |
| GitHub Copilot | `github-copilot` | instructions | documented | project |
| Windsurf | `windsurf` | rules | documented | project, user |
| Cline | `cline` | rules | documented | project |
| Roo Code | `roo-code` | rules | documented | project |
| Gemini CLI | `gemini-cli` | instructions | documented | project, user |
| Continue | `continue` | rules | documented | project, user |
| OpenCode | `opencode` | instructions | documented | project, user |
| Hermes (Nous Research) | `hermes` | native | documented | project, user |
| Universal Markdown | `universal` | instructions | documented | project |

- **Support level** - how the agent discovers skills: `native` (discrete
  `SKILL.md`), `rules` (per-file rule documents), or `instructions` (one
  aggregated file with a managed block).
- **Evidence** - `verified` means the path/format was observed in a real
  installation; `documented` means it comes from vendor docs and was not tested
  locally. Only Codex and Claude Code are `verified`. See
  [docs/supported-agents.md](docs/supported-agents.md).

## Skill catalog

**55 skills across 8 categories.** Every skill has one responsibility, concrete
steps, quality criteria, anti-patterns, and a validation strategy.

| Category | Count | Skills |
| --- | --- | --- |
| frontend | 8 | frontend-architecture, react-best-practices, responsive-design, accessibility-a11y, frontend-performance, design-system, frontend-form-engineering, animation-and-interaction |
| backend | 8 | api-design, database-design, authentication-authorization, secure-backend, backend-architecture, integration-engineering, backend-performance, data-validation-and-integrity |
| ui-ux | 4 | ui-ux-design, anti-generic-ui, design-from-reference, microinteractions |
| svg | 8 | svg-craft, custom-illustration, icon-design, logo-mark-design, svg-optimization, svg-accessibility, svg-security, svg-visual-review |
| testing | 5 | unit-testing, integration-testing, e2e-testing, debugging-root-cause, regression-review |
| security | 8 | secure-coding, owasp-review, dependency-auditing, secret-management, authorization-review, threat-modeling, secure-file-handling, safe-error-handling |
| devops | 10 | git-workflow, pull-request-review, docker, ci-cd, environment-config, deployment-readiness, observability, migration-review, dependency-management, release-notes |
| anti-slop | 4 | task-planning, code-review, documentation, anti-slop-review |

## Presets

Presets are starting points - selecting one preselects its skills, and you can
still toggle individual skills.

| Preset | Skills |
| --- | --- |
| `frontend-developer` | Architecture, React, responsive, a11y, design system, performance, unit testing, anti-slop review |
| `backend-developer` | API design, database, auth, secure backend, architecture, integrations, performance, testing |
| `full-stack-developer` | Frontend + backend + quality + security + testing + docs |
| `creative-developer` | UI/UX, design system, anti-generic UI, SVG craft, illustration, icons, animation, responsive, a11y |
| `svg-specialist` | The full SVG pipeline: craft, illustration, icons, logo, optimize, a11y, security, review |
| `security-focused` | Secure coding, auth, secure backend, OWASP, dependency audit, threat modeling, authorization, regression |
| `minimal` | A small core: code review, anti-slop review, debugging, documentation |

## SVG Craft Pro

The signature feature: a complete pipeline for producing *and validating* vector
graphics. Eight skills plus a validator that reports **five independent stages**,
so "it parses" is never confused with "it is safe" or "it looks right":

1. **XML parse** - is it well-formed?
2. **Security scan** - scripts, event handlers, external refs, unsafe URLs,
   `foreignObject`, DTD entities.
3. **Accessibility** - accessible name (`title`/`aria-label`) or explicit
   decorative marking.
4. **Render** - only if a renderer is available; otherwise `SKIP` with a reason.
5. **Visual review** - *never* automatic; always reported as not done.

```js
const { validateSvgFile } = require('agentskillsmd/dist/core/core');
console.log(validateSvgFile('./art/logo.svg', { render: true }));
```

An SVG is **not** "validated" just because it parses. See
[docs/svg-quality.md](docs/svg-quality.md).

## Quality checker

Objective failures are separated from subjective design preferences. Checks use
four statuses:

- `PASS` - ran and succeeded.
- `FAIL` - ran and found a real problem.
- `WARN` - ran and found something to review.
- `SKIP` - did not run; **a reason is always given**, and a skip is never a pass.

Covers registry schema, skill metadata, duplicate ids, missing files, broken
references, dependency cycles, preset resolution, adapter/format compatibility,
and the SVG pipeline. The registry is validated automatically when the TUI starts;
you can also run it directly:

```bash
npm run validate
```

## Security model

- Writes **instruction and configuration files only**. Skill content is never
  executed. Nothing is sent anywhere.
- Writes are confined to the selected scope; a path that escapes it is refused.
- Untracked files are never silently overwritten; uninstall never deletes files
  it did not create.
- The repository contains no secrets, and CI runs a secret scan.

The SVG scan is **pattern-based** and reduces risk; it is not a guarantee. See
[SECURITY.md](SECURITY.md) and [docs/security.md](docs/security.md).

## Uninstalling

On the main menu:

```bash
npx agentskillsmd
# -> Uninstall skills
```

The uninstall screen lists the skills currently installed in the project so you
can pick which to remove. Only files Agent Skills created are removed; for shared
instruction files it removes only its own managed block, preserving the rest of
the file. Backups of overwritten files live in `.agent-skills/backups/`.

## Architecture

The installer is a single Node.js/TypeScript program - no external engine.

```text
src/
├── cli/         entry point (launches the TUI, non-TTY notice, Ctrl+C handling)
├── tui/         screens + components (@inquirer/prompts)
├── core/        registry, resolver, planner, engine, adapters, manifest, validate
├── validators/  SVG validator
└── types/       shared types
```

- The **TUI** (`src/tui`, `src/cli`) collects your choices and shows the plan.
- The **core** (`src/core`) reads the registry, builds a dry-run plan, writes the
  files and manifest, makes backups, and verifies. It never touches files it did
  not create.
- **Adapters** are data-driven by each agent's `format` field (`skill-md`,
  `mdc-frontmatter`, `instructions-md`, `markdown-rules`,
  `aggregated-instructions`), so a new agent that shares a format needs no code.

## Repository layout

```text
agent-skills/
|-- bin/                 agentskillsmd.js (npm executable)
|-- src/                 cli/, tui/, core/, validators/, types/
|-- registry/            agents.json, skills.json, presets.json + schema/
|-- skills/              canonical SKILL.md packs by category
|-- adapters/            per-agent adapter documentation + fixtures
|-- test/                Node tests (node:test)
|-- docs/                installation, supported-agents, skill-development, ...
\-- .github/             workflows, issue templates, PR template
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and
[docs/skill-development.md](docs/skill-development.md). In short: add a
`SKILL.md` under `skills/<category>/<id>/`, register it in `registry/skills.json`,
run `npm run validate` and `npm test`, and open a pull request.

## Testing

```bash
npm install
npm run build
npm test
```

Tests use Node's built-in test runner and isolated temporary directories; they
never touch the real user profile.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). Quick check:

```bash
npm run validate
```

## Known limitations

- Only **Codex** and **Claude Code** adapters are `verified`; the rest are
  `documented` and can drift with agent versions.
- The **SVG security scan is pattern-based** and is not a security guarantee.
- **SVG rendering** needs an external renderer; otherwise it reports `SKIP`.
- The TUI needs an interactive terminal; in a non-TTY shell it prints a notice
  and exits. Non-Windows is untested.

## Roadmap

- Promote more adapters to `verified`.
- macOS/Linux verification of the TUI.
- More SVG validation (viewBox clipping detection, node-count heuristics).

## License

[MIT](LICENSE).

## Bahasa Indonesia (ringkasan)

**Agent Skills** adalah pengelola *skill pack* modular untuk berbagai agen AI
pengkodean. Jalankan `npx agentskillsmd` untuk membuka pemasang interaktif: pilih
cakupan, agen, dan skill, lalu tinjau sebelum menulis berkas. Terdapat 55 skill
dalam 8 kategori, adaptor per agen, dan pemeriksa kualitas deterministik dengan
status `PASS`/`FAIL`/`WARN`/`SKIP`. Proyek ini **tidak** menjamin bebas dari "AI
slop"; ia mengurangi masalah kualitas yang dapat dicegah dan selalu menyatakan
keterbatasannya.
