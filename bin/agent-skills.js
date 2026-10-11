#!/usr/bin/env node
'use strict';

/*
 * Agent Skills - npm bin wrapper.
 *
 * This is a thin launcher, not a reimplementation. It locates PowerShell and
 * runs installer/install.ps1 from the package directory, forwarding all
 * arguments and the exit code. All real logic lives in the PowerShell module so
 * there is a single implementation to audit.
 *
 * Supported hosts: Windows (powershell.exe / pwsh.exe), and any OS where
 * PowerShell 7+ (`pwsh`) is installed. If PowerShell is not found, we fail
 * clearly instead of pretending to work.
 */

const { spawnSync } = require('node:child_process');
const { existsSync } = require('node:fs');
const path = require('node:path');

const packageRoot = path.resolve(__dirname, '..');
const installerScript = path.join(packageRoot, 'installer', 'install.ps1');

if (!existsSync(installerScript)) {
  console.error(
    '[agent-skills] Could not find installer/install.ps1 inside the package.\n' +
    `[agent-skills] Looked in: ${installerScript}`
  );
  process.exit(1);
}

/** Find a PowerShell host on PATH. Returns { cmd, args } or null. */
function findPowerShell() {
  const candidates = process.platform === 'win32'
    ? ['powershell.exe', 'pwsh.exe', 'pwsh']
    : ['pwsh', 'powershell'];

  for (const cmd of candidates) {
    const probe = spawnSync(cmd, ['-NoProfile', '-Command', '$PSVersionTable.PSVersion.Major'], {
      encoding: 'utf8',
      windowsHide: true,
    });
    if (!probe.error && probe.status === 0) {
      return cmd;
    }
  }
  return null;
}

const pwsh = findPowerShell();

if (!pwsh) {
  console.error(
    '[agent-skills] PowerShell was not found on this system.\n' +
    '\n' +
    'Agent Skills runs on PowerShell. Install one of:\n' +
    '  - Windows: Windows PowerShell 5.1 is already included.\n' +
    '  - macOS/Linux: install PowerShell 7+ (https://aka.ms/powershell).\n' +
    '\n' +
    'Then run this command again.'
  );
  process.exit(1);
}

const forwarded = process.argv.slice(2);

// If invoked with no sub-command, show help rather than dropping into an
// interactive menu that cannot be driven by a non-interactive shell.
if (forwarded.length === 0) {
  forwarded.push('help');
}

const args = [
  '-NoProfile',
  '-ExecutionPolicy', 'Bypass',
  '-File', installerScript,
  ...forwarded,
];

const result = spawnSync(pwsh, args, {
  stdio: 'inherit',
  windowsHide: false,
});

if (result.error) {
  console.error(`[agent-skills] Failed to start ${pwsh}: ${result.error.message}`);
  process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);
