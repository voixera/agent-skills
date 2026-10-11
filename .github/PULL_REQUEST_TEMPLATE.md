# Pull request

## Summary

What does this change and why?

## Type of change

- [ ] New skill
- [ ] Skill improvement
- [ ] Adapter (new / verified)
- [ ] Installer / CLI
- [ ] Validator
- [ ] Documentation
- [ ] Fix

## Checklist

- [ ] `.\installer\install.ps1 validate` passes with no new `FAIL`s.
- [ ] `.\tests\run-tests.ps1` passes.
- [ ] New skills are registered in `registry/skills.json` and are non-duplicative.
- [ ] Documentation is updated if behavior changed.
- [ ] No secrets, no fabricated claims, no invented URLs.
- [ ] Adapter changes state their evidence level honestly.
- [ ] The change is focused (one concern per PR).

## Evidence

For adapter changes, describe how you verified the path and format. For validator
changes, show a before/after example. For skills, note the concrete behavior the
skill changes.

```text
(paste relevant output)
```

## Related issues

Closes #
