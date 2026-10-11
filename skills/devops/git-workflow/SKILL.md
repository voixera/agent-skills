---
name: git-workflow
description: Make focused commits and branches with clear messages, without rewriting shared history. Use when committing, branching, or preparing changes for review.
metadata:
  category: devops
  version: 1.0.0
  agents: all
  tools: git
---

# Git Workflow

## Operating procedure

1. **Inspect before committing.** Run `git status` and `git diff` (and `git diff --staged`)
   to see exactly what you are about to commit. Stage only the files that belong to the
   change. Never commit secrets - check the diff for keys, tokens, and `.env` files.

2. **Keep commits focused.** One logical change per commit. Do not mix a refactor, a bug
   fix, and a formatting sweep in one commit; they cannot be reviewed or reverted
   independently.

3. **Write clear messages.** A good message explains *why*, not just *what* (the diff
   already shows what). Use the repository's existing style. A common convention:
   - Subject line: short, imperative, no trailing period.
   - Body (when needed): the reasoning, the trade-off, anything surprising.

4. **Branch for work.** Use a short, descriptive branch name. Do not commit work directly
   to a protected/main branch in a shared repository.

5. **Do not rewrite shared history.** Avoid force-pushing to branches others use, avoid
   amending commits already pushed to a shared branch, and avoid rebasing shared branches.
   Rewriting is fine on your own unshared branch.

6. **Never fabricate state.** Do not claim a commit or push succeeded without verifying.
   Do not invent remote URLs. If a command fails, report the real output.

7. **Respect the existing repository.** If you are working in a pre-existing repo, match
   its conventions (message style, branch naming, hooks) rather than imposing new ones.

8. **Handle hooks honestly.** If a pre-commit hook fails, fix the underlying problem and
   commit again. Do not bypass hooks with `--no-verify` unless explicitly asked and the
   reason is understood.

## Quality criteria

- The diff contains only intended changes; no secrets; no stray files.
- Commits are logically scoped and independently reviewable.
- Messages explain intent and match repository style.
- History sharing rules are respected.
- No unverified claims about commit/push state.

## Anti-patterns to avoid

- `git add .` without reviewing what it stages.
- Committing build output, editor files, or `.env`.
- Force-pushing to a shared branch.
- A single giant "misc changes" commit.
- Claiming a push succeeded when it was never run.
- Amending a commit that others have already based work on.

## Validation strategy

- Review `git status` and `git diff` before committing.
- Grep the staged diff for secret patterns.
- Confirm the commit message matches the repository's convention (check `git log`).
- Run `git log` / `git status` after committing to confirm the real state.

## Reference

- General Git practice; the repository's own CONTRIBUTING.md.
