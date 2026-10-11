/**
 * SCREEN A - Welcome / main menu.
 *
 * Logo, one-line description, version, and the primary actions. No command
 * typing required: everything is reachable from here.
 */

import { select } from '@inquirer/prompts';
import type { Registry } from '../../types';
import { banner, paint, toolVersion } from '../components/theme';

export type MainAction = 'install' | 'uninstall' | 'quit';

export async function welcomeScreen(registry: Registry): Promise<MainAction> {
  process.stdout.write(banner());

  const stats = `${registry.skills.skills.length} skills  \u2022  ${registry.agents.agents.length} agents  \u2022  ${registry.presets.presets.length} presets`;
  process.stdout.write(`  ${paint(stats, 'dim')}\n`);

  const choice = await select<MainAction>({
    message: 'What would you like to do?',
    loop: false,
    choices: [
      { name: 'Install skills into your agent setup', value: 'install' },
      { name: 'Uninstall skills', value: 'uninstall' },
      { name: 'Exit', value: 'quit' },
    ],
  });

  return choice;
}

export async function postActionMenu(): Promise<'menu' | 'quit'> {
  const choice = await select<'menu' | 'quit'>({
    message: 'What next?',
    loop: false,
    choices: [
      { name: 'Back to main menu', value: 'menu' },
      { name: 'Exit', value: 'quit' },
    ],
  });
  return choice;
}

export { toolVersion };
