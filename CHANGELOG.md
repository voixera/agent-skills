# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- PowerShell module `src/AgentSkills` providing the registry loader, a
  self-contained JSON-Schema (draft-07 subset) validator, the skill/frontmatter
  reader, the adapter engine, safe file operations, the installation manifest,
  the install/uninstall planner and executor, the content validator, and the SVG
  validator.
- Multi-agent adapter layer covering Codex, Claude Code, Cursor, GitHub Copilot,
  Windsurf, Cline, Roo Code, Gemini CLI, Continue, OpenCode, and Universal
  Markdown. Each adapter is documented under `adapters/<id>/README.md` with
  evidence level and limitations, plus shared fixtures under `adapters/_fixtures/`.
- PowerShell installer (`installer/install.ps1`) with interactive and
  non-interactive modes, project and user scopes, installation preview, conflict
  detection, untracked-file protection, force-overwrite with backup, and an
  installation manifest.
- CMD launcher (`installer/install.cmd`) that forwards to the PowerShell
  implementation without duplicating logic.
- Remote bootstrap (`installer/bootstrap.ps1`) backing the `irm | iex` one-liner;
  it downloads the repository archive and runs the installer, with a documented
  save-read-run alternative.
- npm package `agentskillsmd` (`package.json` + `bin/agent-skills.js`) providing a
  thin `npx agentskillsmd` launcher that locates PowerShell and runs the
  installer. Published under this name because the unscoped `agent-skills` name
  on npm belongs to an unrelated publisher.
- CLI commands: `list`, `search`, `agents`, `presets`, `install`, `uninstall`,
  `update`, `verify`, `validate`, `doctor`, `help`, with documented exit codes.
- Quality checker and SVG validator producing `PASS` / `FAIL` / `WARN` / `SKIP`
  results with explicit skip reasons. The SVG validator reports five independent
  stages: XML parse, security scan, accessibility, render, and visual review.
- Automated test suite (self-contained; Pester not required) with unit and
  integration tests, including CLI subprocess tests. All tests use isolated
  temporary directories.
- Documentation: `README.md`, `CONTRIBUTING.md`, and `docs/installation.md`,
  `docs/supported-agents.md`, `docs/skill-development.md`, `docs/svg-quality.md`,
  `docs/troubleshooting.md`, `docs/security.md`.
- GitHub Actions CI: registry validation, tests, PowerShell linting, markdown
  linting, and a secret scan; plus issue templates and a pull request template.

### Compatibility
- Codex and Claude Code adapters were verified against real installations in the
  authoring environment.
- Remaining adapters are based on vendor documentation and are marked `documented`
  rather than `verified`. See `docs/supported-agents.md`.

### Known limitations
- The installer is Windows/PowerShell-first; non-Windows PowerShell 7 is untested.
- The SVG security scan is pattern-based and is not a security guarantee.
- SVG rendering requires an external renderer and is otherwise skipped.
