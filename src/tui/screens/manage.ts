/**
 * Uninstall action (reachable from the main menu).
 *
 * Shows the skills currently installed, then removes the chosen ones. Only files
 * recorded in the manifest are removed; nothing else is touched.
 */

import { select, checkbox } from '@inquirer/prompts';
import type { Registry } from '../../types';
import { section, paint } from '../components/theme';
import { uninstall } from '../../core/installer';
import { installedSkillIds, readManifest } from '../../core/manifest';
import { getSkill } from '../../core/registry';

const SCOPE = 'project' as const;

export async function uninstallScreen(registry: Registry): Promise<'menu' | 'quit'> {
  process.stdout.write(section('Uninstall skills', 'Remove skills Agent Skills installed.'));

  const projectRoot = process.cwd();

  // Show what is installed so the user can decide.
  let installed: string[] = [];
  try {
    installed = installedSkillIds(readManifest(projectRoot, SCOPE));
  } catch {
    installed = [];
  }

  if (installed.length === 0) {
    process.stdout.write(`  ${paint('No skills are installed here.', 'dim')}\n\n`);
    return 'menu';
  }

  // Label each installed skill with its friendly name when known.
  const nameOf = (id: string): string => {
    try {
      return getSkill(registry, id).name;
    } catch {
      return id;
    }
  };

  process.stdout.write(`  ${paint(`Installed skills (${installed.length}):`, 'bold')}\n`);
  for (const id of installed) process.stdout.write(`    - ${nameOf(id)}  ${paint(`(${id})`, 'dim')}\n`);
  process.stdout.write('\n');

  const picked = await checkbox({
    message: 'Select the skills to remove',
    instructions: '\u2191/\u2193 to navigate  \u2022  Space: select  \u2022  a: all  \u2022  Enter: confirm',
    pageSize: 20,
    required: false,
    // Keep choice names plain (no ANSI) - coloured/ANSI names break the cursor
    // math in @inquirer/prompts and make the list loop on arrow keys.
    choices: installed.map((id) => ({ name: `${nameOf(id)}  (${id})`, value: id })),
    validate: (choices) => (choices.length === 0 ? 'Select at least one skill (or Esc to go back).' : true),
  });

  if (picked.length === 0) return 'menu';

  const result = uninstall(registry, projectRoot, SCOPE, picked, []);
  const removed = result.results.filter((r) => r.status === 'PASS').length;
  const stillInstalled = installed.filter((id) => !picked.includes(id));

  process.stdout.write('\n');
  process.stdout.write(`  ${paint(`Removed ${removed} item(s).`, 'ok')}\n`);
  if (stillInstalled.length > 0) {
    process.stdout.write(`  ${paint(`Still installed (${stillInstalled.length}):`, 'dim')} ${stillInstalled.join(', ')}\n`);
  } else {
    process.stdout.write(`  ${paint('Nothing is installed here now.', 'dim')}\n`);
  }
  process.stdout.write('\n');

  return 'menu';
}
