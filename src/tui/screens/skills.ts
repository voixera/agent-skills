/**
 * SCREEN D - Skill pack selection.
 *
 * Choose one or more presets (multi-select). The chosen presets' skills are
 * merged and returned directly - there is no second "customise" screen. The
 * wizard then previews and installs.
 */

import { checkbox } from '@inquirer/prompts';
import type { Registry } from '../../types';
import { section, paint } from '../components/theme';
import { expandPreset } from '../../core/resolver';

export interface SkillChoice {
  skillIds: string[];
  presetId?: string;
}

export async function skillsScreen(
  registry: Registry,
  _agentIds: string[]
): Promise<SkillChoice | 'back'> {
  process.stdout.write(section('Select skill packs', 'Choose one or more presets.'));

  const presetChoices = registry.presets.presets
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((p) => ({
      name: `${p.name}  ${paint(`(${p.skills.length})`, 'dim')}\n      ${paint(p.description, 'dim')}`,
      value: p.id,
    }));

  const pickedPresets = await checkbox({
    message: 'Choose your skills (space to toggle)',
    instructions: '\u2191/\u2193 to navigate  \u2022  Space: select  \u2022  a: all  \u2022  Enter: confirm',
    pageSize: 12,
    required: false,
    choices: presetChoices,
    validate: (choices) => (choices.length === 0 ? 'Select at least one preset.' : true),
  });

  // Merge the selected presets' skills (the resolver also adds dependencies).
  const merged = new Set<string>();
  for (const id of pickedPresets) {
    for (const skillId of expandPreset(registry, id)) merged.add(skillId);
  }

  process.stdout.write(
    `\n  ${paint(`Selected ${pickedPresets.length} preset(s).`, 'ok')}\n`
  );

  return {
    skillIds: [...merged],
    presetId: pickedPresets.join(', '),
  };
}
