/**
 * Installation service (core).
 *
 * Thin facade over the TypeScript engine, kept as the module the TUI imports.
 * Everything runs in-process.
 */

import type { InstallResult, Registry, Scope } from '../types';
import { applyPlan, verify, uninstallSkills, type ApplyOptions } from './engine';
import { buildPlan } from './planner';
import { readManifest } from './manifest';
import { resolveDependencies } from './resolver';

export interface ExecuteOptions {
  registry: Registry;
  projectRoot: string;
  scope: Scope;
  agentIds: string[];
  skillIds: string[];
  force?: boolean;
}

export interface ExecuteOutcome {
  exitCode: number;
  results: InstallResult[];
  created: number;
  updated: number;
  skipped: number;
  failed: number;
}

/** Execute an installation in-process. */
export function executeInstall(options: ExecuteOptions): ExecuteOutcome {
  return applyPlan(options.registry, {
    projectRoot: options.projectRoot,
    scope: options.scope,
    agentIds: options.agentIds,
    skillIds: options.skillIds,
    force: options.force,
  } as ApplyOptions);
}

export interface VerifyOutcome {
  exitCode: number;
  results: InstallResult[];
}

export function verifyInstallation(projectRoot: string, scope: Scope): VerifyOutcome {
  const results = verify(projectRoot, scope);
  const exitCode = results.some((r) => r.status === 'FAIL') ? 1 : 0;
  return { exitCode, results };
}

export interface UninstallOutcome {
  exitCode: number;
  results: InstallResult[];
}

export function uninstall(
  registry: Registry,
  projectRoot: string,
  scope: Scope,
  skillIds: string[],
  agentIds: string[]
): UninstallOutcome {
  const results = uninstallSkills(registry, {
    projectRoot,
    scope,
    skillIds,
    agentIds,
    all: skillIds.length === 0 && agentIds.length === 0,
  });
  const exitCode = results.some((r) => r.status === 'FAIL') ? 1 : 0;
  return { exitCode, results };
}

export { buildPlan };
