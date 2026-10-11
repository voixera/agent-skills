# Troubleshooting

Start here:

```powershell
.\installer\install.ps1 doctor
.\installer\install.ps1 validate
```

## "install.ps1 cannot be loaded because running scripts is disabled"

Your execution policy blocks scripts. Options:

```powershell
# Per-process (no system change) — this is what install.cmd uses:
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\install.ps1 list

# Or unblock a downloaded file:
Unblock-File .\installer\install.ps1
```

See [installation.md](installation.md) for more.

## "Cannot find the Agent Skills module"

The entry point expects the module at `src/AgentSkills/AgentSkills.psd1`
relative to the repository root. This happens if `install.ps1` was moved without
`src/`. Restore the repository layout, or set the root explicitly:

```powershell
$env:AGENT_SKILLS_ROOT = 'C:\path\to\agent-skills'
```

## Exit code 3, "Existing untracked file"

The destination exists but was not created by Agent Skills, so overwriting it was
refused. Review the plan first, then decide:

```powershell
.\installer\install.ps1 install -Skills <id> -Agents <agent> -Preview
.\installer\install.ps1 install -Skills <id> -Agents <agent> -Yes -Force
```

`-Force` writes a backup to `.agent-skills/backups/` before overwriting.

## Nothing was installed (exit code 4)

The selection matched nothing. Check the ids:

```powershell
.\installer\install.ps1 list
.\installer\install.ps1 search <term>
```

Also check the agent supports the scope you chose — unsupported combinations are
skipped with a `WARN`.

## A skill was skipped for an agent

The skill does not list that agent as supported, or the agent does not support
the chosen scope. The plan prints a `WARN` explaining which. Use a supported
combination or an agent whose support level fits the skill.

## "verify" shows WARN "modified since install"

You (or an agent) edited an installed file after installation. This is expected
if you customized a skill. To reset it to the registry version:

```powershell
.\installer\install.ps1 update -Scope project -Force
```

## My `GEMINI.md` / `AGENTS.md` content was changed

The installer writes and updates only the block between:

```text
<!-- agent-skills:begin -->
<!-- agent-skills:end -->
```

If content inside the markers was hand-edited, it will be regenerated on the next
install/update. Keep your own content outside the markers.

## SVG validate says SKIP for render / visual review

- `svg:render` is `SKIP` unless you pass `-Render` **and** a renderer is on
  `PATH`. Install `rsvg-convert`, Inkscape, or ImageMagick to enable it.
- `svg:visual-review` is **always** `SKIP`. It is a human/AI judgement step and
  is never performed automatically. This is intentional.

## "validate" fails on the registry

Run it to see the specific failures:

```powershell
.\installer\install.ps1 validate
```

Common causes: a skill id that does not match its directory name, a file missing
from `skills/`, a preset referencing an unknown skill id, or a dependency cycle.
Fix the registry or the skill file and re-run.

## Tests fail

```powershell
.\tests\run-tests.ps1
```

Tests use isolated temp directories. If a test leaves state behind, remove any
`agentskills-test-*` folders under `%TEMP%`. If a test fails on a machine with a
non-ASCII home path, please open an issue with the failing test name and output.

## Non-Windows / PowerShell 7

The module is plain PowerShell and should run on PowerShell 7. Non-Windows is
**untested** in this repository. If you try it, note it as unverified.

## Rolling back an install

Remove everything the tool created for a scope:

```powershell
.\installer\install.ps1 uninstall -All -Scope project
```

Backups of files that were overwritten are under `.agent-skills/backups/`.
Copy a backup back manually if you need the original file.
