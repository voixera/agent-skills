# Installation

## Requirements

- **Node.js 18+** (provides `npx` and runs the TUI).
- An **interactive terminal** (Windows Terminal, PowerShell, CMD, or another
  ANSI-capable terminal).
- No administrator privileges for project-scope installs.
- No network access is required to install into a project; `npx` fetches the
  package once from npm.

There is no PowerShell, Python, or other runtime dependency.

## npx

```bash
npx agentskillsmd
```

This launches the interactive TUI immediately. There are no subcommands.

`npx` downloads the `agentskillsmd` package and runs it. The program:

1. Renders the TUI and, when you confirm, installs the skills in-process.
2. Prints a short notice and exits if the shell is not an interactive terminal.

Because the whole thing is one Node program, there is nothing else to install.

> Compatibility note: verified on Windows in the authoring environment.
> macOS/Linux is expected to work but is **untested** here.

## Getting the repository

You do not need to clone anything to install into a project. To contribute or to
run the tests, clone:

```bash
git clone https://github.com/voixera/agent-skills.git
cd agent-skills
npm install
npm run build
npm test
```

## Running from a checkout

```bash
npm install
npm run build
node bin/agentskillsmd.js     # launches the TUI
```

## What installation writes

- One file per skill in the agent's native format (or one managed block in an
  aggregated file), and
- a manifest at `.agent-skills/.agent-skills-manifest.json`.

The engine **never executes skill content**. It only writes instruction and
configuration files, and only files recorded in the manifest can later be
removed by uninstall.

## Uninstall

Run `npx agentskillsmd` and choose **Uninstall skills**. Only files Agent Skills
created are removed. For aggregated files, only the managed block is removed;
surrounding content is preserved.

## Verifying an install

Run `npx agentskillsmd` and choose **Verify installed skills**. This checks that
each manifest entry still exists and matches its recorded hash. Files you edited
after install are reported as `WARN` (modified), not `FAIL`.

## Terminal support

The TUI is built with `@inquirer/prompts`. It supports arrow-key navigation,
space to toggle, `enter` to confirm, and `esc` to go back. If the terminal
reports no colour support (`NO_COLOR`), output degrades to plain text. In a
non-interactive shell it prints a notice rather than hanging.
