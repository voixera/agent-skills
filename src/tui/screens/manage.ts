/**
 * Uninstall action (reachable from the main menu).
 *
 * Shows the skills currently installed, then removes the chosen ones. Only files
 * recorded in the manifest are removed; nothing else is touched.
 */

import type { Registry } from '../../types';
import { section, paint } from '../components/theme';
import { plainCheckbox } from '../components/prompts';
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

  // Single list: the checkbox itself is the list of installed skills (showing it
  // twice made the screen look like it repeated).
  const picked = await plainCheckbox<string>({
    message: `Select the skills to remove (${installed.length} installed)`,
    pageSize: 12,
    choices: installed.map((id) => ({ name: `${nameOf(id)}  (${id})`, value: id })),
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
