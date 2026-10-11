# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Rewritten in TypeScript.** The installer is now a single Node.js/TypeScript
  program with an interactive TUI. The previous PowerShell module
  (`src/AgentSkills`), the PowerShell installer (`installer/`), the CMD launcher,
  the `irm | iex` bootstrap, and the PowerShell test suite have been removed. The
  install engine (planning, adapters, file writes, backups, manifest,
  verify/uninstall) is now implemented in `src/core`.
- The CLI is **TUI-only**: `npx agentskillsmd` launches the interactive installer
  immediately, with verify/update/uninstall on the main menu. There are no
  subcommands.
- Node.js 18+ is the only runtime requirement.

### Notes
- This is the initial unreleased development state. Nothing here has been published.
- Only the Codex and Claude Code adapters are `verified`. Every other adapter is
  `documented` and untested against a real installation. Do not read the
  compatibility matrix as a guarantee.

### Added
- Repository foundation: registry files (`registry/agents.json`, `registry/skills.json`,
  `registry/presets.json`) and JSON schemas for each.
- Canonical skill format based on `SKILL.md` with YAML frontmatter.
- Skill packs across eight categories: frontend, backend, ui-ux, svg, testing,
  security, devops, and anti-slop (55 skills total).
- TypeScript core (`src/core`) providing the registry loader, a schema validator,
  the skill/frontmatter reader, the adapter engine, the planner, the install
  engine (file writes, backups, manifest), verify/uninstall/update, and the SVG
  validator.
- Multi-agent adapter layer covering Codex, Claude Code, Cursor, GitHub Copilot,
  Windsurf, Cline, Roo Code, Gemini CLI, Continue, OpenCode, and Universal
  Markdown. Each adapter is documented under `adapters/<id>/README.md` with
  evidence level and limitations, plus shared fixtures under `adapters/_fixtures/`.
- Interactive TUI (`src/tui`) built with `@inquirer/prompts`: welcome/main menu,
  scope, agents, skills, preview, progress, and completion screens.
- Install engine in `src/core`: project and user scopes, installation preview,
  conflict detection, untracked-file protection, force-overwrite with backup, and
  an installation manifest.
- npm package `agentskillsmd` (`package.json` + `bin/agentskillsmd.js`) so the tool
  runs via `npx agentskillsmd`. Published under this name because the unscoped
  `agent-skills` name on npm belongs to an unrelated publisher.
- Quality checker and SVG validator producing `PASS` / `FAIL` / `WARN` / `SKIP`
  results with explicit skip reasons. The SVG validator reports five independent
  stages: XML parse, security scan, accessibility, render, and visual review.
- Automated test suite using Node's built-in test runner. All tests use isolated
  temporary directories.
- Documentation: `README.md`, `CONTRIBUTING.md`, and `docs/installation.md`,
  `docs/supported-agents.md`, `docs/skill-development.md`, `docs/svg-quality.md`,
  `docs/troubleshooting.md`, `docs/security.md`.
- GitHub Actions CI: build, tests, registry validation, markdown linting, and a
  secret scan; plus issue templates and a pull request template.

### Compatibility
- Codex and Claude Code adapters were verified against real installations in the
  authoring environment.
- Remaining adapters are based on vendor documentation and are marked `documented`
  rather than `verified`. See `docs/supported-agents.md`.

### Known limitations
- The TUI requires an interactive terminal; non-Windows is untested.
- The SVG security scan is pattern-based and is not a security guarantee.
- SVG rendering requires an external renderer and is otherwise reported as skipped.
