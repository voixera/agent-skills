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
- [CLI reference](#cli-reference)
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

Install and run with `npx` - no clone required:

```bash
npx agentskillsmd
```

That opens a guided, interactive setup: a 4-step wizard where you **choose** with
the keyboard instead of memorizing commands.

```text
  ------------------------------------------------------
   AGENT SKILLS
   Multi-Agent Skills Manager  v1.0.0
  ------------------------------------------------------

  1/4  Where should skills be installed?
  > This project  (C:\dev\my-app)
    My user profile  (applies everywhere)

  2/4  Which AI agents do you use?
     [x] OpenAI Codex           [native]
  >  [ ] Claude Code           [native]
     [ ] Cursor                [rules]
     [ ] Gemini CLI            [instructions]
     (up/down move, space toggles, "a" all, enter confirms)

  3/4  Start from a preset, or pick skills yourself?
     SVG Specialist
  >  Custom

  4/4  Review
    Summary
      Agents  : codex, claude-code
      Skills  : svg-craft, icon-design, ...
      Changes : 12 new, 0 updated, 0 unchanged
    Files
      [new   ] .codex/skills/svg-craft/SKILL.md
      [new   ] .claude/skills/svg-craft/SKILL.md
  Apply these changes? [y/N]
```

- **Arrow keys** move, **space** toggles a skill/agent, **a** selects all,
  **enter** confirms. Run it in a normal terminal for the full experience.
- On hosts that cannot read keys (piped/redirected input), it automatically
  falls back to simple numbered prompts, so it works in any script.

For scripts and CI, skip the wizard with a non-interactive command:

```bash
npx agentskillsmd install -Preset minimal -Agents claude-code -Scope project -Yes
```

Other examples:

```bash
npx agentskillsmd list -Category svg
npx agentskillsmd install -Preset svg-specialist -Agents codex,claude-code -Preview
npx agentskillsmd doctor
npx agentskillsmd validate
```

> **Requirements:** [Node.js](https://nodejs.org) 16+ (for `npx` itself) and
> **PowerShell** - Windows PowerShell 5.1 (bundled with Windows) or PowerShell 7+
> on any OS. The npm package is a thin launcher: it locates PowerShell and runs
> the same installer. If PowerShell is missing, the command fails with a clear
> message instead of pretending to work. See
> [docs/installation.md](docs/installation.md#npx).

## Installation

Agent Skills installs through `npx`:

```bash
npx agentskillsmd                 # interactive
npx agentskillsmd list -Category svg
npx agentskillsmd install -Preset minimal -Agents claude-code -Scope project -Yes
```

### Requirements

- **Node.js 16+** - provides the `npx` command.
- **PowerShell** - Windows PowerShell 5.1 (included in Windows 10/11) or
  PowerShell 7+ on macOS/Linux.
- No administrator rights are required for **project**-scope installs.

### What the launcher does

`npx agentskillsmd` downloads the `agentskillsmd` package, locates PowerShell, and
runs the installer from the package. It is not a reimplementation: all logic
lives in the PowerShell module, so there is a single implementation to audit.
With no arguments it prints help; pass a command (like `install`) to act.

### Scopes

| Scope | Writes to | Typical use |
| --- | --- | --- |
| `project` | The project directory (default: current) | Commit skills alongside the code. |
| `user` | Your home configuration for each agent | Apply the same skills everywhere. |

## CLI reference

All commands accept `-Path <dir>` to target a project other than the current
directory, and `-Scope project|user`.

| Command | Description |
| --- | --- |
| *(none)* | Run the interactive installer. |
| `list` | List available skills. `-Category <name>` filters. |
| `search <term>` | Search skills by id, name, or description. |
| `agents` | List supported agents and their support level. |
| `presets` | List skill presets. |
| `install` | Install skills (`-Skills`, `-Preset`, `-Agents`, `-Scope`). |
| `uninstall` | Remove installed skills (`-Skills`, `-Agents`, or `-All`). |
| `update` | Re-apply everything the manifest says is installed. |
| `verify` | Verify installed files against the manifest. |
| `validate` | Validate the registry and skills; `-Svg -Path <file>` for SVG. |
| `doctor` | Diagnose the environment and detected agents. |
| `help` | Show usage. |

Common options:

| Option | Meaning |
| --- | --- |
| `-Skills a,b` | Comma-separated skill ids. |
| `-Agents a,b` | Comma-separated agent ids. |
| `-Preset <id>` | Use a preset's skill set. |
| `-Scope project\|user` | Installation scope (default `project`). |
| `-Path <dir>` | Project directory (default current). |
| `-Category <name>` | Filter by category (`list` only). |
| `-Preview` | Show the plan without writing files. |
| `-Force` | Overwrite untracked files (a backup is taken first). |
| `-Yes` | Do not prompt for confirmation. |
| `-No-Dependencies` | Do not pull in skill dependencies. |

### Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success. |
| 1 | Generic failure (validation error, refused operation). |
| 2 | Usage error (bad or missing arguments). |
| 3 | Conflict: an untracked file would be overwritten (rerun with `-Force`). |
| 4 | Nothing to do / no matching selection. |

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

An SVG is **not** "validated" just because it parses. See
[docs/svg-quality.md](docs/svg-quality.md).

```powershell
.\installer\install.ps1 validate -Svg -Path .\art\logo.svg
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

```powershell
.\installer\install.ps1 validate
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

```powershell
# Re-apply from the registry (idempotent)
.\installer\install.ps1 update -Scope project

# Verify installed files against the manifest
.\installer\install.ps1 verify -Scope project

# Remove one skill (leaves other skills in a shared file intact)
.\installer\install.ps1 uninstall -Skills accessibility-a11y -Scope project

# Remove everything for a scope
.\installer\install.ps1 uninstall -All -Scope project
```

## Repository layout

```text
agent-skills/
|-- README.md, LICENSE, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, package.json
|-- bin/                 agent-skills.js (npm launcher)
|-- registry/            agents.json, skills.json, presets.json + schema/
|-- skills/              canonical SKILL.md packs by category
|-- src/AgentSkills/     the PowerShell module (engine)
|-- installer/           install.ps1 (entry point) + install.cmd + bootstrap.ps1
|-- adapters/            per-agent adapter documentation + fixtures
|-- tests/               unit/ integration/ fixtures/ + run-tests.ps1
|-- docs/                installation, supported-agents, skill-development, assets/ ...
\-- .github/             workflows, issue templates, PR template
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and
[docs/skill-development.md](docs/skill-development.md). In short: add a
`SKILL.md` under `skills/<category>/<id>/`, register it in
`registry/skills.json`, run `.\installer\install.ps1 validate` and
`.\tests\run-tests.ps1`, and open a pull request.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md). Quick checks:

```powershell
.\installer\install.ps1 doctor
.\installer\install.ps1 validate
```

## Testing

```powershell
.\tests\run-tests.ps1                 # all tests
.\tests\run-tests.ps1 -Suite unit     # unit only
.\tests\run-tests.ps1 -Suite integration
```

Tests use isolated temporary directories and never touch the real user profile.
Pester is not required.

## Known limitations

- The installer is **Windows/PowerShell-first**. The module is plain PowerShell
  and should run on PowerShell 7 on any OS, but non-Windows is **untested** here.
- Only the **Codex** and **Claude Code** adapters are `verified`. All others are
  `documented` from vendor docs and may drift with agent versions.
- The **SVG security scan is pattern-based** and is not a security guarantee.
- **Rendering** requires an external renderer; without one, rendering is skipped.
- Windows PowerShell 5.1 limitation: JSON is parsed with `ConvertFrom-Json`, and
  very large registries would be slower than on PowerShell 7 with `-AsHashtable`.
- The `npx` route requires PowerShell to be present; it is verified on Windows and
  **untested** on macOS/Linux (expected to work with `pwsh`).

## Roadmap

- Additional verified adapters as they can be tested against real installs.
- Optional `Pester`-based test entry point alongside the built-in harness.
- macOS/Linux verification of the `npx` route with PowerShell 7.
- A `search --remote` path is **not** planned until there is a signed registry;
  offline correctness is preferred.
- More SVG validation (viewBox clipping detection, node-count heuristics).

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
