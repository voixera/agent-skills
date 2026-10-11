/**
 * Dry-run planner (core).
 *
 * Produces the same plan the PowerShell engine would execute, but in-process,
 * so the preview screen is instant. The engine still performs the real install;
 * this module never writes files.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type {
  AgentDefinition,
  InstallPlan,
  PlanAction,
  PlanDiagnostic,
  Registry,
  Scope,
} from '../types';
import { getAgent, getSkill } from './registry';
import { resolveDependencies } from './resolver';
import { homeDirectory, readManifest } from './manifest';
import { MANAGED_BLOCK_MARKERS } from './adapters';

export interface PlanOptions {
  registry: Registry;
  projectRoot: string;
  scope: Scope;
  agentIds: string[];
  skillIds: string[];
  includeDependencies?: boolean;
}

function scopeRoot(projectRoot: string, scope: Scope): string {
  return scope === 'user' ? homeDirectory() : path.resolve(projectRoot);
}

/** Compute the destination for a skill+agent+scope, mirroring the engine. */
export function installPath(
  agent: AgentDefinition,
  skillId: string,
  scope: Scope,
  projectRoot: string
): string {
  const template = agent.paths[scope];
  if (!template) {
    throw new Error(`Agent '${agent.id}' does not support scope '${scope}'.`);
  }
  const expanded = template.replace(/<skillId>/g, skillId);
  if (scope === 'user') {
    const home = homeDirectory();
    return path.join(home, expanded.replace(/^~[\\/]?/, ''));
  }
  return path.join(projectRoot, expanded.replace(/^~[\\/]?/, ''));
}

function isInside(candidate: string, root: string): boolean {
  const rel = path.relative(path.resolve(root), path.resolve(candidate));
  return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
}

export function buildPlan(options: PlanOptions): InstallPlan {
  const { registry, projectRoot, scope, agentIds } = options;
  const includeDeps = options.includeDependencies ?? true;

  const selection = includeDeps
    ? resolveDependencies(registry, options.skillIds)
    : { requested: options.skillIds, resolved: options.skillIds, addedDependencies: [] };

  const root = scopeRoot(projectRoot, scope);
  const actions: PlanAction[] = [];
  const diagnostics: PlanDiagnostic[] = [];

  // Aggregate managed-block destinations (one file per agent).
  const aggregated = new Map<
    string,
    { agent: AgentDefinition; skillIds: string[] }
  >();

  for (const skillId of selection.resolved) {
    const skill = getSkill(registry, skillId);

    for (const agentId of agentIds) {
      const agent = getAgent(registry, agentId);

      if (!skill.agents.includes(agentId)) {
        diagnostics.push({
          status: 'WARN',
          name: `compat ${skillId}/${agentId}`,
          message: `Skill '${skillId}' does not support agent '${agentId}'; it will be skipped.`,
          category: 'compatibility',
        });
        continue;
      }

      if (!agent.scopes.includes(scope)) {
        diagnostics.push({
          status: 'WARN',
          name: `scope ${skillId}/${agentId}`,
          message: `Agent '${agentId}' does not support scope '${scope}'; it will be skipped.`,
          category: 'compatibility',
        });
        continue;
      }

      const destination = installPath(agent, skillId, scope, projectRoot);
      if (!isInside(destination, root)) {
        diagnostics.push({
          status: 'FAIL',
          name: `traversal ${skillId}/${agentId}`,
          message: `Resolved path escapes the selected scope: ${destination}`,
          category: 'safety',
        });
        continue;
      }

      if (agent.format === 'aggregated-instructions') {
        const existing = aggregated.get(destination) ?? { agent, skillIds: [] };
        if (!existing.skillIds.includes(skillId)) existing.skillIds.push(skillId);
        aggregated.set(destination, existing);
        continue;
      }

      const exists = fs.existsSync(destination);
      actions.push({
        kind: 'file',
        agentId,
        skillId,
        skillVersion: skill.version,
        destination,
        relativePath: path.relative(root, destination).split(path.sep).join('/'),
        action: exists ? 'overwrite' : 'create',
        format: agent.format,
      });
    }
  }

  for (const [destination, entry] of aggregated) {
    const exists = fs.existsSync(destination);
    let conflicted = false;
    if (exists) {
      const content = fs.readFileSync(destination, 'utf8');
      conflicted = !content.includes(MANAGED_BLOCK_MARKERS.begin);
    }
    actions.push({
      kind: 'managed-block',
      agentId: entry.agent.id,
      skillId: entry.skillIds.join(', '),
      skillVersion: '',
      destination,
      relativePath: path.relative(root, destination).split(path.sep).join('/'),
      action: exists ? 'overwrite' : 'create',
      format: entry.agent.format,
    });
    if (conflicted) {
      diagnostics.push({
        status: 'WARN',
        name: `managed ${destination}`,
        message: 'Existing file will be merged around a managed block; surrounding content is preserved.',
        category: 'compatibility',
      });
    }
  }

  // A destination that exists but is NOT tracked by the manifest is a conflict
  // for whole-file writes.
  try {
    const manifest = readManifest(projectRoot, scope);
    const tracked = new Set(manifest.files.map((f) => f.path));
    for (const a of actions) {
      if (a.action === 'overwrite' && a.kind === 'file' && !tracked.has(a.destination)) {
        diagnostics.push({
          status: 'FAIL',
          name: a.relativePath,
          message: 'Existing untracked file; confirm overwrite to proceed (a backup is taken).',
          category: 'conflict',
        });
      }
    }
  } catch {
    // A missing/corrupt manifest is not fatal for planning.
  }

  return {
    scope,
    projectRoot,
    scopeRoot: root,
    agents: agentIds,
    requested: selection.requested,
    resolved: selection.resolved,
    addedDependencies: selection.addedDependencies,
    actions,
    diagnostics,
  };
}

export function summarizePlan(plan: InstallPlan) {
  const created = plan.actions.filter((a) => a.action === 'create').length;
  const updated = plan.actions.filter((a) => a.action === 'overwrite').length;
  const unchanged = plan.actions.filter((a) => a.action === 'unchanged').length;
  const conflicts = plan.diagnostics.filter((d) => d.category === 'conflict').length;
  const warnings = plan.diagnostics.filter((d) => d.status === 'WARN').length;
  return { created, updated, unchanged, conflicts, warnings, total: plan.actions.length };
}
