# Troubleshooting

Start here:

```bash
npm run validate
```

Then run `npx agentskillsmd` and try again.

## "Agent Skills needs an interactive terminal"

You ran the command in a shell without a TTY (piped input, some CI runners, or an
IDE task). Open Windows Terminal, PowerShell, CMD, or another terminal and run:

```bash
npx agentskillsmd
```

## The command hangs

It should not. In a non-interactive shell it prints the notice above and exits.
If it hangs, your terminal may not be passing key input; try a different terminal.

## `npx` cannot find the package

Make sure you are online and the package name is correct:

```bash
npx agentskillsmd
```

If the registry does not have it yet (the package may not be published), run from
a checkout instead:

```bash
npm install
npm run build
node bin/agentskillsmd.js
```

## A conflict is reported (`Existing untracked file`)

The destination exists but was not created by Agent Skills, so overwriting it was
refused. Review the preview, then choose **Install and overwrite conflicting
files** on the preview screen (a backup is written to `.agent-skills/backups/`
before anything is replaced).

## Nothing was installed

The selection matched nothing, or an agent does not support the chosen scope.
Re-run and check that at least one agent and one skill are selected; unsupported
combinations are shown as notes on the preview screen and skipped.

## A skill was skipped for an agent

The skill does not list that agent as supported, or the agent does not support the
chosen scope. The preview screen shows a note explaining which. Pick a supported
combination.

## Verify shows `WARN` "modified since install"

You (or an agent) edited an installed file after installation. This is expected if
you customised a skill. To reset it to the registry version, run `npx
agentskillsmd` and choose **Update installed skills**.

## My `GEMINI.md` / `AGENTS.md` content was changed

The installer writes and updates only the block between:

```text
<!-- agent-skills:begin -->
<!-- agent-skills:end -->
```

If content inside the markers was hand-edited, it is regenerated on the next
install/update. Keep your own content outside the markers.

## SVG validation says `SKIP` for render / visual review

- `svg:render` is `SKIP` unless you request rendering and a renderer is on `PATH`.
- `svg:visual-review` is **always** `SKIP`: it is a human/AI judgement step and is
  never performed automatically. This is intentional.

## The registry fails to validate

Run it to see the specific failures:

```bash
npm run validate
```

Common causes: a skill id that does not match its directory name, a file missing
from `skills/`, a preset referencing an unknown skill id, or a dependency cycle.

## Tests fail

```bash
npm install
npm run build
npm test
```

Tests use isolated temp directories. If a test leaves state behind, remove any
`agentskills-*` folders under your temp directory.

## Non-Windows

The TUI is written in Node and should run on macOS/Linux. It is **untested** there
in this repository. If you try it, treat it as unverified.

## Rolling back an install

Run `npx agentskillsmd` and choose **Uninstall skills**. Backups of files that
were overwritten are under `.agent-skills/backups/`; copy one back manually if you
need the original.
