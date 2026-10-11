/**
 * The TUI application state machine.
 *
 * Screens are small functions that render with @inquirer/prompts and return the
 * user's choice. This module wires them together and owns the mutable
 * application state. It contains no install logic: it calls the core.
 */

import type { Registry, UserSelection } from '../types';
import { loadAndValidateRegistry, RegistryError } from '../core/registry';
import { banner } from './components/theme';
import { welcomeScreen } from './screens/welcome';
import { scopeScreen } from './screens/scope';
import { agentsScreen } from './screens/agents';
import { skillsScreen } from './screens/skills';
import { previewScreen } from './screens/preview';
import { progressScreen } from './screens/progress';
import { completeScreen } from './screens/complete';
import { verifyScreen, updateScreen, uninstallScreen } from './screens/manage';
import { installedSkillIds, readManifest } from '../core/manifest';

export interface AppState {
  registry: Registry;
  selection: Partial<UserSelection>;
}

export async function runApp(): Promise<number> {
  // Validate the registry up front so the mistake surfaces immediately.
  let registry: Registry;
  try {
    registry = loadAndValidateRegistry();
  } catch (err) {
    process.stdout.write(banner());
    if (err instanceof RegistryError) {
      process.stderr.write(`\n  ${'Registry is invalid:'}\n`);
      for (const p of err.problems) process.stderr.write(`   - ${p}\n`);
    } else {
      process.stderr.write(`\n  ${(err as Error).message}\n`);
    }
    return 1;
  }

  const state: AppState = { registry, selection: {} };

  // The main loop lets the user return to the menu after completing.
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const outcome = await runFlow(state);
    if (outcome.action === 'quit') return 0;
    if (outcome.action === 'exit') return outcome.exitCode;
    // 'menu' loops again.
  }
}

async function runFlow(state: AppState): Promise<{ action: 'menu' | 'quit' | 'exit'; exitCode: number }> {
  const start = await welcomeScreen(state.registry);
  if (start === 'quit') return { action: 'quit', exitCode: 0 };
  if (start === 'verify') {
    await verifyScreen(state.registry);
    return { action: 'menu', exitCode: 0 };
  }
  if (start === 'update') {
    await updateScreen(state.registry);
    return { action: 'menu', exitCode: 0 };
  }
  if (start === 'uninstall') {
    await uninstallScreen(state.registry);
    return { action: 'menu', exitCode: 0 };
  }

  const scope = await scopeScreen(state.registry);
  if (scope === 'back') return { action: 'menu', exitCode: 0 };

  const agents = await agentsScreen(state.registry, scope.scope);
  if (agents === 'back') return { action: 'menu', exitCode: 0 };

  const skills = await skillsScreen(state.registry, agents.agentIds);
  if (skills === 'back') return { action: 'menu', exitCode: 0 };

  const preview = await previewScreen(state.registry, {
    scope: scope.scope,
    projectRoot: scope.projectRoot,
    agentIds: agents.agentIds,
    skillIds: skills.skillIds,
    presetId: skills.presetId,
  });
  if (preview === 'back') return { action: 'menu', exitCode: 0 };

  const result = await progressScreen(state.registry, preview.selection, preview.force);

  const completion = await completeScreen(state.registry, preview.selection, result);
  if (completion === 'menu') return { action: 'menu', exitCode: 0 };
  return { action: 'exit', exitCode: result.exitCode };
}

export function registrySummary(registry: Registry) {
  return {
    skills: registry.skills.skills.length,
    agents: registry.agents.agents.length,
    presets: registry.presets.presets.length,
  };
}

export function currentlyInstalled(projectRoot: string, scope: 'project' | 'user'): string[] {
  try {
    return installedSkillIds(readManifest(projectRoot, scope));
  } catch {
    return [];
  }
}
