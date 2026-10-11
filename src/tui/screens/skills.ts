/**
 * SCREEN D - Skill pack selection.
 *
 * Choose one or more presets (multi-select). The chosen presets' skills are
 * merged and returned directly - there is no second "customise" screen. The
 * wizard then previews and installs.
 */

import type { Registry } from '../../types';
import { section } from '../components/theme';
import { plainCheckbox } from '../components/prompts';
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
      // Single-line, plain names keep the cursor math correct (multi-line names
      // or embedded ANSI break arrow-key navigation in the prompts library).
      name: `${p.name}  (${p.skills.length} skills)`,
      value: p.id,
      description: p.description,
    }));

  const pickedPresets = await plainCheckbox<string>({
    message: 'Choose your skills (space to toggle)',
    pageSize: 10,
    choices: presetChoices,
  });

  // Merge the selected presets' skills (the resolver also adds dependencies).
  const merged = new Set<string>();
  for (const id of pickedPresets) {
    for (const skillId of expandPreset(registry, id)) merged.add(skillId);
  }

  if (pickedPresets.length === 0) {
    return { skillIds: [], presetId: undefined };
  }

  process.stdout.write(
    `\n  Selected ${pickedPresets.length} preset(s).\n`
  );

  return {
    skillIds: [...merged],
    presetId: pickedPresets.join(', '),
  };
}
