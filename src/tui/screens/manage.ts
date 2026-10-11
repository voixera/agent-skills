/**
 * Maintenance actions reachable from the main menu: verify, update, uninstall.
 *
 * These are the only way to reach them now that the CLI has no subcommands.
 * Each delegates to the PowerShell engine (the single source of install truth).
 */

import { select } from '@inquirer/prompts';
import type { Registry, Scope } from '../../types';
import { section, paint } from '../components/theme';
import { verifyInstallation, uninstall } from '../../core/installer';
import { updateInstalled } from '../../core/uninstaller';
import { installedSkillIds, readManifest } from '../../core/manifest';

async function pickScope(): Promise<{ scope: Scope; projectRoot: string } | 'back'> {
  const choice = await select({
    message: 'Scope',
    loop: false,
    choices: [
      { name: `This project  ${paint(process.cwd(), 'dim')}`, value: 'project' as const },
      { name: 'My user profile', value: 'user' as const },
      { name: 'Back', value: 'back' as const },
    ],
  });
  if (choice === 'back') return 'back';
  return { scope: choice, projectRoot: process.cwd() };
}

export async function verifyScreen(_registry: Registry): Promise<'menu' | 'quit'> {
  process.stdout.write(section('Verify installed skills', 'Check files against the manifest.'));

  const target = await pickScope();
  if (target === 'back') return 'menu';

  const result = verifyInstallation(target.projectRoot, target.scope);
  process.stdout.write('\n');
  if (result.results.length === 0) {
    process.stdout.write(`  ${paint('Nothing installed for this scope.', 'dim')}\n\n`);
  } else {
    for (const r of result.results) {
      const tag =
        r.status === 'PASS' ? paint('PASS', 'ok')
        : r.status === 'FAIL' ? paint('FAIL', 'error')
        : r.status === 'WARN' ? paint('WARN', 'warn')
        : paint('SKIP', 'dim');
      process.stdout.write(`  ${tag} ${r.name}${r.message ? ` - ${r.message}` : ''}\n`);
    }
    process.stdout.write('\n');
  }
  return 'menu';
}

export async function updateScreen(_registry: Registry): Promise<'menu' | 'quit'> {
  process.stdout.write(section('Update installed skills', 'Re-apply from the registry.'));

  const target = await pickScope();
  if (target === 'back') return 'menu';

  const result = updateInstalled(target.projectRoot, target.scope);
  process.stdout.write('\n');
  if (!result) {
    process.stdout.write(`  ${paint('Nothing installed for this scope.', 'dim')}\n\n`);
    return 'menu';
  }
  process.stdout.write(result.stdout || `  ${paint('Update complete.', 'ok')}\n`);
  process.stdout.write('\n');
  return 'menu';
}

export async function uninstallScreen(_registry: Registry): Promise<'menu' | 'quit'> {
  process.stdout.write(section('Uninstall skills', 'Remove only files Agent Skills created.'));

  const target = await pickScope();
  if (target === 'back') return 'menu';

  // Show what is installed so the user can decide.
  let installed: string[] = [];
  try {
    installed = installedSkillIds(readManifest(target.projectRoot, target.scope));
  } catch {
    installed = [];
  }

  if (installed.length === 0) {
    process.stdout.write(`\n  ${paint('Nothing installed for this scope.', 'dim')}\n\n`);
    return 'menu';
  }

  const choice = await select({
    message: 'Remove',
    loop: false,
    choices: [
      { name: `All installed skills (${installed.length})`, value: '__all__' },
      ...installed.map((id) => ({ name: id, value: id })),
      { name: 'Back', value: '__back__' },
    ],
  });

  if (choice === '__back__') return 'menu';

  const skillIds = choice === '__all__' ? [] : [choice as string];
  const result = choice === '__all__'
    ? uninstall(target.projectRoot, target.scope, [], [])
    : uninstall(target.projectRoot, target.scope, skillIds, []);

  process.stdout.write('\n');
  process.stdout.write(result.stdout || `  ${paint('Uninstall complete.', 'ok')}\n`);
  process.stdout.write('\n');
  return 'menu';
}
