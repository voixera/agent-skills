/**
 * CLI entry point.
 *
 * Default behaviour (no arguments): launch the interactive TUI immediately.
 * Advanced subcommands exist for automation but never replace the default
 * experience. In a non-interactive environment (no TTY) we print a helpful
 * explanation with the supported non-interactive usage instead of hanging.
 */

import { runApp } from '../tui/app';
import { banner, paint } from '../tui/components/theme';
import { loadRegistry } from '../core/registry';
import { verifyInstallation } from '../core/installer';
import { updateInstalled } from '../core/core';
import { installedSkillIds, readManifest } from '../core/manifest';
import { runList, runAgents, runPresets, runValidate } from './commands';

export function isInteractive(): boolean {
  return Boolean(process.stdin.isTTY && process.stdout.isTTY);
}

function printNonInteractiveHelp(): void {
  process.stdout.write(banner());
  process.stdout.write(
    [
      '',
      `  ${paint('This looks like a non-interactive shell.', 'warn')}`,
      '  The installer needs a terminal to show its interactive menu.',
      '',
      `  ${paint('Run it in an interactive terminal, or use a command:', 'dim')}`,
      '',
      '    npx agentskillsmd install -Preset minimal -Agents claude-code -Yes',
      '    npx agentskillsmd list',
      '    npx agentskillsmd agents',
      '    npx agentskillsmd presets',
      '    npx agentskillsmd validate',
      '    npx agentskillsmd verify',
      '    npx agentskillsmd update',
      '    npx agentskillsmd uninstall -Skills <id>',
      '',
      '  Help: npx agentskillsmd help',
      '',
    ].join('\n')
  );
}

function parseFlags(args: string[]): Record<string, string | true> {
  const out: Record<string, string | true> = {};
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (!a.startsWith('-')) continue;
    const name = a.replace(/^--?/, '').toLowerCase();
    const eq = name.indexOf('=');
    if (eq >= 0) {
      out[name.slice(0, eq)] = name.slice(eq + 1);
    } else if (i + 1 < args.length && !args[i + 1].startsWith('-')) {
      out[name] = args[i + 1];
      i++;
    } else {
      out[name] = true;
    }
  }
  return out;
}

function splitList(value: string | true | undefined): string[] {
  if (!value || value === true) return [];
  return String(value)
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

async function main(): Promise<number> {
  const argv = process.argv.slice(2);
  const command = argv[0]?.toLowerCase();

  // Advanced commands (never the default path).
  switch (command) {
    case 'help':
    case '--help':
    case '-h':
      process.stdout.write(banner());
      process.stdout.write(
        [
          '',
          '  Usage: agentskillsmd [command] [options]',
          '',
          '  Run with no arguments to open the interactive installer.',
          '',
          '  Commands:',
          '    (none)                 Interactive installer (TUI)',
          '    list                   List skills (-Category <name>)',
          '    agents                 List supported agents',
          '    presets                List presets',
          '    validate               Validate the registry',
          '    verify                 Verify installed files',
          '    update                 Re-apply installed skills',
          '    uninstall              Remove skills (-Skills <a,b> | -All)',
          '    install                Non-interactive install',
          '',
        ].join('\n')
      );
      return 0;

    case 'list':
      return runList(parseFlags(argv.slice(1)));
    case 'agents':
      return runAgents();
    case 'presets':
      return runPresets();
    case 'validate':
      return runValidate();
    case 'verify': {
      const flags = parseFlags(argv.slice(1));
      const scope = (flags.scope as string) ?? 'project';
      const root = (flags.path as string) ?? process.cwd();
      const v = verifyInstallation(root, scope as 'project' | 'user');
      for (const r of v.results) {
        const colored =
          r.status === 'PASS'
            ? paint(r.status, 'ok')
            : r.status === 'FAIL'
            ? paint(r.status, 'error')
            : r.status === 'WARN'
            ? paint(r.status, 'warn')
            : paint(r.status, 'dim');
        process.stdout.write(`  ${colored} ${r.name}${r.message ? ` - ${r.message}` : ''}\n`);
      }
      return v.exitCode;
    }
    case 'update': {
      const flags = parseFlags(argv.slice(1));
      const scope = ((flags.scope as string) ?? 'project') as 'project' | 'user';
      const root = (flags.path as string) ?? process.cwd();
      const res = updateInstalled(root, scope);
      if (!res) {
        process.stdout.write('  Nothing installed for this scope.\n');
        return 4;
      }
      process.stdout.write(res.stdout);
      return res.exitCode;
    }
    case 'uninstall': {
      // Delegate to the engine for full safety semantics.
      const flags = parseFlags(argv.slice(1));
      const scope = ((flags.scope as string) ?? 'project') as 'project' | 'user';
      const root = (flags.path as string) ?? process.cwd();
      const skills = splitList(flags.skills);
      const { uninstall } = await import('../core/installer');
      const res = uninstall(root, scope, skills, []);
      process.stdout.write(res.stdout);
      return res.exitCode;
    }
    case 'install': {
      // Non-interactive install (documented for CI). Delegates to the engine.
      const flags = parseFlags(argv.slice(1));
      const scope = ((flags.scope as string) ?? 'project') as 'project' | 'user';
      const root = (flags.path as string) ?? process.cwd();
      const agents = splitList(flags.agents);
      let skills = splitList(flags.skills);
      const preset = flags.preset as string | undefined;
      if (preset) {
        const reg = loadRegistry();
        const p = reg.presets.presets.find((x) => x.id === preset);
        if (!p) {
          process.stderr.write(`Unknown preset: ${preset}\n`);
          return 2;
        }
        skills = p.skills;
      }
      if (skills.length === 0 || agents.length === 0) {
        process.stderr.write('install requires -Skills/-Preset and -Agents. Run `help`.\n');
        return 2;
      }
      const { executeInstall } = await import('../core/installer');
      const res = executeInstall({ projectRoot: root, scope, agentIds: agents, skillIds: skills, force: Boolean(flags.force) });
      process.stdout.write(res.stdout);
      return res.exitCode;
    }
    default:
      break;
  }

  // Default: interactive TUI.
  if (!isInteractive()) {
    printNonInteractiveHelp();
    return 0;
  }

  return runApp();
}

// Restore terminal state on interrupt. We never call process.exit() from the
// signal handler directly: that can truncate buffered stdout on some terminals.
// Instead we set the exit code and let the process end naturally, which flushes.
let interrupted = false;
process.on('SIGINT', () => {
  interrupted = true;
  process.stdout.write('\n');
  process.exitCode = 130;
});

main()
  .then((code) => {
    process.exitCode = interrupted ? 130 : code;
  })
  .catch((err) => {
    process.stderr.write(`\n  ${paint('Error:', 'error')} ${(err as Error).message}\n`);
    process.exitCode = 1;
  });
