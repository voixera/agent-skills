/**
 * Uninstall and update (core).
 *
 * Both delegate to the PowerShell engine (the single source of install truth).
 * They never touch files directly.
 */

import type { Scope } from '../types';
import { executeInstall, uninstall as engineUninstall, type ExecuteOutcome } from './installer';
import { installedSkillIds, readManifest } from './manifest';

export function uninstallSkills(
  projectRoot: string,
  scope: Scope,
  skillIds: string[]
): ExecuteOutcome {
  return engineUninstall(projectRoot, scope, skillIds, []);
}

export function uninstallAll(projectRoot: string, scope: Scope): ExecuteOutcome {
  return engineUninstall(projectRoot, scope, [], []);
}

/**
 * Update: re-apply exactly what the manifest says is installed. Idempotent.
 */
export function updateInstalled(projectRoot: string, scope: Scope): ExecuteOutcome | null {
  const manifest = readManifest(projectRoot, scope);
  if (manifest.files.length === 0) return null;

  const skillIds = installedSkillIds(manifest);
  const agentIds = [...new Set(manifest.files.map((f) => f.agentId).filter(Boolean))];
  if (skillIds.length === 0 || agentIds.length === 0) return null;

  return executeInstall({
    projectRoot,
    scope,
    agentIds,
    skillIds,
    force: true,
  });
}
