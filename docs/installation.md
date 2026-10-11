# Installation

## Requirements

- **Windows** 10 or 11, or Windows Server with Windows PowerShell 5.1.
- **Windows PowerShell 5.1** (bundled with Windows) or **PowerShell 7+**.
- No administrator privileges for project-scope installs.
- No external PowerShell modules, no Node/Python, no network access.

To confirm your PowerShell version:

```powershell
$PSVersionTable.PSVersion
```

The toolkit targets PowerShell **5.1** and is tested on
`5.1.26100.8875`. It uses only features available in 5.1.

## npx

```bash
npx agent-skills
```

Or non-interactively:

```bash
npx agent-skills install -Preset svg-specialist -Agents codex,claude-code -Scope project -Yes
```

The npm package is a **thin launcher** (`bin/agent-skills.js`). It:

1. Locates PowerShell on `PATH` (`powershell.exe`/`pwsh` on Windows, `pwsh` on
   macOS/Linux).
2. Runs `installer/install.ps1` from the package directory, forwarding your
   arguments and the exit code.

It is **not** a reimplementation — all logic stays in the PowerShell module. Two
consequences worth knowing:

- **PowerShell is required.** Without it, `npx agent-skills` prints a clear error
  and exits non-zero; it does not fake success. On Windows, PowerShell 5.1 is
  already installed. On macOS/Linux, install PowerShell 7+.
- **Running with no arguments prints help** rather than opening an interactive
  menu, because `npx` is often used in non-interactive shells.

> Compatibility note: `npx` is verified on Windows in the authoring environment.
> macOS/Linux with `pwsh` is expected to work but is **untested** here.

## Getting the repository

Agent Skills installs from a local checkout. There is no download step and no
remote manifest.

```powershell
git clone https://github.com/voixera/agent-skills.git
cd agent-skills
```

## Remote bootstrap (irm | iex)

You can run the installer without cloning, by downloading a small bootstrap
script that fetches the repository and runs `install.ps1`:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/voixera/agent-skills/main/installer/bootstrap.ps1)))
```

`irm` is `Invoke-RestMethod` (download) and `iex` would be `Invoke-Expression`
(run). Because running remote code is a real risk, prefer the **save, read, run**
pattern instead of piping straight into `Invoke-Expression`:

```powershell
# 1. Download to a file
irm https://raw.githubusercontent.com/voixera/agent-skills/main/installer/bootstrap.ps1 -OutFile bootstrap.ps1

# 2. Inspect it
Get-Content .\bootstrap.ps1

# 3. Run it
.\bootstrap.ps1
```

### What the bootstrap does

1. Downloads the repository ZIP archive from GitHub (into a temp folder).
2. Extracts it.
3. Runs `installer/install.ps1` from the extracted copy.
4. Deletes the temp folder afterwards (unless you pass `-Keep`).

It does **not** install anything system-wide, does not require administrator
rights, and writes only the files the installer would write.

### Passing arguments

```powershell
# Directly
.\bootstrap.ps1 -InstallerArgs 'install','-Preset','minimal','-Agents','claude-code','-Yes'

# Or via the environment variable (handy for the one-liner form)
$env:AGENT_SKILLS_BOOTSTRAP_ARGS = 'install -Preset minimal -Agents claude-code -Yes'
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/voixera/agent-skills/main/installer/bootstrap.ps1)))
```

### Pinning a ref or a fork

```powershell
.\bootstrap.ps1 -Ref v1.0.0
# or point at any archive URL:
$env:AGENT_SKILLS_ARCHIVE_URL = 'https://github.com/you/agent-skills/archive/refs/tags/v1.0.0.zip'
```

### Why not `npx`?

There is **no npm package**. Agent Skills is a PowerShell tool, and publishing it
to npm would imply a Node runtime that does not exist here. If you see
`npx agent-skills` anywhere, it is not an official command. npm packaging is
listed on the roadmap.

## PowerShell usage

Run the entry-point script directly. It imports the module from `src/`, so no
separate module installation is needed.

```powershell
# Interactive
.\installer\install.ps1

# Non-interactive install into the current project
.\installer\install.ps1 install -Preset minimal -Agents claude-code -Scope project -Preview
.\installer\install.ps1 install -Preset minimal -Agents claude-code -Scope project -Yes
```

### Execution policy

If scripts are blocked, you have three options, in order of preference:

1. **Per-process bypass** (what the CMD launcher does). It does not change your
   machine policy:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\install.ps1 list
   ```

2. **Unblock the file** if it was downloaded:

   ```powershell
   Unblock-File .\installer\install.ps1
   ```

3. **Change the policy for the current user** (a real change to your system):

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

## CMD usage

`install.cmd` is a thin launcher: it locates `install.ps1` next to itself and
forwards all arguments. It prefers `powershell.exe`, then falls back to
`pwsh.exe`. It does not duplicate any installer logic.

```bat
installer\install.cmd help
installer\install.cmd list -Category svg
installer\install.cmd install -Skills accessibility-a11y -Agents claude-code -Scope project -Yes
```

The launcher returns the same exit codes as the PowerShell script.

## Scopes

| Scope | Writes to | Typical use |
| --- | --- | --- |
| `project` | The project directory (default: current) | Commit skills alongside the code. |
| `user` | Your home configuration for each agent | Apply the same skills everywhere. |

The manifest and backups live under `<project>/.agent-skills/` for project scope
and `~/.agent-skills/` for user scope.

Not every agent supports both scopes. See
[docs/supported-agents.md](supported-agents.md); unsupported combinations are
skipped with a `WARN`, never written to a guessed location.

## What installation writes

- One file per skill in the agent's native format (or one managed block in an
  aggregated file), and
- a manifest at `.agent-skills/.agent-skills-manifest.json`.

The installer **never executes skill content.** It only writes instruction and
configuration files.

## Uninstall

```powershell
.\installer\install.ps1 uninstall -Skills accessibility-a11y -Scope project
.\installer\install.ps1 uninstall -All -Scope project
```

Uninstall only removes files recorded in the manifest. For aggregated files it
removes only the managed block, preserving any surrounding user content.

## Verifying an install

```powershell
.\installer\install.ps1 verify -Scope project
```

This checks that each manifest entry still exists and matches its recorded hash.
Files you edited after install are reported as `WARN` (modified), not `FAIL`.

## Manual installation (no scripts)

If you prefer to install by hand, read an agent's adapter page under
`adapters/<agent>/README.md`, then copy the transformed file to the documented
path. The managed-block markers for aggregated files are:

```text
<!-- agent-skills:begin -->
... content ...
<!-- agent-skills:end -->
```

Only edit content inside the markers if you want `uninstall` to still work.
