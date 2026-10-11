/**
 * SCREEN D - Skill pack selection.
 *
 * Choose one or more presets (multi-select). The chosen presets' skills are
 * merged and preselected in a customise list, so you can still toggle individual
 * skills before installing.
 */

import { checkbox } from '@inquirer/prompts';
import type { Registry } from '../../types';
import { section, paint } from '../components/theme';
import { skillsByCategory } from '../../core/registry';
import { expandPreset } from '../../core/resolver';

export interface SkillChoice {
  skillIds: string[];
  presetId?: string;
}

const CATEGORY_TITLES: Record<string, string> = {
  frontend: 'Frontend',
  backend: 'Backend',
  'ui-ux': 'UI/UX',
  svg: 'SVG & Visual Design',
  testing: 'Testing',
  security: 'Security',
  devops: 'DevOps',
  'anti-slop': 'Quality & Engineering',
};

export async function skillsScreen(
  registry: Registry,
  _agentIds: string[]
): Promise<SkillChoice | 'back'> {
  process.stdout.write(section('Select skill packs', 'Choose one or more presets.'));

  // Step 1: multi-select presets.
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

  // Merge the selected presets' skills.
  const merged = new Set<string>();
  for (const id of pickedPresets) {
    for (const skillId of expandPreset(registry, id)) merged.add(skillId);
  }

  process.stdout.write(
    `\n  ${paint(`Selected ${pickedPresets.length} preset(s) - ${merged.size} skill(s).`, 'ok')}\n`
  );

  // Step 2: show the combined skill list, all preselected and still editable.
  const byCategory = skillsByCategory(registry);
  const orderedCategories = Object.keys(CATEGORY_TITLES).filter((c) => byCategory.has(c));
  for (const c of byCategory.keys()) if (!orderedCategories.includes(c)) orderedCategories.push(c);

  const choices: { name: string; value: string; checked?: boolean }[] = [];
  for (const category of orderedCategories) {
    choices.push({
      name: paint(`-- ${CATEGORY_TITLES[category] ?? category} --`, 'brand'),
      value: `__header_${category}__`,
      checked: false,
    });
    for (const skill of byCategory.get(category) ?? []) {
      choices.push({
        name: `${skill.name}  ${paint(`(${skill.id})`, 'dim')}`,
        value: skill.id,
        checked: merged.has(skill.id),
      });
    }
  }

  process.stdout.write('\n');
  const picked = await checkbox({
    message: 'Review and customise the skills to install',
    instructions: '\u2191/\u2193 to navigate  \u2022  Space: select  \u2022  a: all  \u2022  Enter: confirm',
    choices,
    pageSize: 20,
    required: false,
    validate: (choices) => {
      const real = choices.map((c) => c.value).filter((v) => !v.startsWith('__header_'));
      if (real.length === 0) return 'Select at least one skill.';
      return true;
    },
  });

  const skillIds = picked.filter((v) => !v.startsWith('__header_'));
  return {
    skillIds,
    presetId: pickedPresets.join(', '),
  };
}
