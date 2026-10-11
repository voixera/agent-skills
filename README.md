![Agent Skills installer](docs/assets/AgentSkills.png)

# Agent Skills

**Multi-agent skills manager and anti-slop engineering toolkit.**

One command installs a curated set of engineering rules into your AI coding
agents - so they write better frontend, backend, tests, security, and SVG
instead of generic, same-as-everything output.

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
   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—â–ˆâ–ˆâ•—     â–ˆâ–ˆâ•—     â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—
  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•”â•â•â•â•â• â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ•‘â•šâ•â•â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•‘ â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•”â•â•â•â•â•
  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ•”â–ˆâ–ˆâ•— â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â• â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—
  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘     â•šâ•â•â•â•â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ•‘     â•šâ•â•â•â•â–ˆâ–ˆâ•‘
  â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â•šâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘ â•šâ–ˆâ–ˆâ–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘     â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘

  Anti-slop rules for AI coding agents.
  Multi-agent skills manager  â€¢  v2.1.0
  55 skills  â€¢  12 agents  â€¢  7 presets

? What would you like to do?
â¯ Install skills into your agent setup
  Uninstall skills
  Exit
```

Then walk through the wizard:

1. **Agents** - multi-select (choose one or more). Each agent shows its support
   level and whether it is **installed** on your machine. If a chosen agent is
   not installed, you are offered a link to its installer page.
2. **Skills** - choose one or more presets. Their skills are installed directly
   (no second selection step).
3. **Preview** - files to create/update, conflicts, dependencies. Nothing is
   written until you confirm.
4. **Install** - real progress for real work.
5. **Complete** - an accurate report.

Skills are always installed into the current project. **Uninstall** lists the
skills currently installed so you can pick which to remove.

**Keys:** `â†‘`/`â†“` move, `space` toggles, `a` toggles all, `enter` confirms,
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
| Cursor | `cursor` | rules | verified | project, user |
| GitHub Copilot | `github-copilot` | instructions | verified | project |
| Windsurf | `windsurf` | rules | verified | project, user |
| Cline | `cline` | rules | verified | project |
| Roo Code | `roo-code` | rules | verified | project |
| Gemini CLI | `gemini-cli` | native | verified | project, user |
| Continue | `continue` | rules | verified | project, user |
| OpenCode | `opencode` | native | verified | project, user |
| Hermes (Nous Research) | `hermes` | native | verified | project, user |
| Universal Markdown | `universal` | instructions | verified | project |

- **Support level** - how the agent discovers skills: `native` (discrete
  `SKILL.md`), `rules` (per-file rule documents), or `instructions` (one
  aggregated file with a managed block).
- **Evidence** - `verified` means the path/format was observed in a real
  installation; `documented` means it comes from vendor docs and was not tested
  locally. Codex, Claude Code, Gemini CLI, and OpenCode are `verified`.

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
