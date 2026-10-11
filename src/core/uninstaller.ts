/**
 * Update (core): re-apply exactly what the manifest says is installed.
 * Idempotent. Runs in-process via the TypeScript engine.
 */

import type { Registry, Scope } from '../types';
import { executeInstall, type ExecuteOutcome } from './installer';
import { installedSkillIds, readManifest } from './manifest';

export function updateInstalled(registry: Registry, projectRoot: string, scope: Scope): ExecuteOutcome | null {
  const manifest = readManifest(projectRoot, scope);
  if (manifest.files.length === 0) return null;

  const skillIds = installedSkillIds(manifest);
  const agentIds = [...new Set(manifest.files.map((f) => f.agentId).filter(Boolean))];
  if (skillIds.length === 0 || agentIds.length === 0) return null;

  return executeInstall({ registry, projectRoot, scope, agentIds, skillIds, force: true });
}
