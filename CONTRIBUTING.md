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

```bash
git clone https://github.com/voixera/agent-skills.git
cd agent-skills
npm install
npm run build
npm test              # run the suite
npm run validate      # registry sanity check
```

Requirements: Node.js 18+ and Git. No other runtime.

## Adding a skill

Read [docs/skill-development.md](docs/skill-development.md) first. The short
version:

1. Create `skills/<category>/<skill-id>/SKILL.md` with valid frontmatter.
2. Register it in `registry/skills.json`.
3. Run `npm run validate` and `npm test`.
4. Open a pull request.

A skill should have **one coherent responsibility**, concrete steps, quality
criteria, anti-patterns, and a validation strategy. Do not submit a skill that
restates generic best practices without changing behavior.

## Code style

- TypeScript: 2-space indent, UTF-8, LF line endings (see `.editorconfig`).
- Prefer the simplest working implementation.
- No new dependencies unless justified.
- New behavior gets a test.

## Tests

```bash
npm test
```

The suite uses Node's built-in test runner (`node:test`). Tests must use isolated
temporary directories and must **never** touch the real user profile.

## Adapters

If you can verify an agent's real install path and format, promote its
`evidence` from `documented` to `verified` in `registry/agents.json` and say how
you verified it in the pull request. Do not claim `verified` without evidence.

## Pull request checklist

- [ ] `npm run validate` passes with no new `FAIL`s.
- [ ] `npm test` passes.
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
