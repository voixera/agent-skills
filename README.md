![Agent Skills](docs/assets/AgentSkills.png)

# Agent Skills

**Multi-Agent Skills Manager & Anti-Slop Engineering Toolkit.**

Agent Skills is a modular toolkit that installs reusable, high-quality **skill
packs** into supported AI coding agents. The goal is to reduce preventable
quality problems in AI-assisted work — generic UI, brittle tests, missing edge
cases, unsafe defaults, and hand-waved SVG — through actionable instructions,
deterministic checks, and transparent validation results.

> **Honest scope.** This project does not make an AI infallible and does not
> eliminate "AI slop". It reduces a specific class of preventable problems using
> explicit instructions, deterministic validators, and clearly reported limits.
> We never claim a check passed unless it actually ran.

## Table of contents

- [Problems addressed](#problems-addressed)
- [Features](#features)
- [Supported agents](#supported-agents)
- [Quick start](#quick-start)
- [Installation](#installation)
- [Menu reference](#menu-reference)
- [Skill catalog](#skill-catalog)
- [Presets](#presets)
- [SVG Craft Pro](#svg-craft-pro)
- [Quality checker](#quality-checker)
- [Security model](#security-model)
- [Updating and uninstalling](#updating-and-uninstalling)
- [Repository layout](#repository-layout)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Known limitations](#known-limitations)
- [Roadmap](#roadmap)
- [License](#license)

## Problems addressed

- **Generic, templated output.** Agents default to the same hero sections,
  gradients, and floating cards regardless of the brief.
- **Missing states.** Loading, empty, error, and disabled states are forgotten
  until they cause a bug.
- **Weak boundaries.** Validation is scattered, authorization is client-only,
  and secrets leak into logs.
- **Brittle tests.** Tests assert implementation details and are edited to hide
  failures.
- **Hand-waved SVG.** Vector graphics are "syntactically valid" but clipped,
  inaccessible, insecure, or visually incoherent.
- **Tool sprawl.** Every agent has a different file format and location, so the
  same guidance is copied by hand and drifts.

## Features

- **Modular skill packs** — 55 focused skills across 8 categories.
- **Canonical source, per-agent adapters** — one `SKILL.md` format, transformed
  into each agent's native shape. Adapters never blindly copy files.
- **Multi-agent, multi-scope installer** — project or user scope, preview,
  conflict detection, backups, and a manifest.
- **Safe by default** — refuses to overwrite untracked files without `-Force`;
  uninstall only removes files the tool created.
- **Deterministic validation** — registry schema checks, skill metadata,
  broken references, dependency cycles, and a five-stage SVG validator.
- **Idempotent** — reinstalling the same skills reports "unchanged" and writes
  nothing.
- **Offline** — everything runs from a local checkout. No paid API, no network.

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
| Universal Markdown | `universal` | instructions | documented | project |

**Support level** describes how the agent discovers skills:

- **native** — first-class discrete skill discovery (`<dir>/<skillId>/SKILL.md`).
- **rules** — the agent reads per-file rule documents, not discrete skills.
- **instructions** — the agent reads a single aggregated instruction file; skills
  are merged into a delimited managed block.

**Evidence** is either `verified` (the path/format was observed in a real
installation in the authoring environment) or `documented` (based on vendor
documentation, not verified locally). See [docs/supported-agents.md](docs/supported-agents.md).

## Quick start

Run this in an interactive terminal - it opens the installer immediately. There
is **no subcommand to type**:

```bash
npx agentskillsmd
```

You get a guided TUI: a large logo, then keyboard-driven screens where you
*choose* agents and skill packs.

```text
                                       ___                   ___                ___   ___              
                                      (   )                 (   )         .-.  (   ) (   )             
  .---.    .--.     .--.    ___ .-.    | |_         .--.     | |   ___   ( __)  | |   | |      .--.    
 / .-, \  /    \   /    \  (   )   \  (   __)     /  _  \    | |  (   )  (''")  | |   | |    /  _  \   
(__) ; | ;  ,-. ' |  .-. ;  |  .-. .   | |       . .' `. ;   | |  ' /     | |   | |   | |   . .' `. ;  
  .'`  | | |  | | |  | | |  | |  | |   | | ___   | '   | |   | |,' /      | |   | |   | |   | '   | |  
 / .'| | | |  | | |  |/  |  | |  | |   | |(   )  _\_`.(___)  | .  '.      | |   | |   | |   _\_`.(___) 
| /  | | | |  | | |  ' _.'  | |  | |   | | | |  (   ). '.    | | `. \     | |   | |   | |  (   ). '.   
; |  ; | | '  | | |  .'.-.  | |  | |   | ' | |   | |  `\ |   | |   \ \    | |   | |   | |   | |  `\ |  
' `-'  | '  `-' | '  `-' /  | |  | |   ' `-' ;   ; '._,' '   | |    \ .   | |   | |   | |   ; '._,' '  
`.__.'_.  `.__. |  `.__.'  (___)(___)   `.__.     '.___.'   (___ ) (___) (___) (___) (___)   '.___.'   
          ( `-' ;                                                                                      
           `.__.                                                                                       

  AGENT SKILLS  v1.1.0
  Multi-agent skills manager and anti-slop engineering toolkit.
  55 skills  •  11 agents  •  7 presets

? What would you like to do?
❯ Start installation
  Verify installed skills
  Update installed skills
  Uninstall skills
  Exit
```

### The flow

1. **Welcome / menu** - logo, version, and the actions below.
2. **Scope** - this project, your user profile, or a custom path (each explained).
3. **Agents** - multi-select with support level and evidence shown
   (`verified` / `documented`).
4. **Skills** - pick a preset (it preselects its skills), then customise;
   presets are never locked.
5. **Preview** - agents, skills, scope, files to create/update, conflicts, and
   dependencies. Nothing is written until you confirm.
6. **Install** - real progress for real work (resolve, write, manifest, verify).
7. **Complete** - an accurate report, then back to the menu.

Verify, update, and uninstall are also on the main menu - there is nothing to
type.

**Keys:** `↑`/`↓` navigate, `space` toggles, `a` toggles all, `enter` confirms,
`esc` goes back, `ctrl+c` quits safely. No mouse required.

> **Terminal support.** Built with `@inquirer/prompts`; works in Windows Terminal,
> PowerShell, CMD, and other ANSI-capable terminals. If no colour is available,
> output degrades to plain text. In a **non-interactive** shell (piped input) it
> prints a short notice telling you to run it in a terminal, instead of hanging.
>
> **Requirements:** [Node.js](https://nodejs.org) 18+. That is the only
> requirement - there is no PowerShell or other runtime dependency.

## Installation

Agent Skills installs through a single command:

```bash
npx agentskillsmd
```

### Requirements

- **Node.js 18+** - provides the `npx` command and runs the TUI.
- No administrator rights are required for **project**-scope installs.

### What the launcher does

`npx agentskillsmd` runs a single Node.js/TypeScript program. It renders the TUI
and performs the installation in-process - there is no external engine:

- The **TUI** (`src/tui`, `src/cli`) drives the screens and collects your choices.
- The **core** (`src/core`) reads the registry, builds a dry-run plan, writes the
  skill files and manifest, makes backups, and verifies. It never touches files it
  did not create.

Running with no arguments launches the interactive installer. There are no
subcommands.

### Scopes

| Scope | Writes to | Typical use |
| --- | --- | --- |
| `project` | The project directory (default: current) | Commit skills alongside the code. |
| `user` | Your home configuration for each agent | Apply the same skills everywhere. |

## Menu reference

There are no subcommands. Everything is reached from the main menu after
`npx agentskillsmd`:

| Menu option | Description |
| --- | --- |
| Start installation | Choose scope, agents, and skills, preview, then install. |
| Verify installed skills | Check installed files against the manifest. |
| Update installed skills | Re-apply everything the manifest says is installed. |
| Uninstall skills | Remove files Agent Skills created (nothing else is touched). |
| Exit | Quit. |

**Keys**

| Key | Action |
| --- | --- |
| `↑` / `↓` | Move the selection |
| `space` | Toggle a checkbox |
| `a` | Toggle all (multi-select lists) |
| `enter` | Confirm |
| `esc` | Go back |
| `ctrl+c` | Quit safely |

## Skill catalog

### frontend

- `frontend-architecture` — Frontend Architecture
- `react-best-practices` — React Best Practices
- `responsive-design` — Responsive Design
- `accessibility-a11y` — Accessibility (a11y)
- `frontend-performance` — Frontend Performance
- `design-system` — Design System
- `frontend-form-engineering` — Frontend Form Engineering
- `animation-and-interaction` — Animation and Interaction

### backend

- `api-design` — API Design
- `database-design` — Database Design
- `authentication-authorization` — Authentication and Authorization
- `secure-backend` — Secure Backend
- `backend-architecture` — Backend Architecture
- `integration-engineering` — Integration Engineering
- `backend-performance` — Backend Performance
- `data-validation-and-integrity` — Data Validation and Integrity

### ui-ux

- `ui-ux-design` — UI/UX Design
- `anti-generic-ui` — Anti-Generic UI
- `design-from-reference` — Design From Reference
- `microinteractions` — Microinteractions

### svg

- `svg-craft` — SVG Craft
- `custom-illustration` — Custom Illustration
- `icon-design` — Icon Design
- `logo-mark-design` — Logo Mark Design
- `svg-optimization` — SVG Optimization
- `svg-accessibility` — SVG Accessibility
- `svg-security` — SVG Security
- `svg-visual-review` — SVG Visual Review

### testing

- `unit-testing` — Unit Testing
- `integration-testing` — Integration Testing
- `e2e-testing` — End-to-End Testing
- `debugging-root-cause` — Debugging and Root Cause Analysis
- `regression-review` — Regression Review

### security

- `secure-coding` — Secure Coding
- `owasp-review` — OWASP-Oriented Web Security Review
- `dependency-auditing` — Dependency Auditing
- `secret-management` — Secret Management
- `authorization-review` — Authorization Review
- `threat-modeling` — Threat Modeling
- `secure-file-handling` — Secure File Handling
- `safe-error-handling` — Safe Error Handling

### devops

- `git-workflow` — Git Workflow
- `pull-request-review` — Pull Request Review
- `docker` — Docker and Containers
- `ci-cd` — CI/CD
- `environment-config` — Environment Configuration
- `deployment-readiness` — Deployment Readiness
- `observability` — Logging and Observability
- `migration-review` — Database Migration Review
- `dependency-management` — Dependency Management
- `release-notes` — Release Notes

### anti-slop

- `task-planning` — Task Planning
- `code-review` — Code Review
- `documentation` — Technical Documentation
- `anti-slop-review` — Anti-Slop Review

## Presets

| Preset | Description |
| --- | --- |
| `frontend-developer` | Frontend work with accessibility, responsiveness, performance, and design consistency. |
| `backend-developer` | Backend services, APIs, and data layers with security and correctness. |
| `full-stack-developer` | Frontend + backend + quality + security + testing. |
| `creative-developer` | Distinctive interfaces and original vector graphics. |
| `svg-specialist` | Produce, review, optimize, and harden SVG end to end. |
| `security-focused` | Review and harden against common web and backend weaknesses. |
| `minimal` | A small core of broadly useful skills. |

Every preset can be customized before installation; presets are starting points.
All preset references are validated against the registry at load time.

## SVG Craft Pro

The SVG category is the project's signature feature: a complete pipeline for
producing *and validating* vector graphics.

It is a set of eight skills (`svg-craft`, `custom-illustration`, `icon-design`,
`logo-mark-design`, `svg-optimization`, `svg-accessibility`, `svg-security`,
`svg-visual-review`) plus a validator that reports **five independent stages**:

1. **XML parse** — is it well-formed?
2. **Security scan** — scripts, event handlers, external references, unsafe URL
   schemes, `foreignObject`, DTD entities.
3. **Accessibility** — accessible name (`title`/`aria-label`) or explicit
   decorative marking.
4. **Render** — only if a renderer is available (`rsvg-convert`, `inkscape`,
   `magick`); otherwise reported as `SKIP` with a reason.
5. **Visual review** — *never* performed automatically; always reported as not
   done.

An SVG is **not** "validated" just because it parses. The validator is available
from the package API (`validateSvgFile` / `validateSvgText`). See
[docs/svg-quality.md](docs/svg-quality.md).

```js
const { validateSvgFile } = require('agentskillsmd/dist/core/core');
console.log(validateSvgFile('./art/logo.svg', { render: true }));
```

## Quality checker

The quality checker distinguishes objective failures from subjective design
preferences and uses four statuses:

- `PASS` — the check ran and succeeded.
- `FAIL` — the check ran and found a real problem.
- `WARN` — the check ran and found something to review.
- `SKIP` — the check did not run; **a reason is always given**, and a skip is
  never treated as a pass.

Available checks include: registry schema validation, skill metadata validation,
duplicate ids, missing files, broken references, dependency-cycle detection,
preset resolution, adapter/format compatibility, and the SVG pipeline.

The registry is validated automatically when the TUI starts, and can be checked
from the command line:

```bash
npm run validate
```

## Security model

- The installer **writes instruction and configuration files only**. It never
  executes skill content.
- No data is transmitted to any external service.
- Writes are confined to the selected scope; a destination that escapes it is
  refused.
- Untracked files are never silently overwritten.
- Uninstall only removes files recorded in the manifest, and preserves files
  outside the managed block.
- The repository must never contain secrets; CI includes a secret scan.

The SVG security scan is **pattern-based** and reduces risk; it is not a
guarantee that an SVG is safe. It can produce false negatives. See
[docs/security.md](docs/security.md) and the root [SECURITY.md](SECURITY.md).

## Updating and uninstalling

Both are on the **main menu** - run `npx agentskillsmd` and choose the action:

```bash
npx agentskillsmd
# -> Verify installed skills
# -> Update installed skills
# -> Uninstall skills
```

Under the hood these run the in-process TypeScript engine. Uninstall only removes
files Agent Skills created (recorded in the manifest). For shared instruction
files it removes only its own managed block, preserving the rest of the file.

## Repository layout

```text
agent-skills/
|-- README.md, LICENSE, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, package.json
|-- bin/                 agentskillsmd.js (npm executable)
|-- src/
|   |-- cli/             entry point (launches the TUI)
|   |-- tui/             TUI app, screens, components
|   |-- core/            registry, resolver, planner, engine, adapters, manifest
|   |-- validators/      SVG validator
|   \-- types/           shared TypeScript types
|-- registry/            agents.json, skills.json, presets.json + schema/
|-- skills/              canonical SKILL.md packs by category
|-- adapters/            per-agent adapter documentation + fixtures
|-- test/                Node tests (node:test)
|-- docs/                installation, supported-agents, skill-development, assets/ ...
\-- .github/             workflows, issue templates, PR template
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and
[docs/skill-development.md](docs/skill-development.md). In short: add a
`SKILL.md` under `skills/<category>/<id>/`, register it in
`registry/skills.json`, run `npm run validate` and `npm test`, and open a pull
request.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). Quick check:

```bash
npm run validate
```

## Testing

```bash
npm install
npm run build
npm test
```

Tests use isolated temporary directories and never touch the real user profile.

## Known limitations

- Only the **Codex** and **Claude Code** adapters are `verified`. All others are
  `documented` from vendor docs and may drift with agent versions.
- The **SVG security scan is pattern-based** and is not a security guarantee.
- **SVG rendering** requires an external renderer; the validation pipeline reports
  it as `SKIP` when none is present.
- The TUI requires an interactive terminal. In a non-TTY shell it prints a notice
  and exits rather than hanging.

## Roadmap

- Additional verified adapters as they can be tested against real installs.
- macOS/Linux verification of the TUI.
- More SVG validation (viewBox clipping detection, node-count heuristics).
- A `search --remote` path is **not** planned until there is a signed registry;
  offline correctness is preferred.

## License

[MIT](LICENSE).

## Bahasa Indonesia (ringkasan)

**Agent Skills** adalah pengelola *skill pack* modular untuk berbagai agen AI
pengkodean. Fitur utama: 55 skill dalam 8 kategori, adaptor per agen, pemasang
aman (project/user), pratinjau, manifes, serta pemeriksa kualitas deterministik
dengan status `PASS`/`FAIL`/`WARN`/`SKIP`. Proyek ini **tidak** menjamin bebas
dari "AI slop"; ia mengurangi masalah kualitas yang dapat dicegah dan selalu
menyatakan keterbatasannya. Dokumentasi lengkap ada dalam bahasa Inggris di
folder `docs/`.
