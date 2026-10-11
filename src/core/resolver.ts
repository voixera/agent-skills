/**
 * Selection resolution (core): expand a set of requested skill ids into a
 * dependency-closed set, and expand presets into skill ids.
 *
 * so the TUI can preview exactly
 * what will be installed before shelling out.
 */

import type { Registry } from '../types';
import { getPreset, getSkill } from './registry';

export interface ResolvedSelection {
  requested: string[];
  resolved: string[];
  addedDependencies: string[];
}

export function resolveDependencies(reg: Registry, skillIds: string[]): ResolvedSelection {
  const requested = new Set(skillIds);
  const resolved = new Set<string>();
  const addedDependencies: string[] = [];

  // Iterative post-order traversal with an explicit stack for cycle safety.
  const visiting = new Set<string>();
  const done = new Set<string>();

  const visit = (id: string): void => {
    if (done.has(id)) return;
    if (visiting.has(id)) {
      throw new Error(`Circular dependency detected involving skill '${id}'.`);
    }
    visiting.add(id);
    const skill = getSkill(reg, id);
    for (const dep of skill.depends ?? []) {
      visit(dep);
    }
    visiting.delete(id);
    done.add(id);
    resolved.add(id);
    if (!requested.has(id)) addedDependencies.push(id);
  };

  for (const id of skillIds) visit(id);

  return {
    requested: [...requested],
    resolved: [...resolved],
    addedDependencies,
  };
}

export function expandPreset(reg: Registry, presetId: string): string[] {
  const preset = getPreset(reg, presetId);
  // Validate refs (throws on unknown).
  for (const ref of preset.skills) getSkill(reg, ref);
  return [...preset.skills];
}
