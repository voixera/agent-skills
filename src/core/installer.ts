/**
 * Installation engine bridge (core).
 *
 * The TUI must not contain install logic (see the project requirement, section
 * 7). The single source of install truth is the PowerShell engine. This module
 * locates a PowerShell host and invokes the engine, parsing its output into
 * structured results.
 *
 * Planning is done in TypeScript (core/planner.ts) for instant previews, then
 * executed by the engine so previews and results cannot drift.
 */

import { spawnSync, SpawnSyncReturns } from 'node:child_process';
import * as fs from 'node:fs';
import * as path from 'node:path';
import type { InstallResult, Scope } from '../types';
import { resolvePackageRoot } from './registry';

export interface PowerShellHost {
  command: string;
  isWindows: boolean;
}

/** Find a usable PowerShell host, or null when none is present. */
export function findPowerShell(): PowerShellHost | null {
  const candidates =
    process.platform === 'win32'
      ? ['powershell.exe', 'pwsh.exe', 'pwsh']
      : ['pwsh', 'powershell'];

  for (const command of candidates) {
    const probe = spawnSync(command, ['-NoProfile', '-Command', '$PSVersionTable.PSVersion.Major'], {
      encoding: 'utf8',
      windowsHide: true,
    });
    if (!probe.error && probe.status === 0) {
      return { command, isWindows: process.platform === 'win32' };
    }
  }
  return null;
}

export function requirePowerShell(): PowerShellHost {
  const host = findPowerShell();
  if (!host) {
    throw new Error(
      'PowerShell was not found on this system.\n' +
        'Agent Skills runs its installation engine on PowerShell. Install PowerShell 7+ ' +
        '(https://aka.ms/powershell) and try again. Windows already includes PowerShell 5.1.'
    );
  }
  return host;
}

export function installerScript(): string {
  const root = resolvePackageRoot();
  const script = path.join(root, 'installer', 'install.ps1');
  if (!fs.existsSync(script)) {
    throw new Error(`Installer engine not found at ${script}.`);
  }
  return script;
}

function runPowerShell(args: string[]): SpawnSyncReturns<string> {
  const host = requirePowerShell();
  return spawnSync(
    host.command,
    ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', installerScript(), ...args],
    { encoding: 'utf8', windowsHide: true, maxBuffer: 32 * 1024 * 1024 }
  );
}

/** Parse result lines like "[ok] PASS .codex/.../SKILL.md - create". */
export function parseResultLines(output: string): InstallResult[] {
  const results: InstallResult[] = [];
  const re = /\[(?:ok|warn|error)\]\s+(PASS|FAIL|WARN|SKIP)\s+(\S+)(?:\s+-\s+(.*))?/g;
  let match: RegExpExecArray | null;
  while ((match = re.exec(output)) !== null) {
    results.push({
      status: match[1] as InstallResult['status'],
      name: match[2],
      message: (match[3] ?? '').trim(),
      category: 'install',
    });
  }
  return results;
}

export interface ExecuteOptions {
  projectRoot: string;
  scope: Scope;
  agentIds: string[];
  skillIds: string[];
  force?: boolean;
}

export interface ExecuteOutcome {
  exitCode: number;
  stdout: string;
  stderr: string;
  results: InstallResult[];
}

/**
 * Execute an installation. The engine writes files and the manifest; this
 * returns its exit code and parsed results.
 */
export function executeInstall(options: ExecuteOptions): ExecuteOutcome {
  const args = [
    'install',
    '-Skills', options.skillIds.join(','),
    '-Agents', options.agentIds.join(','),
    '-Scope', options.scope,
    '-Path', options.projectRoot,
    '-Yes',
  ];
  if (options.force) args.push('-Force');

  const proc = runPowerShell(args);
  const stdout = proc.stdout ?? '';
  const stderr = proc.stderr ?? '';

  if (proc.error) {
    throw proc.error;
  }

  return {
    exitCode: proc.status ?? 1,
    stdout,
    stderr,
    results: parseResultLines(stdout),
  };
}

export interface VerifyOutcome {
  exitCode: number;
  results: InstallResult[];
}

export function verifyInstallation(projectRoot: string, scope: Scope): VerifyOutcome {
  const proc = runPowerShell(['verify', '-Scope', scope, '-Path', projectRoot]);
  const stdout = proc.stdout ?? '';
  return { exitCode: proc.status ?? 1, results: parseResultLines(stdout) };
}

export function uninstall(projectRoot: string, scope: Scope, skillIds: string[], agentIds: string[]): ExecuteOutcome {
  const args = ['uninstall', '-Scope', scope, '-Path', projectRoot];
  if (skillIds.length) args.push('-Skills', skillIds.join(','));
  if (agentIds.length) args.push('-Agents', agentIds.join(','));
  if (!skillIds.length && !agentIds.length) args.push('-All');

  const proc = runPowerShell(args);
  const stdout = proc.stdout ?? '';
  return {
    exitCode: proc.status ?? 1,
    stdout,
    stderr: proc.stderr ?? '',
    results: parseResultLines(stdout),
  };
}

export function validateEngine(): { exitCode: number; stdout: string } {
  const proc = runPowerShell(['validate']);
  return { exitCode: proc.status ?? 1, stdout: proc.stdout ?? '' };
}
