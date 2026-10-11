# Contributing to Agent Skills

Thanks for helping improve Agent Skills. This project cares about **honest,
actionable quality** — skills that change what an agent actually does, not
generic advice.

## Ways to contribute

- Add or improve a skill.
- Add or verify an agent adapter (most valuable: turning a `documented` adapter
  into a `verified` one).
- Improve the validator, installer, or tests.
- Improve documentation.
- Report a bug or a security issue (see [SECURITY.md](SECURITY.md)).

## Getting set up

```powershell
git clone https://github.com/<your-org>/agent-skills.git
cd agent-skills
.\installer\install.ps1 validate   # sanity check
.\tests\run-tests.ps1              # run the suite
```

Requirements: Windows PowerShell 5.1 (or PowerShell 7+) and Git. No external
modules.

## Adding a skill

Read [docs/skill-development.md](docs/skill-development.md) first. The short
version:

1. Create `skills/<category>/<skill-id>/SKILL.md` with valid frontmatter.
2. Register it in `registry/skills.json`.
3. Run `.\installer\install.ps1 validate` and `.\tests\run-tests.ps1`.
4. Open a pull request.

A skill should have **one coherent responsibility**, concrete steps, quality
criteria, anti-patterns, and a validation strategy. Do not submit a skill that
restates generic best practices without changing behavior.

## Code style

- PowerShell: 4-space indent, UTF-8, LF line endings (see `.editorconfig`).
- Prefer the simplest working implementation.
- No new dependencies unless justified.
- Every public function has comment-based help.
- New behavior gets a test.

## Tests

```powershell
.\tests\run-tests.ps1
```

The suite is self-contained (no Pester required). Tests must use isolated
temporary directories and must **never** touch the real user profile.

## Adapters

If you can verify an agent's real install path and format, promote its
`evidence` from `documented` to `verified` in `registry/agents.json` and say how
you verified it in the pull request. Do not claim `verified` without evidence.

## Pull request checklist

- [ ] `.\installer\install.ps1 validate` passes with no new `FAIL`s.
- [ ] `.\tests\run-tests.ps1` passes.
- [ ] New skills are registered and non-duplicative.
- [ ] Documentation is updated if behavior changed.
- [ ] No secrets, no fabricated claims, no invented URLs.
- [ ] The change is focused and the commit messages are clear.

## Commit messages

Write focused commits with clear messages in the imperative mood, for example:

```text
Add icon-design validation fixture

Document the cursor adapter's alwaysApply default
```

Do not rewrite shared history.

## Code of conduct

Participation is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).
