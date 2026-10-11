/**
 * SCREEN A - Welcome.
 *
 * Logo, description, version, and a Start option. No command typing required.
 */

import { select } from '@inquirer/prompts';
import type { Registry } from '../../types';
import { banner, hintBar, KEY_HINTS, paint } from '../components/theme';

export async function welcomeScreen(registry: Registry): Promise<'start' | 'quit'> {
  process.stdout.write(banner());

  const stats = `${registry.skills.skills.length} skills  \u2022  ${registry.agents.agents.length} agents  \u2022  ${registry.presets.presets.length} presets`;
  process.stdout.write(`  ${paint(stats, 'dim')}\n\n`);

  const choice = await select({
    message: 'What would you like to do?',
    loop: false,
    choices: [
      { name: 'Start installation', value: 'start' as const },
      { name: 'Exit', value: 'quit' as const },
    ],
  });

  return choice;
}
