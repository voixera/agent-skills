/**
 * SCREEN D - Skill pack selection.
 *
 * Two steps:
 *   1. Pick a preset (or Custom). Picking a preset preselects its skills but
 *      does not lock them.
 *   2. Customise the skill set with a checkbox list grouped by category.
 *
 * Only skills present in the validated registry are shown.
 */

import { select, checkbox } from '@inquirer/prompts';
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
  process.stdout.write(
    section('Select skill packs', 'Start from a preset, then customise.')
  );

  const presetChoices = registry.presets.presets
    .sort((a, b) => a.name.localeCompare(b.name))
    .map((p) => ({
      name: `${p.name}  ${paint(`(${p.skills.length})`, 'dim')}\n      ${paint(p.description, 'dim')}`,
      value: p.id,
    }));

  presetChoices.push({
    name: `Custom Setup\n      ${paint('Choose individual skills', 'dim')}`,
    value: '__custom__',
  });
  presetChoices.push({ name: paint('\u2190 Back', 'dim'), value: '__back__' });

  const presetId = await select({
    message: 'Preset',
    loop: false,
    pageSize: 12,
    choices: presetChoices,
  });

  if (presetId === '__back__') return 'back';

  let initialSelection: string[] = [];
  if (presetId !== '__custom__') {
    initialSelection = expandPreset(registry, presetId);
    process.stdout.write(
      `\n  ${paint(`Preset '${presetId}' preselected ${initialSelection.length} skill(s).`, 'ok')}\n` +
        `  ${paint('You can still toggle individual skills below.', 'dim')}\n`
    );
  }

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
        checked: initialSelection.includes(skill.id),
      });
    }
  }

  process.stdout.write('\n');
  const picked = await checkbox({
    message: 'Skills (space toggles, "a" toggles all, enter confirms)',
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
    presetId: presetId === '__custom__' ? undefined : presetId,
  };
}
